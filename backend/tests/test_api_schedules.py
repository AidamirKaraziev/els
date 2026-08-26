"""Ручка ленты графиков: форма ответа, роли, страницы.

Арифметику состояний проверяет `test_crud_schedules` — там «сейчас» задаётся
явно. Здесь его задать нельзя: ручка берёт момент из системных часов, чтобы
отличить просроченное ТО от текущего. Поэтому данные заводятся
**относительно сегодняшнего дня**: ТО, закрытое сегодня, выполнено вовремя в
любой день года.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID, DISPATCHER, FOREMAN, MECHANIC
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.models import ActBase, ActFact, Division, Object, PlannedTO

URL = f"{settings.API_V1_STR}/schedules/rows"

#: id из `create_initial_data` (см. `src/core/db/init_db.py`).
TYPE_ACT_TO_6 = 6


def today():
    return datetime.date.today()


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
    def _make(obj, *, months=None, type_act_id=None, year=None):
        act_base_id = None
        if type_act_id is not None:
            act_base = ActBase(type_act_id=type_act_id)
            db_session.add(act_base)
            db_session.flush()
            act_base_id = act_base.id

        columns = {}
        for month, finished_at in (months or {}).items():
            act = ActFact(
                object_id=obj.id,
                finished_at=finished_at,
                act_base_id=act_base_id,
            )
            db_session.add(act)
            db_session.flush()
            columns[_PLANNED_MONTH_COLUMN[month].key] = act.id

        planned = PlannedTO(
            year=str(year or today().year), object_id=obj.id, **columns
        )
        db_session.add(planned)
        db_session.flush()
        return planned

    return _make


def _data(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


class TestAccess:
    """Право `planned_to:read` есть у всех, кто работает с графиком.

    Границу «кого именно видно» держит область видимости, а не право:
    отдельной ручки «по прорабу» в разделе нет намеренно.
    """

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "role",
        [ADMIN, FOREMAN, MECHANIC, DISPATCHER],
        ids=["админ", "прораб", "механик", "диспетчер"],
    )
    def test_roles_with_planned_to_read_are_allowed(
        self, client_with_db, as_role, role
    ):
        as_role(role)

        assert client_with_db.get(URL).status_code == 200

    @pytest.mark.integration
    def test_client_is_denied(self, client_with_db, as_role):
        # Клиент график ТО не ведёт и не смотрит: права у роли нет.
        as_role(CLIENT_ID)

        assert client_with_db.get(URL).status_code == 403

    @pytest.mark.integration
    def test_anonymous_is_denied(self, client_with_db):
        assert client_with_db.get(URL).status_code == 401


class TestRowShape:
    """Форма строки: её разбирает `ScheduleRow.fromJson` на фронте."""

    @pytest.mark.integration
    def test_twelve_cells_and_current_month_is_done(
        self, client_with_db, as_role, make_object, plan_to
    ):
        obj = make_object(address="ул. Ленина, 1")
        plan_to(
            obj,
            months={today().month: datetime.datetime.now()},
            type_act_id=TYPE_ACT_TO_6,
        )
        as_role(ADMIN)

        row = _data(client_with_db.get(URL))[0]
        cells = {cell["month"]: cell for cell in row["cells"]}

        assert row["object_id"] == obj.id
        assert row["year"] == today().year
        assert row["address"] == "ул. Ленина, 1"
        assert len(row["cells"]) == 12
        # Закрыт сегодня — значит внутри своего месяца, в любой день года.
        assert cells[today().month]["status"] == "done"
        assert cells[today().month]["to_name"] == "ТО 6"
        assert cells[today().month]["act_id"] is not None

    @pytest.mark.integration
    def test_month_without_plan_is_none(
        self, client_with_db, as_role, make_object
    ):
        # График не заводили. Объект остаётся в ленте с двенадцатью пустыми
        # клетками, а не пропадает из неё.
        make_object()
        as_role(ADMIN)

        row = _data(client_with_db.get(URL))[0]

        assert {cell["status"] for cell in row["cells"]} == {"none"}
        assert all(cell["act_id"] is None for cell in row["cells"])

    @pytest.mark.integration
    def test_other_year_is_empty(
        self, client_with_db, as_role, make_object, plan_to
    ):
        obj = make_object()
        plan_to(obj, months={3: None}, year=today().year)
        as_role(ADMIN)

        row = _data(client_with_db.get(URL, params={"year": today().year - 1}))[0]

        assert row["year"] == today().year - 1
        assert {cell["status"] for cell in row["cells"]} == {"none"}


class TestFiltersAndSearch:
    @pytest.mark.integration
    def test_search_narrows_the_feed(
        self, client_with_db, as_role, make_object
    ):
        mark = uuid.uuid4().hex[:8]
        wanted = make_object(name=f"Спортмастер {mark}")
        make_object()
        as_role(ADMIN)

        data = _data(client_with_db.get(URL, params={"search": mark}))

        assert [row["object_id"] for row in data] == [wanted.id]

    @pytest.mark.integration
    def test_schedule_state_filter(
        self, client_with_db, as_role, make_object, plan_to
    ):
        done = make_object()
        plan_to(done, months={today().month: datetime.datetime.now()})
        empty = make_object()
        as_role(ADMIN)

        data = _data(
            client_with_db.get(URL, params={"schedule_state": "all_done"})
        )

        ids = [row["object_id"] for row in data]
        assert done.id in ids
        # Объекту без графика «всё выполнено» не про него.
        assert empty.id not in ids

    @pytest.mark.integration
    def test_unknown_state_is_rejected(self, client_with_db, as_role):
        as_role(ADMIN)

        response = client_with_db.get(
            URL, params={"schedule_state": "everything_is_fine"}
        )

        # 400, а не 422: приложение переводит ошибки валидации в свой формат
        # ответа — см. обработчик в `src/main.py`.
        assert response.status_code == 400


class TestPagination:
    @pytest.mark.integration
    def test_has_next_tells_the_truth(
        self, client_with_db, as_role, make_object
    ):
        # Фронт догружает ленту по `has_next`, а не по «список непуст»:
        # на признаке «непуст» экран уезжал за последнюю страницу.
        for _ in range(31):
            make_object()
        as_role(ADMIN)

        first = client_with_db.get(URL, params={"page": 1}).json()
        second = client_with_db.get(URL, params={"page": 2}).json()

        assert len(first["data"]) == 30
        assert first["meta"]["paginator"]["has_next"] is True
        assert len(second["data"]) == 1
        assert second["meta"]["paginator"]["has_next"] is False

    @pytest.mark.integration
    def test_without_page_the_feed_is_whole(
        self, client_with_db, as_role, make_object
    ):
        for _ in range(3):
            make_object()
        as_role(ADMIN)

        response = client_with_db.get(URL).json()

        assert len(response["data"]) == 3
        assert response["meta"]["paginator"] is None


FILTERS_URL = f"{settings.API_V1_STR}/schedules/filters"


@pytest.fixture
def division(db_session):
    row = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
    db_session.add(row)
    db_session.flush()
    return row


class TestFilterOptionsAccess:
    """Права те же, что у ленты: отдельного права на фильтры нет."""

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "role",
        [ADMIN, FOREMAN, MECHANIC, DISPATCHER],
        ids=["админ", "прораб", "механик", "диспетчер"],
    )
    def test_roles_with_planned_to_read_are_allowed(
        self, client_with_db, as_role, role
    ):
        as_role(role)

        assert client_with_db.get(FILTERS_URL).status_code == 200

    @pytest.mark.integration
    def test_client_is_denied(self, client_with_db, as_role):
        as_role(CLIENT_ID)

        assert client_with_db.get(FILTERS_URL).status_code == 403

    @pytest.mark.integration
    def test_anonymous_is_denied(self, client_with_db):
        assert client_with_db.get(FILTERS_URL).status_code == 401


class TestFilterOptionsShape:
    """Форма ответа фильтров: её разбирает `ScheduleFilterOptions`."""

    @pytest.mark.integration
    def test_four_lists_of_pairs(
        self, client_with_db, as_role, make_object, division
    ):
        obj = make_object(division_id=division.id)
        as_role(ADMIN)

        data = _data(client_with_db.get(FILTERS_URL))

        assert set(data) == {"divisions", "types", "names", "factory_numbers"}
        assert {"id", "title"} == set(data["divisions"][0])
        assert division.id in {item["id"] for item in data["divisions"]}
        assert obj.name in {item["title"] for item in data["names"]}
        assert obj.factory_number in {
            item["title"] for item in data["factory_numbers"]
        }

    @pytest.mark.integration
    def test_chosen_value_narrows_the_feed(
        self, client_with_db, as_role, make_object, division
    ):
        # Значение из списка обязано работать фильтром ленты — иначе список
        # предлагает то, чего лента не понимает.
        wanted = make_object(division_id=division.id)
        make_object()
        as_role(ADMIN)

        data = _data(client_with_db.get(FILTERS_URL))
        option = next(
            item for item in data["divisions"] if item["id"] == division.id
        )
        rows = _data(
            client_with_db.get(URL, params={"division_id": option["id"]})
        )

        assert {row["object_id"] for row in rows} == {wanted.id}


class TestWithoutDivision:
    """«Без участка» — отдельное условие, а не пустой `division_id`."""

    @pytest.mark.integration
    def test_only_objects_with_no_division(
        self, client_with_db, as_role, make_object, division
    ):
        orphan = make_object()
        make_object(division_id=division.id)
        as_role(ADMIN)

        rows = _data(client_with_db.get(URL, params={"without_division": True}))

        assert orphan.id in {row["object_id"] for row in rows}
        assert all(row["division"] is None for row in rows)

    @pytest.mark.integration
    def test_without_the_flag_they_are_all_here(
        self, client_with_db, as_role, make_object, division
    ):
        # Фильтр включается только флагом: без него объект с участком из
        # ленты пропадать не должен.
        orphan = make_object()
        with_division = make_object(division_id=division.id)
        as_role(ADMIN)

        found = {row["object_id"] for row in _data(client_with_db.get(URL))}

        assert {orphan.id, with_division.id} <= found

    @pytest.mark.integration
    def test_together_with_division_id_gives_nothing(
        self, client_with_db, as_role, make_object, division
    ):
        # Два условия складываются, как и все остальные фильтры: «этот
        # участок» и «без участка» вместе не выполняются никогда. Отдельной
        # ошибки на это нет — пустая лента и есть честный ответ.
        make_object(division_id=division.id)
        make_object()
        as_role(ADMIN)

        rows = _data(
            client_with_db.get(
                URL,
                params={"division_id": division.id, "without_division": True},
            )
        )

        assert rows == []

