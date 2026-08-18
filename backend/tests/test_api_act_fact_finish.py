"""Закрытие фактического акта: дата окончания и статус.

Обе проверки защищают виджет «Выполнение графика»: он считает выполненным ТО
акт с заполненным `finished_at`, и если закрытие не доезжает до базы, участок
выглядит проваленным при сделанной работе.
"""

import datetime

import pytest

from src.config import settings
from src.core.roles import ADMIN, Role
from src.models import ActFact, Object

# Справочник `statuses` засеян данными: 4 — «Выполнено».
STATUS_DONE = 4


@pytest.fixture
def act(db_session):
    obj = Object(
        name="Лифт для акта",
        factory_number=f"F-act-{datetime.datetime.now().timestamp()}",
        registration_number=f"R-act-{datetime.datetime.now().timestamp()}",
    )
    db_session.add(obj)
    db_session.flush()
    act_fact = ActFact(object_id=obj.id)
    db_session.add(act_fact)
    db_session.flush()
    return act_fact


def _put(client, act_id, body):
    return client.put(f"{settings.API_V1_STR}/act-fact/{act_id}/", json=body)


@pytest.mark.integration
def test_finished_at_keeps_the_time_of_day(client_with_db, as_role, db_session, act):
    """Колонка объявлена DateTime, и время в ней должно доживать до базы.

    Раньше метка переводилась в `date`, и любое закрытие акта падало на
    полночь UTC — вместе с ним терялась разница между «закрыли до конца
    месяца» и «закрыли первого числа следующего».
    """
    as_role(ADMIN)
    moment = datetime.datetime(2026, 5, 31, 21, 40)

    response = _put(
        client_with_db,
        act.id,
        {"finished_at": int(moment.replace(tzinfo=datetime.timezone.utc).timestamp())},
    )

    assert response.status_code == 200
    db_session.refresh(act)
    assert act.finished_at == moment


@pytest.mark.integration
def test_status_done_is_applied(client_with_db, as_role, db_session, act):
    as_role(ADMIN)

    response = _put(client_with_db, act.id, {"status_id": STATUS_DONE})

    assert response.status_code == 200
    db_session.refresh(act)
    assert act.status_id == STATUS_DONE


@pytest.mark.integration
def test_unknown_status_is_rejected_not_ignored(client_with_db, as_role, db_session, act):
    """Ноль — существующий id в чужих справочниках, и молча глотать его нельзя.

    Проверка стояла на истинности значения, поэтому `status_id: 0` не менял
    ничего и не сообщал об этом. Фронт годами слал именно ноль.
    """
    as_role(ADMIN)
    before = act.status_id

    response = _put(client_with_db, act.id, {"status_id": 0})

    assert response.status_code >= 400
    db_session.refresh(act)
    assert act.status_id == before


@pytest.fixture
def my_act(db_session, as_role):
    """ТО, назначенное на механика: он привязан к акту через `main_mechanic_id`."""
    mechanic = as_role(Role.MECHANIC.value)
    suffix = datetime.datetime.now().timestamp()
    obj = Object(
        name="Лифт механика",
        factory_number=f"F-mech-{suffix}",
        registration_number=f"R-mech-{suffix}",
        mechanic_id=mechanic.id,
    )
    db_session.add(obj)
    db_session.flush()
    act_fact = ActFact(object_id=obj.id, main_mechanic_id=mechanic.id)
    db_session.add(act_fact)
    db_session.flush()
    return act_fact


@pytest.mark.integration
def test_mechanic_closes_his_own_maintenance(client_with_db, db_session, my_act):
    """ТО закрывает механик — на этом держится вся цифра выполнения графика.

    Право `ACT_UPDATE` у него есть с прежних работ, а область пускает к своим
    актам по `main_mechanic_id`. Проверка нужна именно живой ручкой: до неё
    закрытие проверялось только админом, у которого область не ограничена
    вовсе, и запрет механику остался бы незамеченным.
    """
    moment = datetime.datetime(2026, 5, 20, 14, 15)

    response = _put(
        client_with_db,
        my_act.id,
        {
            "finished_at": int(
                moment.replace(tzinfo=datetime.timezone.utc).timestamp()
            ),
            "status_id": STATUS_DONE,
        },
    )

    assert response.status_code == 200, response.text
    db_session.refresh(my_act)
    assert my_act.finished_at == moment
    assert my_act.status_id == STATUS_DONE


@pytest.mark.integration
def test_mechanic_does_not_close_someone_elses_maintenance(
    client_with_db, db_session, act, as_role
):
    """Чужое ТО закрыть нельзя: иначе участок закрывался бы кем угодно."""
    as_role(Role.MECHANIC.value)

    response = _put(client_with_db, act.id, {"status_id": STATUS_DONE})

    assert response.status_code == 403, response.text
    db_session.refresh(act)
    assert act.finished_at is None
