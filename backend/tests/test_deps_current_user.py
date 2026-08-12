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
ME = "/api/v1/auth/me"


@pytest.fixture
def mechanic(db_session):
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


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.integration
def test_missing_token_gives_401_not_403(client_with_db):
    # Именно 401: перехватчик на фронте по нему обновляет токен. 403 остаётся
    # за «вошёл, но не положено» — это разные ситуации для клиента.
    assert client_with_db.get(ME).status_code == 401


@pytest.mark.integration
def test_valid_token_returns_the_profile(client_with_db, mechanic):
    response = client_with_db.get(
        ME, headers=_auth(create_access_token(user_id=mechanic.id))
    )
    assert response.status_code == 200
    assert response.json()["data"]["email"] == mechanic.email


@pytest.mark.integration
def test_tampered_token_gives_401(client_with_db, mechanic):
    token = create_access_token(user_id=mechanic.id)
    assert client_with_db.get(ME, headers=_auth(token[:-3] + "aaa")).status_code == 401


@pytest.mark.integration
def test_refresh_token_is_not_accepted_on_regular_endpoint(client_with_db):
    token = generate_refresh_token()
    assert client_with_db.get(ME, headers=_auth(token)).status_code == 401


@pytest.mark.integration
def test_token_of_deleted_user_gives_401(client_with_db, db_session):
    # Пользователя может не быть: токен на руках остался, записи нет.
    token = create_access_token(user_id=10**7)
    assert client_with_db.get(ME, headers=_auth(token)).status_code == 401


@pytest.mark.integration
def test_archived_employee_loses_access_immediately(
    client_with_db, db_session, mechanic
):
    """Главная дыра: раньше `is_actual` при проверке токена не смотрел никто."""
    token = create_access_token(user_id=mechanic.id)
    assert client_with_db.get(ME, headers=_auth(token)).status_code == 200

    mechanic.is_active = False
    db_session.commit()

    assert client_with_db.get(ME, headers=_auth(token)).status_code == 403


@pytest.mark.integration
def test_password_change_kills_old_tokens(client_with_db, db_session, mechanic):
    """Токен несёт отпечаток пароля и проверяется на точное совпадение.

    Сравнивать времена нельзя: `iat` в JWT округляется до секунды, и вход в ту
    же секунду, что и смена пароля, попадал бы в неоднозначность — либо
    человека не пускает после смены, либо украденный токен её переживает.
    """
    old_token = create_access_token(
        user_id=mechanic.id, password_changed_at=mechanic.password_changed_at
    )
    assert client_with_db.get(ME, headers=_auth(old_token)).status_code == 200

    mechanic.password_changed_at = datetime.utcnow().replace(microsecond=0)
    db_session.commit()

    assert client_with_db.get(ME, headers=_auth(old_token)).status_code == 401

    # Токен, выданный под новый пароль, работает — даже если это та же секунда.
    new_token = create_access_token(
        user_id=mechanic.id, password_changed_at=mechanic.password_changed_at
    )
    assert client_with_db.get(ME, headers=_auth(new_token)).status_code == 200


@pytest.mark.integration
def test_expired_token_gives_401(client_with_db, mechanic):
    expired = create_access_token(
        user_id=mechanic.id, expires_delta=timedelta(seconds=-10)
    )
    assert client_with_db.get(ME, headers=_auth(expired)).status_code == 401


@pytest.mark.integration
def test_require_allows_with_permission_and_denies_without(
    client_with_db, app, mechanic
):
    """Зависимость `require` — то, чего на ручках не было вообще."""
    from fastapi import Depends

    from src.api import deps
    from src.core.permissions import Permission

    @app.get("/__test__/delete-user")
    def _needs_rare_permission(user=Depends(deps.require(Permission.USER_DELETE))):
        return {"ok": True}

    @app.get("/__test__/read-orders")
    def _needs_common_permission(user=Depends(deps.require(Permission.ORDER_READ))):
        return {"ok": True}

    headers = _auth(create_access_token(user_id=mechanic.id))
    # Механик читает заявки, но удалять пользователей не может.
    assert (
        client_with_db.get("/__test__/read-orders", headers=headers).status_code == 200
    )
    assert (
        client_with_db.get("/__test__/delete-user", headers=headers).status_code == 403
    )
