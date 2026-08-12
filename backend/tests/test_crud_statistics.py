"""Топ поломок: что попадает в счёт, в каком порядке и как считается время.

Тесты бьют по живой БД через `db_session`, потому что вся логика здесь —
это SQL: агрегаты с FILTER, границы месяца и сортировка. Мок такой запрос
не проверит, он проверит только сам себя.
"""

import datetime
import itertools
import uuid

import pytest

from src.crud.crud_statistics import crud_statistics, month_period, previous_month
from src.models import Company, Division, FactoryModel, Object, Order, Organization
from tests.scopes import ALL_SCOPE

# id из `create_initial_data` (см. src/core/db/init_db.py:check_fault_category).
CAT_AA = 1  # застревание пассажира, самая тяжёлая
CAT_A = 2  # остановка лифта
CAT_V = 3  # ухудшение характеристик
CAT_N = 4  # незначительные проблемы
CAT_TO = 6  # плановые работы — не поломка
CAT_PTO = 7  # освидетельствование — не поломка
CAT_KR = 8  # капремонт — не поломка
CAT_L = 10  # ложный вызов — не поломка

MAY = month_period(2026, 5)


@pytest.fixture
def make_object(db_session):
    """Объект с гарантированно уникальными заводским и рег. номерами."""
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
def make_order(db_session):
    def _make(obj, created_at, fault_category_id=CAT_A, **kwargs):
        order = Order(
            object_id=obj.id if obj is not None else None,
            created_at=created_at,
            fault_category_id=fault_category_id,
            **kwargs,
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


def _counts(rows):
    return {row.object_id: row.breakdown_count for row in rows}


class TestWhatCountsAsBreakdown:
    @pytest.mark.integration
    @pytest.mark.parametrize(
        "category_id", [CAT_TO, CAT_PTO, CAT_KR, CAT_L], ids=["ТО", "ПТО", "КР", "Л"]
    )
    def test_planned_and_false_calls_are_excluded(
        self, db_session, make_object, make_order, category_id
    ):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 10), fault_category_id=category_id)

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert obj.id not in _counts(rows)

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "category_id", [CAT_AA, CAT_A, CAT_V, CAT_N], ids=["AA", "А", "В", "Н"]
    )
    def test_real_faults_are_counted(
        self, db_session, make_object, make_order, category_id
    ):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 10), fault_category_id=category_id)

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert _counts(rows)[obj.id] == 1

    @pytest.mark.integration
    def test_order_without_category_is_counted(
        self, db_session, make_object, make_order
    ):
        """Недозаполненная заявка — всё равно выезд, терять её нельзя."""
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 10), fault_category_id=None)

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert _counts(rows)[obj.id] == 1

    @pytest.mark.integration
    def test_order_without_object_is_ignored(self, db_session, make_object, make_order):
        """Заявка без объекта в топ объектов попасть не может."""
        make_order(None, datetime.datetime(2026, 5, 10))

        total, objects = crud_statistics.count_breakdown_objects(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )

        assert (total, objects) == (0, 0)


class TestMonthBoundaries:
    @pytest.mark.integration
    def test_first_moment_of_month_is_included(
        self, db_session, make_object, make_order
    ):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 1, 0, 0, 0))

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert _counts(rows)[obj.id] == 1

    @pytest.mark.integration
    def test_last_moment_of_month_is_included(
        self, db_session, make_object, make_order
    ):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 31, 23, 59, 59, 999999))

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert _counts(rows)[obj.id] == 1

    @pytest.mark.integration
    def test_next_month_is_excluded(self, db_session, make_object, make_order):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 6, 1, 0, 0, 0))

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert obj.id not in _counts(rows)

    @pytest.mark.integration
    def test_december_rolls_over_into_next_year(
        self, db_session, make_object, make_order
    ):
        """Декабрь — единственный месяц, где конец периода уезжает в другой год."""
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 12, 31, 23, 0))
        make_order(obj, datetime.datetime(2027, 1, 1, 0, 0))

        rows = crud_statistics.top_breakdown_objects(
            db=db_session, period=month_period(2026, 12), scope=ALL_SCOPE
        )

        assert _counts(rows)[obj.id] == 1

    @pytest.mark.integration
    def test_previous_month_crosses_year_boundary(self):
        assert previous_month(2026, 1) == (2025, 12)
        assert previous_month(2026, 5) == (2026, 4)


class TestOrdering:
    @pytest.mark.integration
    def test_sorted_by_breakdown_count_desc(self, db_session, make_object, make_order):
        quiet = make_object()
        noisy = make_object()
        make_order(quiet, datetime.datetime(2026, 5, 2))
        for day in (3, 4, 5):
            make_order(noisy, datetime.datetime(2026, 5, day))

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert [row.object_id for row in rows] == [noisy.id, quiet.id]

    @pytest.mark.integration
    def test_equal_counts_put_the_more_severe_object_first(
        self, db_session, make_object, make_order
    ):
        """У обоих по две заявки, но у одного было застревание пассажира."""
        minor = make_object()
        severe = make_object()
        make_order(minor, datetime.datetime(2026, 5, 2), fault_category_id=CAT_N)
        make_order(minor, datetime.datetime(2026, 5, 3), fault_category_id=CAT_N)
        make_order(severe, datetime.datetime(2026, 5, 4), fault_category_id=CAT_N)
        make_order(severe, datetime.datetime(2026, 5, 5), fault_category_id=CAT_AA)

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert [row.object_id for row in rows] == [severe.id, minor.id]

    @pytest.mark.integration
    def test_uncategorised_orders_lose_the_severity_tiebreak(
        self, db_session, make_object, make_order
    ):
        """Пустая категория считается, но тяжести не добавляет."""
        unknown = make_object()
        known = make_object()
        make_order(unknown, datetime.datetime(2026, 5, 2), fault_category_id=None)
        make_order(known, datetime.datetime(2026, 5, 3), fault_category_id=CAT_V)

        rows = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert [row.object_id for row in rows] == [known.id, unknown.id]

    @pytest.mark.integration
    def test_limit_and_offset(self, db_session, make_object, make_order):
        objects = []
        for index, count in enumerate((4, 3, 2, 1)):
            obj = make_object()
            objects.append(obj)
            for day in range(count):
                make_order(obj, datetime.datetime(2026, 5, 2 + day + index * 5))

        top_two = crud_statistics.top_breakdown_objects(
            db=db_session, period=MAY, scope=ALL_SCOPE, limit=2
        )
        assert [row.object_id for row in top_two] == [objects[0].id, objects[1].id]

        next_two = crud_statistics.top_breakdown_objects(
            db=db_session, period=MAY, scope=ALL_SCOPE, limit=2, offset=2
        )
        assert [row.object_id for row in next_two] == [objects[2].id, objects[3].id]


class TestTiming:
    @pytest.mark.integration
    def test_reaction_time_uses_accepted_at(self, db_session, make_object, make_order):
        obj = make_object()
        make_order(
            obj,
            datetime.datetime(2026, 5, 10, 10, 0),
            accepted_at=datetime.datetime(2026, 5, 10, 12, 0),
        )

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.reacted_count == 1
        assert float(row.avg_reaction_seconds) == 2 * 3600

    @pytest.mark.integration
    def test_reaction_time_falls_back_to_in_progress_at(
        self, db_session, make_object, make_order
    ):
        """Диспетчер прыгнул из «Создано» сразу в «В процессе», минуя «Принято»."""
        obj = make_object()
        make_order(
            obj,
            datetime.datetime(2026, 5, 10, 10, 0),
            accepted_at=None,
            in_progress_at=datetime.datetime(2026, 5, 10, 13, 0),
        )

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.reacted_count == 1
        assert float(row.avg_reaction_seconds) == 3 * 3600

    @pytest.mark.integration
    def test_untouched_orders_do_not_drag_the_average(
        self, db_session, make_object, make_order
    ):
        """Заявка, которую не взяли в работу, в среднее не входит вовсе."""
        obj = make_object()
        make_order(
            obj,
            datetime.datetime(2026, 5, 10, 10, 0),
            accepted_at=datetime.datetime(2026, 5, 10, 11, 0),
        )
        make_order(obj, datetime.datetime(2026, 5, 11, 10, 0))

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.breakdown_count == 2
        assert row.reacted_count == 1, "нетронутая заявка не должна попадать в среднее"
        assert float(row.avg_reaction_seconds) == 3600

    @pytest.mark.integration
    def test_negative_reaction_time_is_discarded(
        self, db_session, make_object, make_order
    ):
        """Битые данные: заявку «приняли» раньше, чем создали."""
        obj = make_object()
        make_order(
            obj,
            datetime.datetime(2026, 5, 10, 10, 0),
            accepted_at=datetime.datetime(2026, 5, 9, 10, 0),
        )

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.reacted_count == 0
        assert row.avg_reaction_seconds is None

    @pytest.mark.integration
    def test_resolution_time_is_empty_while_done_at_is_not_written(
        self, db_session, make_object, make_order
    ):
        """Сегодняшняя реальность прода: done_at не заполняется (этап 2)."""
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 10, 10, 0), status_id=4)

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.resolved_count == 0
        assert row.avg_resolution_seconds is None

    @pytest.mark.integration
    def test_resolution_time_counts_once_done_at_appears(
        self, db_session, make_object, make_order
    ):
        obj = make_object()
        make_order(
            obj,
            datetime.datetime(2026, 5, 10, 10, 0),
            done_at=datetime.datetime(2026, 5, 10, 15, 0),
        )

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.resolved_count == 1
        assert float(row.avg_resolution_seconds) == 5 * 3600


class TestCategorySummary:
    @pytest.mark.integration
    def test_summary_is_ordered_by_severity(self, db_session, make_object, make_order):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=CAT_N)
        make_order(obj, datetime.datetime(2026, 5, 3), fault_category_id=CAT_AA)
        make_order(obj, datetime.datetime(2026, 5, 4), fault_category_id=CAT_A)
        make_order(obj, datetime.datetime(2026, 5, 5), fault_category_id=CAT_A)

        rows = crud_statistics.breakdowns_by_category(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert [(row.code, row.count) for row in rows] == [
            ("AA", 1),
            ("А", 2),
            ("Н", 1),
        ]

    @pytest.mark.integration
    def test_uncategorised_orders_go_last(self, db_session, make_object, make_order):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=None)
        make_order(obj, datetime.datetime(2026, 5, 3), fault_category_id=CAT_AA)

        rows = crud_statistics.breakdowns_by_category(db=db_session, period=MAY, scope=ALL_SCOPE)

        assert [row.category_id for row in rows] == [CAT_AA, None]

    @pytest.mark.integration
    def test_severity_breakdown_per_object(self, db_session, make_object, make_order):
        first = make_object()
        second = make_object()
        make_order(first, datetime.datetime(2026, 5, 2), fault_category_id=CAT_AA)
        make_order(first, datetime.datetime(2026, 5, 3), fault_category_id=CAT_N)
        make_order(second, datetime.datetime(2026, 5, 4), fault_category_id=CAT_A)

        breakdown = crud_statistics.object_severity_breakdown(
            db=db_session, period=MAY, scope=ALL_SCOPE, object_ids=[first.id, second.id]
        )

        assert [(row.code, row.count) for row in breakdown[first.id]] == [
            ("AA", 1),
            ("Н", 1),
        ]
        assert [(row.code, row.count) for row in breakdown[second.id]] == [("А", 1)]

    @pytest.mark.integration
    def test_severity_breakdown_without_objects_makes_no_query(self, db_session):
        assert (
            crud_statistics.object_severity_breakdown(
                db=db_session, period=MAY, scope=ALL_SCOPE, object_ids=[]
            )
            == {}
        )


class TestFilters:
    @pytest.mark.integration
    def test_filter_by_division(self, db_session, make_object, make_order):
        division = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
        db_session.add(division)
        db_session.flush()

        mine = make_object(division_id=division.id)
        other = make_object()
        make_order(mine, datetime.datetime(2026, 5, 2))
        make_order(other, datetime.datetime(2026, 5, 3))

        rows = crud_statistics.top_breakdown_objects(
            db=db_session, period=MAY, scope=ALL_SCOPE, division_id=division.id
        )

        assert [row.object_id for row in rows] == [mine.id]

    @pytest.mark.integration
    def test_filter_by_organization(self, db_session, make_object, make_order):
        organization = Organization(title=f"УК {uuid.uuid4().hex[:6]}")
        db_session.add(organization)
        db_session.flush()

        mine = make_object(organization_id=organization.id)
        other = make_object()
        make_order(mine, datetime.datetime(2026, 5, 2))
        make_order(other, datetime.datetime(2026, 5, 3))

        rows = crud_statistics.top_breakdown_objects(
            db=db_session, period=MAY, scope=ALL_SCOPE, organization_id=organization.id
        )

        assert [row.object_id for row in rows] == [mine.id]


class TestObjectFields:
    @pytest.mark.integration
    def test_client_falls_back_to_company_when_organization_is_empty(
        self, db_session, make_object, make_order
    ):
        company = Company(name=f"ООО {uuid.uuid4().hex[:6]}")
        db_session.add(company)
        db_session.flush()

        obj = make_object(company_id=company.id)
        make_order(obj, datetime.datetime(2026, 5, 2))

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.client == company.name

    @pytest.mark.integration
    def test_organization_wins_over_company(self, db_session, make_object, make_order):
        organization = Organization(title=f"УК {uuid.uuid4().hex[:6]}")
        company = Company(name=f"ООО {uuid.uuid4().hex[:6]}")
        db_session.add_all([organization, company])
        db_session.flush()

        obj = make_object(organization_id=organization.id, company_id=company.id)
        make_order(obj, datetime.datetime(2026, 5, 2))

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.client == organization.title

    @pytest.mark.integration
    def test_factory_model_and_numbers_are_returned(
        self, db_session, make_object, make_order
    ):
        factory_model = FactoryModel(
            factory=f"Завод {uuid.uuid4().hex[:6]}", model="ПП-0411"
        )
        db_session.add(factory_model)
        db_session.flush()

        obj = make_object(factory_model_id=factory_model.id, address="ул. Красная, 1")
        make_order(obj, datetime.datetime(2026, 5, 2))

        row = crud_statistics.top_breakdown_objects(db=db_session, period=MAY, scope=ALL_SCOPE)[0]

        assert row.factory == factory_model.factory
        assert row.model == "ПП-0411"
        assert row.address == "ул. Красная, 1"
        assert row.registration_number == obj.registration_number


class TestTotalsAndComparison:
    @pytest.mark.integration
    def test_totals_count_orders_and_distinct_objects(
        self, db_session, make_object, make_order
    ):
        first = make_object()
        second = make_object()
        make_order(first, datetime.datetime(2026, 5, 2))
        make_order(first, datetime.datetime(2026, 5, 3))
        make_order(second, datetime.datetime(2026, 5, 4))
        make_order(first, datetime.datetime(2026, 5, 5), fault_category_id=CAT_TO)

        total, objects = crud_statistics.count_breakdown_objects(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )

        assert (total, objects) == (3, 2), "плановое ТО не должно попадать в итог"

    @pytest.mark.integration
    def test_previous_month_counts_for_delta(self, db_session, make_object, make_order):
        obj = make_object()
        quiet_now = make_object()
        make_order(obj, datetime.datetime(2026, 4, 10))
        make_order(obj, datetime.datetime(2026, 4, 11))
        make_order(quiet_now, datetime.datetime(2026, 5, 1))

        counts = crud_statistics.breakdown_counts_by_object(
            db=db_session,
            period=month_period(*previous_month(2026, 5)),
            scope=ALL_SCOPE,
            object_ids=[obj.id, quiet_now.id],
        )

        assert counts == {obj.id: 2}, (
            "объекта без поломок в прошлом месяце быть не должно"
        )
