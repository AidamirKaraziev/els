"""Проверка токена на живой ручке.

Здесь закрываются дыры, из-за которых токен работал сам по себе: уволенный
сотрудник ходил по системе до восьми суток, а смена пароля не выкидывала того,
кто украл токен.
"""

from datetime import datetime, timedelta

import pytest

from src.core.roles import Role
from src.core.security import (
    create_access_token,
    generate_refresh_token,
    get_password_hash,
)

# Ручка «мой профиль» — самая дешёвая из закрытых токеном.
ME = "/api/v1/cp/universal-user/me/"


@pytest.fixture
def механик(db_session):
    from src.models import UniversalUser

    user = UniversalUser(
        name="Механик для проверки токена",
        email="token-check@example.ru",
        hashed_password=get_password_hash("надёжный-пароль"),
        role_id=Role.MECHANIC,
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    yield user
    db_session.delete(user)
    db_session.commit()


def _заголовок(token):
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.integration
def test_без_токена_даёт_401_а_не_403(client_with_db):
    # Именно 401: перехватчик на фронте по нему обновляет токен. 403 остаётся
    # за «вошёл, но не положено» — это разные ситуации для клиента.
    assert client_with_db.get(ME).status_code == 401


@pytest.mark.integration
def test_с_токеном_отдаёт_профиль(client_with_db, механик):
    ответ = client_with_db.get(
        ME, headers=_заголовок(create_access_token(user_id=механик.id))
    )
    assert ответ.status_code == 200
    assert ответ.json()["data"]["email"] == механик.email


@pytest.mark.integration
def test_испорченный_токен_даёт_401(client_with_db, механик):
    токен = create_access_token(user_id=механик.id)
    ответ = client_with_db.get(ME, headers=_заголовок(токен[:-3] + "aaa"))
    assert ответ.status_code == 401


@pytest.mark.integration
def test_refresh_токен_не_пускает_в_обычную_ручку(client_with_db):
    ответ = client_with_db.get(ME, headers=_заголовок(generate_refresh_token()))
    assert ответ.status_code == 401


@pytest.mark.integration
def test_токен_удалённого_пользователя_даёт_401(client_with_db, db_session):
    # Пользователя может не быть: токен на руках остался, записи нет.
    ответ = client_with_db.get(
        ME, headers=_заголовок(create_access_token(user_id=10**7))
    )
    assert ответ.status_code == 401


@pytest.mark.integration
def test_архивированный_сотрудник_теряет_доступ_сразу(
    client_with_db, db_session, механик
):
    """Главная дыра: раньше `is_actual` при проверке токена не смотрел никто."""
    токен = create_access_token(user_id=механик.id)
    assert client_with_db.get(ME, headers=_заголовок(токен)).status_code == 200

    механик.is_active = False
    db_session.commit()

    ответ = client_with_db.get(ME, headers=_заголовок(токен))
    assert ответ.status_code == 403


@pytest.mark.integration
def test_смена_пароля_гасит_старые_токены(client_with_db, db_session, механик):
    старый_токен = create_access_token(user_id=механик.id)
    assert client_with_db.get(ME, headers=_заголовок(старый_токен)).status_code == 200

    # Пароль сменили минутой позже выпуска токена.
    механик.password_changed_at = datetime.utcnow() + timedelta(minutes=1)
    db_session.commit()

    assert client_with_db.get(ME, headers=_заголовок(старый_токен)).status_code == 401

    # А выданный после смены — работает.
    новый_токен = create_access_token(user_id=механик.id)
    механик.password_changed_at = datetime.utcnow() - timedelta(minutes=1)
    db_session.commit()
    assert client_with_db.get(ME, headers=_заголовок(новый_токен)).status_code == 200


@pytest.mark.integration
def test_просроченный_токен_даёт_401(client_with_db, механик):
    просроченный = create_access_token(
        user_id=механик.id, expires_delta=timedelta(seconds=-10)
    )
    assert client_with_db.get(ME, headers=_заголовок(просроченный)).status_code == 401


@pytest.mark.integration
def test_require_пускает_по_праву_и_отказывает_без_него(client_with_db, app, механик):
    """Зависимость `require` — то, чего на ручках не было вообще."""
    from fastapi import Depends

    from src.api import deps
    from src.core.permissions import Permission

    @app.get("/__тест__/удалить-пользователя")
    def _только_с_правом(user=Depends(deps.require(Permission.USER_DELETE))):
        return {"ok": True}

    @app.get("/__тест__/читать-заявки")
    def _обычное_право(user=Depends(deps.require(Permission.ORDER_READ))):
        return {"ok": True}

    заголовки = _заголовок(create_access_token(user_id=механик.id))
    # Механик читает заявки, но удалять пользователей не может.
    assert (
        client_with_db.get("/__тест__/читать-заявки", headers=заголовки).status_code
        == 200
    )
    assert (
        client_with_db.get(
            "/__тест__/удалить-пользователя", headers=заголовки
        ).status_code
        == 403
    )
