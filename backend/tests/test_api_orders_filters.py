"""Фильтры у `GET /order/all`.

Нужны для перехода из виджета «Топ поломок»: человек видит у объекта число
за месяц и хочет посмотреть, какие именно это были заявки. Главное здесь —
чтобы число в виджете и длина списка сходились.

Все параметры необязательные, поэтому отдельно проверяется, что без них
ручка ведёт себя как раньше.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import Object, Order

URL = f"{settings.API_V1_STR}/order/all"

CAT_AA = 1  # застревание пассажира
CAT_A = 2  # остановка лифта
CAT_TO = 6  # плановые работы — не поломка
CAT_L = 10  # ложный вызов — не поломка


@pytest.fixture
def make_object(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make():
        number = next(counter)
        obj = Object(
            name=f"Лифт {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def make_order(db_session):
    def _make(obj, created_at, fault_category_id=CAT_A):
        order = Order(
            object_id=obj.id if obj is not None else None,
            # Автора проставляем обязательно: в схеме ответа `OrderGet` поле
            # `creator_id` не Optional, и заявка без него роняет всю выдачу
            # с 500. Берём засеянного суперадмина (id=1).
            creator_id=1,
            created_at=created_at,
            fault_category_id=fault_category_id,
            task_text="проверка",
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


def _ids(response):
    return [item["id"] for item in response.json()["data"]]


class TestFilters:
    @pytest.fixture(autouse=True)
    def logged_in(self, as_role):
        """Ручка требует прав на чтение заявок: входим админом.

        Фильтры и разбор периода к правам отношения не имеют, проверяем их —
        а не вход.
        """
        return as_role(Role.ADMIN)

    @pytest.mark.integration
    def test_by_object(self, client_with_db, make_object, make_order):
        mine = make_object()
        other = make_object()
        wanted = make_order(mine, datetime.datetime(2026, 5, 2))
        make_order(other, datetime.datetime(2026, 5, 3))

        response = client_with_db.get(URL, params={"object_id": mine.id})

        assert _ids(response) == [wanted.id]

    @pytest.mark.integration
    def test_by_month(self, client_with_db, make_object, make_order):
        obj = make_object()
        wanted = make_order(obj, datetime.datetime(2026, 5, 31, 23, 59))
        make_order(obj, datetime.datetime(2026, 6, 1, 0, 0))
        make_order(obj, datetime.datetime(2026, 4, 30, 23, 59))

        response = client_with_db.get(URL, params={"year": 2026, "month": 5})

        assert _ids(response) == [wanted.id]

    @pytest.mark.integration
    def test_only_breakdowns_matches_the_widget(
        self, client_with_db, make_object, make_order
    ):
        """Счётчик в виджете и длина списка должны сходиться."""
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=CAT_AA)
        make_order(obj, datetime.datetime(2026, 5, 3), fault_category_id=CAT_A)
        make_order(obj, datetime.datetime(2026, 5, 4), fault_category_id=CAT_TO)
        make_order(obj, datetime.datetime(2026, 5, 5), fault_category_id=CAT_L)

        params = {"object_id": obj.id, "year": 2026, "month": 5}

        assert len(_ids(client_with_db.get(URL, params=params))) == 4
        assert (
            len(
                _ids(
                    client_with_db.get(URL, params={**params, "only_breakdowns": True})
                )
            )
            == 2
        ), "плановое ТО и ложный вызов поломками не считаются"

    @pytest.mark.integration
    def test_order_without_category_stays_a_breakdown(
        self, client_with_db, make_object, make_order
    ):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=None)

        response = client_with_db.get(
            URL, params={"object_id": obj.id, "only_breakdowns": True}
        )

        assert len(_ids(response)) == 1

    @pytest.mark.integration
    def test_newest_first(self, client_with_db, make_object, make_order):
        obj = make_object()
        old = make_order(obj, datetime.datetime(2026, 5, 2))
        new = make_order(obj, datetime.datetime(2026, 5, 20))

        response = client_with_db.get(URL, params={"object_id": obj.id})

        assert _ids(response) == [new.id, old.id]


class TestBackwardCompatibility:
    @pytest.fixture(autouse=True)
    def logged_in(self, as_role):
        """Ручка требует прав на чтение заявок: входим админом.

        Фильтры и разбор периода к правам отношения не имеют, проверяем их —
        а не вход.
        """
        return as_role(Role.ADMIN)

    @pytest.mark.integration
    def test_without_filters_returns_everything(
        self, client_with_db, make_object, make_order
    ):
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=CAT_TO)
        make_order(obj, datetime.datetime(2020, 1, 1), fault_category_id=CAT_A)

        response = client_with_db.get(URL)

        assert response.status_code == 200
        assert len(_ids(response)) == 2, "без фильтров ручка ничего не отсекает"


class TestValidation:
    @pytest.fixture(autouse=True)
    def logged_in(self, as_role):
        """Ручка требует прав на чтение заявок: входим админом.

        Фильтры и разбор периода к правам отношения не имеют, проверяем их —
        а не вход.
        """
        return as_role(Role.ADMIN)

    @pytest.mark.integration
    @pytest.mark.parametrize("params", [{"year": 2026}, {"month": 5}])
    def test_year_and_month_only_together(self, client_with_db, params):
        """Половина периода — почти наверняка ошибка вызывающего."""
        response = client_with_db.get(URL, params=params)

        assert response.status_code == 422

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "params", [{"year": 2026, "month": 13}, {"year": 1700, "month": 5}]
    )
    def test_invalid_period_is_rejected(self, client_with_db, params):
        assert client_with_db.get(URL, params=params).status_code == 400


class TestAccess:
    @pytest.mark.integration
    def test_requires_authentication(self, client_with_db):
        """Раньше список заявок отдавался кому угодно без токена.

        Это была утечка: `/order/all` возвращает заявки по всем объектам всех
        компаний, включая чужие.
        """
        assert client_with_db.get(URL).status_code == 401
