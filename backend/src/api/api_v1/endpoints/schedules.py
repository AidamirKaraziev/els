"""Раздел «Графики»: годовая лента ТО по объектам.

Две ручки: лента и значения выпадающих фильтров. Лента отдаёт строку
«объект + двенадцать клеток» с посчитанным на сервере состоянием каждой
клетки.

Считать состояние на клиенте нельзя: «просрочено» отличается от «назначено»
только тем, кончился ли плановый месяц, а часы браузера у каждого свои — на
машине с уехавшей датой картина графика была бы другой. Поэтому и разворот
двенадцати колонок `january_to_id … december_to_id` в клетки, и сравнение с
концом месяца живут здесь.
"""

import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.crud.crud_schedules import crud_schedules, schedule_year
from src.getters.schedules import get_filter_options, get_schedule_rows
from src.schemas.schedules import (
    ScheduleFilterOptions,
    ScheduleRow,
    ScheduleState,
)

router = APIRouter()

TAGS = ["Графики ТО"]


@router.get(
    path="/schedules/rows",
    response_model=ListOfEntityResponse[ScheduleRow],
    name="schedule_rows",
    summary="Лента графиков ТО за год",
    description=(
        "🗓 Объект и его двенадцать клеток за выбранный год.\n\n"
        "**Состояние клетки считает сервер.** `done` — акт закрыт внутри "
        "своего планового месяца, `late` — закрыт позже, `overdue` — месяц "
        "кончился, а акт не закрыт, `pending` — месяц ещё идёт, `none` — ТО "
        "на этот месяц не назначали. Различать два последних обязательно: "
        "иначе первого числа каждого месяца лента показывала бы всплеск "
        "просрочки на ровном месте.\n\n"
        "Клеток всегда двенадцать: месяцы без плана приходят со статусом "
        "`none`, иначе колонки разъехались бы между строками.\n\n"
        "**Клетка без акта — незаполненный график, а не проваленное ТО.** "
        "Объект, которому график на год не ставили, из выдачи не пропадает: "
        "он приходит с двенадцатью пустыми клетками.\n\n"
        "`search` ищет по названию, заводскому номеру, адресу, участку, типу "
        "оборудования и виду ТО сразу — человек набирает одну строку и не "
        "обязан знать, где что лежит. Поиск и фильтры **складываются**: "
        "ищем внутри выбранных фильтров, а не вместо них.\n\n"
        "`schedule_state` отвечает на вопрос «где болит». `all_done` — это "
        "«зелёные и жёлтые без красных»: ни одной просроченной клетки. "
        "Выполненное с опозданием чистоту не портит, и не портят её месяцы, "
        "которые ещё не наступили; объект без графика вовсе сюда не "
        "попадает.\n\n"
        "`without_division` — про объекты, которым участок **не проставлен**, "
        "а не «любой участок». Вместе с `division_id` эти два условия "
        "складываются и дают пустую выдачу: отдельной ошибки на это нет.\n\n"
        "Выдача режется областью видимости: прораб видит объекты своих "
        "участков, отдельной ручки «по прорабу» для этого не нужно."
    ),
    tags=TAGS,
)
def schedule_rows(
    session=Depends(deps.get_db),
    year: int = Query(
        None,
        ge=2000,
        le=2100,
        title="Год графика",
        description="Без параметра — текущий год.",
    ),
    page: int = Query(
        None,
        ge=1,
        title="Номер страницы",
        description="Без параметра выдача полная, без разбивки на страницы.",
    ),
    search: str = Query(None, title="Поиск по объекту, участку, типу и виду ТО"),
    division_id: int = Query(None, title="Только объекты этого участка"),
    without_division: bool = Query(
        False, title="Только объекты, которым участок не проставлен"
    ),
    type_object_id: int = Query(None, title="Только этот тип оборудования"),
    factory_number: str = Query(None, title="Заводской номер целиком"),
    name: str = Query(None, title="Название объекта целиком"),
    schedule_state: Optional[ScheduleState] = Query(
        None, title="Состояние годовой ленты"
    ),
    current_user=Depends(deps.require(Permission.PLANNED_TO_READ)),
    scope=Depends(deps.get_read_scope),
):
    year = year or datetime.datetime.now().year
    period = schedule_year(year)

    filters = {
        "division_id": division_id,
        "without_division": without_division,
        "type_object_id": type_object_id,
        "factory_number": factory_number,
        "name": name,
    }

    rows, paginator = crud_schedules.rows(
        db=session,
        scope=scope,
        period=period,
        page=page,
        search=search,
        schedule_state=schedule_state,
        **filters,
    )

    return ListOfEntityResponse(
        data=get_schedule_rows(
            rows=rows,
            # Клетки — только по объектам страницы: на тысяче лифтов запрос
            # вернул бы данные, которые никто не покажет.
            cells=crud_schedules.cells(
                db=session,
                scope=scope,
                period=period,
                object_ids=[row.object_id for row in rows],
                **filters,
            ),
            year=year,
            now=period.now,
        ),
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/schedules/filters",
    response_model=SingleEntityResponse[ScheduleFilterOptions],
    name="schedule_filter_options",
    summary="Значения выпадающих фильтров ленты",
    description=(
        "🔽 Чем можно сузить ленту: участки, типы оборудования, названия "
        "объектов и заводские номера.\n\n"
        "Списки строятся по видимым объектам, а не по справочникам целиком: "
        "иначе прораб выбрал бы в фильтре чужой участок и получил пустую "
        "ленту, не понимая, за что.\n\n"
        "От года и от уже выбранных фильтров списки не зависят намеренно — "
        "иначе набор участков менялся бы от того, какая страница объектов "
        "сейчас открыта.\n\n"
        "У участков и типов `id` настоящий, его и надо слать в `division_id` "
        "и `type_object_id`. У названий и заводских номеров своего `id` нет: "
        "они уходят на сервер значением, а номер здесь порядковый."
    ),
    tags=TAGS,
)
def schedule_filter_options(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.PLANNED_TO_READ)),
    scope=Depends(deps.get_read_scope),
):
    return SingleEntityResponse(
        data=get_filter_options(crud_schedules.filter_options(db=session, scope=scope))
    )
