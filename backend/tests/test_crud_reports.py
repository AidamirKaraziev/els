"""Отчёт о работах: границы периода, статусы ТО и деление заявок.

Тесты бьют по живой БД: вся логика здесь — SQL. Развёртка двенадцати колонок
графика через `UNION ALL`, `CASE` с концом планового месяца, агрегаты с
`FILTER` и подзапрос области видимости. Мок проверил бы сам себя.

Определения, которые тесты защищают:
- заявки режутся по датам точно, плановые ТО — по плановому месяцу целиком;
- ТО за месяц имеет четыре состояния, и «просрочено» отличается от «ещё идёт»
  только тем, кончился ли плановый месяц;
- авария остаётся аварией, даже если заявку завёл клиент;
- объект без единой работы всё равно попадает в отчёт.

«Сейчас» во всех тестах задано явно (`report_range(..., now=...)`), а не
берётся из `datetime.now()`: иначе набор проходящих тестов зависел бы от дня
прогона.
"""

import datetime
import itertools
import uuid

import pytest

from src.core.access import AccessScope, ScopeKind
from src.core.roles import Role
from src.crud.crud_reports import crud_reports, report_range
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import (
    ActFact,
    Company,
    Division,
    Object,
    Order,
    Organization,
    PlannedTO,
    UniversalUser,
)
from tests.scopes import ALL_SCOPE

# id из `create_initial_data` (см. src/core/db/init_db.py:check_fault_category).
CAT_A = 2  # остановка лифта — поломка
CAT_TO = 6  # плановые работы — не поломка

#: Сейчас — 20 августа 2026. Значит месяцы по июль включительно уже прошли.
NOW = datetime.datetime(2026, 8, 20, 12, 0)

#: Весь 2026 год.
YEAR = report_range(datetime.date(2026, 1, 1), datetime.date(2026, 12, 31), now=NOW)


@pytest.fixture
def make_object(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(**kwargs):
        number = next(counter)
        obj = Object(
            name=kwargs.pop("name", f"Лифт {number}"),
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            **kwargs,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def plan_to(db_session):
    """Строка графика на год: `{номер месяца: finished_at}`.

    `None` означает «акт заведён, но не закрыт». Одной строкой на год, а не
    вызовом на каждый месяц: в `planned_to` висит
    `UniqueConstraint("year", "object_id")`.
    """

    def _make(obj, *, months=None, empty=(), year=2026):
        columns = {}
        for month, finished_at in (months or {}).items():
            act = ActFact(object_id=obj.id, finished_at=finished_at)
            db_session.add(act)
            db_session.flush()
            columns[_PLANNED_MONTH_COLUMN[month].key] = act.id
        for month in empty:
            columns[_PLANNED_MONTH_COLUMN[month].key] = None

        planned = PlannedTO(year=str(year), object_id=obj.id, **columns)
        db_session.add(planned)
        db_session.flush()
        return planned

    return _make


@pytest.fixture
def make_user(db_session):
    def _make(role_id):
        user = UniversalUser(
            name=f"Пользователь {uuid.uuid4().hex[:6]}",
            email=f"{uuid.uuid4().hex[:12]}@example.com",
            hashed_password="x",
            role_id=role_id,
            is_active=True,
        )
        db_session.add(user)
        db_session.flush()
        return user

    return _make


@pytest.fixture
def make_order(db_session):
    def _make(obj, created_at, fault_category_id=CAT_A, creator=None, **kwargs):
        order = Order(
            object_id=obj.id,
            created_at=created_at,
            fault_category_id=fault_category_id,
            creator_id=creator.id if creator is not None else None,
            **kwargs,
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


def _cells(rows, object_id):
    """{(год, месяц): строка} по одному объекту."""
    return {
        (int(row.year), int(row.month)): row
        for row in rows
        if row.object_id == object_id
    }


class TestPeriodBoundaries:
    """Разная точность у ТО и у заявок — главное следствие решения о периоде."""

    @pytest.mark.integration
    def test_maintenance_of_partial_month_is_taken_whole(
        self, db_session, make_object, plan_to
    ):
        # Период начинается 15 марта, а ТО за март в базе без дня. Взять его
        # обязаны целиком: иначе мартовское ТО потерялось бы вовсе.
        obj = make_object()
        plan_to(obj, months={3: datetime.datetime(2026, 3, 10)})
        period = report_range(
            datetime.date(2026, 3, 15), datetime.date(2026, 6, 20), now=NOW
        )

        row = crud_reports.maintenance_totals(
            db=db_session, period=period, scope=ALL_SCOPE, object_id=obj.id
        )

        assert row.planned == 1
        assert row.completed == 1

    @pytest.mark.integration
    def test_orders_respect_exact_dates(
        self, db_session, make_object, make_order
    ):
        # У заявки дата есть, и период по ней соблюдается день в день.
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 3, 14, 23, 59))
        make_order(obj, datetime.datetime(2026, 3, 15, 0, 1))
        period = report_range(
            datetime.date(2026, 3, 15), datetime.date(2026, 6, 20), now=NOW
        )

        row = crud_reports.order_totals(
            db=db_session, period=period, scope=ALL_SCOPE, object_id=obj.id
        )

        assert row.breakdowns == 1

    @pytest.mark.integration
    def test_last_day_is_included_whole(self, db_session, make_object, make_order):
        # Заявка в 23:59 последнего дня обязана попасть: период — полуинтервал
        # до начала следующих суток, а не сравнение с датой.
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 6, 20, 23, 59))
        period = report_range(
            datetime.date(2026, 3, 15), datetime.date(2026, 6, 20), now=NOW
        )

        row = crud_reports.order_totals(
            db=db_session, period=period, scope=ALL_SCOPE, object_id=obj.id
        )

        assert row.breakdowns == 1

    @pytest.mark.integration
    def test_other_year_is_not_taken(self, db_session, make_object, plan_to):
        obj = make_object()
        plan_to(obj, months={3: None}, year=2025)

        row = crud_reports.maintenance_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert row.planned == 0


class TestMaintenanceStatus:
    """Четыре состояния ТО, из которых два легко перепутать."""

    @pytest.mark.integration
    def test_finished_inside_month_is_not_late(
        self, db_session, make_object, plan_to
    ):
        obj = make_object()
        plan_to(obj, months={3: datetime.datetime(2026, 3, 31, 23, 0)})

        row = crud_reports.maintenance_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.completed, row.late, row.overdue) == (1, 0, 0)

    @pytest.mark.integration
    def test_finished_after_month_is_late_but_completed(
        self, db_session, make_object, plan_to
    ):
        # Закрыто вторым апреля — это выполнение марта, но с опозданием.
        # `late` входит в `completed`, а не считается отдельно от него.
        obj = make_object()
        plan_to(obj, months={3: datetime.datetime(2026, 4, 2)})

        row = crud_reports.maintenance_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.completed, row.late, row.overdue) == (1, 1, 0)

    @pytest.mark.integration
    def test_past_month_without_act_closed_is_overdue(
        self, db_session, make_object, plan_to
    ):
        obj = make_object()
        plan_to(obj, months={3: None})

        row = crud_reports.maintenance_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.completed, row.overdue) == (0, 1)

    @pytest.mark.integration
    def test_current_month_is_not_overdue(self, db_session, make_object, plan_to):
        # Август ещё идёт: ТО не сделано, но и не просрочено. Если смешать
        # эти два состояния, первого числа каждого месяца отчёт показывал бы
        # всплеск долга на ровном месте.
        obj = make_object()
        plan_to(obj, months={8: None})

        row = crud_reports.maintenance_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.planned, row.overdue) == (1, 0)

    @pytest.mark.integration
    def test_future_month_is_not_overdue(self, db_session, make_object, plan_to):
        obj = make_object()
        plan_to(obj, months={12: None})

        row = crud_reports.maintenance_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.planned, row.overdue) == (1, 0)

    @pytest.mark.integration
    def test_empty_cell_is_not_planned(self, db_session, make_object, plan_to):
        # Ячейка без акта — незаполненный график, а не пропущенное ТО. То же
        # определение плана, что и у выполнения графика на главной.
        obj = make_object()
        plan_to(obj, empty=(3,))

        row = crud_reports.maintenance_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert row.planned == 0


class TestOrderKinds:
    """Аварии, обращения заказчика и прочие работы — три непересекающихся вида."""

    @pytest.mark.integration
    def test_breakdown_wins_over_author(
        self, db_session, make_object, make_order, make_user
    ):
        # Настоящая поломка остаётся поломкой, даже если о ней сообщил сам
        # клиент. Иначе аварийность объекта зависела бы от того, кто первым
        # нажал кнопку.
        obj = make_object()
        client = make_user(Role.CLIENT)
        make_order(obj, datetime.datetime(2026, 3, 10), creator=client)

        row = crud_reports.order_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.breakdowns, row.client_requests, row.other_requests) == (1, 0, 0)

    @pytest.mark.integration
    def test_client_request_is_separated(
        self, db_session, make_object, make_order, make_user
    ):
        obj = make_object()
        client = make_user(Role.CLIENT)
        make_order(
            obj,
            datetime.datetime(2026, 3, 10),
            fault_category_id=CAT_TO,
            creator=client,
        )

        row = crud_reports.order_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.breakdowns, row.client_requests, row.other_requests) == (0, 1, 0)

    @pytest.mark.integration
    def test_employee_request_is_other(
        self, db_session, make_object, make_order, make_user
    ):
        obj = make_object()
        foreman = make_user(Role.FOREMAN)
        make_order(
            obj,
            datetime.datetime(2026, 3, 10),
            fault_category_id=CAT_TO,
            creator=foreman,
        )

        row = crud_reports.order_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.breakdowns, row.client_requests, row.other_requests) == (0, 0, 1)

    @pytest.mark.integration
    def test_order_without_author_is_other(
        self, db_session, make_object, make_order
    ):
        # Автор мог быть удалён — `creator_id` уходит в NULL. Заявка при этом
        # не исчезает и не становится обращением заказчика.
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 3, 10), fault_category_id=CAT_TO)

        row = crud_reports.order_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert (row.breakdowns, row.client_requests, row.other_requests) == (0, 0, 1)

    @pytest.mark.integration
    def test_order_without_category_is_breakdown(
        self, db_session, make_object, make_order
    ):
        # Недозаполненная заявка — всё равно выезд. То же правило, что и в
        # статистике главной.
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 3, 10), fault_category_id=None)

        row = crud_reports.order_totals(
            db=db_session, period=YEAR, scope=ALL_SCOPE, object_id=obj.id
        )

        assert row.breakdowns == 1


class TestObjectsAreTheBase:
    @pytest.mark.integration
    def test_object_without_any_work_is_still_in_report(
        self, db_session, make_object
    ):
        # Лифт, на котором за год ничего не случилось, — это результат, а не
        # повод пропасть из отчёта клиенту.
        obj = make_object()

        rows = crud_reports.objects(
            db=db_session, scope=ALL_SCOPE, limit=None, object_id=obj.id
        )

        assert [row.object_id for row in rows] == [obj.id]

    @pytest.mark.integration
    def test_count_ignores_page(self, db_session, make_object):
        division = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
        db_session.add(division)
        db_session.flush()
        for _ in range(3):
            make_object(division_id=division.id)

        page = crud_reports.objects(
            db=db_session, scope=ALL_SCOPE, limit=2, division_id=division.id
        )
        total = crud_reports.count_objects(
            db=db_session, scope=ALL_SCOPE, division_id=division.id
        )

        assert len(page) == 2
        assert total == 3


class TestScope:
    @pytest.mark.integration
    def test_client_sees_only_own_company(
        self, db_session, make_object, make_order
    ):
        # Область видимости — граница, а не фильтр: клиент не увидит чужой
        # лифт, даже запросив его напрямую.
        mine = Company(name=f"Моя {uuid.uuid4().hex[:6]}")
        theirs = Company(name=f"Чужая {uuid.uuid4().hex[:6]}")
        db_session.add_all([mine, theirs])
        db_session.flush()

        my_object = make_object(company_id=mine.id)
        their_object = make_object(company_id=theirs.id)
        make_order(my_object, datetime.datetime(2026, 3, 10))
        make_order(their_object, datetime.datetime(2026, 3, 10))

        client_scope = AccessScope(
            kind=ScopeKind.COMPANY,
            user_id=0,
            division_ids=frozenset(),
            company_id=mine.id,
        )

        visible = crud_reports.objects(
            db=db_session, scope=client_scope, limit=None, company_id=theirs.id
        )
        totals = crud_reports.order_totals(
            db=db_session, period=YEAR, scope=client_scope, object_id=their_object.id
        )

        assert visible == []
        assert totals.breakdowns == 0

    @pytest.mark.integration
    def test_organization_filter_narrows_but_scope_binds(
        self, db_session, make_object
    ):
        organization = Organization(title=f"Орг {uuid.uuid4().hex[:6]}")
        db_session.add(organization)
        db_session.flush()
        obj = make_object(organization_id=organization.id)
        make_object()

        rows = crud_reports.objects(
            db=db_session,
            scope=ALL_SCOPE,
            limit=None,
            organization_id=organization.id,
        )

        assert [row.object_id for row in rows] == [obj.id]


class TestMonthBreakdown:
    @pytest.mark.integration
    def test_cells_land_in_their_own_months(
        self, db_session, make_object, plan_to, make_order
    ):
        obj = make_object()
        plan_to(obj, months={3: datetime.datetime(2026, 3, 20), 4: None})
        make_order(obj, datetime.datetime(2026, 3, 5))
        make_order(obj, datetime.datetime(2026, 3, 6))
        make_order(obj, datetime.datetime(2026, 5, 5))

        cells = _cells(
            crud_reports.maintenance_cells(
                db=db_session,
                period=YEAR,
                scope=ALL_SCOPE,
                object_ids=[obj.id],
                object_id=obj.id,
            ),
            obj.id,
        )
        orders = _cells(
            crud_reports.order_counts(
                db=db_session,
                period=YEAR,
                scope=ALL_SCOPE,
                object_ids=[obj.id],
                object_id=obj.id,
            ),
            obj.id,
        )

        assert sorted(cells) == [(2026, 3), (2026, 4)]
        assert cells[(2026, 3)].finished_at == datetime.datetime(2026, 3, 20)
        assert cells[(2026, 4)].finished_at is None
        assert orders[(2026, 3)].breakdowns == 2
        assert orders[(2026, 5)].breakdowns == 1
