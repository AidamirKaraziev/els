"""Программа обслуживания модели оборудования.

Программа — шаблон на модель: какой вид ТО идёт в каком месяце цикла. По ней
мастер расставляет годовой график объекта, а экран графика показывает
плановые ТО и находит шаблон чек-листа.

Программа принадлежит **модели**, а не объекту: лифты одной модели
обслуживаются одинаково, и заводить одну и ту же раскладку на каждый дом —
это двенадцать прощёлкиваний на объект, из-за которых правило чередования
ТО1/ТО3/ТО6/ТО12 и жило до сих пор в голове прораба.

Правится программа целиком, одним телом. Частичной правки нет по смыслу:
позиции — цикл, и «поменять март отдельно» означает получить год, в котором
ТО12 встречается дважды или не встречается вовсе.
"""

from fastapi import APIRouter, Body, Depends, Path, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.crud.crud_maintenance_program import crud_maintenance_program
from src.exceptions import ListOfEntityError, UnfoundEntity, UnprocessableEntity
from src.getters.maintenance_program import get_maintenance_program, suggest_program
from src.models import TypeAct
from src.schemas.maintenance_program import (
    PROGRAM_LENGTH,
    MaintenanceProgramOut,
    MaintenanceProgramSuggestion,
    MaintenanceProgramUpsert,
)

router = APIRouter()

TAGS = ["Программа обслуживания"]


def _require_factory_model(session, factory_model_id: int) -> None:
    if not crud_maintenance_program.factory_model_exists(
        db=session, factory_model_id=factory_model_id
    ):
        raise UnfoundEntity(
            message="Такой модели техники не существует!",
            num=115,
            description="Выберете существующую Модель техники!",
            path="$.path",
        )


def _problem(message: str, description: str) -> UnprocessableEntity:
    """Одна беда программы.

    Конкретика идёт в `message`: наружу из списка ошибок отдаётся именно оно
    (`errors.py`), а `description` у отдельной ошибки списка не показывается.
    """
    return UnprocessableEntity(
        message=message, num=138, description=description, path="$.body.items"
    )


def _validate_cycle(session, items) -> None:
    """Проверить программу целиком и назвать сразу все её беды.

    Ошибки собираются списком, а не выбрасываются по одной: человек правит
    таблицу из двенадцати строк, и возвращать её по одной беде за запрос —
    двенадцать заходов вместо одного.

    Проверка живёт здесь, а не в схеме, ради кода ответа: pydantic ушёл бы в
    общий обработчик с 400 («не разобрали тело»), а тут тело разобрано —
    неверны данные, и это 422.
    """
    problems = []

    positions = [item.position for item in items]
    if len(positions) != PROGRAM_LENGTH:
        problems.append(
            _problem(
                f"В программе должно быть ровно {PROGRAM_LENGTH} позиций, "
                f"прислано {len(positions)}!",
                "Частичной правки нет: программа сохраняется целиком.",
            )
        )

    out_of_range = sorted({p for p in positions if not 1 <= p <= PROGRAM_LENGTH})
    if out_of_range:
        problems.append(
            _problem(
                "Позиции программы нумеруются с 1 по 12, вне диапазона: "
                f"{out_of_range}!",
                "Позиция — месяц цикла обслуживания.",
            )
        )

    duplicates = sorted({p for p in positions if positions.count(p) > 1})
    if duplicates:
        problems.append(
            _problem(
                f"Позиции программы повторяются: {duplicates}!",
                "В одном месяце цикла может быть только одно ТО.",
            )
        )

    missing = sorted(set(range(1, PROGRAM_LENGTH + 1)) - set(positions))
    if missing:
        problems.append(
            _problem(
                f"В программе пропущены позиции: {missing}!",
                "Цикл заполняется целиком, с 1 по 12.",
            )
        )

    requested = {item.type_act_id for item in items}
    unknown = sorted(
        requested
        - crud_maintenance_program.existing_type_act_ids(db=session, ids=requested)
    )
    if unknown:
        bad_positions = sorted(
            item.position for item in items if item.type_act_id in unknown
        )
        problems.append(
            _problem(
                f"Нет видов ТО с id {unknown} — проверьте позиции {bad_positions}!",
                "Вид ТО берётся из справочника types_acts.",
            )
        )

    if problems:
        raise ListOfEntityError(
            errors=problems,
            description="Программа обслуживания заполнена неверно",
            http_status=422,
        )


@router.get(
    path="/maintenance-program/by-model/{factory_model_id}/",
    response_model=SingleEntityResponse[MaintenanceProgramOut],
    name="maintenance_program_by_model",
    summary="Программа обслуживания модели",
    description=(
        "🛠 Двенадцать позиций «месяц цикла → вид ТО» для модели "
        "оборудования.\n\n"
        "**Программы нет — 404.** Пустой программы не бывает: раскладка "
        "либо утверждена целиком, либо её нет. Подсказку, с чего начать, "
        "даёт `.../suggestion/` — она считается на лету и в базу не пишется.\n\n"
        "Позиции приходят по порядку, `position` 1..12. Это месяцы **цикла**, "
        "а не календаря: с какого месяца цикл начнётся на конкретном объекте, "
        "решает мастер расстановки графика."
    ),
    tags=TAGS,
)
def maintenance_program_by_model(
    factory_model_id: int = Path(..., title="ID модели оборудования"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.MAINTENANCE_PROGRAM_READ)),
):
    _require_factory_model(session, factory_model_id)

    program = crud_maintenance_program.get_by_model(
        db=session, factory_model_id=factory_model_id
    )
    if program is None:
        raise UnfoundEntity(
            message="У этой модели нет программы обслуживания!",
            num=137,
            description=(
                "Заведите программу через PUT по этому же пути. Готовую "
                "раскладку можно взять из .../suggestion/."
            ),
            path="$.path",
        )

    return SingleEntityResponse(data=get_maintenance_program(program))


@router.put(
    path="/maintenance-program/by-model/{factory_model_id}/",
    response_model=SingleEntityResponse[MaintenanceProgramOut],
    name="maintenance_program_upsert",
    summary="Сохранить программу обслуживания модели",
    description=(
        "🛠 Заводит программу или заменяет её целиком.\n\n"
        "**Тело — всегда двенадцать позиций**, `position` в точности 1..12, "
        "без пропусков и повторов. Неполное тело — 422 со списком проблем; "
        "частичной правки нет по смыслу.\n\n"
        "Старые позиции не сверяются по одной, а заменяются новыми. "
        "Заведённые акты и `planned_to` эта ручка не трогает: программа — "
        "шаблон, а не график объекта.\n\n"
        "Несуществующий `type_act_id` — тоже 422, и в ответе перечислены "
        "**все** плохие позиции разом, а не первая попавшаяся."
    ),
    tags=TAGS,
)
def maintenance_program_upsert(
    factory_model_id: int = Path(..., title="ID модели оборудования"),
    new_data: MaintenanceProgramUpsert = Body(...),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.MAINTENANCE_PROGRAM_WRITE)),
):
    _require_factory_model(session, factory_model_id)

    _validate_cycle(session, new_data.items)

    program = crud_maintenance_program.upsert_by_model(
        db=session, factory_model_id=factory_model_id, data=new_data
    )
    return SingleEntityResponse(data=get_maintenance_program(program))


@router.get(
    path="/maintenance-program/by-model/{factory_model_id}/suggestion/",
    response_model=SingleEntityResponse[MaintenanceProgramSuggestion],
    name="maintenance_program_suggestion",
    summary="Предложение программы по умолчанию",
    description=(
        "🛠 Раскладка, которую система предлагает сама. **В базу не "
        "пишется** — пока человек не сохранил её через `PUT`, это подсказка, "
        "а не программа.\n\n"
        "Правило: позиция получает наибольшую периодичность, на которую она "
        "делится, — ТО12 на двенадцатой, ТО6 на шестой, ТО3 на третьей и "
        "девятой, ТО1 на остальных.\n\n"
        "**Предлагаются только виды с шаблоном чек-листа** (`acts_bases` по "
        "этой модели): по виду без шаблона механику нечего показать. Если "
        "шаблона нет, позиция опускается до ближайшего вида, который есть, а "
        "не подошёл ни один — приходит пустой. Чего не хватает, перечислено "
        "в `missing_type_act_ids`; утверждать график, не заведя эти шаблоны, "
        "нельзя.\n\n"
        "Считается всегда, в том числе когда программа уже сохранена: это и "
        "есть «сбросить к предложенному»."
    ),
    tags=TAGS,
)
def maintenance_program_suggestion(
    factory_model_id: int = Path(..., title="ID модели оборудования"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.MAINTENANCE_PROGRAM_READ)),
):
    _require_factory_model(session, factory_model_id)

    available = crud_maintenance_program.available_type_act_ids(
        db=session, factory_model_id=factory_model_id
    )
    names = dict(session.query(TypeAct.id, TypeAct.name).all())

    return SingleEntityResponse(
        data=suggest_program(
            factory_model_id=factory_model_id,
            available_type_act_ids=available,
            type_act_names=names,
        )
    )


@router.get(
    path="/maintenance-program/all/",
    response_model=ListOfEntityResponse[MaintenanceProgramOut],
    name="maintenance_program_all",
    summary="Список программ обслуживания",
    description=(
        "🛠 Все заведённые программы, по одной на модель оборудования.\n\n"
        "Без `page` выдача полная, без разбивки на страницы: программ "
        "столько же, сколько моделей в парке, и выпадающему списку на фронте "
        "удобнее получить их разом."
    ),
    tags=TAGS,
)
def maintenance_program_all(
    session=Depends(deps.get_db),
    page: int = Query(
        None,
        ge=1,
        title="Номер страницы",
        description="Без параметра выдача полная, без разбивки на страницы.",
    ),
    current_user=Depends(deps.require(Permission.MAINTENANCE_PROGRAM_READ)),
):
    programs, paginator = crud_maintenance_program.list_all(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_maintenance_program(program) for program in programs],
        meta=Meta(paginator=paginator),
    )
