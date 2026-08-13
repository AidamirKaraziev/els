"""Ручка `GET /statistics/overdue-maintenance`: форма ответа, роли, параметры.

Арифметику просрочки проверяет `test_crud_overdue_maintenance` — там текущий
месяц задаётся явно. Здесь его задать нельзя: ручка берёт его из системных
часов, потому что просрочка — состояние на сегодня, а не срез периода.
Поэтому данные тесты заводят **относительно сегодняшнего дня**: ТО на
предыдущий месяц просрочено всегда, на текущий — никогда, в какой бы день
года прогон ни случился.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID, ENGINEER, FOREMAN
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN, previous_month
from src.models import (
    ActFact,
    Division,
    Object,
    Organization,
    PlannedTO,
    UniversalUser,
    UserDivision,
)

URL = f"{settings.API_V1_STR}/statistics/overdue-maintenance"


def current_month():
    today = datetime.date.today()
    return today.year, today.month


def previous_month_period():
    """Заведомо просроченный месяц — предыдущий.

    Через `previous_month`, а не вычитанием единицы: в январе предыдущий
    месяц лежит в другом году, и тест ломался бы один месяц в году.
    """
    return previous_month(*current_month())


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
    """Заведённое, но не закрытое ТО на указанные месяцы года.

    По умолчанию — на предыдущий месяц, то есть заведомо просроченное.
    """

    def _make(obj, *, months=None, year=None, finished_at=None):
        if months is None or year is None:
            year, month = previous_month_period()
            months = months or (month,)

        columns = {}
        for month in months:
            act = ActFact(object_id=obj.id, finished_at=finished_at)
            db_session.add(act)
            db_session.flush()
            columns[_PLANNED_MONTH_COLUMN[month].key] = act.id

        db_session.add(PlannedTO(year=str(year), object_id=obj.id, **columns))
        db_session.flush()

    return _make


class TestAccess:
    @pytest.mark.integration
    def test_requires_authentication(self, client_with_db):
        assert client_with_db.get(URL).status_code == 401

    @pytest.mark.integration
    def test_admin_gets_the_report(self, client_with_db, as_role):
        as_role(ADMIN)
        assert client_with_db.get(URL).status_code == 200

    @pytest.mark.integration
    def test_client_is_allowed(self, client_with_db, as_role):
        # Как и в двух других виджетах: выдача режется по компании клиента,
        # поэтому запрета по роли здесь нет.
        as_role(CLIENT_ID)
        assert client_with_db.get(URL).status_code == 200

    @pytest.mark.integration
    def test_engineer_sees_only_his_divisions(
        self, client_with_db, as_role, db_session, make_division, make_object, plan_to
    ):
        # Инженер, а не прораб: прораб на чтение видит всё, и на нём урезание
        # по участкам не проверишь.
        mine = make_division()
        foreign = make_division()
        visible = make_object(division_id=mine.id)
        plan_to(visible)
        plan_to(make_object(division_id=foreign.id))

        engineer = as_role(ENGINEER, division_id=mine.id)
        db_session.add(UserDivision(user_id=engineer.id, division_id=mine.id))
        db_session.flush()

        data = client_with_db.get(URL).json()["data"]

        assert [item["object_id"] for item in data["items"]] == [visible.id]
        assert data["total_count"] == 1

    @pytest.mark.integration
    def test_foreman_sees_every_division(
        self, client_with_db, as_role, db_session, make_division, make_object, plan_to
    ):
        mine = make_division()
        foreign = make_division()
        first = make_object(division_id=mine.id)
        second = make_object(division_id=foreign.id)
        plan_to(first)
        plan_to(second)

        foreman = as_role(FOREMAN, division_id=mine.id)
        db_session.add(UserDivision(user_id=foreman.id, division_id=mine.id))
        db_session.flush()

        data = client_with_db.get(URL).json()["data"]

        assert {first.id, second.id} <= {item["object_id"] for item in data["items"]}


class TestReportShape:
    @pytest.mark.integration
    def test_nothing_overdue_returns_zeros(self, client_with_db, as_role):
        """Пустая карточка — это «долгов нет», а не сломанный виджет."""
        as_role(ADMIN)

        data = client_with_db.get(URL).json()["data"]

        year, month = current_month()
        assert data["generated_for"] == {"year": year, "month": month}
        assert data["total_count"] == 0
        assert data["objects_affected"] == 0
        assert data["items"] == []

    @pytest.mark.integration
    def test_row_carries_everything_the_card_draws(
        self, client_with_db, as_role, db_session, make_division, make_object, plan_to
    ):
        as_role(ADMIN)
        division = make_division(title="Участок №1")
        organization = Organization(title="УК «Престиж»")
        mechanic = UniversalUser(
            name="В.Р. Никифоров",
            email=f"m-{uuid.uuid4().hex[:8]}@test",
            role_id=FOREMAN,
            is_active=True,
        )
        db_session.add_all([organization, mechanic])
        db_session.flush()

        obj = make_object(
            name="Лифт №13",
            division_id=division.id,
            organization_id=organization.id,
            mechanic_id=mechanic.id,
        )
        plan_to(obj)

        data = client_with_db.get(URL).json()["data"]
        item = next(row for row in data["items"] if row["object_id"] == obj.id)

        year, month = previous_month_period()
        assert item["object_name"] == "Лифт №13"
        assert item["client"] == "УК «Престиж»"
        assert item["division"] == "Участок №1"
        assert item["responsible_mechanic"] == "В.Р. Никифоров"
        assert (item["year"], item["month"]) == (year, month)
        assert item["months_overdue"] == 1
        assert item["act_id"] > 0

    @pytest.mark.integration
    def test_current_month_is_not_overdue(
        self, client_with_db, as_role, make_object, plan_to
    ):
        as_role(ADMIN)
        year, month = current_month()
        plan_to(make_object(), months=(month,), year=year)

        data = client_with_db.get(URL).json()["data"]

        assert data["total_count"] == 0

    @pytest.mark.integration
    def test_finished_maintenance_is_not_overdue(
        self, client_with_db, as_role, make_object, plan_to
    ):
        as_role(ADMIN)
        plan_to(make_object(), finished_at=datetime.datetime.now())

        data = client_with_db.get(URL).json()["data"]

        assert data["total_count"] == 0

    @pytest.mark.integration
    def test_object_with_two_gaps_gives_two_rows_but_one_object(
        self, client_with_db, as_role, make_object, plan_to
    ):
        as_role(ADMIN)
        year, month = previous_month_period()
        # Предыдущий месяц и месяц перед ним — оба в прошлом, оба просрочены.
        # Через `previous_month`, а не `month - 1`: в январе это другой год.
        earlier_year, earlier_month = previous_month(year, month)

        obj = make_object()
        if earlier_year == year:
            # Одной строкой графика: на пару «год и объект» в `planned_to`
            # висит UniqueConstraint, второй вызов упал бы.
            plan_to(obj, months=(earlier_month, month), year=year)
        else:
            plan_to(obj, months=(month,), year=year)
            plan_to(obj, months=(earlier_month,), year=earlier_year)

        data = client_with_db.get(URL).json()["data"]
        rows = [row for row in data["items"] if row["object_id"] == obj.id]

        assert len(rows) == 2
        assert data["objects_affected"] == 1
        assert rows[0]["months_overdue"] == 2, "самое старое ТО идёт первым"
        assert rows[1]["months_overdue"] == 1


class TestParameters:
    @pytest.mark.integration
    def test_limit_cuts_the_list_but_not_the_total(
        self, client_with_db, as_role, make_object, plan_to
    ):
        as_role(ADMIN)
        year, month = previous_month_period()
        for _ in range(3):
            plan_to(make_object(), months=(month,), year=year)

        data = client_with_db.get(URL, params={"limit": 2}).json()["data"]

        assert len(data["items"]) == 2
        assert data["total_count"] == 3, "счётчик считает по всей выдаче"
        assert data["objects_affected"] == 3

    @pytest.mark.integration
    @pytest.mark.parametrize("limit", [0, 201])
    def test_limit_out_of_range_is_rejected(self, client_with_db, as_role, limit):
        as_role(ADMIN)
        # Проект превращает ошибки валидации в 400 (см. src/errors.py), а не 422.
        assert client_with_db.get(URL, params={"limit": limit}).status_code == 400

    @pytest.mark.integration
    def test_division_filter_narrows_output(
        self, client_with_db, as_role, make_division, make_object, plan_to
    ):
        as_role(ADMIN)
        mine = make_division()
        other = make_division()
        visible = make_object(division_id=mine.id)
        plan_to(visible)
        plan_to(make_object(division_id=other.id))

        data = client_with_db.get(
            URL, params={"division_id": mine.id}
        ).json()["data"]

        assert [item["object_id"] for item in data["items"]] == [visible.id]

    @pytest.mark.integration
    def test_month_is_not_a_parameter(self, client_with_db, as_role):
        # Просрочка — состояние на сегодня. Если у ручки однажды появится
        # выбор месяца, карточка на главной начнёт врать молча.
        as_role(ADMIN)
        assert client_with_db.get(URL, params={"month": 3}).status_code == 200
