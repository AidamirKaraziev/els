"""Ручка `GET /statistics/breakdowns`: форма ответа, роли и параметры.

Арифметику агрегатов проверяет `test_crud_statistics`. Здесь — что запрос
доходит до БД, что схема собирается и что параметры делают обещанное.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID
from src.models import Object, Order, Organization

URL = f"{settings.API_V1_STR}/statistics/breakdowns"

CAT_AA = 1
CAT_A = 2
CAT_N = 4
CAT_TO = 6


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
def make_order(db_session):
    def _make(obj, created_at, fault_category_id=CAT_A, **kwargs):
        order = Order(
            object_id=obj.id,
            created_at=created_at,
            fault_category_id=fault_category_id,
            **kwargs,
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


def _get(client, **params):
    params.setdefault("year", 2026)
    params.setdefault("month", 5)
    return client.get(URL, params=params)


class TestAccess:
    @pytest.mark.integration
    def test_requires_authentication(self, client_with_db):
        # 401, а не 403: отсутствие токена и нехватка прав — разные
        # ситуации, и перехватчик на фронте обновляет токен именно по 401.
        assert _get(client_with_db).status_code == 401

    @pytest.mark.integration
    def test_client_is_allowed_and_sees_only_his_company(
        self, client_with_db, as_role
    ):
        """Клиента до статистики пускаем с этапа 5.

        Раньше здесь стояла временная проверка роли: без фильтра по области
        ручка отдала бы клиенту сводку по всем компаниям сразу. Теперь сводка
        режется по его `company_id`, поэтому запрет снят. Клиент без компании
        видит нули, а не чужие цифры.
        """
        as_role(CLIENT_ID)
        assert _get(client_with_db).status_code == 200

    @pytest.mark.integration
    def test_employee_gets_the_report(self, client_with_db, as_role):
        as_role(ADMIN)
        assert _get(client_with_db).status_code == 200


class TestReportShape:
    @pytest.mark.integration
    def test_empty_month_returns_zeros_not_an_error(self, client_with_db, as_role):
        """Тихий месяц — это хорошая новость, а не сломанный виджет."""
        as_role(ADMIN)

        data = _get(client_with_db).json()["data"]

        assert data["period"] == {"year": 2026, "month": 5}
        assert data["total_breakdowns"] == 0
        assert data["objects_affected"] == 0
        assert data["severity_summary"] == []
        assert data["items"] == []

    @pytest.mark.integration
    def test_report_carries_object_details_and_severity(
        self, client_with_db, as_role, db_session, make_object, make_order
    ):
        as_role(ADMIN)
        organization = Organization(title=f"УК {uuid.uuid4().hex[:6]}")
        db_session.add(organization)
        db_session.flush()

        obj = make_object(
            organization_id=organization.id, address="ул. Красная, 1", name="Лифт 12"
        )
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=CAT_AA)
        make_order(obj, datetime.datetime(2026, 5, 3), fault_category_id=CAT_N)
        make_order(obj, datetime.datetime(2026, 5, 4), fault_category_id=CAT_TO)

        data = _get(client_with_db).json()["data"]

        assert data["total_breakdowns"] == 2, "плановое ТО в счёт не идёт"
        assert data["objects_affected"] == 1

        item = data["items"][0]
        assert item["object_id"] == obj.id
        assert item["object_name"] == "Лифт 12"
        assert item["registration_number"] == obj.registration_number
        assert item["address"] == "ул. Красная, 1"
        assert item["client"] == organization.title
        assert item["breakdown_count"] == 2
        assert [(row["code"], row["count"]) for row in item["severity"]] == [
            ("AA", 1),
            ("Н", 1),
        ]

    @pytest.mark.integration
    def test_severity_summary_shares_add_up(
        self, client_with_db, as_role, make_object, make_order
    ):
        as_role(ADMIN)
        obj = make_object()
        for day in (2, 3, 4, 5):
            category = CAT_AA if day == 2 else CAT_A
            make_order(obj, datetime.datetime(2026, 5, day), fault_category_id=category)

        summary = _get(client_with_db).json()["data"]["severity_summary"]

        assert [(row["code"], row["count"], row["share"]) for row in summary] == [
            ("AA", 1, 25.0),
            ("А", 3, 75.0),
        ]

    @pytest.mark.integration
    def test_reaction_time_is_reported_in_hours(
        self, client_with_db, as_role, make_object, make_order
    ):
        as_role(ADMIN)
        obj = make_object()
        make_order(
            obj,
            datetime.datetime(2026, 5, 10, 10, 0),
            accepted_at=datetime.datetime(2026, 5, 10, 11, 30),
        )

        item = _get(client_with_db).json()["data"]["items"][0]

        assert item["avg_reaction_hours"] == 1.5
        assert item["reacted_count"] == 1

    @pytest.mark.integration
    def test_resolution_time_is_null_while_done_at_is_not_written(
        self, client_with_db, as_role, make_object, make_order
    ):
        as_role(ADMIN)
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 10, 10, 0), status_id=4)

        item = _get(client_with_db).json()["data"]["items"][0]

        assert item["avg_resolution_hours"] is None
        assert item["resolved_count"] == 0

    @pytest.mark.integration
    def test_factory_model_is_null_when_object_has_no_model(
        self, client_with_db, as_role, make_object, make_order
    ):
        """Пустые завод и модель не должны склеиваться в строку из пробелов."""
        as_role(ADMIN)
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2))

        item = _get(client_with_db).json()["data"]["items"][0]

        assert item["factory_model"] is None


class TestParameters:
    @pytest.mark.integration
    def test_limit_trims_the_list_but_not_the_totals(
        self, client_with_db, as_role, make_object, make_order
    ):
        """Карточка показывает пять строк, но «всего» считается по всем объектам."""
        as_role(ADMIN)
        for index in range(3):
            obj = make_object()
            make_order(obj, datetime.datetime(2026, 5, 2 + index))

        data = _get(client_with_db, limit=1).json()["data"]

        assert len(data["items"]) == 1
        assert data["objects_affected"] == 3
        assert data["total_breakdowns"] == 3

    @pytest.mark.integration
    def test_without_previous_there_is_no_delta(
        self, client_with_db, as_role, make_object, make_order
    ):
        as_role(ADMIN)
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2))

        item = _get(client_with_db).json()["data"]["items"][0]

        assert item["previous_count"] is None
        assert item["delta"] is None

    @pytest.mark.integration
    def test_with_previous_adds_delta(
        self, client_with_db, as_role, make_object, make_order
    ):
        as_role(ADMIN)
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 4, 2))
        make_order(obj, datetime.datetime(2026, 4, 3))
        make_order(obj, datetime.datetime(2026, 4, 4))
        make_order(obj, datetime.datetime(2026, 5, 2))

        item = _get(client_with_db, with_previous=True).json()["data"]["items"][0]

        assert item["previous_count"] == 3
        assert item["delta"] == -2, "поломок стало меньше — дельта отрицательная"

    @pytest.mark.integration
    def test_object_quiet_last_month_gets_zero_not_null(
        self, client_with_db, as_role, make_object, make_order
    ):
        as_role(ADMIN)
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2))

        item = _get(client_with_db, with_previous=True).json()["data"]["items"][0]

        assert item["previous_count"] == 0
        assert item["delta"] == 1

    @pytest.mark.integration
    def test_filter_by_organization(
        self, client_with_db, as_role, db_session, make_object, make_order
    ):
        as_role(ADMIN)
        organization = Organization(title=f"УК {uuid.uuid4().hex[:6]}")
        db_session.add(organization)
        db_session.flush()

        mine = make_object(organization_id=organization.id)
        other = make_object()
        make_order(mine, datetime.datetime(2026, 5, 2))
        make_order(other, datetime.datetime(2026, 5, 3))

        data = _get(client_with_db, organization_id=organization.id).json()["data"]

        assert [item["object_id"] for item in data["items"]] == [mine.id]
        assert data["total_breakdowns"] == 1, "итоги тоже должны учитывать фильтр"

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "params",
        [
            {"month": 13},
            {"month": 0},
            {"year": 1700},
            {"limit": 0},
            {"offset": -1},
        ],
    )
    def test_invalid_parameters_are_rejected(self, client_with_db, as_role, params):
        as_role(ADMIN)
        # Проект превращает ошибки валидации в 400 (см. src/errors.py), а не 422.
        assert _get(client_with_db, **params).status_code == 400

    @pytest.mark.integration
    def test_year_and_month_are_required(self, client_with_db, as_role):
        as_role(ADMIN)
        assert client_with_db.get(URL).status_code == 400
