"""Запросы для статистики на главной.

Здесь живут топ поломок, выполнение графика ТО и просроченные ТО. Рядом
встанет топ сотрудников — у них общий период и общие фильтры, поэтому модуль
отдельный, а не внутри `crud_order`.

Что считается просрочкой
------------------------
Плановая ячейка месяца заполнена, плановый месяц уже **закончился**, а
`finished_at` у связанного акта пуст. Текущий месяц не просрочен: он ещё идёт.

В отличие от двух других виджетов, у этого нет выбора месяца: просрочка — это
состояние на сегодня, а не срез периода. Смотрим на два года — текущий и
предыдущий: иначе первого января долги обнулялись бы сами собой, а копать
глубже смысла нет, ТО двухлетней давности уже никто не закроет.

Что считается выполнением графика
---------------------------------
План на месяц — заполненная ячейка месяца в `planned_to` за нужный год.
Отдельного признака «в этом месяце ТО положено» в модели нет: на экране
графика нажатие на месяц сразу создаёт акт, то есть заведение акта и есть
планирование. Из-за этого объект, которому ТО на месяц просто не завели, в
знаменатель не попадает — и разная периодичность обслуживания учитывается
сама собой.

Выполнено — у связанного акта заполнен `finished_at`, любой датой. Месяц
берётся из ячейки плана, а не из даты закрытия: ТО за март, закрытое второго
апреля, остаётся выполнением марта, иначе процент за прошлый месяц менялся бы
задним числом. Закрытие после конца планового месяца отдельно считается
просрочкой.

Что считается поломкой
----------------------
Заявка (`order`), созданная в выбранном месяце, у которой категория помечена
`counts_as_breakdown`. Заявка без категории тоже считается: пустое поле —
это недозаполненная заявка, а не плановая работа, и терять её нельзя.
Плановые ТО, ПТО, капремонт и ложные вызовы исключены — см. миграцию
`a1c7f3d92b40`.

Порядок тяжести
---------------
Классификация засеяна по убыванию тяжести: id 1 — AA (застревание пассажира),
дальше А, В, Н и так далее. Поэтому «severity_rank» — это `fault_category.id`,
и меньший id означает более тяжёлое событие. Категория, заведённая админом
позже, получает больший id и считается наименее тяжёлой — безопасное умолчание.
Отдельной колонки-ранга нет намеренно: лишнее поле, которое надо
поддерживать руками, разъедется с реальностью быстрее, чем принесёт пользу.
"""

import datetime
from typing import Dict, FrozenSet, List, NamedTuple, Optional, Tuple

from sqlalchemy import and_, func, literal, or_, select, union_all
from sqlalchemy.orm import Session

from src.core.access import (
    AccessScope,
    apply_order_scope,
    apply_user_scope,
    object_scope_filter,
)
from src.core.roles import FIELD_ROLES, FOREMAN
from src.models import (
    ActBase,
    ActFact,
    Company,
    Division,
    FactoryModel,
    FaultCategory,
    Object,
    Order,
    Organization,
    PlannedTO,
    UniversalUser,
    UserDivision,
)

# Категория, заведённая до миграции или вручную, приходит с NULL в
# `counts_as_breakdown` только теоретически (колонка NOT NULL), но `id` у
# заявки без категории отсутствует всегда. Чтобы такие заявки не выигрывали
# сортировку по тяжести, подставляем заведомо больший ранг.
_UNKNOWN_SEVERITY_RANK = 10**6

# «Выполнено» в таблице `statuses`. Статусы засеяны при первом старте и в
# коде уже зашиты числами (`crud_order.update` ставит по ним отметки времени),
# так что константа здесь только называет число, а не вводит новое.
_STATUS_DONE = 4

# Чек-лист акта хранится строкой, похожей на JSON: список словарей с ключами
# `text`, `bool`, `comment`, `photo`. Число пунктов — это число вхождений
# ключа `text`; считать его в SQL дешевле, чем разбирать строку в Python на
# каждой из трёхсот заготовок.
_STEP_MARKER = '"text":'

# Месяц в `planned_to` — это отдельная колонка, а не строка таблицы. Разложить
# её в нормальную форму значило бы переписать экран графика ТО, который в неё
# пишет; здесь достаточно карты «номер месяца → колонка».
_PLANNED_MONTH_COLUMN = {
    1: PlannedTO.january_to_id,
    2: PlannedTO.february_to_id,
    3: PlannedTO.march_to_id,
    4: PlannedTO.april_to_id,
    5: PlannedTO.may_to_id,
    6: PlannedTO.june_to_id,
    7: PlannedTO.july_to_id,
    8: PlannedTO.august_to_id,
    9: PlannedTO.september_to_id,
    10: PlannedTO.october_to_id,
    11: PlannedTO.november_to_id,
    12: PlannedTO.december_to_id,
}


class MonthPeriod(NamedTuple):
    """Календарный месяц как полуинтервал [start, end)."""

    year: int
    month: int
    start: datetime.datetime
    end: datetime.datetime


def month_period(year: int, month: int) -> MonthPeriod:
    start = datetime.datetime(year, month, 1)
    if month == 12:
        end = datetime.datetime(year + 1, 1, 1)
    else:
        end = datetime.datetime(year, month + 1, 1)
    return MonthPeriod(year=year, month=month, start=start, end=end)


def _checklist_steps():
    """Число пунктов в чек-листе заготовки акта, выражением SQL.

    Считаем вхождения ключа `text`: строка хранится питоновским `repr`-подобным
    текстом, и разбирать её ради одного числа дорого. Пустая заготовка даёт
    ноль — деления на это число нигде нет.
    """
    stripped = func.length(func.replace(ActBase.step_list, _STEP_MARKER, ""))
    return (func.length(ActBase.step_list) - stripped) / len(_STEP_MARKER)


def previous_month(year: int, month: int) -> Tuple[int, int]:
    if month == 1:
        return year - 1, 12
    return year, month - 1


class CrudStatistics:
    """Агрегаты для виджетов главной. Модели своей нет, поэтому не CRUDBase."""

    # ------------------------------------------------------------------
    # Общие куски запроса
    # ------------------------------------------------------------------

    def _breakdowns_query(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ):
        """Заявки-поломки за период с присоединённым объектом и категорией.

        Возвращает `Query`, к которому вызывающий добавляет свою группировку.

        Область видимости применяется здесь — единственной точкой на всю
        статистику. Все агрегаты ниже строятся поверх этого запроса, поэтому
        порезаны разом и не могут разойтись между собой: цифра в карточке,
        свод по категориям и выгрузка в PDF считают по одному отбору.
        """
        query = (
            db.query(Order)
            .join(Object, Order.object_id == Object.id)
            .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
            .filter(
                Order.created_at.isnot(None),
                Order.created_at >= period.start,
                Order.created_at < period.end,
                # Заявка без категории считается поломкой: недозаполненная
                # заявка — это не повод потерять реальный выезд.
                (
                    (Order.fault_category_id.is_(None))
                    | (FaultCategory.counts_as_breakdown.is_(True))
                ),
            )
        )

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        # Тем же фильтром, что и список заявок. Фильтры выше — это выбор
        # пользователя, а этот — граница, за которую он выйти не может:
        # запрошенный `company_id` чужой компании не расширит выдачу.
        return apply_order_scope(query, scope)

    # ------------------------------------------------------------------
    # Топ объектов
    # ------------------------------------------------------------------

    def top_breakdown_objects(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        limit: Optional[int] = 5,
        offset: int = 0,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> List:
        """Объекты с наибольшим числом поломок за месяц.

        Сортировка: сначала по числу заявок, при равенстве выше тот, у кого
        случилось более тяжёлое событие, затем по id — чтобы порядок не
        плавал между запросами при полностью одинаковых показателях.
        """
        # Время реакции: сколько прошло от создания заявки до момента, когда
        # её взяли в работу. `accepted_at` пишется на статусе «Принято»,
        # `in_progress_at` — на «В процессе». Диспетчер нередко прыгает сразу
        # в «В процессе», поэтому берём первое непустое из двух.
        reacted_at = func.coalesce(Order.accepted_at, Order.in_progress_at)
        reaction_seconds = func.extract("epoch", reacted_at - Order.created_at)
        # Отрицательная разница означает битые данные (взяли раньше, чем
        # создали) — такие заявки в среднее не пускаем, иначе одна кривая
        # запись утащит цифру в минус.
        reaction_is_sane = (reacted_at.isnot(None)) & (reaction_seconds >= 0)

        resolution_seconds = func.extract("epoch", Order.done_at - Order.created_at)
        resolution_is_sane = (Order.done_at.isnot(None)) & (resolution_seconds >= 0)

        severity_rank = func.coalesce(FaultCategory.id, _UNKNOWN_SEVERITY_RANK)

        query = (
            self._breakdowns_query(
                db=db,
                period=period,
                scope=scope,
                division_id=division_id,
                organization_id=organization_id,
                company_id=company_id,
            )
            .outerjoin(Organization, Object.organization_id == Organization.id)
            .outerjoin(Company, Object.company_id == Company.id)
            .outerjoin(Division, Object.division_id == Division.id)
            .outerjoin(FactoryModel, Object.factory_model_id == FactoryModel.id)
            .outerjoin(UniversalUser, Object.mechanic_id == UniversalUser.id)
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
                UniversalUser.name.label("responsible_mechanic"),
                func.count(Order.id).label("breakdown_count"),
                func.min(severity_rank).label("top_severity_rank"),
                func.avg(reaction_seconds)
                .filter(reaction_is_sane)
                .label("avg_reaction_seconds"),
                func.count(Order.id).filter(reaction_is_sane).label("reacted_count"),
                func.avg(resolution_seconds)
                .filter(resolution_is_sane)
                .label("avg_resolution_seconds"),
                func.count(Order.id).filter(resolution_is_sane).label("resolved_count"),
            )
            .group_by(
                Object.id,
                Object.name,
                Object.registration_number,
                Object.factory_number,
                Object.address,
                Organization.title,
                Company.name,
                Division.title,
                FactoryModel.factory,
                FactoryModel.model,
                UniversalUser.name,
            )
            .order_by(
                func.count(Order.id).desc(),
                func.min(severity_rank).asc(),
                Object.id.asc(),
            )
        )

        if offset:
            query = query.offset(offset)
        if limit is not None:
            query = query.limit(limit)

        return query.all()

    def count_breakdown_objects(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Tuple[int, int]:
        """(всего поломок, объектов с поломками) за период.

        Нужно и карточке («показано 5 из 23»), и экрану подробностей.
        """
        row = (
            self._breakdowns_query(
                db=db,
                period=period,
                scope=scope,
                division_id=division_id,
                organization_id=organization_id,
                company_id=company_id,
            )
            .with_entities(
                func.count(Order.id).label("total"),
                func.count(func.distinct(Object.id)).label("objects"),
            )
            .one()
        )
        return int(row.total or 0), int(row.objects or 0)

    # ------------------------------------------------------------------
    # Разрезы по категориям
    # ------------------------------------------------------------------

    def breakdowns_by_category(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> List:
        """Свод по категориям за период — чипы под заголовком карточки.

        Порядок — по тяжести, то есть по id категории. Заявки без категории
        идут последними отдельной строкой с `category_id = None`.
        """
        return (
            self._breakdowns_query(
                db=db,
                period=period,
                scope=scope,
                division_id=division_id,
                organization_id=organization_id,
                company_id=company_id,
            )
            .with_entities(
                FaultCategory.id.label("category_id"),
                FaultCategory.code.label("code"),
                FaultCategory.name.label("name"),
                func.count(Order.id).label("count"),
            )
            .group_by(FaultCategory.id, FaultCategory.code, FaultCategory.name)
            .order_by(func.coalesce(FaultCategory.id, _UNKNOWN_SEVERITY_RANK).asc())
            .all()
        )

    def object_severity_breakdown(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        object_ids: List[int],
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Dict[int, List]:
        """Разбивка по тяжести внутри каждого объекта: {object_id: [строки]}.

        Считается только для объектов, попавших в выдачу, — иначе на тысяче
        лифтов запрос вернёт данные, которые никто не покажет.
        """
        if not object_ids:
            return {}

        rows = (
            self._breakdowns_query(
                db=db,
                period=period,
                scope=scope,
                division_id=division_id,
                organization_id=organization_id,
                company_id=company_id,
            )
            .filter(Object.id.in_(object_ids))
            .with_entities(
                Object.id.label("object_id"),
                FaultCategory.id.label("category_id"),
                FaultCategory.code.label("code"),
                FaultCategory.name.label("name"),
                func.count(Order.id).label("count"),
            )
            .group_by(
                Object.id, FaultCategory.id, FaultCategory.code, FaultCategory.name
            )
            .order_by(
                Object.id.asc(),
                func.coalesce(FaultCategory.id, _UNKNOWN_SEVERITY_RANK).asc(),
            )
            .all()
        )

        result: Dict[int, List] = {object_id: [] for object_id in object_ids}
        for row in rows:
            result[row.object_id].append(row)
        return result

    # ------------------------------------------------------------------
    # Сравнение с прошлым месяцем
    # ------------------------------------------------------------------

    def breakdown_counts_by_object(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        object_ids: List[int],
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Dict[int, int]:
        """{object_id: число поломок} за период — для дельты к прошлому месяцу.

        Объект, которого в периоде не было, в словарь не попадает: ноль и
        «не было данных» здесь означают разное, и решает это вызывающий.
        """
        if not object_ids:
            return {}

        rows = (
            self._breakdowns_query(
                db=db,
                period=period,
                scope=scope,
                division_id=division_id,
                organization_id=organization_id,
                company_id=company_id,
            )
            .filter(Object.id.in_(object_ids))
            .with_entities(
                Object.id.label("object_id"),
                func.count(Order.id).label("count"),
            )
            .group_by(Object.id)
            .all()
        )
        return {row.object_id: int(row.count) for row in rows}

    # ------------------------------------------------------------------
    # Выполнение графика ТО
    # ------------------------------------------------------------------

    def schedule_execution_by_division(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> List:
        """План и факт ТО за месяц в разрезе участков.

        Порядок — от худшего участка к лучшему: карточка на главной нужна,
        чтобы находить отстающих, а не чтобы читать её сверху вниз целиком.
        При равном проценте выше тот, у кого план больше, — там и цена
        отставания выше.
        """
        month_column = _PLANNED_MONTH_COLUMN[period.month]

        # Внутреннее соединение с актом и есть определение плана: ячейка без
        # акта — это не проваленное ТО, а незаполненный график.
        finished = ActFact.finished_at.isnot(None)
        # Закрыто после конца планового месяца. Сравнение с `period.end`, а не
        # с началом следующего дня: период — полуинтервал [start, end).
        finished_late = finished & (ActFact.finished_at >= period.end)

        planned = func.count(PlannedTO.id)
        completed = func.count(PlannedTO.id).filter(finished)

        query = (
            db.query(PlannedTO)
            .join(Object, PlannedTO.object_id == Object.id)
            .join(ActFact, ActFact.id == month_column)
            .outerjoin(Division, Object.division_id == Division.id)
            # `year` в модели строковый, приводить период к строке приходится
            # здесь. Менять тип колонки — отдельная миграция на живой таблице.
            .filter(PlannedTO.year == str(period.year))
        )

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        # Граница, за которую человек выйти не может. Заодно отсекает строки
        # графика, осиротевшие после удаления объекта: у них `object_id` пуст,
        # и соединение с `objects` их не пропускает.
        query = query.filter(object_scope_filter(scope))

        return (
            query.with_entities(
                Object.division_id.label("division_id"),
                Division.title.label("division"),
                planned.label("planned_count"),
                completed.label("completed_count"),
                func.count(PlannedTO.id)
                .filter(finished_late)
                .label("completed_late_count"),
            )
            .group_by(Object.division_id, Division.title)
            .order_by(
                # Доля выполненных: считаем в SQL, чтобы сортировка и число на
                # экране заведомо совпадали. Делить безопасно: группа
                # существует только там, где есть хотя бы одна строка плана.
                (completed * 1.0 / planned).asc(),
                planned.desc(),
                Object.division_id.asc(),
            )
            .all()
        )

    # ------------------------------------------------------------------
    # Просроченные ТО
    # ------------------------------------------------------------------

    def _planned_cells(self, *, years: List[int]):
        """Двенадцать колонок месяцев, развёрнутые в строки.

        `planned_to` хранит месяц колонкой, а не строкой таблицы, поэтому
        «все просроченные ТО» одним `WHERE` не выражаются: нужен `UNION ALL`
        из двенадцати выборок. У выполнения графика этой проблемы нет — там
        месяц ровно один и колонка выбирается по карте.

        Ветки узкие: каждая отсекает пустые ячейки и чужие годы до слияния,
        так что до объединения доходит только то, что заведено.
        """
        year_strings = [str(year) for year in years]

        branches = [
            select(
                PlannedTO.object_id.label("object_id"),
                PlannedTO.year.label("year"),
                literal(month_number).label("month"),
                column.label("act_id"),
            ).where(
                column.isnot(None),
                # Год в модели строковый. Сравниваем перечислением заведомо
                # известных значений, а не приведением типа: в колонке живут
                # данные, набитые руками, и `CAST` уронил бы запрос целиком на
                # первой же строке вроде «2025 г.».
                PlannedTO.year.in_(year_strings),
            )
            for month_number, column in _PLANNED_MONTH_COLUMN.items()
        ]

        return union_all(*branches).subquery("planned_cells")

    def _overdue_query(
        self,
        *,
        db: Session,
        reference: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ):
        """Незакрытые ТО, чей плановый месяц уже прошёл.

        `reference` — месяц, который идёт сейчас; он сам не просрочен.
        Передаётся снаружи, а не берётся из `datetime.now()` здесь, иначе
        тесты этой арифметики зависели бы от дня прогона.

        Возвращает `Query` с присоединёнными объектом и актом; вызывающий
        добавляет свою выборку — список или счётчик.
        """
        cells = self._planned_cells(years=[reference.year - 1, reference.year])

        # Плановый месяц строго раньше текущего. Прошлый год просрочен весь,
        # текущий — до предыдущего месяца включительно. В январе вторая ветка
        # не даёт ничего сама собой, отдельного случая не нужно.
        overdue = or_(
            cells.c.year == str(reference.year - 1),
            and_(
                cells.c.year == str(reference.year),
                cells.c.month < reference.month,
            ),
        )

        query = (
            db.query(Object)
            .select_from(cells)
            # Внутренние соединения намеренно: ячейка без объекта — осиротевший
            # график (`object_id` уходит в NULL при удалении объекта), а ячейка
            # с несуществующим актом — мусор. Ни то, ни другое не долг.
            .join(Object, Object.id == cells.c.object_id)
            .join(ActFact, ActFact.id == cells.c.act_id)
            .filter(overdue, ActFact.finished_at.is_(None))
        )

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        # Граница, за которую человек выйти не может — той же функцией, что и
        # выполнение графика: объект здесь присоединён явно.
        return query.filter(object_scope_filter(scope)), cells

    def overdue_maintenance(
        self,
        *,
        db: Session,
        reference: MonthPeriod,
        scope: AccessScope,
        limit: Optional[int] = 5,
        offset: int = 0,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> List:
        """Список просроченных ТО, самые старые сверху.

        Строка — одно ТО, то есть пара «объект и плановый месяц». Объект с
        тремя пропущенными месяцами даёт три строки: свернуть их в одну
        значило бы потерять, за какие именно месяцы долг.
        """
        query, cells = self._overdue_query(
            db=db,
            reference=reference,
            scope=scope,
            division_id=division_id,
            organization_id=organization_id,
            company_id=company_id,
        )

        query = (
            query.outerjoin(Organization, Object.organization_id == Organization.id)
            .outerjoin(Company, Object.company_id == Company.id)
            .outerjoin(Division, Object.division_id == Division.id)
            .outerjoin(UniversalUser, Object.mechanic_id == UniversalUser.id)
            .with_entities(
                cells.c.act_id.label("act_id"),
                cells.c.year.label("year"),
                cells.c.month.label("month"),
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.registration_number.label("registration_number"),
                Object.factory_number.label("factory_number"),
                Object.address.label("address"),
                func.coalesce(Organization.title, Company.name).label("client"),
                Division.title.label("division"),
                UniversalUser.name.label("responsible_mechanic"),
            )
            .order_by(
                # Год строковый, но здесь их всего два и оба четырёхзначные —
                # текстовый порядок совпадает с числовым.
                cells.c.year.asc(),
                cells.c.month.asc(),
                Object.id.asc(),
            )
        )

        if offset:
            query = query.offset(offset)
        if limit is not None:
            query = query.limit(limit)

        return query.all()

    def count_overdue_maintenance(
        self,
        *,
        db: Session,
        reference: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Tuple[int, int]:
        """(просроченных ТО, объектов с просрочкой).

        Нужно счётчику в шапке карточки: `len(items)` там соврёт, потому что
        список обрезан `limit`.
        """
        query, cells = self._overdue_query(
            db=db,
            reference=reference,
            scope=scope,
            division_id=division_id,
            organization_id=organization_id,
            company_id=company_id,
        )

        row = query.with_entities(
            func.count(cells.c.act_id).label("total"),
            func.count(func.distinct(Object.id)).label("objects"),
        ).one()
        return int(row.total or 0), int(row.objects or 0)

    # ------------------------------------------------------------------
    # Топ сотрудников
    # ------------------------------------------------------------------
    #
    # Здесь запросы отдают строки, а не готовые агрегаты, — в отличие от трёх
    # виджетов выше. Причина в том, что балл сотрудника считается по
    # нормативам, разным для разной тяжести аварии, и живёт формулой в
    # `src/services/employee_score.py`. Сложить её в SQL значило бы размазать
    # правило по двум местам и потерять возможность проверить его тестом без
    # базы. Строк при этом немного: заявки и ТО одного месяца в границах
    # области видимости.

    def rateable_employees(
        self,
        *,
        db: Session,
        scope: AccessScope,
        role_ids: FrozenSet[int],
        division_id: Optional[int] = None,
    ) -> List:
        """Сотрудники, которых вообще можно поставить в рейтинг.

        Только действующие: уволенный не должен всплывать в «худших» через
        месяц после ухода. Список режется тем же фильтром, что и обычный
        список людей — см. [[список людей режется по участкам]].
        """
        query = (
            db.query(UniversalUser)
            .outerjoin(Division, UniversalUser.division_id == Division.id)
            .filter(
                UniversalUser.role_id.in_(sorted(role_ids)),
                UniversalUser.is_active.is_(True),
            )
        )
        query = apply_user_scope(query, scope)

        if division_id is not None:
            # Участок берём и из основного поля, и из связи: у человека их
            # может быть несколько, а фильтр в шапке карточки один.
            query = query.filter(
                or_(
                    UniversalUser.division_id == division_id,
                    UniversalUser.id.in_(
                        select(UserDivision.user_id)
                        .where(UserDivision.division_id == division_id)
                        .correlate(None)
                        .scalar_subquery()
                    ),
                )
            )

        return (
            query.with_entities(
                UniversalUser.id.label("user_id"),
                UniversalUser.name.label("name"),
                UniversalUser.role_id.label("role_id"),
                Division.title.label("division"),
            )
            .order_by(UniversalUser.id)
            .all()
        )

    def employee_orders(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> List:
        """Закрытые заявки периода построчно, с исполнителем и тяжестью.

        Дата закрытия — `coalesce(done_at, created_at)`. Честнее был бы один
        `done_at`, но он начал заполняться только после починки опечатки
        (`dane_at` в `OrderUpdate`), и по историческим заявкам пуст у всех до
        одной. Без запасного варианта карточка на проде оказалась бы пустой
        не потому, что люди не работали, а потому что поле не писалось.

        Отметки времени отдаются как есть: считать разницы и отбрасывать
        битые — дело скоринга, там же лежат нормативы.
        """
        closed_at = func.coalesce(Order.done_at, Order.created_at)

        query = (
            db.query(Order)
            .join(Object, Order.object_id == Object.id)
            .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
            .filter(
                Order.executor_id.isnot(None),
                Order.status_id == _STATUS_DONE,
                Order.created_at.isnot(None),
                closed_at >= period.start,
                closed_at < period.end,
            )
        )

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        return (
            apply_order_scope(query, scope)
            .with_entities(
                Order.id.label("order_id"),
                Order.executor_id.label("executor_id"),
                Order.object_id.label("object_id"),
                Order.created_at.label("created_at"),
                func.coalesce(Order.accepted_at, Order.in_progress_at).label(
                    "reacted_at"
                ),
                Order.done_at.label("done_at"),
                closed_at.label("closed_at"),
                FaultCategory.code.label("category_code"),
                # Заявка без категории считается поломкой — то же правило, что
                # и в топе поломок, иначе два виджета разошлись бы в цифрах.
                func.coalesce(FaultCategory.counts_as_breakdown, True).label(
                    "is_breakdown"
                ),
                # Свой лифт или чужой: за выезд на чужой объект в скоринге
                # положен коэффициент.
                (Object.mechanic_id == Order.executor_id).label("is_own_object"),
            )
            .order_by(Order.id)
            .all()
        )

    def employee_maintenance(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> List:
        """Плановые ТО месяца построчно: чьё, закрыто ли и насколько объёмно.

        План и «вовремя» понимаются ровно как у виджета выполнения графика:
        план — заполненная ячейка месяца, вовремя — `finished_at` раньше
        конца планового месяца. Расхождение между двумя карточками главной
        стоило бы дороже любой находки.

        Объём чек-листа едет строкой: у ТО-12 пунктов вчетверо больше, чем у
        ТО-3, и скоринг взвешивает работу по этому числу.
        """
        month_column = _PLANNED_MONTH_COLUMN[period.month]

        query = (
            db.query(PlannedTO)
            .join(Object, PlannedTO.object_id == Object.id)
            .join(ActFact, ActFact.id == month_column)
            .outerjoin(ActBase, ActFact.act_base_id == ActBase.id)
            .filter(PlannedTO.year == str(period.year))
        )

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        query = query.filter(object_scope_filter(scope))

        return (
            query.with_entities(
                ActFact.id.label("act_id"),
                ActFact.main_mechanic_id.label("mechanic_id"),
                ActFact.finished_at.label("finished_at"),
                Object.id.label("object_id"),
                (Object.mechanic_id == ActFact.main_mechanic_id).label("is_own_object"),
                _checklist_steps().label("steps_count"),
            )
            .order_by(ActFact.id)
            .all()
        )

    def median_checklist_steps(self, *, db: Session) -> float:
        """Медианное число пунктов в заготовке акта.

        Нужна, чтобы вес ТО был безразмерным: акт с пунктами по медиане
        весит единицу, вчетверо длиннее — четыре. Считаем в Python: заготовок
        три сотни, а `percentile_cont` в SQLAlchemy 1.4 читается хуже, чем
        стоит.
        """
        counts = sorted(
            int(row[0] or 0)
            for row in db.query(_checklist_steps())
            .filter(ActBase.step_list.isnot(None))
            .all()
        )
        counts = [count for count in counts if count > 0]
        if not counts:
            return 0.0

        middle = len(counts) // 2
        if len(counts) % 2:
            return float(counts[middle])
        return (counts[middle - 1] + counts[middle]) / 2

    def objects_per_mechanic(
        self,
        *,
        db: Session,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Dict[int, int]:
        """{mechanic_id: сколько лифтов на нём закреплено}.

        Знаменатель аварийности парка. Считается по нынешнему закреплению, а
        не по тому, кто обслуживал лифт в тот месяц: истории закреплений в
        базе нет.
        """
        query = db.query(Object).filter(Object.mechanic_id.isnot(None))

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        rows = (
            query.filter(object_scope_filter(scope))
            .with_entities(
                Object.mechanic_id.label("mechanic_id"),
                func.count(Object.id).label("objects"),
            )
            .group_by(Object.mechanic_id)
            .all()
        )
        return {int(row.mechanic_id): int(row.objects) for row in rows}

    def breakdowns_per_mechanic(
        self,
        *,
        db: Session,
        period: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Dict[int, int]:
        """{mechanic_id: поломок за месяц на его лифтах}.

        Числитель аварийности парка. Поломка определяется тем же подзапросом,
        что и в топе поломок, — включая заявки категории «Д (Заказчик или
        другие)». Разойтись в определении поломки между двумя виджетами
        главной было бы дороже, чем эта неточность.
        """
        rows = (
            self._breakdowns_query(
                db=db,
                period=period,
                scope=scope,
                division_id=division_id,
                organization_id=organization_id,
                company_id=company_id,
            )
            .filter(Object.mechanic_id.isnot(None))
            .with_entities(
                Object.mechanic_id.label("mechanic_id"),
                func.count(Order.id).label("breakdowns"),
            )
            .group_by(Object.mechanic_id)
            .all()
        )
        return {int(row.mechanic_id): int(row.breakdowns) for row in rows}

    def breakdown_events(
        self,
        *,
        db: Session,
        start: datetime.datetime,
        end: datetime.datetime,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> List:
        """Поломки за произвольное окно: (объект, когда случилась).

        Нужны, чтобы найти повторный вызов на тот же лифт после ремонта.
        Окно шире отчётного месяца — на длину срока повтора, иначе авария
        первого числа следующего месяца не нашлась бы и переделка в конце
        месяца прощалась бы сама собой.
        """
        query = (
            db.query(Order)
            .join(Object, Order.object_id == Object.id)
            .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
            .filter(
                Order.created_at.isnot(None),
                Order.created_at >= start,
                Order.created_at < end,
                (
                    (Order.fault_category_id.is_(None))
                    | (FaultCategory.counts_as_breakdown.is_(True))
                ),
            )
        )

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        return (
            apply_order_scope(query, scope)
            .with_entities(
                Order.object_id.label("object_id"),
                Order.created_at.label("created_at"),
            )
            .order_by(Order.created_at)
            .all()
        )

    def mechanics_by_division(
        self, *, db: Session, division_ids: List[int]
    ) -> Dict[int, List[int]]:
        """{division_id: [id механиков и инженеров]}.

        Нужно баллу прораба: половина его оценки — средний балл людей его
        участков. Через `user_divisions`, как и прорабы: участков у человека
        бывает несколько.
        """
        if not division_ids:
            return {}

        rows = (
            db.query(UserDivision.division_id, UniversalUser.id)
            .join(UniversalUser, UniversalUser.id == UserDivision.user_id)
            .filter(
                UserDivision.division_id.in_(division_ids),
                UniversalUser.role_id.in_(sorted(FIELD_ROLES)),
                UniversalUser.is_active.is_(True),
            )
            .order_by(UserDivision.division_id, UniversalUser.id)
            .all()
        )

        result: Dict[int, List[int]] = {}
        for division_id, user_id in rows:
            result.setdefault(division_id, []).append(user_id)
        return result

    def divisions_by_user(
        self, *, db: Session, user_ids: List[int]
    ) -> Dict[int, List[int]]:
        """{user_id: [участки]} — связь плюс основной участок.

        Тем же правилом, что и `division_ids_of` в проверках доступа: основное
        поле добавляется на случай, если связь не заполнена. Прораб, у
        которого участок проставлен только в карточке, иначе оценивался бы по
        пустому списку объектов.
        """
        if not user_ids:
            return {}

        result: Dict[int, List[int]] = {}

        rows = (
            db.query(UserDivision.user_id, UserDivision.division_id)
            .filter(UserDivision.user_id.in_(user_ids))
            .order_by(UserDivision.user_id, UserDivision.division_id)
            .all()
        )
        for user_id, division_id in rows:
            result.setdefault(user_id, []).append(division_id)

        primary = (
            db.query(UniversalUser.id, UniversalUser.division_id)
            .filter(
                UniversalUser.id.in_(user_ids),
                UniversalUser.division_id.isnot(None),
            )
            .all()
        )
        for user_id, division_id in primary:
            divisions = result.setdefault(user_id, [])
            if division_id not in divisions:
                divisions.append(division_id)

        return result

    def objects_per_division(
        self,
        *,
        db: Session,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Dict[int, int]:
        """{division_id: сколько лифтов на участке}. Знаменатель для долгов."""
        query = db.query(Object).filter(Object.division_id.isnot(None))

        if division_id is not None:
            query = query.filter(Object.division_id == division_id)
        if organization_id is not None:
            query = query.filter(Object.organization_id == organization_id)
        if company_id is not None:
            query = query.filter(Object.company_id == company_id)

        rows = (
            query.filter(object_scope_filter(scope))
            .with_entities(
                Object.division_id.label("division_id"),
                func.count(Object.id).label("objects"),
            )
            .group_by(Object.division_id)
            .all()
        )
        return {int(row.division_id): int(row.objects) for row in rows}

    def overdue_per_division(
        self,
        *,
        db: Session,
        reference: MonthPeriod,
        scope: AccessScope,
        division_id: Optional[int] = None,
        organization_id: Optional[int] = None,
        company_id: Optional[int] = None,
    ) -> Dict[int, int]:
        """{division_id: сколько ТО просрочено на сегодня}.

        Тем же запросом, что и карточка просроченных ТО, — чтобы долг у
        прораба в рейтинге и долг в соседней карточке были одним числом.
        """
        query, cells = self._overdue_query(
            db=db,
            reference=reference,
            scope=scope,
            division_id=division_id,
            organization_id=organization_id,
            company_id=company_id,
        )

        rows = (
            query.filter(Object.division_id.isnot(None))
            .with_entities(
                Object.division_id.label("division_id"),
                func.count(cells.c.act_id).label("overdue"),
            )
            .group_by(Object.division_id)
            .all()
        )
        return {int(row.division_id): int(row.overdue) for row in rows}

    def foremen_by_division(
        self, *, db: Session, division_ids: List[int]
    ) -> Dict[int, List[str]]:
        """{division_id: [имена прорабов]} — одним запросом на все участки.

        Через `user_divisions`, а не через `universal_users.division_id`:
        участков у человека может быть несколько, и проверки доступа смотрят
        именно в связь. Основное поле показало бы прораба только на одном из
        его участков.
        """
        if not division_ids:
            return {}

        rows = (
            db.query(UserDivision.division_id, UniversalUser.name)
            .join(UniversalUser, UniversalUser.id == UserDivision.user_id)
            .filter(
                UserDivision.division_id.in_(division_ids),
                UniversalUser.role_id == FOREMAN,
                UniversalUser.is_active.is_(True),
            )
            .order_by(UserDivision.division_id, UniversalUser.id)
            .all()
        )

        result: Dict[int, List[str]] = {}
        for division_id, name in rows:
            if name:
                result.setdefault(division_id, []).append(name)
        return result


crud_statistics = CrudStatistics()
