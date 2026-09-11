"""Запросы раздела «Отчёты».

Отвечают на один вопрос: что делали на объектах за период. От статистики
главной отличаются двумя вещами.

**Период — диапазон, а не месяц.** Заявки режутся по датам точно, плановые ТО
— по плановому месяцу целиком: у ячейки графика нет дня, и резать помесячный
план по датам нечем. Период «15.03 — 20.06» захватывает ТО за весь март и
весь июнь. Решение и его цена — в заметке «период отчёта режется по датам, а
ТО — по плановому месяцу целиком».

**Объекты берутся все, а не только те, где что-то происходило.** Лифт, на
котором за год не было ни одной работы, — это тоже результат, и в отчёте
клиенту он обязан быть виден. Поэтому основа отбора — объекты, а работы к ним
подклеиваются.

Как считается статус ТО за месяц
--------------------------------
Четыре состояния вместо двух. `DONE` — акт закрыт внутри планового месяца,
`LATE` — закрыт после его конца, `OVERDUE` — месяц кончился, акт не закрыт,
`PENDING` — месяц ещё идёт. Различать два последних обязательно: иначе
первого числа каждого месяца отчёт показывал бы всплеск просрочки на ровном
месте.

Конец планового месяца нужен построчно, а месяцев в периоде много, поэтому он
собирается выражением `CASE` по списку месяцев периода — список ограничен
периодом, и выражение не разрастается.

Как делятся заявки
------------------
Сначала отделяются аварии — по флагу `counts_as_breakdown` у категории, тем же
правилом, что и в статистике: заявка без категории тоже авария, недозаполненная
заявка не повод потерять реальный выезд. Из оставшихся заявки, заведённые
пользователем с ролью клиента, считаются обращениями заказчика, прочие —
прочими работами.

Порядок именно такой: настоящая поломка остаётся поломкой, даже если о ней
сообщил сам клиент. Иначе аварийность объекта зависела бы от того, кто первым
нажал кнопку.
"""

import datetime
from typing import Dict, List, NamedTuple, Optional, Tuple

from sqlalchemy import and_, case, func, literal, select, union_all
from sqlalchemy.orm import Session, aliased

from src.core.access import AccessScope, object_scope_filter
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import (
    ActFact,
    Company,
    DefectiveAct,
    DefectiveActPhoto,
    Division,
    FactoryModel,
    FaultCategory,
    Object,
    Order,
    OrderPhoto,
    Organization,
    PlannedTO,
    ReasonFault,
    Status,
    UniversalUser,
)
from src.services.work_kind import order_kind_flags


class ReportRange(NamedTuple):
    """Период отчёта в двух видах сразу.

    `start`/`end` — полуинтервал по времени для заявок, `months` — список
    месяцев для плана ТО. Оба набора считаются один раз и передаются во все
    запросы, чтобы разные части отчёта заведомо смотрели на один период.

    `now` — момент, относительно которого месяц считается прошедшим. Лежит
    здесь, а не берётся из `datetime.now()` в запросе, потому что от него
    зависит граница между «просрочено» и «ещё идёт»: иначе набор проходящих
    тестов зависел бы от дня прогона.
    """

    date_from: datetime.date
    date_to: datetime.date
    start: datetime.datetime
    end: datetime.datetime
    months: List[Tuple[int, int]]
    now: datetime.datetime


def report_range(
    date_from: datetime.date,
    date_to: datetime.date,
    now: Optional[datetime.datetime] = None,
) -> ReportRange:
    """Границы отчёта из пары дат. Дата «по» входит в период целиком."""
    start = datetime.datetime.combine(date_from, datetime.time.min)
    # Полуинтервал [start, end): заявка, созданная в 23:59 последнего дня,
    # обязана попасть в отчёт. Сравнение `<= date_to` этого не даёт — время
    # у заявки не нулевое.
    end = datetime.datetime.combine(
        date_to + datetime.timedelta(days=1), datetime.time.min
    )

    months: List[Tuple[int, int]] = []
    year, month = date_from.year, date_from.month
    while (year, month) <= (date_to.year, date_to.month):
        months.append((year, month))
        year, month = (year + 1, 1) if month == 12 else (year, month + 1)

    return ReportRange(
        date_from=date_from,
        date_to=date_to,
        start=start,
        end=end,
        months=months,
        now=now if now is not None else datetime.datetime.now(),
    )


def month_end(year: int, month: int) -> datetime.datetime:
    """Начало следующего месяца — правая граница планового месяца."""
    if month == 12:
        return datetime.datetime(year + 1, 1, 1)
    return datetime.datetime(year, month + 1, 1)


def days_late(finished_at: datetime.datetime, year: int, month: int) -> int:
    """На сколько дней акт закрыт позже конца планового месяца.

    Ноль означает «в последний день месяца», а не «вовремя»: вовремя — это
    вообще не `LATE`, и до этой функции такой акт не доходит.
    """
    return max((finished_at - month_end(year, month)).days, 0)


class CrudReports:
    """Отчёт о работах на объектах. Своей модели нет, поэтому не CRUDBase."""

    # ------------------------------------------------------------------
    # Общие куски
    # ------------------------------------------------------------------

    def _object_conditions(
        self,
        *,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
        object_id: Optional[int] = None,
    ) -> List:
        """Условия отбора объектов — единственное место, где они описаны.

        Первым идёт область видимости: фильтры ниже — это выбор пользователя,
        а она граница, за которую он выйти не может. Запрошенный чужой
        `company_id` выдачу не расширит.
        """
        conditions = [object_scope_filter(scope)]

        if division_id is not None:
            conditions.append(Object.division_id == division_id)
        if organization_id is not None:
            conditions.append(Object.organization_id == organization_id)
        if company_id is not None:
            conditions.append(Object.company_id == company_id)
        if object_id is not None:
            conditions.append(Object.id == object_id)

        return conditions

    def _objects_query(self, *, db: Session, **filters):
        """Объекты отбора. Основа всего отчёта."""
        return db.query(Object).filter(*self._object_conditions(**filters))

    def _visible_object_ids(self, **filters):
        """Подзапрос с id объектов отбора — граница для всех агрегатов.

        `correlate(None)` обязателен: без него SQLAlchemy склеит подзапрос с
        внешним, который уже присоединил `objects` — а это все запросы отчёта,
        — и условие превратится в тавтологию, то есть в утечку. Та же грабля
        описана у `visible_object_ids` в `core/access.py`.
        """
        return (
            select(Object.id)
            .where(*self._object_conditions(**filters))
            .correlate(None)
            .scalar_subquery()
        )

    def _planned_cells(self, *, months: List[Tuple[int, int]]):
        """Ячейки графика за месяцы периода, развёрнутые в строки.

        `planned_to` хранит месяц колонкой, а не строкой таблицы, поэтому
        «ТО за период» одним `WHERE` не выражается — нужен `UNION ALL` из
        двенадцати выборок. Карта «номер месяца → колонка» берётся из
        статистики, а не переписывается здесь: двенадцать имён колонок,
        продублированных в двух модулях, разъедутся при первой же правке
        графика.

        Год в модели строковый, и сравнивается перечислением заведомо
        известных значений, а не приведением типа: в колонке живут данные,
        набитые руками, и `CAST` уронил бы запрос целиком на первой же
        строке вроде «2025 г.».
        """
        years_by_month = {}
        for year, month in months:
            years_by_month.setdefault(month, []).append(str(year))

        branches = [
            select(
                PlannedTO.object_id.label("object_id"),
                PlannedTO.year.label("year"),
                literal(month).label("month"),
                _PLANNED_MONTH_COLUMN[month].label("act_id"),
            ).where(
                _PLANNED_MONTH_COLUMN[month].isnot(None),
                PlannedTO.year.in_(year_strings),
            )
            for month, year_strings in sorted(years_by_month.items())
        ]

        return union_all(*branches).subquery("report_cells")

    def _month_end_case(self, cells, months: List[Tuple[int, int]]):
        """Конец планового месяца для каждой строки ячейки.

        Нужен, чтобы отличить закрытое вовремя от закрытого с опозданием и
        незакрытое текущее от незакрытого просроченного. Месяцев в периоде
        ограниченное число, поэтому `CASE` не разрастается: годовой отчёт даёт
        двенадцать веток.
        """
        # Ветки передаются позиционно, а не списком: список — старая форма,
        # она помечена к удалению в SQLAlchemy 2.0 и уже сыплет предупреждением.
        return case(
            *[
                (
                    and_(cells.c.year == str(year), cells.c.month == month),
                    literal(month_end(year, month)),
                )
                for year, month in months
            ],
            # До `else` дойти нечем: ветки покрывают ровно те месяцы, по
            # которым отобраны ячейки. Значение поставлено, чтобы выражение
            # оставалось тотальным и не возвращало NULL, который тихо
            # выключил бы сравнения.
            else_=literal(datetime.datetime.max),
        )

    def _maintenance_query(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        **filters,
    ):
        """Плановые ТО периода: ячейка графика плюс её акт.

        Внутреннее соединение с актом и есть определение плана: ячейка без
        акта — это не проваленное ТО, а незаполненный график.
        """
        cells = self._planned_cells(months=period.months)

        query = (
            db.query(ActFact)
            .select_from(cells)
            # Внутренние соединения намеренно: ячейка без объекта —
            # осиротевший график, ячейка с несуществующим актом — мусор.
            .join(Object, Object.id == cells.c.object_id)
            .join(ActFact, ActFact.id == cells.c.act_id)
            .filter(Object.id.in_(self._visible_object_ids(scope=scope, **filters)))
        )
        return query, cells

    def _orders_query(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        **filters,
    ):
        """Заявки периода с автором и категорией.

        Отбор по объектам, а не через `apply_order_scope`: отчёт показывает
        работы на объектах, и своя заявка на чужом лифте в него попасть не
        должна. Область видимости при этом соблюдена — список объектов уже
        порезан ею.
        """
        creator = aliased(UniversalUser)

        query = (
            db.query(Order)
            .join(Object, Order.object_id == Object.id)
            .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
            .outerjoin(creator, Order.creator_id == creator.id)
            .filter(
                Order.created_at.isnot(None),
                Order.created_at >= period.start,
                Order.created_at < period.end,
                Object.id.in_(self._visible_object_ids(scope=scope, **filters)),
            )
        )
        return query, creator

    def _kind_flags(self, creator):
        """Три взаимоисключающих условия «авария / клиент / прочее».

        Само правило живёт в `services/work_kind`: по нему же лента сданных
        работ называет вид заявки, и разъехаться им нельзя.
        """
        return order_kind_flags(creator)

    def _defects_query(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        **filters,
    ):
        """Дефектные акты периода.

        Период режется по `created_at`, а не по паре «год графика + месяц
        акта»: акт заводится из четырёх мест, и три из них (`act_fact_id`,
        `order_id`, пункт меню) плановое ТО не заполняют. Раньше запрос
        соединял акты с `PlannedTO` внутренним join'ом и терял всё, что
        заведено не старой ручкой. Дата создания есть у любого акта, и по
        ней же считает лента актов объекта
        (`crud_defective_act.get_by_object_and_year`) — числа в отчёте и в
        окне графика теперь одни и те же.

        Клиентские акты (`kind == "client"`) не считаются: это порождённые
        записи, они видны из своего первоисточника. То же правило — в
        `crud_schedules._defects_count`.
        """
        return (
            db.query(DefectiveAct)
            .join(Object, DefectiveAct.object_id == Object.id)
            .filter(
                DefectiveAct.kind == "internal",
                DefectiveAct.created_at >= period.start,
                DefectiveAct.created_at < period.end,
                Object.id.in_(self._visible_object_ids(scope=scope, **filters)),
            )
        )

    @staticmethod
    def _defect_year_month():
        """Год и месяц акта — из даты создания, см. `_defects_query`."""
        return (
            func.extract("year", DefectiveAct.created_at),
            func.extract("month", DefectiveAct.created_at),
        )

    # ------------------------------------------------------------------
    # Объекты отбора
    # ------------------------------------------------------------------

    def objects(
        self,
        *,
        db: Session,
        scope: AccessScope,
        limit: Optional[int] = 25,
        offset: int = 0,
        **filters,
    ) -> List:
        """Объекты отчёта с полями для карточки строки.

        Порядок — по адресу: отчёт читают по домам, а не по внутренним id.
        `is_actual` не проверяется намеренно: лифт, выведенный из
        эксплуатации в середине года, работы за этот год всё равно имел, и
        прятать его из годового отчёта значило бы соврать.
        """
        foreman = aliased(UniversalUser)
        mechanic = aliased(UniversalUser)

        query = (
            self._objects_query(db=db, scope=scope, **filters)
            .outerjoin(Organization, Object.organization_id == Organization.id)
            .outerjoin(Company, Object.company_id == Company.id)
            .outerjoin(Division, Object.division_id == Division.id)
            .outerjoin(FactoryModel, Object.factory_model_id == FactoryModel.id)
            .outerjoin(foreman, Object.foreman_id == foreman.id)
            .outerjoin(mechanic, Object.mechanic_id == mechanic.id)
            .with_entities(
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.registration_number.label("registration_number"),
                Object.factory_number.label("factory_number"),
                Object.address.label("address"),
                func.coalesce(Organization.title, Company.name).label("client"),
                Division.title.label("division"),
                FactoryModel.factory.label("factory"),
                FactoryModel.model.label("model"),
                mechanic.name.label("responsible_mechanic"),
                foreman.name.label("responsible_foreman"),
            )
            .order_by(Object.address.asc(), Object.name.asc(), Object.id.asc())
        )

        if offset:
            query = query.offset(offset)
        if limit is not None:
            query = query.limit(limit)

        return query.all()

    def count_objects(self, *, db: Session, scope: AccessScope, **filters) -> int:
        """Объектов в отборе — по всей выдаче, а не по странице."""
        return (
            self._objects_query(db=db, scope=scope, **filters)
            .with_entities(func.count(Object.id))
            .scalar()
            or 0
        )

    # ------------------------------------------------------------------
    # Итоги за период
    # ------------------------------------------------------------------

    def maintenance_totals(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ):
        """План, факт, опоздания и просрочка по всему отбору одной строкой."""
        query, cells = self._maintenance_query(
            db=db, period=period, scope=scope, **filters
        )
        ends = self._month_end_case(cells, period.months)

        finished = ActFact.finished_at.isnot(None)
        late = finished & (ActFact.finished_at >= ends)
        overdue = (ActFact.finished_at.is_(None)) & (ends <= period.now)

        row = query.with_entities(
            func.count(cells.c.act_id).label("planned"),
            func.count(cells.c.act_id).filter(finished).label("completed"),
            func.count(cells.c.act_id).filter(late).label("late"),
            func.count(cells.c.act_id).filter(overdue).label("overdue"),
        ).one()

        return row

    def order_totals(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ):
        """Заявки по видам плюс время реакции по авариям."""
        query, creator = self._orders_query(
            db=db, period=period, scope=scope, **filters
        )
        is_breakdown, is_client, is_other = self._kind_flags(creator)

        # Время реакции: от создания до момента, когда заявку взяли в работу.
        # Диспетчер нередко прыгает сразу в «В процессе», поэтому берём первое
        # непустое из двух — тем же способом, что и статистика главной.
        reacted_at = func.coalesce(Order.accepted_at, Order.in_progress_at)
        reaction_seconds = func.extract("epoch", reacted_at - Order.created_at)
        # Отрицательная разница — битые данные: взяли раньше, чем создали.
        # Одна такая запись утащила бы среднее в минус.
        reaction_is_sane = (
            (reacted_at.isnot(None)) & (reaction_seconds >= 0) & is_breakdown
        )

        return query.with_entities(
            func.count(Order.id).filter(is_breakdown).label("breakdowns"),
            func.count(Order.id).filter(is_client).label("client_requests"),
            func.count(Order.id).filter(is_other).label("other_requests"),
            func.avg(reaction_seconds)
            .filter(reaction_is_sane)
            .label("avg_reaction_seconds"),
            func.count(Order.id).filter(reaction_is_sane).label("reacted_count"),
            func.count(func.distinct(Object.id))
            .filter(is_breakdown)
            .label("objects_with_breakdowns"),
        ).one()

    def defect_total(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ) -> int:
        """Дефектных ведомостей за период по всему отбору."""
        return (
            self._defects_query(db=db, period=period, scope=scope, **filters)
            .with_entities(func.count(DefectiveAct.id))
            .scalar()
            or 0
        )

    # ------------------------------------------------------------------
    # Помесячная полоса
    # ------------------------------------------------------------------

    def maintenance_by_month(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ) -> List:
        """План и факт ТО по месяцам периода — верхняя половина полосы."""
        query, cells = self._maintenance_query(
            db=db, period=period, scope=scope, **filters
        )
        finished = ActFact.finished_at.isnot(None)

        return (
            query.with_entities(
                cells.c.year.label("year"),
                cells.c.month.label("month"),
                func.count(cells.c.act_id).label("planned"),
                func.count(cells.c.act_id).filter(finished).label("completed"),
            )
            .group_by(cells.c.year, cells.c.month)
            .all()
        )

    def orders_by_month(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ) -> List:
        """Заявки по месяцам периода — нижняя половина полосы."""
        query, creator = self._orders_query(
            db=db, period=period, scope=scope, **filters
        )
        is_breakdown, is_client, is_other = self._kind_flags(creator)

        year = func.extract("year", Order.created_at)
        month = func.extract("month", Order.created_at)

        return (
            query.with_entities(
                year.label("year"),
                month.label("month"),
                func.count(Order.id).filter(is_breakdown).label("breakdowns"),
                func.count(Order.id).filter(is_client).label("client_requests"),
                func.count(Order.id).filter(is_other).label("other_requests"),
            )
            .group_by(year, month)
            .all()
        )

    def defects_by_month(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ) -> List:
        """Дефектные акты по месяцам периода."""
        year, month = self._defect_year_month()

        return (
            self._defects_query(db=db, period=period, scope=scope, **filters)
            .with_entities(
                year.label("year"),
                month.label("month"),
                func.count(DefectiveAct.id).label("defects"),
            )
            .group_by(year, month)
            .all()
        )

    # ------------------------------------------------------------------
    # Разрезы по объектам страницы
    # ------------------------------------------------------------------

    def maintenance_cells(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        object_ids: List[int],
        **filters,
    ) -> List:
        """Ячейки ТО по объектам страницы: объект, месяц, статус, дата закрытия.

        Считается только по объектам выдачи — иначе на тысяче лифтов запрос
        вернёт данные, которые никто не покажет.
        """
        if not object_ids:
            return []

        query, cells = self._maintenance_query(
            db=db, period=period, scope=scope, **filters
        )
        ends = self._month_end_case(cells, period.months)

        return (
            query.filter(Object.id.in_(object_ids))
            .with_entities(
                Object.id.label("object_id"),
                cells.c.year.label("year"),
                cells.c.month.label("month"),
                cells.c.act_id.label("act_id"),
                ActFact.finished_at.label("finished_at"),
                ends.label("month_end"),
            )
            .order_by(Object.id.asc(), cells.c.year.asc(), cells.c.month.asc())
            .all()
        )

    def order_counts(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        object_ids: List[int],
        **filters,
    ) -> List:
        """Заявки по видам, разложенные на объект и месяц."""
        if not object_ids:
            return []

        query, creator = self._orders_query(
            db=db, period=period, scope=scope, **filters
        )
        is_breakdown, is_client, is_other = self._kind_flags(creator)

        year = func.extract("year", Order.created_at)
        month = func.extract("month", Order.created_at)

        return (
            query.filter(Object.id.in_(object_ids))
            .with_entities(
                Object.id.label("object_id"),
                year.label("year"),
                month.label("month"),
                func.count(Order.id).filter(is_breakdown).label("breakdowns"),
                func.count(Order.id).filter(is_client).label("client_requests"),
                func.count(Order.id).filter(is_other).label("other_requests"),
            )
            .group_by(Object.id, year, month)
            .all()
        )

    def defect_counts(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        object_ids: List[int],
        **filters,
    ) -> List:
        """Дефектные акты, разложенные на объект и месяц."""
        if not object_ids:
            return []

        year, month = self._defect_year_month()

        return (
            self._defects_query(db=db, period=period, scope=scope, **filters)
            .filter(Object.id.in_(object_ids))
            .with_entities(
                Object.id.label("object_id"),
                year.label("year"),
                month.label("month"),
                func.count(DefectiveAct.id).label("defects"),
            )
            .group_by(Object.id, year, month)
            .all()
        )

    # ------------------------------------------------------------------
    # Построчные детали работ
    # ------------------------------------------------------------------
    #
    # Те же три метода обслуживают и раскрытую строку одного объекта, и листы
    # выгрузки по всему отбору: разница только в том, передан ли `object_id`
    # среди фильтров. Отдельная пара «для экрана» и «для файла» означала бы
    # два набора условий, которые однажды разойдутся, и цифра в отправленном
    # заказчику файле перестала бы совпадать с цифрой на экране.

    def maintenance_details(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        **filters,
    ) -> List:
        """Плановые ТО построчно: чек-лист, даты, прораб и механик."""
        foreman = aliased(UniversalUser)
        mechanic = aliased(UniversalUser)

        query, cells = self._maintenance_query(
            db=db, period=period, scope=scope, **filters
        )
        ends = self._month_end_case(cells, period.months)

        return (
            query.outerjoin(foreman, ActFact.foreman_id == foreman.id)
            .outerjoin(mechanic, ActFact.main_mechanic_id == mechanic.id)
            .with_entities(
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("address"),
                cells.c.act_id.label("act_id"),
                cells.c.year.label("year"),
                cells.c.month.label("month"),
                ActFact.started_at.label("started_at"),
                ActFact.finished_at.label("finished_at"),
                ActFact.step_list_fact.label("step_list_fact"),
                ends.label("month_end"),
                foreman.name.label("foreman"),
                mechanic.name.label("mechanic"),
            )
            .order_by(
                Object.address.asc(),
                Object.id.asc(),
                cells.c.year.asc(),
                cells.c.month.asc(),
            )
            .all()
        )

    def order_details(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        **filters,
    ) -> List:
        """Заявки построчно, по возрастанию даты."""
        executor = aliased(UniversalUser)

        query, creator_joined = self._orders_query(
            db=db, period=period, scope=scope, **filters
        )
        is_breakdown, is_client, _ = self._kind_flags(creator_joined)

        return (
            query.outerjoin(executor, Order.executor_id == executor.id)
            .outerjoin(ReasonFault, Order.reason_fault_id == ReasonFault.id)
            .outerjoin(Status, Order.status_id == Status.id)
            .with_entities(
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("address"),
                Order.id.label("order_id"),
                Order.created_at.label("created_at"),
                func.coalesce(Order.accepted_at, Order.in_progress_at).label(
                    "accepted_at"
                ),
                Order.done_at.label("done_at"),
                Order.task_text.label("task_text"),
                Order.commentary.label("commentary"),
                FaultCategory.name.label("category"),
                FaultCategory.code.label("category_code"),
                ReasonFault.name.label("reason"),
                Status.name.label("status"),
                creator_joined.name.label("creator"),
                executor.name.label("executor"),
                is_breakdown.label("is_breakdown"),
                is_client.label("is_client"),
            )
            .order_by(Order.created_at.asc(), Order.id.asc())
            .all()
        )

    def defect_details(
        self,
        *,
        db: Session,
        period: ReportRange,
        scope: AccessScope,
        **filters,
    ) -> List:
        """Дефектные акты построчно, с числом фотографий.

        Одни и те же строки для листа «Дефекты» файла, для шторки объекта и
        для списка за период с плитки сводки: число строк здесь равно
        `defect_total` того же отбора, иначе цифра на плитке и длина списка
        под ней разошлись бы.
        """
        responsible = aliased(UniversalUser)
        year, month = self._defect_year_month()

        # Число фотографий отдельным подзапросом, а не соединением с
        # группировкой: соединить напрямую значило бы размножить строки
        # ведомости по числу снимков и считать всё остальное по ним же.
        photos = (
            select(
                DefectiveActPhoto.defective_act_id.label("act_id"),
                func.count(DefectiveActPhoto.id).label("photo_count"),
            )
            .group_by(DefectiveActPhoto.defective_act_id)
            .subquery()
        )

        return (
            self._defects_query(db=db, period=period, scope=scope, **filters)
            .outerjoin(responsible, DefectiveAct.responsible_user_id == responsible.id)
            .outerjoin(Status, DefectiveAct.status_id == Status.id)
            .outerjoin(photos, photos.c.act_id == DefectiveAct.id)
            .with_entities(
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("address"),
                DefectiveAct.id.label("defect_id"),
                DefectiveAct.title.label("title"),
                DefectiveAct.description.label("description"),
                month.label("month"),
                DefectiveAct.created_at.label("created_at"),
                year.label("year"),
                Status.name.label("status"),
                responsible.name.label("responsible"),
                func.coalesce(photos.c.photo_count, 0).label("photo_count"),
            )
            .order_by(DefectiveAct.created_at.asc(), DefectiveAct.id.asc())
            .all()
        )

    # ------------------------------------------------------------------
    # Фотографии и реквизиты — только для файла
    # ------------------------------------------------------------------

    def order_photos(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ) -> Dict[int, List[str]]:
        """{id заявки: [пути к фото]} по тому же отбору, что и сам отчёт.

        Отдельным методом, а не колонкой в `order_details`: фотографии нужны
        только выгрузке с галочкой, и тянуть их в каждый ответ экрана значило
        бы возить байты, которые никто не смотрит.
        """
        query, _ = self._orders_query(db=db, period=period, scope=scope, **filters)

        rows = (
            query.join(OrderPhoto, OrderPhoto.order_id == Order.id)
            .with_entities(Order.id.label("order_id"), OrderPhoto.photo.label("photo"))
            .order_by(Order.id.asc(), OrderPhoto.id.asc())
            .all()
        )

        result: Dict[int, List[str]] = {}
        for row in rows:
            if row.photo:
                result.setdefault(row.order_id, []).append(row.photo)
        return result

    def defect_photos(
        self, *, db: Session, period: ReportRange, scope: AccessScope, **filters
    ) -> Dict[int, List[str]]:
        """{id дефектной ведомости: [пути к фото]}."""
        rows = (
            self._defects_query(db=db, period=period, scope=scope, **filters)
            .join(
                DefectiveActPhoto,
                DefectiveActPhoto.defective_act_id == DefectiveAct.id,
            )
            .with_entities(
                DefectiveAct.id.label("defect_id"),
                DefectiveActPhoto.photo.label("photo"),
            )
            .order_by(DefectiveAct.id.asc(), DefectiveActPhoto.id.asc())
            .all()
        )

        result: Dict[int, List[str]] = {}
        for row in rows:
            if row.photo:
                result.setdefault(row.defect_id, []).append(row.photo)
        return result

    def executor_organization(
        self, *, db: Session, scope: AccessScope, **filters
    ) -> Optional[object]:
        """Организация-исполнитель для шапки файла.

        Берётся у объектов отбора, а не из настроек: организация в этой
        системе — наше юрлицо по договору, и на разных объектах оно может
        быть разным. Если объекты отбора принадлежат нескольким организациям,
        шапку заполнять нечем — возвращаем пусто, и файл выходит без неё.
        """
        rows = (
            self._objects_query(db=db, scope=scope, **filters)
            .join(Organization, Object.organization_id == Organization.id)
            .with_entities(
                Organization.id.label("id"),
                Organization.title.label("title"),
                Organization.photo.label("logo"),
                Organization.phone_office.label("phone"),
                Organization.site.label("site"),
                Organization.address.label("address"),
            )
            .distinct()
            .limit(2)
            .all()
        )
        return rows[0] if len(rows) == 1 else None

    def client_names(self, *, db: Session, scope: AccessScope, **filters) -> List[str]:
        """Названия клиентов отбора — вторая строка шапки файла."""
        rows = (
            self._objects_query(db=db, scope=scope, **filters)
            .outerjoin(Company, Object.company_id == Company.id)
            .with_entities(Company.name.label("name"))
            .distinct()
            .all()
        )
        return sorted({row.name for row in rows if row.name})


crud_reports = CrudReports()
