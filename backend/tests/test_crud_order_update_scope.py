"""Частичная правка заявки не должна упираться в проверку объекта.

Регрессия: телефон механика шлёт `PUT /order/{id}/` только со `status_id` и
комментарием — весь объект заявки в теле ему не нужен. `update_order`
проверяла лифт безусловно, `object_id` приходил `None`, поиск по
`Object.id == None` ничего не находил, и смена статуса отвечала `404`
«объекта с таким id нет». Механик закрывал заявку в подвале, очередь
исходящих получала отказ и показывала «Сервер отклонил действие».

Проверка лифта нужна только тогда, когда заявку **перевешивают** на другой
лифт: без неё её можно было бы перевести на чужой объект и получить к нему
доступ через заявку. Если лифт тот же самый, проверять нечего — доступ к
самой заявке уже проверен выше.
"""

import datetime
import itertools
import uuid

import pytest

from src.core.access import AccessScope, ScopeKind
from src.core.permissions import Role
from src.crud.crud_order import crud_orders
from src.models import Object, Order, UniversalUser
from src.schemas.order import OrderUpdate
from tests.scopes import ALL_SCOPE

STATUS_IN_PROGRESS = 3
STATUS_PROBLEM = 5


def _user(db_session, role):
    user = UniversalUser(
        name="Сотрудник для теста",
        email=f"user-{uuid.uuid4().hex[:8]}@test",
        role_id=role.value,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def mechanic(db_session):
    """Исполнитель заявки. Лифт ведёт не он."""
    return _user(db_session, Role.MECHANIC)


def _object(db_session, **kwargs):
    prefix = uuid.uuid4().hex[:8]
    number = next(itertools.count(1))
    obj = Object(
        name="Лифт для теста",
        factory_number=f"F-{prefix}-{number}",
        registration_number=f"R-{prefix}-{number}",
        **kwargs,
    )
    db_session.add(obj)
    db_session.flush()
    return obj


@pytest.fixture
def foreign_object(db_session):
    """Лифт, который ведёт кто-то другой."""
    return _object(
        db_session,
        mechanic_id=_user(db_session, Role.MECHANIC).id,
        foreman_id=_user(db_session, Role.FOREMAN).id,
    )


@pytest.fixture
def order(db_session, foreign_object, mechanic):
    db_order = Order(
        object_id=foreign_object.id,
        creator_id=1,
        created_at=datetime.datetime(2026, 8, 20, 10, 0),
        fault_category_id=2,
        status_id=STATUS_IN_PROGRESS,
        executor_id=mechanic.id,
        task_text="заявка на чужом лифте",
    )
    db_session.add(db_order)
    db_session.flush()
    return db_order


@pytest.fixture
def mechanic_scope(mechanic):
    return AccessScope(
        kind=ScopeKind.ASSIGNED,
        user_id=mechanic.id,
        division_ids=frozenset(),
        company_id=None,
    )


@pytest.mark.integration
def test_status_changes_without_object_id_in_body(db_session, order):
    """Тело без `object_id` — обычная частичная правка, а не ошибка."""
    obj, code, _ = crud_orders.update_order(
        db=db_session,
        new_data=OrderUpdate(status_id=STATUS_PROBLEM, commentary="не смог"),
        order_id=order.id,
        scope=ALL_SCOPE,
    )

    assert code == 0, "частичная правка ответила ошибкой, хотя лифт не менялся"
    assert obj.status_id == STATUS_PROBLEM
    assert obj.commentary == "не смог"


@pytest.mark.integration
def test_executor_closes_own_order_on_foreign_object(db_session, order, mechanic_scope):
    """Исполнитель закрывает свою заявку, даже если лифт ведёт не он.

    Так работает `can_access_order`: своя заявка видна всегда, иначе механик
    потеряет её при переназначении объекта. Правка статуса обязана слушаться
    того же правила.
    """
    obj, code, _ = crud_orders.update_order(
        db=db_session,
        new_data=OrderUpdate(status_id=STATUS_PROBLEM, commentary="лифт залит"),
        order_id=order.id,
        scope=mechanic_scope,
    )

    assert code == 0, "механик не смог закрыть свою заявку на чужом лифте"
    assert obj.status_id == STATUS_PROBLEM


@pytest.mark.integration
def test_moving_order_to_foreign_object_is_still_denied(
    db_session, order, mechanic_scope
):
    """Перевесить заявку на чужой лифт по-прежнему нельзя."""
    another = _object(
        db_session,
        mechanic_id=_user(db_session, Role.MECHANIC).id,
        foreman_id=_user(db_session, Role.FOREMAN).id,
    )

    obj, code, _ = crud_orders.update_order(
        db=db_session,
        new_data=OrderUpdate(object_id=another.id, status_id=STATUS_PROBLEM),
        order_id=order.id,
        scope=mechanic_scope,
    )

    assert code != 0, "заявку перевесили на чужой лифт"
    assert obj is None
