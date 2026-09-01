"""Годовой график объекта по программе обслуживания модели.

Две ручки на одну раскладку. Предпросмотр ничего не пишет в базу: человек
сначала смотрит, что ляжет в двенадцать месяцев. Создание пишет — и берёт
клетки того же предпросмотра, а не считает год заново.

Путь начинается с `/planned-to/`, потому что речь про годовой план объекта,
а не про программу модели: программа — шаблон на модель, а тут уже
конкретный дом и конкретный год.
"""

from typing import Optional, Tuple

from fastapi import APIRouter, Depends, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import SingleEntityResponse
from src.crud.crud_maintenance_program import crud_maintenance_program
from src.crud.crud_object import crud_objects
from src.crud.crud_schedule_plan import (
    act_bases_by_type_act,
    create_year_schedule,
    months_of_year,
)
from src.exceptions import UnfoundEntity, UnprocessableEntity
from src.getters.schedule_plan import build_preview, detect_anchor
from src.models import Object
from src.schemas.maintenance_program import PROGRAM_LENGTH
from src.schemas.schedule_plan import (
    ScheduleGenerate,
    ScheduleGeneratedCell,
    ScheduleGenerateResult,
    SchedulePreview,
)
from src.templates_raise import get_raise

router = APIRouter()

TAGS = ["Годовой график"]


def _anchor_required(reason: str) -> UnprocessableEntity:
    """Якорь не восстановился — его обязан назвать человек.

    Молча выбрать сдвиг за него нельзя: это сдвинуло бы весь год, и на
    экране это выглядело бы как «система сама так решила».
    """
    return UnprocessableEntity(
        message=f"Укажите anchor_month — месяц, с которого начинается цикл: {reason}",
        num=144,
        description=(
            "Якорь берётся из графика за прошлый год. Если его нет или он "
            "расставлен не по этой программе, месяц начала цикла выбирает "
            "человек."
        ),
        path="$.query.anchor_month",
    )


def _resolve_preview(
    session,
    *,
    scope,
    object_id: int,
    year: int,
    anchor_month: Optional[int],
) -> Tuple[SchedulePreview, Object]:
    """Разбор входа, общий для предпросмотра и создания графика.

    Объект, его модель, программа модели, якорь цикла и занятые месяцы —
    создание графика спрашивает у базы ровно то же, что и предпросмотр, и
    отвечает теми же кодами. Держим это в одном месте, чтобы ручки не
    разошлись в текстах ошибок.
    """
    # Объект достаётся готовой проверкой: она уже различает «нет такого»
    # (404) и «не ваш» (403), и список объектов режется тем же правилом.
    obj, code, _ = crud_objects.get_object_by_id(
        db=session, object_id=object_id, scope=scope
    )
    get_raise(code=code)

    if obj.factory_model_id is None:
        raise UnfoundEntity(
            message="У этого объекта не указана модель оборудования!",
            num=142,
            description=(
                "Программа обслуживания принадлежит модели, поэтому без "
                "модели график не разложить."
            ),
            path="$.query.object_id",
        )

    program = crud_maintenance_program.get_by_model(
        db=session, factory_model_id=obj.factory_model_id
    )
    if program is None:
        raise UnfoundEntity(
            message="У модели этого объекта нет программы обслуживания!",
            num=143,
            description=(
                "Заведите программу через PUT /maintenance-program/by-model/"
                "{factory_model_id}/. Готовую раскладку можно взять из "
                ".../suggestion/."
            ),
            path="$.query.object_id",
        )

    program_by_position = {item.position: item.type_act_id for item in program.items}
    missing_positions = sorted(
        set(range(1, PROGRAM_LENGTH + 1)) - set(program_by_position)
    )
    if missing_positions:
        # Через `PUT` неполная программа не пройдёт, но данные в базе старше
        # этой проверки. Пусть будет внятный 422, а не `KeyError` и 500.
        raise UnprocessableEntity(
            message=f"В программе модели не заполнены позиции {missing_positions}!",
            num=145,
            description=(
                "Сохраните программу целиком через "
                "PUT /maintenance-program/by-model/{factory_model_id}/."
            ),
            path="$.query.object_id",
        )

    type_act_names = {
        item.type_act_id: item.type_act.name
        for item in program.items
        if item.type_act is not None and item.type_act.name is not None
    }

    if anchor_month is None:
        previous = months_of_year(session, object_id=object_id, year=year - 1)
        if not previous:
            raise _anchor_required(f"графика за {year - 1} год у объекта нет")

        anchor_month = detect_anchor(
            program_by_position=program_by_position,
            previous_type_acts={
                month: row.type_act_id for month, row in previous.items()
            },
        )
        if anchor_month is None:
            raise _anchor_required(
                f"график за {year - 1} год не ложится на эту программу однозначно"
            )

    occupied = months_of_year(session, object_id=object_id, year=year)

    preview = build_preview(
        object_id=object_id,
        year=year,
        anchor_month=anchor_month,
        program_id=program.id,
        factory_model_id=obj.factory_model_id,
        program_by_position=program_by_position,
        type_act_names=type_act_names,
        available_type_act_ids=crud_maintenance_program.available_type_act_ids(
            db=session, factory_model_id=obj.factory_model_id
        ),
        occupied_months=occupied.keys(),
    )
    return preview, obj


@router.get(
    path="/planned-to/preview/",
    response_model=SingleEntityResponse[SchedulePreview],
    name="schedule_preview",
    summary="Предпросмотр годового графика по программе",
    description=(
        "🗓 Двенадцать клеток года, разложенных по программе обслуживания "
        "модели. **В базу не пишется ничего** — ни `planned_to`, ни актов: "
        "это заготовка, которую человек ещё утверждает.\n\n"
        "`position` — месяц **цикла**, `month` — месяц календаря. Связывает "
        "их якорь: на `anchor_month` приходится первая позиция программы.\n\n"
        "**Якорь можно не передавать**, если у объекта есть график за "
        "прошлый год: тогда сдвиг цикла подбирается по видам ТО его "
        "заполненных месяцев, и цикл продолжается через границу года без "
        "разрыва. Прошлого года нет, он расставлен не по этой программе или "
        "ложится на неё несколькими способами — `anchor_month` обязателен, "
        "иначе 422.\n\n"
        "`occupied` — месяц уже занят актом: создание графика такой месяц не "
        "тронет. `template_missing` — у модели нет шаблона чек-листа "
        "(`acts_bases`) на этот вид ТО: клетка показывается, но утвердить "
        "график, не заведя шаблон, не выйдет.\n\n"
        "Нет программы у модели объекта — 404: сначала заводится программа "
        "(`PUT /maintenance-program/by-model/{factory_model_id}/`), готовую "
        "раскладку даёт `.../suggestion/`.\n\n"
        "Объект режется областью видимости: чужой лифт — 403, а не 404."
    ),
    tags=TAGS,
)
def schedule_preview(
    session=Depends(deps.get_db),
    object_id: int = Query(..., title="ID объекта"),
    year: int = Query(..., ge=2000, le=2100, title="Год графика"),
    anchor_month: int = Query(
        None,
        ge=1,
        le=12,
        title="Месяц, с которого начинается цикл программы",
        description=(
            "Без параметра берётся из графика за прошлый год. Переданный "
            "параметр прошлый год не смотрит вовсе."
        ),
    ),
    current_user=Depends(deps.require(Permission.PLANNED_TO_READ)),
    scope=Depends(deps.get_read_scope),
):
    preview, _ = _resolve_preview(
        session,
        scope=scope,
        object_id=object_id,
        year=year,
        anchor_month=anchor_month,
    )
    return SingleEntityResponse(data=preview)


@router.post(
    path="/planned-to/generate/",
    response_model=SingleEntityResponse[ScheduleGenerateResult],
    name="schedule_generate",
    summary="Создать годовой график по программе",
    description=(
        "🗓 Расставляет год по программе обслуживания модели одним вызовом: "
        "заводит `planned_to` за год, если его ещё нет, и по акту "
        "(`acts_fact`) в каждый **свободный** месяц.\n\n"
        "Раскладка та же, что показывает `GET /planned-to/preview/` при тех "
        "же параметрах: сначала предпросмотр, потом эта ручка.\n\n"
        "**Занятый месяц не трогается вовсе** — ни акт, ни ячейка: его номер "
        "возвращается в `skipped`. Отсюда и идемпотентность — повторный "
        "вызов с теми же параметрами не добавляет ничего и отдаёт все "
        "двенадцать месяцев в `skipped`.\n\n"
        "Созданный акт: объект, шаблон чек-листа модели на этот вид ТО, "
        "чек-лист из шаблона и статус «Создано». Прораб и механик берутся из "
        "карточки объекта; **не заполнены у объекта — остаются пустыми в "
        "актах**, проставить их можно потом.\n\n"
        "**422, если хоть на один нужный вид ТО у модели нет шаблона** "
        "(`acts_bases`) — в предпросмотре это `template_missing`. График не "
        "создаётся частично: сначала заводятся шаблоны.\n\n"
        "Ручная правка отдельного месяца по-прежнему делается через "
        "`POST /planned-to/` и `PUT /planned-to/{planned_to_id}/`.\n\n"
        "Права `planned_to:write`; чужой лифт — 403, а не 404."
    ),
    tags=TAGS,
)
def schedule_generate(
    new_data: ScheduleGenerate,
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.PLANNED_TO_WRITE)),
    scope=Depends(deps.get_write_scope),
):
    preview, obj = _resolve_preview(
        session,
        scope=scope,
        object_id=new_data.object_id,
        year=new_data.year,
        anchor_month=new_data.anchor_month,
    )

    # Шаблона нет — акт по этому виду ТО завести нечем. Отказываем на весь
    # год, а не пишем половину: полграфика в базе хуже, чем ни одного.
    missing = sorted(
        {cell.type_act_id for cell in preview.cells if cell.template_missing}
    )
    if missing:
        raise UnprocessableEntity(
            message=(f"У модели нет шаблонов чек-листа на виды ТО {missing}!"),
            num=146,
            description=(
                "Заведите шаблон (`acts_bases`) на каждый вид ТО программы. "
                "В предпросмотре такие клетки помечены `template_missing`."
            ),
            path="$.body.object_id",
        )

    planned, created, skipped = create_year_schedule(
        session,
        object_id=new_data.object_id,
        year=new_data.year,
        cells=preview.cells,
        act_bases=act_bases_by_type_act(session, factory_model_id=obj.factory_model_id),
        foreman_id=obj.foreman_id,
        main_mechanic_id=obj.mechanic_id,
    )

    return SingleEntityResponse(
        data=ScheduleGenerateResult(
            object_id=preview.object_id,
            year=preview.year,
            anchor_month=preview.anchor_month,
            factory_model_id=preview.factory_model_id,
            program_id=preview.program_id,
            planned_to_id=planned.id,
            created=[
                ScheduleGeneratedCell(
                    month=cell.month,
                    position=cell.position,
                    type_act_id=cell.type_act_id,
                    type_act_name=cell.type_act_name,
                    act_fact_id=act_id,
                )
                for cell, act_id in created
            ],
            skipped=skipped,
        )
    )
