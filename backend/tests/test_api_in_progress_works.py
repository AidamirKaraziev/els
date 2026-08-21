"""Текущие работы у прораба: `GET /work/in-progress`.

Механик умеет приостановить ТО и сообщить о проблеме — прораб должен увидеть
это сразу, а не когда работу закроют. Лента сданных на такой вопрос не
отвечает: в ней только закрытое.

Проверяется главным образом то, чего не видно глазами: состояние собирается
из статуса и дат тем же порядком проверок, что в телефоне механика; вставшая
работа стоит выше идущей; область видимости работает так же, как в ленте
сданных.
"""

import datetime
import itertools
import json
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import ActFact, Division, Object, UniversalUser, UserDivision

FEED = f"{settings.API_V1_STR}/work/in-progress"

STATUS_ACCEPTED = 2
STATUS_IN_PROGRESS = 3
STATUS_DONE = 4
STATUS_PROBLEM = 5


def _items(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


def _checklist(title="ТО-1", done=0, total=3):
    """Чек-лист в канонической форме — той, что пишет телефон механика."""
    return json.dumps(
        {
            "title": title,
            "steps": [
                {
                    "id": number,
                    "title": f"Пункт {number}",
                    "done": number <= done,
                    "comment": None,
                }
                for number in range(1, total + 1)
            ],
        },
        ensure_ascii=False,
    )


@pytest.fixture
def division(db_session):
    div = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


@pytest.fixture
def foreman(as_role, db_session, division):
    """Прораб своего участка."""
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
            address=f"ул. Текущая, {number}",
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
        name="Механик Ковалёв",
        email=f"mech-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.MECHANIC.value,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def act(db_session, make_object, mechanic):
    """Начатое ТО. По умолчанию — работа идёт."""

    def _make(
        started_at=datetime.datetime(2026, 8, 21, 9, 30),
        status_id=STATUS_IN_PROGRESS,
        paused_at=None,
        finished_at=None,
        commentary=None,
        step_list_fact=None,
        obj=None,
        is_actual=True,
    ):
        record = ActFact(
            object_id=(obj or make_object()).id,
            main_mechanic_id=mechanic.id,
            started_at=started_at,
            paused_at=paused_at,
            finished_at=finished_at,
            status_id=status_id,
            commentary=commentary,
            step_list_fact=step_list_fact,
            is_actual=is_actual,
        )
        db_session.add(record)
        db_session.flush()
        return record

    return _make


@pytest.mark.integration
def test_running_maintenance_is_in_the_feed(client_with_db, foreman, act):
    record = act(step_list_fact=_checklist(done=2, total=10))

    item = _items(client_with_db.get(FEED))[0]

    assert item["work_id"] == record.id
    assert item["kind"] == "maintenance"
    assert item["state"] == "running"
    assert item["since"] == item["started_at"]
    assert item["title"] == "ТО-1"
    assert item["progress"] == {"done": 2, "total": 10}
    assert item["object"]["address"].startswith("ул. Текущая")


@pytest.mark.integration
def test_paused_maintenance_carries_the_moment_and_the_reason(
    client_with_db, foreman, act
):
    """Пауза — это статус «Принято» при начатой работе, не отдельный статус."""
    record = act(
        status_id=STATUS_ACCEPTED,
        paused_at=datetime.datetime(2026, 8, 21, 10, 40),
        commentary="Уехал на аварийный вызов",
    )

    item = _items(client_with_db.get(FEED))[0]

    assert item["work_id"] == record.id
    assert item["state"] == "paused"
    assert item["reason"] == "Уехал на аварийный вызов"
    # Счёт идёт от момента остановки, а не от начала работы.
    assert item["since"] > item["started_at"]


@pytest.mark.integration
def test_problem_has_a_reason_but_no_moment(client_with_db, foreman, act):
    """Когда механик объявил проблему, в системе не записано.

    Отдавать вместо этого метку правки записи нельзя: она меняется от любого
    действия, и экран показал бы часы, которые ничего не значат.
    """
    record = act(status_id=STATUS_PROBLEM, commentary="Не подходит трос")

    item = _items(client_with_db.get(FEED))[0]

    assert item["work_id"] == record.id
    assert item["state"] == "problem"
    assert item["reason"] == "Не подходит трос"
    assert item["since"] is None
    assert item["started_at"] is not None


@pytest.mark.integration
def test_closed_and_untouched_and_archived_works_are_not_in_the_feed(
    client_with_db, foreman, act
):
    """В ленте только то, за что взялись и не закончили."""
    act(finished_at=datetime.datetime(2026, 8, 21, 12, 0), status_id=STATUS_DONE)
    act(started_at=None, status_id=1)
    act(is_actual=False)

    assert _items(client_with_db.get(FEED)) == []


@pytest.mark.integration
def test_stalled_work_stands_above_running_one(client_with_db, foreman, act):
    """Сверху то, что требует вмешательства, и дольше стоящее — выше."""
    running = act(started_at=datetime.datetime(2026, 8, 21, 11, 0))
    paused_recently = act(
        status_id=STATUS_ACCEPTED,
        started_at=datetime.datetime(2026, 8, 21, 8, 0),
        paused_at=datetime.datetime(2026, 8, 21, 10, 30),
    )
    paused_long_ago = act(
        status_id=STATUS_ACCEPTED,
        started_at=datetime.datetime(2026, 8, 21, 8, 0),
        paused_at=datetime.datetime(2026, 8, 21, 9, 0),
    )
    problem = act(status_id=STATUS_PROBLEM)

    items = _items(client_with_db.get(FEED))

    assert [item["work_id"] for item in items] == [
        problem.id,
        paused_long_ago.id,
        paused_recently.id,
        running.id,
    ]


@pytest.mark.integration
def test_work_without_a_checklist_has_no_progress(client_with_db, foreman, act):
    """Пустой чек-лист — это «не заполнен», а не «ноль пунктов сделано»."""
    act(step_list_fact=None)

    item = _items(client_with_db.get(FEED))[0]

    assert item["progress"] is None
    assert item["title"] is None


@pytest.mark.integration
def test_foreman_does_not_see_a_foreign_division(
    client_with_db, foreman, db_session, act, make_object
):
    """Здесь видимость уже общего правила — так решил заказчик.

    В остальной системе прораб смотрит по всем участкам, а правит только свои
    (`read_scope` и `write_scope` в `core/access.py`). Раздел текущих работ —
    про вмешательство, и границу ему поставили по ответственности: чужая
    бригада в нём только шумит.
    """
    foreign = Division(title=f"Чужой участок {uuid.uuid4().hex[:6]}")
    db_session.add(foreign)
    db_session.flush()
    mine = act()
    act(obj=make_object(div=foreign))

    items = _items(client_with_db.get(FEED))

    assert [item["work_id"] for item in items] == [mine.id]


@pytest.mark.integration
def test_mechanic_sees_only_his_own_work(
    client_with_db, as_role, db_session, act, make_object
):
    """А вот механику область видимости ленту режет — как и все списки."""
    act()
    me = as_role(Role.MECHANIC.value)
    mine = make_object()
    mine.mechanic_id = me.id
    db_session.flush()
    my_act = act(obj=mine)

    items = _items(client_with_db.get(FEED))

    assert [item["work_id"] for item in items] == [my_act.id]


@pytest.mark.integration
def test_client_does_not_see_the_feed(client_with_db, as_role, act):
    """Внутренняя лента заказчику не положена: у роли нет `act:read`."""
    act()
    as_role(Role.CLIENT.value)

    assert client_with_db.get(FEED).status_code == 403
