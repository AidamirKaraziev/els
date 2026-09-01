"""Чтение годового графика объекта — для предпросмотра по программе.

Здесь только один вопрос к базе: какие месяцы года у объекта уже заняты и
какой вид ТО в каждом из них. Занятость нужна за запрашиваемый год, виды ТО
— за прошлый: по ним восстанавливается якорь цикла.

Ленту графиков (`crud_schedules`) для этого не трогаем. Там `UNION ALL` из
двенадцати выборок, отчётный период и статусы «просрочено / выполнено с
опозданием» — всё это про многие объекты сразу и про то, как график
исполняется. Предпросмотру нужен один объект и голый факт «месяц занят».
"""

from typing import Dict, NamedTuple, Optional

from sqlalchemy.orm import Session

from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import ActBase, ActFact, PlannedTO


class MonthRow(NamedTuple):
    """Занятый месяц графика: работа за ним и её вид ТО."""

    act_id: int
    #: Вид ТО акта. Пусто, если у акта не заполнен шаблон или у шаблона —
    #: вид: у актов подрядчика такое встречается, и падать на этом нельзя.
    type_act_id: Optional[int]


def months_of_year(db: Session, *, object_id: int, year: int) -> Dict[int, MonthRow]:
    """Занятые месяцы графика объекта за год.

    Год в модели строковый, поэтому сравнивается со `str(year)`, а не
    приведением типа: в колонке живут значения, набитые руками, и `CAST`
    уронил бы запрос целиком на первой же строке вроде «2025 г.».

    Архивные строки не отсеиваются: `(year, object_id)` уникальна, второй
    строки за тот же год не бывает, и месяц, за которым стоит акт, занят
    независимо от того, убрали ли график из списков.
    """
    planned = (
        db.query(PlannedTO)
        .filter(PlannedTO.object_id == object_id, PlannedTO.year == str(year))
        .first()
    )
    if planned is None:
        return {}

    act_by_month = {}
    for month, column in _PLANNED_MONTH_COLUMN.items():
        act_id = getattr(planned, column.key)
        if act_id is not None:
            act_by_month[month] = act_id

    if not act_by_month:
        return {}

    rows = (
        db.query(ActFact.id, ActBase.type_act_id)
        .outerjoin(ActBase, ActFact.act_base_id == ActBase.id)
        .filter(ActFact.id.in_(sorted(act_by_month.values())))
        .all()
    )
    type_act_by_act = dict(rows)

    return {
        month: MonthRow(act_id=act_id, type_act_id=type_act_by_act.get(act_id))
        for month, act_id in act_by_month.items()
    }
