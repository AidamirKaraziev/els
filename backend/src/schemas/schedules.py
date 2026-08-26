"""Раздел «Графики»: годовая лента ТО одного объекта.

Строка — объект и двенадцать клеток, январь..декабрь. Состояние каждой
клетки считает сервер: «просрочено» отличается от «назначено» только тем,
кончился ли плановый месяц, и по локальным часам браузера это считать
нельзя — на разных машинах картина разъехалась бы.

Состояния берутся из `MaintenanceStatus` отчётов, а не заводятся заново.
Лента графиков и отчёт обязаны называть одно и то же одинаково, иначе
прораб видит в графике зелёный месяц, а в отчёте — просрочку.
"""

from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field

from src.schemas.reports import MaintenanceStatus


class ScheduleState(str, Enum):
    """Фильтр «где болит» — состояние всей годовой ленты объекта.

    `all_done` — «зелёные и жёлтые без красных»: ни одной просроченной
    клетки. Выполненное с опозданием чистоту не портит — работа сделана, — и
    не портят её месяцы, которые ещё не наступили. Объект, которому график
    на год не ставили вовсе, сюда не попадает: винить его не в чем, но и
    «всё выполнено» про него неправда.
    """

    HAS_OVERDUE = "has_overdue"
    HAS_LATE = "has_late"
    HAS_PENDING = "has_pending"
    ALL_DONE = "all_done"


class ScheduleCell(BaseModel):
    """Один месяц годовой ленты."""

    month: int = Field(..., ge=1, le=12, title="Месяц")
    status: MaintenanceStatus = Field(..., title="Состояние планового ТО")
    to_name: Optional[str] = Field(
        None,
        title="Вид ТО",
        description=(
            "«ТО-1», «ТО-6» — из типа акта. Пусто, если ТО на месяц не "
            "назначено или вид у акта не заполнен."
        ),
    )
    act_id: Optional[int] = Field(
        None,
        title="Работа за этой клеткой",
        description="`act_fact.id`. Именно её открывает клик по клетке.",
    )


class ScheduleRow(BaseModel):
    """Объект и его график ТО за год."""

    object_id: int = Field(..., title="ID объекта")
    name: Optional[str] = Field(None, title="Название объекта")
    year: int = Field(..., title="Год графика")
    cells: List[ScheduleCell] = Field(
        ...,
        title="Двенадцать клеток, январь..декабрь",
        description=(
            "Приходит полной всегда: месяцы без плана есть в списке со "
            "статусом `none`, иначе колонки разъехались бы между строками."
        ),
    )

    factory_number: Optional[str] = Field(None, title="Заводской номер")
    address: Optional[str] = Field(None, title="Адрес")
    division: Optional[str] = Field(None, title="Участок")
    foreman: Optional[str] = Field(None, title="Прораб объекта")
    type_name: Optional[str] = Field(
        None,
        title="Тип оборудования",
        description="Достаётся через модель завода: у объекта своего типа нет.",
    )
