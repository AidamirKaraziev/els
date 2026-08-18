"""Мягкое удаление: запись уходит из списков, но доезжает до телефона.

Проверяется не «колонка появилась», а то, ради чего она заводилась. Офлайн-
клиент узнаёт об удалении единственным способом — запись приходит в выдаче по
`changed_since` с `is_actual=false`. Значит обязаны сойтись сразу три вещи:
архивирование двигает `updated_at`, синхронизация не фильтрует по актуальности,
а обычные списки — фильтруют.

Самое хрупкое здесь — метка времени. Пока архивирование делалось массовым
`UPDATE`, `onupdate` не срабатывал, и удаление проходило мимо синхронизации
целиком: на телефоне запись оставалась бы навсегда.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import ActFact, Division, Object, Order, PlannedTO, UserDivision

ORDERS_ALL = f"{settings.API_V1_STR}/order/all"
ORDERS_FOR_ME = f"{settings.API_V1_STR}/order/for-me"
ACTS_ALL = f"{settings.API_V1_STR}/all-acts-fact/"
ACTS_FOR_ME = f"{settings.API_V1_STR}/act-fact/for-me"
PLANNED_ALL = f"{settings.API_V1_STR}/all-planned-to/"
FEED = f"{settings.API_V1_STR}/work/submitted"

STATUS_CREATED = 1
STATUS_DONE = 4


def _archive_order(client, order_id):
    return client.post(f"{settings.API_V1_STR}/order/{order_id}/archive/")


def _restore_order(client, order_id):
    return client.post(f"{settings.API_V1_STR}/order/{order_id}/restore/")


def _mark(dt: datetime.datetime) -> int:
    """Метка так, как её присылает клиент: наивное время в базе — UTC."""
    return int(dt.replace(tzinfo=datetime.timezone.utc).timestamp())


def _items(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


def _ids(response):
    return [item["id"] for item in _items(response)]


@pytest.fixture
def division(db_session):
    div = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


@pytest.fixture
def make_object(db_session, division):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(mechanic=None, div=division):
        number = next(counter)
        obj = Object(
            name=f"Лифт {number}",
            address=f"ул. Удалённая, {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            division_id=div.id if div else None,
            mechanic_id=mechanic.id if mechanic else None,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def make_order(db_session, make_object):
    def _make(executor=None, status_id=STATUS_CREATED, obj=None, done_at=None):
        order = Order(
            object_id=(obj or make_object()).id,
            # Автора проставляем всегда: в `OrderGet` поле обязательное.
            creator_id=1,
            executor_id=executor.id if executor else 1,
            created_at=datetime.datetime(2026, 5, 2),
            done_at=done_at,
            status_id=status_id,
            task_text="проверка",
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


@pytest.fixture
def plan_to(db_session, make_object):
    """Акт в ячейке графика — так же, как его кладёт экран прораба."""
    years = itertools.count(2026)

    def _plan(mechanic=None, finished_at=None, obj=None):
        obj = obj or make_object(mechanic)
        act = ActFact(
            object_id=obj.id,
            main_mechanic_id=mechanic.id if mechanic else None,
            finished_at=finished_at,
        )
        db_session.add(act)
        db_session.flush()

        plan = PlannedTO(year=str(next(years)), object_id=obj.id, may_to_id=act.id)
        db_session.add(plan)
        db_session.flush()
        return act, plan

    return _plan


@pytest.fixture
def admin(as_role):
    return as_role(Role.ADMIN.value)


# ---------------------------------------------------------------------------
# Списки
# ---------------------------------------------------------------------------


@pytest.mark.integration
def test_archived_order_leaves_the_list(client_with_db, admin, make_order):
    """Удалённая заявка не висит вперемешку с живыми."""
    alive = make_order()
    archived = make_order()

    assert _archive_order(client_with_db, archived.id).status_code == 200

    assert _ids(client_with_db.get(ORDERS_ALL)) == [alive.id]


@pytest.mark.integration
def test_archive_view_shows_only_archived(client_with_db, admin, make_order):
    """Архив — отдельный вид, а не примесь к обычному списку."""
    make_order()
    archived = make_order()
    _archive_order(client_with_db, archived.id)

    got = _ids(client_with_db.get(ORDERS_ALL, params={"only_archived": True}))

    assert got == [archived.id]


@pytest.mark.integration
def test_archived_order_still_opens_by_id(client_with_db, admin, make_order):
    """Карточку из архива нужно уметь открыть — иначе её не вернуть обратно."""
    order = make_order()
    _archive_order(client_with_db, order.id)

    response = client_with_db.get(f"{settings.API_V1_STR}/order/{order.id}/")

    assert response.status_code == 200, response.text
    assert response.json()["data"]["is_actual"] is False


@pytest.mark.integration
def test_restore_brings_the_order_back(client_with_db, admin, make_order):
    order = make_order()
    _archive_order(client_with_db, order.id)

    assert _restore_order(client_with_db, order.id).status_code == 200

    assert _ids(client_with_db.get(ORDERS_ALL)) == [order.id]
    assert _ids(client_with_db.get(ORDERS_ALL, params={"only_archived": True})) == []


@pytest.mark.integration
def test_archived_maintenance_leaves_the_lists(client_with_db, admin, plan_to):
    """Акт и график ТО убираются из списков тем же способом."""
    act, plan = plan_to()

    archive = client_with_db.post(
        f"{settings.API_V1_STR}/act-fact/{act.id}/archive/"
    )
    assert archive.status_code == 200, archive.text
    archive = client_with_db.post(
        f"{settings.API_V1_STR}/planned-to/{plan.id}/archive/"
    )
    assert archive.status_code == 200, archive.text

    assert _ids(client_with_db.get(ACTS_ALL)) == []
    assert _ids(client_with_db.get(PLANNED_ALL)) == []
    assert _ids(client_with_db.get(ACTS_ALL, params={"only_archived": True})) == [act.id]
    assert _ids(client_with_db.get(PLANNED_ALL, params={"only_archived": True})) == [
        plan.id
    ]


# ---------------------------------------------------------------------------
# Синхронизация телефона
# ---------------------------------------------------------------------------


@pytest.mark.integration
def test_archiving_moves_the_sync_mark(client_with_db, admin, make_order, db_session):
    """Без сдвига `updated_at` удаление прошло бы мимо синхронизации.

    Это и есть весь смысл мягкого удаления: телефон спрашивает «что менялось
    после T», и заархивированная заявка обязана в этот ответ попасть.
    """
    order = make_order()
    before = order.updated_at

    _archive_order(client_with_db, order.id)
    db_session.refresh(order)

    assert order.updated_at > before


@pytest.mark.integration
def test_sync_returns_archived_orders(client_with_db, as_role, make_order, db_session):
    """`changed_since` отдаёт и удалённые — иначе телефон о них не узнает."""
    from src.core.access import AccessScope, ScopeKind
    from src.crud.crud_order import crud_orders

    mechanic = as_role(Role.MECHANIC.value)
    obj = None
    order = make_order(executor=mechanic, obj=obj)
    # Механик архивировать не вправе, поэтому запись убирает CRUD напрямую —
    # тот же путь, которым ходит ручка прораба.
    crud_orders.archive_order(
        db=db_session,
        order_id=order.id,
        scope=AccessScope(
            kind=ScopeKind.ALL, user_id=0, division_ids=frozenset(), company_id=None
        ),
    )
    since = _mark(order.created_at)

    items = _items(client_with_db.get(ORDERS_FOR_ME, params={"changed_since": since}))

    assert [item["id"] for item in items] == [order.id]
    assert items[0]["is_actual"] is False


@pytest.mark.integration
def test_archived_order_hidden_from_the_phone_list(
    client_with_db, as_role, make_order, db_session
):
    """Без `changed_since` список механика архив не показывает."""
    from src.core.access import AccessScope, ScopeKind
    from src.crud.crud_order import crud_orders

    mechanic = as_role(Role.MECHANIC.value)
    alive = make_order(executor=mechanic)
    archived = make_order(executor=mechanic)
    crud_orders.archive_order(
        db=db_session,
        order_id=archived.id,
        scope=AccessScope(
            kind=ScopeKind.ALL, user_id=0, division_ids=frozenset(), company_id=None
        ),
    )

    assert _ids(client_with_db.get(ORDERS_FOR_ME)) == [alive.id]


@pytest.mark.integration
def test_sync_returns_archived_maintenance(
    client_with_db, as_role, plan_to, db_session
):
    """То же самое для ТО: список чистый, синхронизация полная."""
    from src.core.access import AccessScope, ScopeKind
    from src.crud.crud_act_fact import crud_acts_fact

    mechanic = as_role(Role.MECHANIC.value)
    act, _ = plan_to(mechanic)
    scope = AccessScope(
        kind=ScopeKind.ALL, user_id=0, division_ids=frozenset(), company_id=None
    )
    before = act.updated_at
    crud_acts_fact.archive_act_fact(db=db_session, act_fact_id=act.id, scope=scope)
    db_session.refresh(act)

    assert act.updated_at > before
    assert [item["act_id"] for item in _items(client_with_db.get(ACTS_FOR_ME))] == []

    items = _items(
        client_with_db.get(ACTS_FOR_ME, params={"changed_since": _mark(before)})
    )
    assert [item["act_id"] for item in items] == [act.id]
    assert items[0]["is_actual"] is False


# ---------------------------------------------------------------------------
# Лента сданных работ
# ---------------------------------------------------------------------------


@pytest.fixture
def foreman(as_role, db_session, division):
    user = as_role(Role.FOREMAN.value, division_id=division.id)
    db_session.add(UserDivision(user_id=user.id, division_id=division.id))
    db_session.flush()
    return user


@pytest.mark.integration
def test_archived_work_leaves_the_feed(client_with_db, foreman, make_order, plan_to):
    """Удалённую работу прорабу проверять незачем."""
    order = make_order(status_id=STATUS_DONE, done_at=datetime.datetime(2026, 5, 3))
    act, _ = plan_to(finished_at=datetime.datetime(2026, 5, 4))

    assert len(_items(client_with_db.get(FEED))) == 2

    _archive_order(client_with_db, order.id)
    client_with_db.post(f"{settings.API_V1_STR}/act-fact/{act.id}/archive/")

    assert _items(client_with_db.get(FEED)) == []


@pytest.mark.integration
def test_archived_work_cannot_be_reviewed(client_with_db, foreman, make_order):
    """Отметить «проверил» на удалённой работе нельзя: в ленте её нет."""
    order = make_order(status_id=STATUS_DONE, done_at=datetime.datetime(2026, 5, 3))
    _archive_order(client_with_db, order.id)

    response = client_with_db.post(
        f"{settings.API_V1_STR}/work/breakdown/{order.id}/reviewed/"
    )

    assert response.status_code == 404, response.text


# ---------------------------------------------------------------------------
# Права и область
# ---------------------------------------------------------------------------


@pytest.mark.integration
def test_mechanic_cannot_archive(client_with_db, as_role, make_order):
    """Иначе механик убирал бы заявки, которые не хочется делать."""
    mechanic = as_role(Role.MECHANIC.value)
    order = make_order(executor=mechanic)

    assert _archive_order(client_with_db, order.id).status_code == 403


@pytest.mark.integration
def test_foreman_archives_only_on_his_divisions(
    client_with_db, foreman, make_order, make_object, db_session
):
    """Право есть, но область записи у прораба — его участки."""
    another = Division(title=f"Чужой участок {uuid.uuid4().hex[:6]}")
    db_session.add(another)
    db_session.flush()

    mine = make_order(obj=make_object())
    alien = make_order(obj=make_object(div=another))

    assert _archive_order(client_with_db, mine.id).status_code == 200
    assert _archive_order(client_with_db, alien.id).status_code == 403
