"""Ручка `GET /statistics/top-employees`: доступ, форма ответа, параметры.

Арифметику балла проверяет `test_employee_score` — там формула считается без
базы. Здесь проверяется, что запросы действительно достают то, из чего она
считает: закрытые заявки, плановые ТО, закрепление лифтов за механиком.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID, DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import (
    ActFact,
    Division,
    Object,
    Order,
    PlannedTO,
    UniversalUser,
    UserDivision,
)

URL = f"{settings.API_V1_STR}/statistics/top-employees"

YEAR = 2026
MONTH = 5
INSIDE = datetime.datetime(YEAR, MONTH, 10, 9, 0)

CAT_AA = 1  # застревание пассажира
CAT_N = 4  # незначительные проблемы
STATUS_DONE = 4


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
def make_mechanic(db_session):
    def _make(name="Механик", role_id=MECHANIC, **fields):
        user = UniversalUser(
            name=name,
            email=f"m-{uuid.uuid4().hex[:8]}@test",
            role_id=role_id,
            is_active=True,
            **fields,
        )
        db_session.add(user)
        db_session.flush()
        return user

    return _make


@pytest.fixture
def close_order(db_session):
    """Закрытая заявка: исполнитель, время реакции, категория."""

    def _make(
        obj,
        executor,
        *,
        created_at=INSIDE,
        reaction=datetime.timedelta(minutes=10),
        fault_category_id=CAT_AA,
        done_at=None,
    ):
        order = Order(
            object_id=obj.id,
            executor_id=executor.id,
            created_at=created_at,
            accepted_at=created_at + reaction,
            done_at=done_at if done_at is not None else created_at,
            status_id=STATUS_DONE,
            fault_category_id=fault_category_id,
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


@pytest.fixture
def plan_to(db_session):
    """Плановое ТО месяца с назначенным главным механиком."""

    def _make(obj, mechanic, *, month=MONTH, year=YEAR, finished_at=None):
        act = ActFact(
            object_id=obj.id, main_mechanic_id=mechanic.id, finished_at=finished_at
        )
        db_session.add(act)
        db_session.flush()
        db_session.add(
            PlannedTO(
                year=str(year),
                object_id=obj.id,
                **{_PLANNED_MONTH_COLUMN[month].key: act.id},
            )
        )
        db_session.flush()
        return act

    return _make


def _get(client, **params):
    params.setdefault("year", YEAR)
    params.setdefault("month", MONTH)
    return client.get(URL, params=params)


def _row(data, user_id):
    return next(item for item in data["items"] if item["user_id"] == user_id)


class TestAccess:
    @pytest.mark.integration
    def test_requires_authentication(self, client_with_db):
        assert _get(client_with_db).status_code == 401

    @pytest.mark.integration
    @pytest.mark.parametrize("role", [ADMIN, FOREMAN])
    def test_admin_and_foreman_are_allowed(self, client_with_db, as_role, role):
        as_role(role)
        assert _get(client_with_db).status_code == 200

    @pytest.mark.integration
    @pytest.mark.parametrize("role", [MECHANIC, ENGINEER, DISPATCHER, CLIENT_ID])
    def test_everyone_else_is_refused(self, client_with_db, as_role, role):
        """Рейтинг людей — не общая статистика.

        Клиенту внутренняя оценка подрядчика не положена, механику — его
        собственное место в списке худших.
        """
        as_role(role)
        assert _get(client_with_db).status_code == 403

    @pytest.mark.integration
    def test_foreman_ranking_is_admin_only(self, client_with_db, as_role):
        as_role(FOREMAN)
        assert _get(client_with_db, kind="foreman").status_code == 403

        as_role(ADMIN)
        assert _get(client_with_db, kind="foreman").status_code == 200


class TestReportShape:
    @pytest.mark.integration
    def test_quiet_month_returns_zeros_not_an_error(self, client_with_db, as_role):
        as_role(ADMIN)

        data = _get(client_with_db).json()["data"]

        assert data["period"] == {"year": YEAR, "month": MONTH}
        assert data["kind"] == "mechanic"
        assert data["order"] == "best"
        assert data["ranked_count"] == 0

    @pytest.mark.integration
    def test_row_carries_everything_the_card_draws(
        self, client_with_db, as_role, db_session, make_object, make_mechanic, close_order
    ):
        as_role(ADMIN)
        division = Division(title="Участок №1")
        db_session.add(division)
        db_session.flush()

        mechanic = make_mechanic(name="В.Р. Никифоров", division_id=division.id)
        obj = make_object(division_id=division.id, mechanic_id=mechanic.id)
        close_order(obj, mechanic)

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]
        item = _row(data, mechanic.id)

        assert item["name"] == "В.Р. Никифоров"
        assert item["division"] == "Участок №1"
        assert item["role_id"] == MECHANIC
        assert item["orders_closed"] == 1
        assert item["works_count"] == 1
        assert item["score"] is not None
        assert item["metrics"]["reaction"] == 100.0
        assert item["avg_reaction_hours"] == pytest.approx(0.2, abs=0.05)
        assert item["foreman_metrics"] is None


class TestFacts:
    @pytest.mark.integration
    def test_closed_order_counts_for_its_executor(
        self, client_with_db, as_role, make_object, make_mechanic, close_order
    ):
        as_role(ADMIN)
        worker = make_mechanic(name="Работал")
        idle = make_mechanic(name="Не работал")
        close_order(make_object(mechanic_id=worker.id), worker)

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]

        assert _row(data, worker.id)["orders_closed"] == 1
        assert _row(data, idle.id)["orders_closed"] == 0

    @pytest.mark.integration
    def test_open_order_is_not_work_yet(
        self, client_with_db, as_role, db_session, make_object, make_mechanic
    ):
        as_role(ADMIN)
        mechanic = make_mechanic()
        db_session.add(
            Order(
                object_id=make_object(mechanic_id=mechanic.id).id,
                executor_id=mechanic.id,
                created_at=INSIDE,
                status_id=1,
                fault_category_id=CAT_AA,
            )
        )
        db_session.flush()

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]

        assert _row(data, mechanic.id)["orders_closed"] == 0

    @pytest.mark.integration
    def test_order_of_another_month_does_not_count(
        self, client_with_db, as_role, make_object, make_mechanic, close_order
    ):
        as_role(ADMIN)
        mechanic = make_mechanic()
        close_order(
            make_object(mechanic_id=mechanic.id),
            mechanic,
            created_at=datetime.datetime(YEAR, MONTH - 1, 20, 9, 0),
        )

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]

        assert _row(data, mechanic.id)["orders_closed"] == 0

    @pytest.mark.integration
    def test_legacy_order_without_done_at_falls_into_its_creation_month(
        self, client_with_db, as_role, db_session, make_object, make_mechanic
    ):
        """Заявки, закрытые до починки `done_at`, не должны пропадать."""
        as_role(ADMIN)
        mechanic = make_mechanic()
        db_session.add(
            Order(
                object_id=make_object(mechanic_id=mechanic.id).id,
                executor_id=mechanic.id,
                created_at=INSIDE,
                accepted_at=INSIDE + datetime.timedelta(minutes=5),
                done_at=None,
                status_id=STATUS_DONE,
                fault_category_id=CAT_AA,
            )
        )
        db_session.flush()

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]

        assert _row(data, mechanic.id)["orders_closed"] == 1

    @pytest.mark.integration
    def test_maintenance_on_time_is_counted(
        self, client_with_db, as_role, make_object, make_mechanic, plan_to
    ):
        as_role(ADMIN)
        mechanic = make_mechanic()
        obj = make_object(mechanic_id=mechanic.id)
        plan_to(obj, mechanic, finished_at=datetime.datetime(YEAR, MONTH, 20))
        plan_to(make_object(mechanic_id=mechanic.id), mechanic, finished_at=None)

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]
        item = _row(data, mechanic.id)

        assert item["maintenance_total"] == 2
        assert item["maintenance_on_time"] == 1
        assert item["metrics"]["timeliness"] == 50.0

    @pytest.mark.integration
    def test_breakdowns_on_his_lifts_are_counted(
        self, client_with_db, as_role, db_session, make_object, make_mechanic
    ):
        as_role(ADMIN)
        mechanic = make_mechanic()
        obj = make_object(mechanic_id=mechanic.id)
        db_session.add(
            Order(object_id=obj.id, created_at=INSIDE, fault_category_id=CAT_AA)
        )
        db_session.flush()

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]
        item = _row(data, mechanic.id)

        assert item["objects_count"] == 1
        assert item["breakdowns_on_objects"] == 1

    @pytest.mark.integration
    def test_work_on_a_foreign_lift_weighs_more(
        self, client_with_db, as_role, make_object, make_mechanic, close_order
    ):
        as_role(ADMIN)
        owner = make_mechanic(name="Хозяин")
        helper = make_mechanic(name="Выручил")
        # Один и тот же лифт: у хозяина он свой, у второго — чужой.
        close_order(make_object(mechanic_id=owner.id), owner, fault_category_id=CAT_N)
        close_order(make_object(mechanic_id=owner.id), helper, fault_category_id=CAT_N)

        data = _get(client_with_db, limit=50, min_works=0).json()["data"]

        assert _row(data, helper.id)["work_units"] > _row(data, owner.id)["work_units"]


class TestOrderingAndPaging:
    @pytest.fixture
    def two_mechanics(self, make_object, make_mechanic, close_order):
        fast = make_mechanic(name="Быстрый")
        slow = make_mechanic(name="Медленный")
        for mechanic, reaction in (
            (fast, datetime.timedelta(minutes=5)),
            (slow, datetime.timedelta(hours=4)),
        ):
            for _ in range(3):
                close_order(
                    make_object(mechanic_id=mechanic.id),
                    mechanic,
                    reaction=reaction,
                )
        return fast, slow

    @pytest.mark.integration
    def test_best_first_by_default(self, client_with_db, as_role, two_mechanics):
        as_role(ADMIN)
        fast, slow = two_mechanics

        data = _get(client_with_db, limit=50).json()["data"]
        ranked = [item["user_id"] for item in data["items"] if not item["is_provisional"]]

        assert ranked.index(fast.id) < ranked.index(slow.id)

    @pytest.mark.integration
    def test_worst_first_flips_the_list(self, client_with_db, as_role, two_mechanics):
        as_role(ADMIN)
        fast, slow = two_mechanics

        data = _get(client_with_db, limit=50, order="worst").json()["data"]
        ranked = [item["user_id"] for item in data["items"] if not item["is_provisional"]]

        assert data["order"] == "worst"
        assert ranked.index(slow.id) < ranked.index(fast.id)

    @pytest.mark.integration
    def test_low_activity_never_leads_either_list(
        self, client_with_db, as_role, two_mechanics, make_object, make_mechanic, close_order
    ):
        as_role(ADMIN)
        lazy = make_mechanic(name="Одна заявка")
        close_order(
            make_object(mechanic_id=lazy.id),
            lazy,
            reaction=datetime.timedelta(minutes=1),
        )

        for order in ("best", "worst"):
            data = _get(client_with_db, limit=50, order=order).json()["data"]
            assert data["items"][0]["user_id"] != lazy.id
            assert _row(data, lazy.id)["is_provisional"] is True

    @pytest.mark.integration
    def test_limit_cuts_the_list_but_not_the_counters(
        self, client_with_db, as_role, two_mechanics
    ):
        as_role(ADMIN)

        data = _get(client_with_db, limit=1).json()["data"]

        assert len(data["items"]) == 1
        assert data["total_count"] > 1

    @pytest.mark.integration
    def test_offset_moves_the_window(self, client_with_db, as_role, two_mechanics):
        as_role(ADMIN)

        first = _get(client_with_db, limit=1).json()["data"]["items"][0]
        second = _get(client_with_db, limit=1, offset=1).json()["data"]["items"][0]

        assert first["user_id"] != second["user_id"]


class TestScopeAndFilters:
    @pytest.mark.integration
    def test_division_filter_narrows_the_list(
        self,
        client_with_db,
        as_role,
        db_session,
        make_object,
        make_mechanic,
        close_order,
    ):
        as_role(ADMIN)
        mine = Division(title="Мой участок")
        foreign = Division(title="Чужой участок")
        db_session.add_all([mine, foreign])
        db_session.flush()

        ours = make_mechanic(name="Наш", division_id=mine.id)
        theirs = make_mechanic(name="Их", division_id=foreign.id)
        db_session.add_all(
            [
                UserDivision(user_id=ours.id, division_id=mine.id),
                UserDivision(user_id=theirs.id, division_id=foreign.id),
            ]
        )
        db_session.flush()
        close_order(make_object(division_id=mine.id, mechanic_id=ours.id), ours)
        close_order(make_object(division_id=foreign.id, mechanic_id=theirs.id), theirs)

        data = _get(
            client_with_db, limit=50, min_works=0, division_id=mine.id
        ).json()["data"]
        ids = {item["user_id"] for item in data["items"]}

        assert ours.id in ids
        assert theirs.id not in ids


class TestForemanRanking:
    @pytest.mark.integration
    def test_foreman_row_carries_his_own_metrics(
        self,
        client_with_db,
        as_role,
        db_session,
        make_object,
        make_mechanic,
        plan_to,
    ):
        as_role(ADMIN)
        division = Division(title="Участок прораба")
        db_session.add(division)
        db_session.flush()

        foreman = make_mechanic(
            name="Прораб", role_id=FOREMAN, division_id=division.id
        )
        mechanic = make_mechanic(name="Его механик", division_id=division.id)
        db_session.add_all(
            [
                UserDivision(user_id=foreman.id, division_id=division.id),
                UserDivision(user_id=mechanic.id, division_id=division.id),
            ]
        )
        db_session.flush()

        obj = make_object(division_id=division.id, mechanic_id=mechanic.id)
        plan_to(obj, mechanic, finished_at=datetime.datetime(YEAR, MONTH, 15))

        data = _get(
            client_with_db, kind="foreman", limit=50, min_works=0
        ).json()["data"]
        item = _row(data, foreman.id)

        assert data["kind"] == "foreman"
        assert item["foreman_metrics"] is not None
        assert item["foreman_metrics"]["schedule"] == 100.0
