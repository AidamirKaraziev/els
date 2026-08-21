"""Состояние работы по ТО: пауза и комментарий ко всей работе.

Механик взялся за ТО, приехал аварийный вызов — работу надо приостановить так,
чтобы прораб отличил вставшую работу от идущей прямо сейчас. Это `paused_at`
плюс статус, и обе половины должны доезжать до базы: без даты прораб знает
только «стоит», но не с какого момента.

`commentary` — комментарий ко всей работе, причина проблемы или запись при
закрытии. С комментарием к пункту регламента он не пересекается: тот живёт
внутри чек-листа.
"""

import datetime

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import ActFact, Object, PlannedTO

# Справочник `statuses` засеян данными: 2 — «Принято», 5 — «Проблема».
STATUS_ACCEPTED = 2
STATUS_PROBLEM = 5


@pytest.fixture
def my_act(db_session, as_role):
    """Начатое ТО механика, стоящее в ячейке графика.

    Ячейка нужна не для красоты: список «мои ТО» идёт от графика, и акт без
    планового месяца в него не попадает вовсе.
    """
    mechanic = as_role(Role.MECHANIC.value)
    suffix = datetime.datetime.now().timestamp()
    obj = Object(
        name="Лифт с паузой",
        factory_number=f"F-pause-{suffix}",
        registration_number=f"R-pause-{suffix}",
        mechanic_id=mechanic.id,
    )
    db_session.add(obj)
    db_session.flush()
    act = ActFact(
        object_id=obj.id,
        main_mechanic_id=mechanic.id,
        started_at=datetime.datetime(2026, 8, 21, 9, 30),
    )
    db_session.add(act)
    db_session.flush()

    plan = PlannedTO(year="2026", object_id=obj.id, august_to_id=act.id)
    db_session.add(plan)
    db_session.flush()
    return act


def _put(client, act_id, body):
    return client.put(f"{settings.API_V1_STR}/act-fact/{act_id}/", json=body)


def _seconds(moment):
    return int(moment.replace(tzinfo=datetime.timezone.utc).timestamp())


@pytest.mark.integration
def test_pause_keeps_the_time_of_day(client_with_db, db_session, my_act):
    """Время паузы доживает до базы целиком, а не падает на полночь.

    Та же ошибка когда-то стоила времени закрытия акта: колонка объявлена
    DateTime, и перевод в `date` молча терял час.
    """
    moment = datetime.datetime(2026, 8, 21, 15, 20)

    response = _put(
        client_with_db,
        my_act.id,
        {"paused_at": _seconds(moment), "status_id": STATUS_ACCEPTED},
    )

    assert response.status_code == 200, response.text
    db_session.refresh(my_act)
    assert my_act.paused_at == moment
    assert my_act.status_id == STATUS_ACCEPTED


@pytest.mark.integration
def test_resuming_clears_the_pause(client_with_db, db_session, my_act):
    """Пустой `paused_at` в запросе означает «сбрось», а не «не трогай».

    Обновление идёт с `exclude_unset=True`: не прислали — поле не меняется,
    прислали пустым — очищается. Иначе возобновлённая работа так и осталась бы
    с меткой прошлой паузы, и прораб видел бы стоящую работу там, где её нет.
    """
    my_act.paused_at = datetime.datetime(2026, 8, 21, 15, 20)
    db_session.flush()

    response = _put(client_with_db, my_act.id, {"paused_at": None})

    assert response.status_code == 200, response.text
    db_session.refresh(my_act)
    assert my_act.paused_at is None


@pytest.mark.integration
def test_problem_carries_its_reason(client_with_db, db_session, my_act):
    """Статус «Проблема» без причины прорабу ничего не говорит."""
    response = _put(
        client_with_db,
        my_act.id,
        {"status_id": STATUS_PROBLEM, "commentary": "Нет запчасти на складе"},
    )

    assert response.status_code == 200, response.text
    db_session.refresh(my_act)
    assert my_act.status_id == STATUS_PROBLEM
    assert my_act.commentary == "Нет запчасти на складе"


@pytest.mark.integration
def test_state_comes_back_in_the_maintenance_list(client_with_db, db_session, my_act):
    """Телефон читает состояние из списка ТО, а не из карточки акта.

    Карточку механик открывает по одной, а список — единственное, что у него
    есть без связи; не отдав состояние здесь, мы заставили бы его открывать
    каждое ТО ради ответа «идёт или стоит».
    """
    my_act.paused_at = datetime.datetime(2026, 8, 21, 15, 20)
    my_act.status_id = STATUS_ACCEPTED
    my_act.commentary = "Уехал на аварию"
    db_session.flush()

    response = client_with_db.get(f"{settings.API_V1_STR}/act-fact/for-me")

    assert response.status_code == 200, response.text
    rows = [row for row in response.json()["data"] if row["act_id"] == my_act.id]
    assert len(rows) == 1
    assert rows[0]["paused_at"] == _seconds(my_act.paused_at)
    assert rows[0]["status_id"] == STATUS_ACCEPTED
    assert rows[0]["commentary"] == "Уехал на аварию"
