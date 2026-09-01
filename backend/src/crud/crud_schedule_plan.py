"""Годовой график объекта по программе модели: чтение и создание.

Чтение — один вопрос к базе: какие месяцы года у объекта уже заняты и какой
вид ТО в каждом из них. Занятость нужна за запрашиваемый год, виды ТО — за
прошлый: по ним восстанавливается якорь цикла.

Создание раскладку не считает заново: ему приносят готовые клетки
предпросмотра (`getters/schedule_plan.build_preview`), и он только пишет.
Второго определения цикла в проекте быть не должно.

Ленту графиков (`crud_schedules`) для этого не трогаем. Там `UNION ALL` из
двенадцати выборок, отчётный период и статусы «просрочено / выполнено с
опозданием» — всё это про многие объекты сразу и про то, как график
исполняется. Предпросмотру нужен один объект и голый факт «месяц занят».
"""

from typing import Dict, List, NamedTuple, Optional, Tuple

from sqlalchemy.orm import Session

from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import ActBase, ActFact, PlannedTO
from src.schemas.schedule_plan import SchedulePreviewCell
from src.services.checklist import dump_checklist, parse_checklist

#: Статус «Создано» из `core/db/init_db.py` — он же дефолт колонки.
STATUS_CREATED = 1


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


def act_bases_by_type_act(db: Session, *, factory_model_id: int) -> Dict[int, ActBase]:
    """Шаблоны чек-листов модели: вид ТО → шаблон.

    Пара «модель + вид ТО» в `acts_bases` уникальна
    (`_type_act_factory_model_uc`), поэтому шаблон на вид ТО ровно один и
    словарь однозначен.
    """
    rows = (
        db.query(ActBase)
        .filter(
            ActBase.factory_model_id == factory_model_id,
            ActBase.type_act_id.isnot(None),
        )
        .all()
    )
    return {row.type_act_id: row for row in rows}


def create_year_schedule(
    db: Session,
    *,
    object_id: int,
    year: int,
    cells: List[SchedulePreviewCell],
    act_bases: Dict[int, ActBase],
    foreman_id: Optional[int],
    main_mechanic_id: Optional[int],
) -> Tuple[PlannedTO, List[Tuple[SchedulePreviewCell, int]], List[int]]:
    """Разложить год по клеткам предпросмотра: график, созданное, пропущенное.

    Занятый месяц не трогается вовсе — ни акт, ни колонка. На этом и держится
    идемпотентность: на повторном вызове месяцы заняты актами, созданными в
    первый раз, и добавлять нечего.

    Ответственные приходят от объекта и могут быть пустыми: у объекта они не
    обязательны, а отказывать в графике из-за незаполненной карточки нельзя —
    проставить прораба и механика можно и потом.
    """
    planned = (
        db.query(PlannedTO)
        .filter(PlannedTO.object_id == object_id, PlannedTO.year == str(year))
        .first()
    )
    if planned is None:
        planned = PlannedTO(object_id=object_id, year=str(year))
        db.add(planned)
        db.flush()

    created: List[Tuple[SchedulePreviewCell, int]] = []
    skipped: List[int] = []

    for cell in cells:
        if cell.occupied:
            skipped.append(cell.month)
            continue

        act_base = act_bases[cell.type_act_id]
        checklist = parse_checklist(act_base.step_list)
        act = ActFact(
            object_id=object_id,
            act_base_id=act_base.id,
            # Название ТО в шаблоне не хранится — оно есть только у вида ТО.
            step_list_fact=dump_checklist(
                checklist._replace(title=checklist.title or cell.type_act_name)
            ),
            status_id=STATUS_CREATED,
            foreman_id=foreman_id,
            main_mechanic_id=main_mechanic_id,
        )
        db.add(act)
        db.flush()

        setattr(planned, _PLANNED_MONTH_COLUMN[cell.month].key, act.id)
        created.append((cell, act.id))

    db.commit()
    db.refresh(planned)
    return planned, created, skipped
