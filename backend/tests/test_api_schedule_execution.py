"""Ручка `GET /statistics/schedule-execution`: форма ответа, роли, параметры.

Арифметику плана и факта проверяет `test_crud_schedule_execution`. Здесь —
что запрос доходит до БД, что схема собирается и что виджет на главной
получает ровно те поля, которые рисует.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID, ENGINEER, FOREMAN
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import (
    ActFact,
    Division,
    Object,
    PlannedTO,
    UniversalUser,
    UserDivision,
)

URL = f"{settings.API_V1_STR}/statistics/schedule-execution"


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
def make_division(db_session):
    def _make(title=None):
        division = Division(title=title or f"Участок {uuid.uuid4().hex[:6]}")
        db_session.add(division)
        db_session.flush()
        return division

    return _make


@pytest.fixture
def plan_to(db_session):
    def _make(obj, *, month=5, year=2026, finished_at=None):
        act = ActFact(object_id=obj.id, finished_at=finished_at)
        db_session.add(act)
        db_session.flush()
        column_name = _PLANNED_MONTH_COLUMN[month].key
        db_session.add(
            PlannedTO(year=str(year), object_id=obj.id, **{column_name: act.id})
        )
        db_session.flush()

    return _make


def _get(client, **params):
    params.setdefault("year", 2026)
    params.setdefault("month", 5)
    return client.get(URL, params=params)


class TestAccess:
    @pytest.mark.integration
    def test_requires_authentication(self, client_with_db):
        assert _get(client_with_db).status_code == 401

    @pytest.mark.integration
    def test_admin_gets_the_report(self, client_with_db, as_role):
        as_role(ADMIN)
        assert _get(client_with_db).status_code == 200

    @pytest.mark.integration
    def test_client_is_allowed(self, client_with_db, as_role):
        # Как и в топе поломок: выдача режется по компании клиента, поэтому
        # запрета по роли здесь нет.
        as_role(CLIENT_ID)
        assert _get(client_with_db).status_code == 200

    @pytest.mark.integration
    def test_engineer_sees_only_his_divisions(
        self, client_with_db, as_role, db_session, make_division, make_object, plan_to
    ):
        # Инженер, а не прораб: прораб на чтение видит всё («видит всё, меняет
        # только своё» — решение заказчика), и на нём урезание по участкам не
        # проверишь.
        mine = make_division()
        foreign = make_division()
        plan_to(make_object(division_id=mine.id))
        plan_to(make_object(division_id=foreign.id))

        engineer = as_role(ENGINEER, division_id=mine.id)
        db_session.add(UserDivision(user_id=engineer.id, division_id=mine.id))
        db_session.flush()

        data = _get(client_with_db).json()["data"]

        assert [item["division_id"] for item in data["items"]] == [mine.id]

    @pytest.mark.integration
    def test_foreman_sees_every_division(
        self, client_with_db, as_role, db_session, make_division, make_object, plan_to
    ):
        mine = make_division()
        foreign = make_division()
        plan_to(make_object(division_id=mine.id))
        plan_to(make_object(division_id=foreign.id))

        foreman = as_role(FOREMAN, division_id=mine.id)
        db_session.add(UserDivision(user_id=foreman.id, division_id=mine.id))
        db_session.flush()

        data = _get(client_with_db).json()["data"]
        divisions = [item["division_id"] for item in data["items"]]

        assert {mine.id, foreign.id} <= set(divisions)


class TestReportShape:
    @pytest.mark.integration
    def test_month_without_schedule_returns_zeros(self, client_with_db, as_role):
        """Пустой месяц — это «графика нет», а не сломанный виджет."""
        as_role(ADMIN)

        data = _get(client_with_db).json()["data"]

        assert data["period"] == {"year": 2026, "month": 5}
        assert data["planned_count"] == 0
        assert data["completed_count"] == 0
        assert data["completion_percent"] == 0
        assert data["items"] == []

    @pytest.mark.integration
    def test_row_carries_everything_the_card_draws(
        self, client_with_db, as_role, db_session, make_division, make_object, plan_to
    ):
        as_role(ADMIN)
        division = make_division(title="Участок №1")
        plan_to(
            make_object(division_id=division.id),
            finished_at=datetime.datetime(2026, 5, 6),
        )
        plan_to(
            make_object(division_id=division.id),
            finished_at=datetime.datetime(2026, 6, 6),
        )
        plan_to(make_object(division_id=division.id))
        plan_to(make_object(division_id=division.id))

        foreman = UniversalUser(
            name="Никифоров В.Р.",
            email=f"f-{uuid.uuid4().hex[:8]}@test",
            role_id=FOREMAN,
            is_active=True,
            division_id=division.id,
        )
        db_session.add(foreman)
        db_session.flush()
        db_session.add(UserDivision(user_id=foreman.id, division_id=division.id))
        db_session.flush()

        data = _get(client_with_db).json()["data"]
        item = next(row for row in data["items"] if row["division_id"] == division.id)

        assert item["division"] == "Участок №1"
        assert item["responsible"] == "Никифоров В.Р."
        assert item["responsible_count"] == 1
        assert item["planned_count"] == 4
        assert item["completed_count"] == 2, "закрытое в июне ТО остаётся майским"
        assert item["completed_late_count"] == 1
        assert item["completion_percent"] == 50.0

    @pytest.mark.integration
    def test_several_foremen_are_folded_into_plus_n(
        self, client_with_db, as_role, db_session, make_division, make_object, plan_to
    ):
        as_role(ADMIN)
        division = make_division()
        plan_to(make_object(division_id=division.id))

        for _ in range(3):
            user = UniversalUser(
                name=f"Прораб {uuid.uuid4().hex[:4]}",
                email=f"f-{uuid.uuid4().hex[:8]}@test",
                role_id=FOREMAN,
                is_active=True,
            )
            db_session.add(user)
            db_session.flush()
            db_session.add(UserDivision(user_id=user.id, division_id=division.id))
        db_session.flush()

        data = _get(client_with_db).json()["data"]
        item = next(row for row in data["items"] if row["division_id"] == division.id)

        assert item["responsible"].endswith(" +2")
        assert item["responsible_count"] == 3

    @pytest.mark.integration
    def test_totals_are_counted_from_numbers_not_averaged_percents(
        self, client_with_db, as_role, make_division, make_object, plan_to
    ):
        # Участок с одним ТО не должен весить столько же, сколько участок с
        # тремя: среднее из процентов дало бы 50, а не 25.
        as_role(ADMIN)
        big = make_division()
        small = make_division()
        for _ in range(3):
            plan_to(make_object(division_id=big.id))
        plan_to(
            make_object(division_id=small.id), finished_at=datetime.datetime(2026, 5, 6)
        )

        data = _get(client_with_db).json()["data"]

        assert data["planned_count"] == 4
        assert data["completed_count"] == 1
        assert data["completion_percent"] == 25.0


class TestParameters:
    @pytest.mark.integration
    @pytest.mark.parametrize("month", [0, 13])
    def test_month_out_of_range_is_rejected(self, client_with_db, as_role, month):
        as_role(ADMIN)
        # Проект превращает ошибки валидации в 400 (см. src/errors.py), а не 422.
        assert _get(client_with_db, month=month).status_code == 400

    @pytest.mark.integration
    def test_period_is_required(self, client_with_db, as_role):
        as_role(ADMIN)
        assert client_with_db.get(URL).status_code == 400

    @pytest.mark.integration
    def test_division_filter_narrows_output(
        self, client_with_db, as_role, make_division, make_object, plan_to
    ):
        as_role(ADMIN)
        mine = make_division()
        other = make_division()
        plan_to(make_object(division_id=mine.id))
        plan_to(make_object(division_id=other.id))

        data = _get(client_with_db, division_id=mine.id).json()["data"]

        assert [item["division_id"] for item in data["items"]] == [mine.id]
