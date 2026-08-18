"""Лента сданных работ у прораба: `GET /work/submitted`.

Механик закрывает ТО сам, и работа засчитывается сразу — приёмки, блокирующей
зачёт, в системе нет. Прорабу нужно видеть, что за него сдали, и уметь
сказать «эту посмотрел», чтобы счётчик на главной гас.

Проверяется главным образом то, чего не видно глазами: два разных вида работ
приезжают одним упорядоченным списком, страницы режут именно его, а область
видимости работает и на ленте, и на отметке.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import (
    ActFact,
    Division,
    FaultCategory,
    Object,
    Order,
    UniversalUser,
    UserDivision,
)

FEED = f"{settings.API_V1_STR}/work/submitted"
COUNT = f"{settings.API_V1_STR}/work/submitted/unreviewed-count"

STATUS_DONE = 4
STATUS_IN_PROGRESS = 3


def _mark(client, kind, work_id):
    return client.post(f"{settings.API_V1_STR}/work/{kind}/{work_id}/reviewed/")


def _items(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.fixture
def division(db_session):
    div = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


@pytest.fixture
def foreman(as_role, db_session, division):
    """Прораб своего участка: правит своё, смотрит по всем участкам."""
    user = as_role(Role.FOREMAN.value, division_id=division.id)
    db_session.add(UserDivision(user_id=user.id, division_id=division.id))
    db_session.flush()
    return user


@pytest.fixture
def make_object(db_session, division):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(div=division):
        number = next(counter)
        obj = Object(
            name=f"Лифт {number}",
            address=f"ул. Сданная, {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            division_id=div.id if div else None,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def mechanic(db_session):
    user = UniversalUser(
        name="Механик Петров",
        email=f"mech-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.MECHANIC.value,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def closed_act(db_session, make_object, mechanic):
    def _make(finished_at=None, obj=None):
        act = ActFact(
            object_id=(obj or make_object()).id,
            main_mechanic_id=mechanic.id,
            finished_at=finished_at or datetime.datetime(2026, 8, 10, 12, 0),
        )
        db_session.add(act)
        db_session.flush()
        return act

    return _make


@pytest.fixture
def closed_order(db_session, make_object, mechanic):
    def _make(done_at=None, obj=None, status_id=STATUS_DONE, creator=None,
              category=None):
        order = Order(
            object_id=(obj or make_object()).id,
            executor_id=mechanic.id,
            creator_id=creator.id if creator else None,
            fault_category_id=category.id if category else None,
            task_text="Не закрывается дверь",
            status_id=status_id,
            done_at=done_at or datetime.datetime(2026, 8, 11, 9, 30),
            created_at=datetime.datetime(2026, 8, 11, 8, 0),
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


@pytest.mark.integration
def test_closed_maintenance_and_closed_order_come_in_one_list(
    client_with_db, foreman, closed_act, closed_order
):
    act = closed_act(finished_at=datetime.datetime(2026, 8, 10, 12, 0))
    order = closed_order(done_at=datetime.datetime(2026, 8, 12, 9, 0))

    items = _items(client_with_db.get(FEED))

    # Свежие сверху: заявка закрыта позже ТО.
    assert [(item["kind"], item["work_id"]) for item in items] == [
        ("breakdown", order.id),
        ("maintenance", act.id),
    ]


@pytest.mark.integration
def test_unfinished_work_is_not_submitted(
    client_with_db, foreman, db_session, make_object, mechanic, closed_order
):
    """ТО без даты закрытия и незакрытая заявка в ленту не попадают."""
    db_session.add(
        ActFact(object_id=make_object().id, main_mechanic_id=mechanic.id)
    )
    db_session.flush()
    closed_order(status_id=STATUS_IN_PROGRESS)

    assert _items(client_with_db.get(FEED)) == []


@pytest.mark.integration
def test_card_says_what_where_and_who(client_with_db, foreman, closed_act, mechanic):
    act = closed_act()

    item = _items(client_with_db.get(FEED))[0]

    assert item["performer"] == mechanic.name
    assert item["object"]["id"] == act.object_id
    assert item["object"]["address"].startswith("ул. Сданная")
    assert item["closed_at"] is not None
    assert item["reviewed_at"] is None


@pytest.mark.integration
def test_time_of_day_survives(client_with_db, foreman, closed_act):
    """Даты идут через `utc_to_timestamp`: иначе всё сдано «в полночь»."""
    moment = datetime.datetime(2026, 8, 10, 17, 45)
    closed_act(finished_at=moment)

    closed_at = _items(client_with_db.get(FEED))[0]["closed_at"]

    assert closed_at == int(
        moment.replace(tzinfo=datetime.timezone.utc).timestamp()
    )


@pytest.mark.integration
def test_request_of_the_client_is_told_apart_from_a_breakdown(
    client_with_db, foreman, db_session, closed_order
):
    """Вид заявки считается тем же правилом, что и в отчётах."""
    client_user = UniversalUser(
        name="Заказчик",
        email=f"client-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.CLIENT.value,
        is_active=True,
    )
    db_session.add(client_user)
    calm = FaultCategory(name=f"Плановое {uuid.uuid4().hex[:6]}", counts_as_breakdown=False)
    db_session.add(calm)
    db_session.flush()

    closed_order(creator=client_user, category=calm)

    assert _items(client_with_db.get(FEED))[0]["kind"] == "client_request"


@pytest.mark.integration
def test_kind_filter_leaves_only_what_was_asked(
    client_with_db, foreman, closed_act, closed_order
):
    act = closed_act()
    closed_order()

    items = _items(client_with_db.get(FEED, params={"kind": "maintenance"}))

    assert [item["work_id"] for item in items] == [act.id]


@pytest.mark.integration
def test_both_kinds_are_ordered_by_one_ruler(
    client_with_db, foreman, closed_act, closed_order
):
    """Ради этого лента и собирается `UNION`, а не склейкой двух списков.

    Склей мы два списка в Python — порядок и страницы считались бы по каждому
    виду работ отдельно, и на первой странице оказались бы свежайшие ТО плюс
    свежайшие заявки, а не свежайшие работы.
    """
    for day in range(1, 4):
        closed_act(finished_at=datetime.datetime(2026, 8, day, 10, 0))
        closed_order(done_at=datetime.datetime(2026, 8, day, 11, 0))

    items = _items(client_with_db.get(FEED, params={"page": 1}))

    assert len(items) == 6
    closed = [item["closed_at"] for item in items]
    assert closed == sorted(closed, reverse=True)
    # Виды идут вперемешку: заявка дня закрыта позже своего ТО.
    assert [item["kind"] for item in items] == [
        "breakdown",
        "maintenance",
        "breakdown",
        "maintenance",
        "breakdown",
        "maintenance",
    ]


@pytest.mark.integration
def test_foreman_marks_a_work_reviewed(
    client_with_db, foreman, closed_act, db_session
):
    act = closed_act()

    response = _mark(client_with_db, "maintenance", act.id)

    assert response.status_code == 200, response.text
    db_session.refresh(act)
    assert act.reviewed_at is not None
    assert act.reviewed_by_id == foreman.id


@pytest.mark.integration
def test_marking_twice_keeps_the_first_mark(
    client_with_db, foreman, closed_act, db_session
):
    """Первая отметка и есть ответ на вопрос «когда посмотрели»."""
    act = closed_act()
    _mark(client_with_db, "maintenance", act.id)
    db_session.refresh(act)
    first = act.reviewed_at

    _mark(client_with_db, "maintenance", act.id)

    db_session.refresh(act)
    assert act.reviewed_at == first


@pytest.mark.integration
def test_counter_counts_what_was_not_looked_at(
    client_with_db, foreman, closed_act, closed_order
):
    act = closed_act()
    closed_order()

    assert client_with_db.get(COUNT).json()["data"]["count"] == 2

    marked = _mark(client_with_db, "maintenance", act.id)

    assert marked.json()["data"]["count"] == 1
    assert client_with_db.get(COUNT).json()["data"]["count"] == 1


@pytest.mark.integration
def test_only_unreviewed_hides_what_was_marked(
    client_with_db, foreman, closed_act, closed_order
):
    act = closed_act()
    order = closed_order()
    _mark(client_with_db, "maintenance", act.id)

    items = _items(client_with_db.get(FEED, params={"only_unreviewed": True}))

    assert [item["work_id"] for item in items] == [order.id]


@pytest.mark.integration
def test_reviewed_work_still_shows_who_and_when(
    client_with_db, foreman, closed_act
):
    act = closed_act()
    _mark(client_with_db, "maintenance", act.id)

    item = _items(client_with_db.get(FEED))[0]

    assert item["reviewed_at"] is not None
    assert item["reviewer"] == foreman.name


@pytest.mark.integration
def test_unfinished_work_cannot_be_marked(
    client_with_db, foreman, db_session, make_object, mechanic
):
    """Проверять нечего: в ленте такой работы нет."""
    act = ActFact(object_id=make_object().id, main_mechanic_id=mechanic.id)
    db_session.add(act)
    db_session.flush()

    assert _mark(client_with_db, "maintenance", act.id).status_code == 404


@pytest.mark.integration
def test_defect_is_not_a_work_of_the_feed(client_with_db, foreman, closed_act):
    act = closed_act()

    assert _mark(client_with_db, "defect", act.id).status_code == 404


@pytest.mark.integration
def test_mechanic_does_not_close_the_foremans_counter_for_himself(
    client_with_db, as_role, closed_act, db_session
):
    """Право `work:review` механику не дали: он бы отмечал свою же работу."""
    act = closed_act()
    as_role(Role.MECHANIC.value)

    response = _mark(client_with_db, "maintenance", act.id)

    assert response.status_code == 403
    db_session.refresh(act)
    assert act.reviewed_at is None


@pytest.mark.integration
def test_client_does_not_see_the_feed(client_with_db, as_role, closed_act):
    """Внутренняя лента заказчику не положена: у роли нет `act:read`."""
    closed_act()
    as_role(Role.CLIENT.value)

    assert client_with_db.get(FEED).status_code == 403


@pytest.mark.integration
def test_mechanic_sees_only_his_own_work(
    client_with_db, as_role, db_session, make_object, closed_act, mechanic
):
    """Область видимости режет ленту так же, как остальные списки."""
    closed_act()
    me = as_role(Role.MECHANIC.value)
    mine = make_object()
    mine.mechanic_id = me.id
    act_of_mine = closed_act(obj=mine)
    db_session.flush()

    items = _items(client_with_db.get(FEED))

    assert [item["work_id"] for item in items] == [act_of_mine.id]


@pytest.mark.integration
def test_foreman_cannot_mark_a_work_of_a_foreign_division(
    client_with_db, foreman, db_session, make_object, closed_act
):
    """Прораб смотрит по всем участкам, а правит только свои."""
    other = Division(title=f"Чужой участок {uuid.uuid4().hex[:6]}")
    db_session.add(other)
    db_session.flush()
    foreign = closed_act(obj=make_object(div=other))

    # В ленте она видна — область чтения у прораба полная.
    assert foreign.id in [item["work_id"] for item in _items(client_with_db.get(FEED))]

    response = _mark(client_with_db, "maintenance", foreign.id)

    assert response.status_code == 403
    db_session.refresh(foreign)
    assert foreign.reviewed_at is None
