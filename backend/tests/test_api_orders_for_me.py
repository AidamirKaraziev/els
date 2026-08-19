"""Список задач механика: `GET /order/for-me`.

Это главный экран механика в телефоне, и он опрашивается часто. Раньше ручка
отдавала все заявки исполнителя за всё время, без порядка и без страниц —
через год работы это сотни записей в каждом ответе.

Фильтры необязательные, поэтому отдельно закреплено, что без них выдача
остаётся полной: старый клиент не должен заметить правку.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import Object, Order

URL = f"{settings.API_V1_STR}/order/for-me"

STATUS_CREATED = 1
STATUS_IN_PROGRESS = 3
STATUS_DONE = 4
STATUS_PROBLEM = 5


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
def me(as_role):
    """Механик, от лица которого запрашиваем список."""
    return as_role(Role.MECHANIC.value)


@pytest.fixture
def make_order(db_session, make_object):
    def _make(executor, created_at, status_id=STATUS_CREATED, obj=None):
        order = Order(
            object_id=(obj or make_object()).id,
            # Автора проставляем обязательно: в `OrderGet` поле `creator_id`
            # не Optional, и заявка без него роняет всю выдачу с 500.
            creator_id=1,
            executor_id=executor.id,
            created_at=created_at,
            status_id=status_id,
            task_text="проверка",
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


def _mark(dt: datetime.datetime) -> int:
    """Метка так, как её видит и присылает клиент: наивное время в базе — UTC."""
    return int(dt.replace(tzinfo=datetime.timezone.utc).timestamp())


def _ids(response):
    assert response.status_code == 200, response.text
    return [item["id"] for item in response.json()["data"]]


@pytest.mark.integration
def test_returns_only_my_orders(client_with_db, me, as_role, make_order, db_session):
    """Чужая заявка в списке механика не появляется."""
    from src.models import UniversalUser

    someone = UniversalUser(
        name="Другой механик",
        email=f"other-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.MECHANIC.value,
        is_active=True,
    )
    db_session.add(someone)
    db_session.flush()

    mine = make_order(me, datetime.datetime(2026, 5, 2))
    make_order(someone, datetime.datetime(2026, 5, 3))

    assert _ids(client_with_db.get(URL)) == [mine.id]


@pytest.mark.integration
def test_without_params_returns_everything(client_with_db, me, make_order):
    """Старый клиент ходит без параметров и должен видеть всё, как раньше."""
    for day in range(1, 6):
        make_order(me, datetime.datetime(2026, 5, day), status_id=STATUS_DONE)

    body = client_with_db.get(URL).json()

    assert len(body["data"]) == 5
    assert body["meta"]["paginator"] is None, "без page страниц быть не должно"


@pytest.mark.integration
def test_only_open_hides_finished_work(client_with_db, me, make_order):
    """«Выполнено» и «Проблема» механику делать уже нечего."""
    open_order = make_order(me, datetime.datetime(2026, 5, 2))
    in_progress = make_order(me, datetime.datetime(2026, 5, 3), STATUS_IN_PROGRESS)
    make_order(me, datetime.datetime(2026, 5, 4), STATUS_DONE)
    make_order(me, datetime.datetime(2026, 5, 5), STATUS_PROBLEM)

    got = _ids(client_with_db.get(URL, params={"only_open": True}))

    assert sorted(got) == sorted([open_order.id, in_progress.id])


@pytest.mark.integration
def test_order_without_status_counts_as_open(client_with_db, me, make_order):
    """`status_id` в базе обнуляемый, а NOT IN на NULL молча съедает строку.

    Заявка без статуса — это заявка, которую никто не закрывал, и потерять её
    в списке механика нельзя.
    """
    lost = make_order(me, datetime.datetime(2026, 5, 2), status_id=None)

    assert _ids(client_with_db.get(URL, params={"only_open": True})) == [lost.id]


@pytest.mark.integration
def test_filter_by_exact_status(client_with_db, me, make_order):
    wanted = make_order(me, datetime.datetime(2026, 5, 3), STATUS_IN_PROGRESS)
    make_order(me, datetime.datetime(2026, 5, 2), STATUS_CREATED)

    got = _ids(client_with_db.get(URL, params={"status_id": STATUS_IN_PROGRESS}))

    assert got == [wanted.id]


@pytest.mark.integration
def test_filter_by_month(client_with_db, me, make_order):
    wanted = make_order(me, datetime.datetime(2026, 5, 31, 23, 59))
    make_order(me, datetime.datetime(2026, 6, 1, 0, 0))
    make_order(me, datetime.datetime(2026, 4, 30, 23, 59))

    got = _ids(client_with_db.get(URL, params={"year": 2026, "month": 5}))

    assert got == [wanted.id]


@pytest.mark.integration
def test_half_of_the_period_is_rejected(client_with_db, me):
    """Молча игнорировать половину фильтра нельзя — человек не поймёт выдачу."""
    assert client_with_db.get(URL, params={"year": 2026}).status_code == 422


@pytest.mark.integration
def test_pages_cut_the_list(client_with_db, me, make_order):
    for day in range(1, 32):
        make_order(me, datetime.datetime(2026, 5, day))

    body = client_with_db.get(URL, params={"page": 1}).json()

    assert len(body["data"]) == 30, "на странице тридцать записей"
    assert body["meta"]["paginator"]["has_next"] is True
    assert len(client_with_db.get(URL, params={"page": 2}).json()["data"]) == 1


@pytest.mark.integration
def test_newest_first(client_with_db, me, make_order):
    """Механику нужна свежая заявка, а не та, что завели год назад."""
    old = make_order(me, datetime.datetime(2026, 5, 1))
    new = make_order(me, datetime.datetime(2026, 5, 9))

    assert _ids(client_with_db.get(URL)) == [new.id, old.id]


class TestChangedSince:
    """Синхронизация офлайн-клиента.

    Телефон запоминает наибольшую метку из полученных и в следующий раз
    спрашивает только изменившееся. Без этого приложение при каждом выходе на
    связь качало бы весь список заново.
    """

    @pytest.mark.integration
    def test_returns_only_what_changed(
        self, client_with_db, me, make_order, db_session
    ):
        old = make_order(me, datetime.datetime(2026, 5, 1))
        fresh = make_order(me, datetime.datetime(2026, 5, 2))

        # Метку правим руками: в тесте обе записи созданы в одну миллисекунду.
        old.updated_at = datetime.datetime(2026, 5, 1, 10, 0)
        fresh.updated_at = datetime.datetime(2026, 5, 1, 12, 0)
        db_session.flush()

        since = _mark(datetime.datetime(2026, 5, 1, 11, 0))
        got = _ids(client_with_db.get(URL, params={"changed_since": since}))

        assert got == [fresh.id]

    @pytest.mark.integration
    def test_closing_an_order_brings_it_back(
        self, client_with_db, me, make_order, db_session
    ):
        """Закрытие — это изменение, и телефон обязан его увидеть.

        Проверка сторожит договорённость из описания ручки: `changed_since`
        нельзя совмещать с `only_open`, иначе закрытая заявка исчезнет из
        ответа и на телефоне навсегда останется «в работе».
        """
        order = make_order(me, datetime.datetime(2026, 5, 2))
        order.updated_at = datetime.datetime(2026, 5, 2, 10, 0)
        db_session.flush()
        since = _mark(datetime.datetime(2026, 5, 2, 11, 0))

        assert _ids(client_with_db.get(URL, params={"changed_since": since})) == []

        order.status_id = STATUS_DONE
        db_session.flush()

        assert _ids(client_with_db.get(URL, params={"changed_since": since})) == [
            order.id
        ]

    @pytest.mark.integration
    def test_mark_survives_the_round_trip(
        self, client_with_db, me, make_order, db_session
    ):
        """Что клиент получил, то он и присылает обратно — без сдвига.

        Метка и её разбор должны быть строго обратными. Сдвиг на часовой пояс
        в одну сторону заставил бы телефон перекачивать сутки данных, в
        другую — молча терять изменения.
        """
        order = make_order(me, datetime.datetime(2026, 5, 2))
        order.updated_at = datetime.datetime(2026, 5, 2, 10, 30, 15)
        db_session.flush()

        mark = client_with_db.get(URL).json()["data"][0]["updated_at"]

        assert mark == _mark(datetime.datetime(2026, 5, 2, 10, 30, 15))
        assert _ids(client_with_db.get(URL, params={"changed_since": mark})) == [], (
            "по собственной метке заявка второй раз приходить не должна"
        )

    @pytest.mark.integration
    def test_client_gets_the_mark_it_must_send_back(
        self, client_with_db, me, make_order
    ):
        make_order(me, datetime.datetime(2026, 5, 2))

        item = client_with_db.get(URL).json()["data"][0]

        assert item["updated_at"] is not None, (
            "без метки в ответе клиенту нечего прислать в changed_since"
        )


class TestBothMechanicsSeeTheWork:
    """Заявку ведут двое: исполнитель и механик, отвечающий за лифт.

    До этой правки список отдавал заявку только исполнителю, и ответственный
    за лифт узнавал о работе на своём объекте от людей. Отбор идёт по двум
    признакам сразу, поэтому отдельно закреплено, что чужое в список всё ещё
    не попадает и что своё не удваивается.
    """

    @pytest.fixture
    def someone(self, db_session):
        from src.models import UniversalUser

        other = UniversalUser(
            name="Другой механик",
            email=f"other-{uuid.uuid4().hex[:8]}@test",
            role_id=Role.MECHANIC.value,
            is_active=True,
        )
        db_session.add(other)
        db_session.flush()
        return other

    @pytest.mark.integration
    def test_object_mechanic_sees_someone_elses_order(
        self, client_with_db, me, someone, make_object, make_order, db_session
    ):
        """Работает другой, отвечаю за лифт я — заявка обязана быть в списке."""
        obj = make_object()
        obj.mechanic_id = me.id
        db_session.flush()

        order = make_order(someone, datetime.datetime(2026, 5, 2), obj=obj)

        assert _ids(client_with_db.get(URL)) == [order.id]

    @pytest.mark.integration
    def test_someone_elses_object_stays_hidden(
        self, client_with_db, me, someone, make_object, make_order, db_session
    ):
        """Чужой лифт с чужим исполнителем — по-прежнему не моё дело."""
        obj = make_object()
        obj.mechanic_id = someone.id
        db_session.flush()

        make_order(someone, datetime.datetime(2026, 5, 2), obj=obj)

        assert _ids(client_with_db.get(URL)) == []

    @pytest.mark.integration
    def test_being_both_does_not_double_the_order(
        self, client_with_db, me, make_object, make_order, db_session
    ):
        """Исполнитель и ответственный — одно лицо: запись всё равно одна.

        Отбор двумя условиями через `OR` — та самая правка, где `join` по
        объекту вместо подзапроса дал бы вторую строку.
        """
        obj = make_object()
        obj.mechanic_id = me.id
        db_session.flush()

        order = make_order(me, datetime.datetime(2026, 5, 2), obj=obj)

        assert _ids(client_with_db.get(URL)) == [order.id]

    @pytest.mark.integration
    def test_filters_still_apply_to_the_wider_list(
        self, client_with_db, me, someone, make_object, make_order, db_session
    ):
        """Расширение выдачи не отменяет `only_open`."""
        obj = make_object()
        obj.mechanic_id = me.id
        db_session.flush()

        open_order = make_order(someone, datetime.datetime(2026, 5, 2), obj=obj)
        make_order(someone, datetime.datetime(2026, 5, 3), STATUS_DONE, obj=obj)

        got = _ids(client_with_db.get(URL, params={"only_open": True}))

        assert got == [open_order.id]

    @pytest.mark.integration
    def test_sync_brings_the_object_mechanic_orders_too(
        self, client_with_db, me, someone, make_object, make_order, db_session
    ):
        """Офлайн-клиент ответственного тоже должен догонять изменения."""
        obj = make_object()
        obj.mechanic_id = me.id
        db_session.flush()

        order = make_order(someone, datetime.datetime(2026, 5, 2), obj=obj)
        order.updated_at = datetime.datetime(2026, 5, 2, 12, 0)
        db_session.flush()
        since = _mark(datetime.datetime(2026, 5, 2, 11, 0))

        assert _ids(client_with_db.get(URL, params={"changed_since": since})) == [
            order.id
        ]
