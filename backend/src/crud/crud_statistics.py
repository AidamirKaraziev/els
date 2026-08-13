"""Запросы для статистики на главной.

Здесь живут топ поломок и выполнение графика ТО. Рядом встанут просроченные
ТО и топ сотрудников — у них общий период и общие фильтры, поэтому модуль
отдельный, а не внутри `crud_order`.

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
from typing import Dict, List, NamedTuple, Optional, Tuple

from sqlalchemy import func
from sqlalchemy.orm import Session

from src.core.access import AccessScope, apply_order_scope, object_scope_filter
from src.core.roles import FOREMAN
from src.models import (
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
