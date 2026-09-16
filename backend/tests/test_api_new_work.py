"""Форма «Новая работа»: `GET /work/new/context` и `POST /order/` без исполнителя.

Проверяется то, чего не видно глазами: справочники приезжают в области
видимости спрашивающего; заказчик попадает в список исполнителей со словом,
по которому форма кладёт его в свою группу; код категории срезан из имени;
заявка без исполнителя ложится в ленту «Новой» и требует внимания.
"""

import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import Company, Division, Object, Order, UniversalUser, UserDivision

CONTEXT = f"{settings.API_V1_STR}/work/new/context"
ORDER = f"{settings.API_V1_STR}/order/"
FEED = f"{settings.API_V1_STR}/work/feed"

STATUS_CREATED = 1
STATUS_DONE = 4


def _data(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.fixture
def division(db_session):
    div = Division(title=f"Центр {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


@pytest.fixture
def company(db_session):
    record = Company(name=f"УК «Речная» {uuid.uuid4().hex[:6]}")
    db_session.add(record)
    db_session.flush()
    return record


@pytest.fixture
def mechanic(db_session, division):
    user = UniversalUser(
        name="Механик Ковалёв",
        email=f"mech-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.MECHANIC.value,
        contact_phone="+7 900 000-00-00",
        division_id=division.id,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def client_user(db_session, company):
    user = UniversalUser(
        name="Администрация ТЦ",
        email=f"client-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.CLIENT.value,
        company_id=company.id,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def make_object(db_session, division):
    prefix = uuid.uuid4().hex[:8]
    counter = iter(range(1, 100))

    def _make(mechanic=None, company=None, is_actual=True):
        number = next(counter)
        obj = Object(
            name=f"Лифт {prefix}-{number}",
            address=f"ул. Единая, {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            division_id=division.id,
            mechanic_id=mechanic.id if mechanic else None,
            company_id=company.id if company else None,
            is_actual=is_actual,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def foreman(as_role, db_session, division):
    user = as_role(Role.FOREMAN.value, division_id=division.id)
    db_session.add(UserDivision(user_id=user.id, division_id=division.id))
    db_session.flush()
    return user


def _category(context, code):
    for category in context["categories"]:
        if category["code"] == code:
            return category
    raise AssertionError(f"категории {code} нет в ответе")


# ---------------------------------------------------------------------------
# GET /work/new/context
# ---------------------------------------------------------------------------


def test_context_objects_carry_mechanic_and_section(
    client_with_db, foreman, make_object, mechanic, division
):
    obj = make_object(mechanic=mechanic)
    archived = make_object(is_actual=False)

    context = _data(client_with_db.get(CONTEXT))

    by_id = {o["id"]: o for o in context["objects"]}
    assert obj.id in by_id
    row = by_id[obj.id]
    assert row["mechanic_id"] == mechanic.id
    assert row["mechanic"] == "Механик Ковалёв"
    assert row["section_id"] == division.id
    assert row["section"] == division.title
    assert row["factory_number"] == obj.factory_number
    # Архивный лифт в выборе не предлагается.
    assert archived.id not in by_id
    assert context["my_sections"] == [division.id]
    assert context["author"] == foreman.name


def test_context_client_sees_only_own_company_objects(
    client_with_db, as_role, make_object, company
):
    own = make_object(company=company)
    foreign = make_object()
    as_role(Role.CLIENT.value, company_id=company.id)

    context = _data(client_with_db.get(CONTEXT))

    ids = {o["id"] for o in context["objects"]}
    assert own.id in ids
    assert foreign.id not in ids


def test_context_employees_include_clients_as_customers(
    client_with_db, foreman, mechanic, client_user
):
    context = _data(client_with_db.get(CONTEXT))

    by_id = {e["id"]: e for e in context["employees"]}
    assert mechanic.id in by_id
    assert client_user.id in by_id
    assert by_id[client_user.id]["specialty"] == "Заказчик"

    # В ленте заказчиков по-прежнему нет — назначать на них из строки нельзя.
    feed = _data(client_with_db.get(FEED, params={"limit": 1}))
    assert client_user.id not in {e["id"] for e in feed["employees"]}


def test_context_categories_split_code_from_name(client_with_db, foreman):
    context = _data(client_with_db.get(CONTEXT))

    repair = _category(context, "Р")
    assert repair["name"] == "Ремонт по заявке"
    assert repair["counts_as_breakdown"] is False
    stuck = _category(context, "AA")
    assert stuck["name"] == "Застревание пассажира. Опасность"
    assert stuck["counts_as_breakdown"] is True
    # Сид категорий заявок — весь, от Р до ДР.
    assert {c["code"] for c in context["categories"]} >= {
        "Р",
        "НЛ",
        "ЗЧ",
        "О",
        "ПР",
        "М",
        "УБ",
        "ДОК",
        "ДР",
    }


def test_context_open_works_by_object(
    client_with_db, foreman, make_object, mechanic, db_session
):
    obj = make_object(mechanic=mechanic)
    db_session.add(
        Order(
            object_id=obj.id,
            executor_id=mechanic.id,
            task_text="Не закрывается дверь",
            status_id=STATUS_CREATED,
            is_actual=True,
        )
    )
    db_session.add(Order(object_id=obj.id, task_text="Сделано", status_id=STATUS_DONE))
    db_session.flush()

    context = _data(client_with_db.get(CONTEXT))

    open_works = context["open_works"][str(obj.id)]
    assert [w["title"] for w in open_works] == ["Не закрывается дверь"]
    assert open_works[0]["performer"] == "Механик Ковалёв"
    assert open_works[0]["status"] == "fresh"


def test_context_requires_order_create(client_with_db, as_role):
    as_role(Role.MECHANIC.value)
    assert client_with_db.get(CONTEXT).status_code == 403


# ---------------------------------------------------------------------------
# POST /order/ без исполнителя
# ---------------------------------------------------------------------------


def test_create_order_without_executor_lands_fresh_and_unassigned(
    client_with_db, foreman, make_object
):
    obj = make_object()

    created = _data(
        client_with_db.post(
            ORDER,
            json={
                "object_id": obj.id,
                "fault_category_id": 11,
                "executor_id": None,
                "task_text": "Заменить кнопку вызова",
            },
        )
    )
    assert created["executor_id"] is None
    assert created["creator_id"]["id"] == foreman.id

    feed = _data(client_with_db.get(FEED, params={"search": obj.name}))
    rows = [i for i in feed["items"] if i["work_id"] == created["id"]]
    assert len(rows) == 1
    assert rows[0]["status"] == "fresh"
    assert rows[0]["attention"] == "unassigned"
    assert rows[0]["kind"] == "request"


def test_create_order_with_unknown_executor_is_rejected(
    client_with_db, foreman, make_object
):
    obj = make_object()
    response = client_with_db.post(
        ORDER,
        json={"object_id": obj.id, "fault_category_id": 11, "executor_id": 999999},
    )
    assert 400 <= response.status_code < 500, response.text


def test_create_order_zero_executor_means_nobody(client_with_db, foreman, make_object):
    obj = make_object()
    created = _data(
        client_with_db.post(
            ORDER, json={"object_id": obj.id, "fault_category_id": 11, "executor_id": 0}
        )
    )
    assert created["executor_id"] is None
