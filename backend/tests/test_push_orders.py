"""Push по заявкам и регистрация телефона — на подменённом FCM.

До Google не ходим: подменяется доставка одного сообщения (`push._transport`)
и ключ сервисного аккаунта. Проверяется то, что важно человеку с телефоном:
кому ушло, кому не ушло, и что мёртвый адрес исчезает из базы.
"""

import uuid
from types import SimpleNamespace
from typing import List, Tuple

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import DeviceToken, Division, Object, UniversalUser, UserDivision
from src.services import push

ORDER = f"{settings.API_V1_STR}/order/"
DEVICE = f"{settings.API_V1_STR}/device-token/"

# Ремонт по заявке — есть в справочнике после миграции e9b7d4a06c32.
CATEGORY = 11


def _data(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


class _FakeAccount:
    project_id = "test-project"

    def access_token(self, client):  # noqa: ANN001 — подпись как у настоящего
        return "fake-access-token"


@pytest.fixture
def fcm(monkeypatch, db_session):
    """Подменённый FCM: запоминает отправленное, отвечает по словарю ошибок."""
    sent: List[Tuple[str, dict]] = []
    errors = {}

    def transport(token, access, message):
        sent.append((token, message))
        if token in errors:
            return push.FcmResult(False, errors[token])
        return push.FcmResult(True)

    monkeypatch.setattr(push, "_account", _FakeAccount())
    monkeypatch.setattr(push, "_account_loaded", True)
    monkeypatch.setattr(push, "_transport", transport)
    # Фоновой задаче нужна своя сессия; в тесте — та же, что и у ручки, иначе
    # она не увидит незакоммиченные строки савпоинта.
    monkeypatch.setattr(push, "_db_factory", lambda: _NoClose(db_session))

    class Fake:
        def __init__(self):
            self.sent = sent
            self.errors = errors

        def tokens(self):
            return [token for token, _ in sent]

        def titles(self):
            return [message["notification"]["title"] for _, message in sent]

    return Fake()


class _NoClose:
    """Сессия теста, у которой `close()` фоновой задачи ничего не делает."""

    def __init__(self, session):
        self._session = session

    def __getattr__(self, name):
        return getattr(self._session, name)

    def close(self):
        return None


@pytest.fixture
def division(db_session):
    div = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


def _user(db_session, division, name):
    user = UniversalUser(
        name=name,
        email=f"{uuid.uuid4().hex[:8]}@test",
        role_id=Role.MECHANIC.value,
        division_id=division.id,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


def _token(db_session, user, value=None):
    value = value or f"tok-{uuid.uuid4().hex}"
    db_session.add(DeviceToken(user_id=user.id, token=value))
    db_session.flush()
    return value


@pytest.fixture
def executor(db_session, division):
    return _user(db_session, division, "Исполнитель")


@pytest.fixture
def object_mechanic(db_session, division):
    return _user(db_session, division, "Механик объекта")


@pytest.fixture
def lift(db_session, division, object_mechanic):
    obj = Object(
        name=f"Лифт {uuid.uuid4().hex[:6]}",
        address="ул. Единая, 1",
        factory_number=f"F-{uuid.uuid4().hex[:6]}",
        division_id=division.id,
        mechanic_id=object_mechanic.id,
    )
    db_session.add(obj)
    db_session.flush()
    return obj


@pytest.fixture
def foreman(as_role, db_session, division):
    user = as_role(Role.FOREMAN.value, division_id=division.id)
    db_session.add(UserDivision(user_id=user.id, division_id=division.id))
    db_session.flush()
    return user


def _create(client, lift, executor_id=None, **fields):
    body = {"object_id": lift.id, "fault_category_id": CATEGORY, **fields}
    if executor_id is not None:
        body["executor_id"] = executor_id
    return _data(client.post(ORDER, json=body))


# --- создание -----------------------------------------------------------------


def test_new_order_pushes_executor_and_object_mechanic(
    client_with_db, fcm, foreman, lift, executor, object_mechanic, db_session
):
    t_exec = _token(db_session, executor)
    t_mech = _token(db_session, object_mechanic)

    order = _create(client_with_db, lift, executor.id, task_text="Застрял лифт")

    assert sorted(fcm.tokens()) == sorted([t_exec, t_mech])
    _, message = fcm.sent[0]
    assert message["notification"]["title"] == f"Новая задача №{order['id']}"
    assert lift.name in message["notification"]["body"]
    assert "Застрял лифт" in message["notification"]["body"]
    assert message["data"] == {
        "kind": "order_assigned",
        "order_id": str(order["id"]),
        "look": "request",
    }
    assert message["android"]["notification"]["channel_id"] == "emergency"
    # Категория 11 — «Р (Ремонт по заявке)»: синяя заявка, не авария.
    assert message["android"]["notification"]["icon"] == "ic_push_request"
    assert message["android"]["notification"]["color"] == "#1565C0"


@pytest.mark.parametrize(
    "category, look, icon",
    [
        (1, "alarm", "ic_push_alarm"),  # AA — застревание
        (6, "maintenance", "ic_push_maintenance"),  # ТО
        (8, "request", "ic_push_request"),  # КР — ремонт
    ],
)
def test_look_follows_category(
    client_with_db, fcm, foreman, lift, executor, db_session, category, look, icon
):
    _token(db_session, executor)
    _data(
        client_with_db.post(
            ORDER,
            json={
                "object_id": lift.id,
                "executor_id": executor.id,
                "fault_category_id": category,
            },
        )
    )

    _, message = fcm.sent[0]
    assert message["data"]["look"] == look
    assert message["android"]["notification"]["icon"] == icon
    assert message["android"]["notification"]["color"] == push.LOOKS[look]["color"]


def test_order_without_category_is_alarm():
    """API без категории не пустит, но в базе такие заявки есть."""
    order = SimpleNamespace(fault_category=None)
    assert push.order_look(order, push.KIND_ASSIGNED) == "alarm"
    assert push.order_look(order, push.KIND_REMOVED) == "removed"


def test_author_does_not_push_himself(
    client_with_db, fcm, foreman, division, db_session
):
    # Прораб — механик своего лифта и сам заводит на него заявку: уведомлять
    # его не о чем, он только что нажал кнопку.
    own = Object(
        name="Свой лифт",
        factory_number=f"F-{uuid.uuid4().hex[:6]}",
        division_id=division.id,
        mechanic_id=foreman.id,
    )
    db_session.add(own)
    db_session.flush()
    _token(db_session, foreman)

    _create(client_with_db, own, foreman.id)

    assert fcm.sent == []


def test_no_tokens_no_calls(client_with_db, fcm, foreman, lift, executor):
    _create(client_with_db, lift, executor.id)

    assert fcm.sent == []


def test_two_tokens_of_one_person_both_get_it(
    client_with_db, fcm, foreman, lift, executor, db_session
):
    # Два телефона у одного человека — уведомляем оба, но по разу.
    first = _token(db_session, executor)
    second = _token(db_session, executor)

    _create(client_with_db, lift, executor.id)

    assert sorted(fcm.tokens()) == sorted([first, second])


# --- переназначение и снятие --------------------------------------------------


def test_reassign_pushes_new_and_previous_executor(
    client_with_db, fcm, foreman, lift, executor, division, db_session
):
    other = _user(db_session, division, "Другой исполнитель")
    t_old = _token(db_session, executor)
    t_new = _token(db_session, other)
    order = _create(client_with_db, lift, executor.id)
    fcm.sent.clear()

    _data(client_with_db.put(f"{ORDER}{order['id']}/", json={"executor_id": other.id}))

    by_token = {token: message["notification"]["title"] for token, message in fcm.sent}
    assert by_token == {
        t_new: f"Новая задача №{order['id']}",
        t_old: f"Задача №{order['id']} передана другому",
    }


def test_status_change_does_not_push(
    client_with_db, fcm, foreman, lift, executor, db_session
):
    _token(db_session, executor)
    order = _create(client_with_db, lift, executor.id)
    fcm.sent.clear()

    _data(client_with_db.put(f"{ORDER}{order['id']}/", json={"status_id": 2}))

    assert fcm.sent == []


def test_archive_pushes_removed(
    client_with_db, fcm, foreman, lift, executor, object_mechanic, db_session
):
    _token(db_session, executor)
    _token(db_session, object_mechanic)
    order = _create(client_with_db, lift, executor.id)
    fcm.sent.clear()

    _data(client_with_db.post(f"{ORDER}{order['id']}/archive/"))

    assert len(fcm.sent) == 2
    assert set(fcm.titles()) == {f"Задача №{order['id']} снята"}
    assert fcm.sent[0][1]["data"]["kind"] == "order_removed"
    # Снятие серое при любой категории.
    assert fcm.sent[0][1]["data"]["look"] == "removed"
    assert fcm.sent[0][1]["android"]["notification"]["icon"] == "ic_push_removed"


# --- мёртвые токены -----------------------------------------------------------


def test_unregistered_token_is_dropped(
    client_with_db, fcm, foreman, lift, executor, db_session
):
    dead = _token(db_session, executor)
    alive = _token(db_session, executor)
    fcm.errors[dead] = "UNREGISTERED"

    _create(client_with_db, lift, executor.id)

    left = {row.token for row in db_session.query(DeviceToken).all()}
    assert alive in left
    assert dead not in left


def test_transient_error_keeps_token(
    client_with_db, fcm, foreman, lift, executor, db_session
):
    token = _token(db_session, executor)
    fcm.errors[token] = "UNAVAILABLE"

    _create(client_with_db, lift, executor.id)

    assert db_session.query(DeviceToken).filter_by(token=token).count() == 1


# --- регистрация телефона -----------------------------------------------------


def test_register_requires_login(client_with_db):
    response = client_with_db.post(DEVICE, json={"token": "abc"})
    assert response.status_code == 401


def test_register_twice_keeps_one_row(client_with_db, as_role, db_session):
    user = as_role(Role.MECHANIC.value)

    first = _data(client_with_db.post(DEVICE, json={"token": "tok-1"}))
    second = _data(client_with_db.post(DEVICE, json={"token": "tok-1"}))

    assert first["id"] == second["id"]
    assert first["platform"] == "android"
    assert db_session.query(DeviceToken).filter_by(user_id=user.id).count() == 1


def test_token_moves_to_new_owner(client_with_db, as_role, db_session, division):
    # Один телефон, два человека по очереди: адрес уходит к последнему.
    previous = _user(db_session, division, "Прежний")
    _token(db_session, previous, "shared-phone")
    user = as_role(Role.MECHANIC.value)

    _data(client_with_db.post(DEVICE, json={"token": "shared-phone"}))

    rows = db_session.query(DeviceToken).filter_by(token="shared-phone").all()
    assert [row.user_id for row in rows] == [user.id]


def test_unregister_own_token_only(client_with_db, as_role, db_session, division):
    stranger = _user(db_session, division, "Чужой")
    _token(db_session, stranger, "not-mine")
    user = as_role(Role.MECHANIC.value)
    _token(db_session, user, "mine")

    assert (
        _data(client_with_db.request("DELETE", DEVICE, json={"token": "mine"})) is True
    )
    assert (
        _data(client_with_db.request("DELETE", DEVICE, json={"token": "not-mine"}))
        is False
    )
    assert db_session.query(DeviceToken).filter_by(token="not-mine").count() == 1
    assert db_session.query(DeviceToken).filter_by(token="mine").count() == 0


# --- ключ не настроен ---------------------------------------------------------


def test_without_key_orders_still_work(
    client_with_db, monkeypatch, foreman, lift, executor, db_session
):
    monkeypatch.setattr(push, "_account", None)
    monkeypatch.setattr(push, "_account_loaded", True)
    _token(db_session, executor)

    order = _create(client_with_db, lift, executor.id)

    # Заявка создана как обычно — исполнитель на месте.
    assert order["executor_id"]["id"] == executor.id
