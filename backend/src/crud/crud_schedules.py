"""Запросы раздела «Графики»: годовая лента ТО по объектам.

Это та же матрица «объект × месяц», что и в отчёте, только за год целиком и
без заявок с дефектами. Поэтому класс наследует `CrudReports`, а не
переписывает его внутренности: разворот двенадцати колонок графика в строки
(`_planned_cells`), конец планового месяца (`_month_end_case`) и отбор
объектов с областью видимости (`_object_conditions`) уже написаны и обязаны
остаться в одном экземпляре. Разойдись они — прораб увидел бы в графике
зелёный месяц, а в отчёте за тот же год просрочку.

Что добавлено сверху отчёта
---------------------------
**Поиск свободным текстом.** Ищется не только по колонкам объекта, но и по
участку, типу оборудования и виду ТО. Последние три — подзапросами `EXISTS`,
а не соединениями: соединение с клетками размножило бы объект на двенадцать
строк, и постраничная выдача поехала бы.

**Фильтр по состоянию ленты.** «Есть просроченные», «есть выполненные не
вовремя», «есть незакрытые» и «всё выполнено» — тоже `EXISTS` по клеткам
года, с теми же выражениями статуса, что считает `maintenance_totals`.
"""

import datetime
from typing import Dict, List, Optional, Tuple

from sqlalchemy import and_, literal, not_, select
from sqlalchemy.orm import Session, aliased

from src.core.access import AccessScope
from src.crud.crud_reports import CrudReports, ReportRange, report_range
from src.models import (
    ActBase,
    ActFact,
    Division,
    FactoryModel,
    Object,
    TypeAct,
    TypeObject,
    UniversalUser,
)
from src.schemas.schedules import ScheduleState
from src.utils import pagination
from src.utils.search import ilike_any


def schedule_year(year: int, now: Optional[datetime.datetime] = None) -> ReportRange:
    """Год графика в терминах отчётного периода — двенадцать месяцев.

    `now` задаётся явно по той же причине, что и в отчётах: от него зависит
    граница между «просрочено» и «месяц ещё идёт», и без него набор
    проходящих тестов зависел бы от дня прогона.
    """
    return report_range(datetime.date(year, 1, 1), datetime.date(year, 12, 31), now=now)


class CrudSchedules(CrudReports):
    """Лента графиков ТО. Своей модели нет, поэтому не CRUDBase."""

    # ------------------------------------------------------------------
    # Отбор объектов
    # ------------------------------------------------------------------

    def _object_conditions(
        self,
        *,
        type_object_id: Optional[int] = None,
        factory_number: Optional[str] = None,
        name: Optional[str] = None,
        without_division: bool = False,
        **filters,
    ) -> List:
        """Условия отчёта плюс четыре фильтра, которых там не было.

        `name` и `factory_number` сравниваются точно, а не по вхождению: на
        экране это значения выпадающих списков, а не свободный текст. Текст
        живёт отдельно, в поиске.

        `without_division` — не «любой участок», а «участок не проставлен».
        Значением `division_id` это не выразить: `None` там означает «не
        фильтруем», и объекты без участка иначе не отобрать вовсе.
        """
        conditions = super()._object_conditions(**filters)

        if without_division:
            conditions.append(Object.division_id.is_(None))

        if type_object_id is not None:
            # Подзапросом, а не соединением: своего `type_object_id` у
            # объекта нет (колонка закомментирована в модели), тип достаётся
            # через модель завода, и соединение размножило бы строки.
            conditions.append(
                Object.factory_model_id.in_(
                    select(FactoryModel.id)
                    .where(FactoryModel.type_object_id == type_object_id)
                    .correlate(None)
                    .scalar_subquery()
                )
            )
        if factory_number is not None:
            conditions.append(Object.factory_number == factory_number)
        if name is not None:
            conditions.append(Object.name == name)

        return conditions

    # ------------------------------------------------------------------
    # Поиск и состояние ленты
    # ------------------------------------------------------------------

    def _search_condition(self, text: Optional[str], period: ReportRange):
        """Свободный текст: объект, участок, тип оборудования и вид ТО.

        Человек ищет одной строкой и не обязан знать, в какой таблице лежит
        то, что он набрал. Поэтому «Спортмастер», «F-1024», «ТО 6» и
        «Участок № 1» находятся одним и тем же полем.
        """
        by_object = ilike_any(text, Object.name, Object.factory_number, Object.address)
        if by_object is None:
            return None

        by_division = (
            select(literal(1))
            .select_from(Division)
            .where(
                Division.id == Object.division_id,
                ilike_any(text, Division.title),
            )
            .correlate(Object)
            .exists()
        )

        by_type = (
            select(literal(1))
            .select_from(FactoryModel)
            .join(TypeObject, TypeObject.id == FactoryModel.type_object_id)
            .where(
                FactoryModel.id == Object.factory_model_id,
                ilike_any(text, TypeObject.name),
            )
            .correlate(Object)
            .exists()
        )

        # Вид ТО лежит через две таблицы от клетки, поэтому здесь свой
        # подзапрос с явными соединениями, а не общий `_state_exists`.
        search_cells = self._planned_cells(months=period.months).alias(
            "schedule_search_cells"
        )
        by_type_act = (
            select(literal(1))
            .select_from(search_cells)
            .join(ActFact, ActFact.id == search_cells.c.act_id)
            .join(ActBase, ActBase.id == ActFact.act_base_id)
            .join(TypeAct, TypeAct.id == ActBase.type_act_id)
            .where(
                search_cells.c.object_id == Object.id,
                ilike_any(text, TypeAct.name),
            )
            .correlate(Object)
            .exists()
        )

        return by_object | by_division | by_type | by_type_act

    def _state_exists(self, period: ReportRange, name: str, kind: str):
        """`EXISTS`: у объекта есть клетка года в таком состоянии.

        Выражения статуса собираются здесь же, на своём экземпляре клеток:
        конец планового месяца — это `CASE` по колонкам подзапроса, и взятый
        от чужого экземпляра он ссылался бы на таблицу, которой в этом
        `EXISTS` нет.

        Своё имя подзапроса каждому вызову нужно по той же причине: в фильтре
        «всё выполнено» таких `EXISTS` два сразу, и одинаковые имена
        столкнулись бы прямо в SQL.

        Клетки соединяются с актом внутренним соединением — как и в отчёте:
        клетка без акта это незаполненный график, а не проваленное ТО.
        """
        cells = self._planned_cells(months=period.months).alias(name)
        ends = self._month_end_case(cells, period.months)

        finished = ActFact.finished_at.isnot(None)
        unfinished = ActFact.finished_at.is_(None)
        by_kind = {
            # Любая назначенная клетка: «график вообще есть».
            "any": None,
            "late": and_(finished, ActFact.finished_at >= ends),
            "overdue": and_(unfinished, ends <= period.now),
            "pending": and_(unfinished, ends > period.now),
        }
        conditions = [cells.c.object_id == Object.id]
        if by_kind[kind] is not None:
            conditions.append(by_kind[kind])

        return (
            select(literal(1))
            .select_from(cells)
            .join(ActFact, ActFact.id == cells.c.act_id)
            .where(*conditions)
            .correlate(Object)
            .exists()
        )

    def _state_condition(self, state: Optional[ScheduleState], period: ReportRange):
        """Состояние всей годовой ленты объекта.

        Выражения статуса — те же, что в `maintenance_totals`: второго
        определения «просрочено» в проекте быть не должно.
        """
        if state is None:
            return None

        if state is ScheduleState.ALL_DONE:
            # Зелёные и жёлтые без красных. Опоздание чистоту не портит —
            # работа сделана, — и не портят её месяцы, которые ещё не
            # наступили. Но график должен быть хоть какой-то: объекту без
            # единой назначенной клетки «всё выполнено» не про него.
            return and_(
                self._state_exists(period, "schedule_planned_cells", "any"),
                not_(self._state_exists(period, "schedule_overdue_cells", "overdue")),
            )

        kind = {
            ScheduleState.HAS_OVERDUE: "overdue",
            ScheduleState.HAS_LATE: "late",
            # «Есть незакрытые» — именно текущие: просрочка спрашивается
            # отдельным значением фильтра.
            ScheduleState.HAS_PENDING: "pending",
        }[state]
        return self._state_exists(period, "schedule_state_cells", kind)

    # ------------------------------------------------------------------
    # Выдача
    # ------------------------------------------------------------------

    def rows(
        self,
        *,
        db: Session,
        scope: AccessScope,
        period: ReportRange,
        page: Optional[int] = None,
        search: Optional[str] = None,
        schedule_state: Optional[ScheduleState] = None,
        **filters,
    ) -> Tuple[List, Optional[object]]:
        """Объекты страницы с полями строки.

        Порядок — по адресу: ленту читают по домам, а не по внутренним id.
        Третьим ключом идёт `id`, и он обязателен: без него две строки с
        одним адресом обменялись бы местами между страницами, и при
        бесконечной подгрузке одна из них пропала бы совсем.
        """
        foreman = aliased(UniversalUser)

        query = (
            self._objects_query(db=db, scope=scope, **filters)
            .outerjoin(Division, Object.division_id == Division.id)
            .outerjoin(FactoryModel, Object.factory_model_id == FactoryModel.id)
            .outerjoin(TypeObject, FactoryModel.type_object_id == TypeObject.id)
            .outerjoin(foreman, Object.foreman_id == foreman.id)
            .with_entities(
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.factory_number.label("factory_number"),
                Object.address.label("address"),
                Division.title.label("division"),
                TypeObject.name.label("type_name"),
                foreman.name.label("foreman"),
            )
            .order_by(Object.address.asc(), Object.name.asc(), Object.id.asc())
        )

        for condition in (
            self._search_condition(search, period),
            self._state_condition(schedule_state, period),
        ):
            # Поиск и фильтры складываются: ищем внутри выбранных фильтров,
            # а не вместо них.
            if condition is not None:
                query = query.filter(condition)

        return pagination.get_page(query, page)

    def cells(
        self,
        *,
        db: Session,
        scope: AccessScope,
        period: ReportRange,
        object_ids: List[int],
        **filters,
    ) -> List:
        """Клетки графика по объектам страницы: месяц, вид ТО, дата закрытия.

        Только по объектам выдачи: на тысяче лифтов запрос вернул бы данные,
        которые никто не покажет.
        """
        if not object_ids:
            return []

        query, cells = self._maintenance_query(
            db=db, period=period, scope=scope, **filters
        )
        ends = self._month_end_case(cells, period.months)

        return (
            query.filter(Object.id.in_(object_ids))
            .outerjoin(ActBase, ActFact.act_base_id == ActBase.id)
            .outerjoin(TypeAct, ActBase.type_act_id == TypeAct.id)
            .with_entities(
                Object.id.label("object_id"),
                cells.c.month.label("month"),
                cells.c.act_id.label("act_id"),
                ActFact.finished_at.label("finished_at"),
                ends.label("month_end"),
                TypeAct.name.label("to_name"),
            )
            .order_by(Object.id.asc(), cells.c.month.asc())
            .all()
        )

    # ------------------------------------------------------------------
    # Значения выпадающих фильтров
    # ------------------------------------------------------------------

    def filter_options(self, *, db: Session, scope: AccessScope) -> Dict[str, List]:
        """Что можно выбрать в фильтрах ленты.

        Всё строится поверх видимых объектов, а не поверх справочников
        целиком: иначе прораб выбрал бы в списке чужой участок и получил
        пустую ленту, не понимая, за что.

        Год и уже выбранные фильтры на списки намеренно не влияют. Список
        участков не должен зависеть от того, какая страница объектов сейчас
        открыта, — иначе фильтр показывал бы только те участки, что попали в
        первые тридцать строк.
        """
        objects = self._objects_query(db=db, scope=scope)

        divisions = (
            objects.join(Division, Object.division_id == Division.id)
            .with_entities(Division.id, Division.title)
            .distinct()
            .order_by(Division.title.asc())
            .all()
        )
        types = (
            objects.join(FactoryModel, Object.factory_model_id == FactoryModel.id)
            .join(TypeObject, TypeObject.id == FactoryModel.type_object_id)
            .with_entities(TypeObject.id, TypeObject.name)
            .distinct()
            .order_by(TypeObject.name.asc())
            .all()
        )

        return {
            "divisions": divisions,
            "types": types,
            "names": self._distinct_column(objects, Object.name),
            "factory_numbers": self._distinct_column(objects, Object.factory_number),
        }

    def _distinct_column(self, objects, column) -> List[str]:
        """Непустые значения колонки объекта — по одному разу, по алфавиту."""
        rows = (
            objects.with_entities(column)
            .filter(column.isnot(None), column != "")
            .distinct()
            .order_by(column.asc())
            .all()
        )
        return [row[0] for row in rows]


crud_schedules = CrudSchedules()
