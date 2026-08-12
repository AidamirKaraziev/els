"""Метки времени заявки проставляются при смене статуса.

Регрессия: `done_at` не заполнялся никогда. В `crud_order.update_order` при
переходе в статус «Выполнено» присваивался `new_data.dane_at` — опечатка, а
поле с таким именем было и в схеме, поэтому присваивание не падало.
`CRUDBase.update` переносит в модель только те поля, чьи имена совпадают с
колонками, так что значение просто терялось. Молча, без ошибки.

Из-за этого статистика не могла показать время устранения поломки, и вместо
него на главную вывели время реакции.
"""

import datetime
import itertools
import uuid

import pytest

from src.crud.crud_order import crud_orders
from src.models import Object, Order
from src.schemas.order import OrderUpdate
from tests.scopes import ALL_SCOPE

STATUS_ACCEPTED = 2
STATUS_IN_PROGRESS = 3
STATUS_DONE = 4


@pytest.fixture
def order(db_session):
    prefix = uuid.uuid4().hex[:8]
    number = next(itertools.count(1))
    obj = Object(
        name="Лифт для теста",
        factory_number=f"F-{prefix}-{number}",
        registration_number=f"R-{prefix}-{number}",
    )
    db_session.add(obj)
    db_session.flush()

    db_order = Order(
        object_id=obj.id,
        creator_id=1,
        created_at=datetime.datetime(2026, 5, 10, 10, 0),
        fault_category_id=2,
        task_text="проверка меток времени",
    )
    db_session.add(db_order)
    db_session.flush()
    return db_order


def _update(db_session, db_order, status_id):
    obj, code, _ = crud_orders.update_order(
        db=db_session,
        new_data=OrderUpdate(object_id=db_order.object_id, status_id=status_id),
        order_id=db_order.id,
        scope=ALL_SCOPE,
    )
    assert code == 0
    return obj


@pytest.mark.integration
def test_done_at_is_written_when_order_is_closed(db_session, order):
    assert order.done_at is None

    updated = _update(db_session, order, STATUS_DONE)

    assert updated.done_at is not None, (
        "заявка закрыта, а время закрытия не записано — вернулась опечатка dane_at"
    )


@pytest.mark.integration
@pytest.mark.parametrize(
    ("status_id", "field"),
    [
        (STATUS_ACCEPTED, "accepted_at"),
        (STATUS_IN_PROGRESS, "in_progress_at"),
        (STATUS_DONE, "done_at"),
    ],
)
def test_each_status_writes_its_own_timestamp(db_session, order, status_id, field):
    updated = _update(db_session, order, status_id)

    assert getattr(updated, field) is not None


@pytest.mark.integration
def test_closing_does_not_touch_other_timestamps(db_session, order):
    """Закрытие заявки не должно задним числом проставлять «принято»."""
    updated = _update(db_session, order, STATUS_DONE)

    assert updated.accepted_at is None
    assert updated.in_progress_at is None


@pytest.mark.integration
def test_resolution_time_becomes_countable(db_session, order):
    """Ради этого правка и делалась: разницу теперь есть из чего считать."""
    updated = _update(db_session, order, STATUS_DONE)

    assert (updated.done_at - updated.created_at).total_seconds() > 0
