"""Ручки /api/v1/auth: вход, обновление, выход, работа с паролем."""

import pytest

from src.config import settings
from src.core.roles import Role
from src.core.security import (
    create_access_token,
    create_password_reset_token,
    get_password_hash,
)

LOGIN = "/api/v1/auth/login"
REFRESH = "/api/v1/auth/refresh"
LOGOUT = "/api/v1/auth/logout"
LOGOUT_ALL = "/api/v1/auth/logout-all"
ME = "/api/v1/auth/me"
SESSIONS = "/api/v1/auth/sessions"
CHANGE = "/api/v1/auth/password/change"
RESET_REQUEST = "/api/v1/auth/password/reset-request"
RESET_CONFIRM = "/api/v1/auth/password/reset-confirm"

PASSWORD = "надёжный-пароль"


def _make_user(db_session, *, email, role=Role.MECHANIC, password=PASSWORD):
    from src.models import UniversalUser

    user = UniversalUser(
        name="Тестовый пользователь",
        email=email,
        hashed_password=get_password_hash(password),
        role_id=role,
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def mechanic(db_session):
    user = _make_user(db_session, email="auth-mechanic@example.ru")
    yield user
    db_session.delete(user)
    db_session.commit()


@pytest.fixture
def admin(db_session):
    user = _make_user(db_session, email="auth-admin@example.ru", role=Role.ADMIN)
    yield user
    db_session.delete(user)
    db_session.commit()


def _login(client, email, password=PASSWORD):
    return client.post(LOGIN, json={"email": email, "password": password})


def _tokens(response):
    return response.json()["data"]


def _auth(access_token):
    return {"Authorization": f"Bearer {access_token}"}


# --- вход -----------------------------------------------------------------


@pytest.mark.integration
def test_login_returns_a_token_pair(client_with_db, mechanic):
    response = _login(client_with_db, mechanic.email)
    assert response.status_code == 200

    data = _tokens(response)
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0
    # Access и refresh — разные вещи, а не одна строка в двух полях.
    assert data["access_token"] != data["refresh_token"]


@pytest.mark.integration
def test_issued_token_works(client_with_db, mechanic):
    tokens = _tokens(_login(client_with_db, mechanic.email))
    response = client_with_db.get(ME, headers=_auth(tokens["access_token"]))
    assert response.status_code == 200
    assert response.json()["data"]["email"] == mechanic.email


@pytest.mark.integration
def test_login_with_wrong_password_issues_nothing(client_with_db, mechanic):
    response = _login(client_with_db, mechanic.email, "не тот пароль")
    assert response.status_code != 200
    assert "access_token" not in response.text


@pytest.mark.integration
def test_login_creates_a_session(client_with_db, mechanic):
    tokens = _tokens(_login(client_with_db, mechanic.email))
    response = client_with_db.get(SESSIONS, headers=_auth(tokens["access_token"]))
    assert response.status_code == 200
    assert len(response.json()["data"]) == 1


@pytest.mark.integration
def test_two_devices_work_at_once(client_with_db, mechanic):
    """Согласовано с заказчиком: телефон и компьютер живут параллельно."""
    first = _tokens(_login(client_with_db, mechanic.email))
    second = _tokens(_login(client_with_db, mechanic.email))

    for tokens in (first, second):
        assert (
            client_with_db.get(ME, headers=_auth(tokens["access_token"])).status_code
            == 200
        )

    listing = client_with_db.get(SESSIONS, headers=_auth(first["access_token"]))
    assert len(listing.json()["data"]) == 2


# --- обновление -----------------------------------------------------------


@pytest.mark.integration
def test_refresh_returns_a_new_pair(client_with_db, mechanic):
    old = _tokens(_login(client_with_db, mechanic.email))
    response = client_with_db.post(
        REFRESH, json={"refresh_token": old["refresh_token"]}
    )
    assert response.status_code == 200

    new = _tokens(response)
    # Ротация: старый refresh погашен, выдан другой.
    assert new["refresh_token"] != old["refresh_token"]
    assert client_with_db.get(ME, headers=_auth(new["access_token"])).status_code == 200


@pytest.mark.integration
def test_refresh_twice_with_the_same_token_fails(client_with_db, mechanic):
    old = _tokens(_login(client_with_db, mechanic.email))
    client_with_db.post(REFRESH, json={"refresh_token": old["refresh_token"]})

    second_try = client_with_db.post(
        REFRESH, json={"refresh_token": old["refresh_token"]}
    )
    assert second_try.status_code != 200


@pytest.mark.integration
def test_reuse_of_an_old_token_revokes_every_session(
    client_with_db, db_session, mechanic
):
    """Погашенный токен всплыл спустя время — считаем это кражей."""
    from datetime import datetime, timedelta

    from src.crud.crud_refresh_session import REUSE_GRACE_SECONDS, crud_refresh_sessions
    from src.models import RefreshSession

    first = _tokens(_login(client_with_db, mechanic.email))
    client_with_db.post(REFRESH, json={"refresh_token": first["refresh_token"]})

    # Отматываем время отзыва назад, за пределы поблажки на гонку.
    db_session.query(RefreshSession).filter(
        RefreshSession.user_id == mechanic.id,
        RefreshSession.revoked_at.isnot(None),
    ).update(
        {"revoked_at": datetime.utcnow() - timedelta(seconds=REUSE_GRACE_SECONDS + 60)},
        synchronize_session=False,
    )
    db_session.commit()

    response = client_with_db.post(
        REFRESH, json={"refresh_token": first["refresh_token"]}
    )
    assert response.status_code != 200
    assert crud_refresh_sessions.active_for_user(db_session, user_id=mechanic.id) == []


@pytest.mark.integration
def test_made_up_refresh_token_fails(client_with_db):
    assert (
        client_with_db.post(REFRESH, json={"refresh_token": "выдуманный"}).status_code
        != 200
    )


@pytest.mark.integration
def test_archived_employee_cannot_refresh(client_with_db, db_session, mechanic):
    tokens = _tokens(_login(client_with_db, mechanic.email))
    mechanic.is_active = False
    db_session.commit()

    response = client_with_db.post(
        REFRESH, json={"refresh_token": tokens["refresh_token"]}
    )
    assert response.status_code != 200


# --- выход ----------------------------------------------------------------


@pytest.mark.integration
def test_logout_kills_only_that_device(client_with_db, mechanic):
    phone = _tokens(_login(client_with_db, mechanic.email))
    desktop = _tokens(_login(client_with_db, mechanic.email))

    assert (
        client_with_db.post(
            LOGOUT, json={"refresh_token": phone["refresh_token"]}
        ).status_code
        == 200
    )

    # Телефон больше не обновится, компьютер продолжает работать.
    assert (
        client_with_db.post(
            REFRESH, json={"refresh_token": phone["refresh_token"]}
        ).status_code
        != 200
    )
    assert (
        client_with_db.post(
            REFRESH, json={"refresh_token": desktop["refresh_token"]}
        ).status_code
        == 200
    )


@pytest.mark.integration
def test_logout_all_kills_every_device(client_with_db, mechanic):
    phone = _tokens(_login(client_with_db, mechanic.email))
    desktop = _tokens(_login(client_with_db, mechanic.email))

    assert (
        client_with_db.post(
            LOGOUT_ALL, headers=_auth(phone["access_token"])
        ).status_code
        == 200
    )

    for tokens in (phone, desktop):
        assert (
            client_with_db.post(
                REFRESH, json={"refresh_token": tokens["refresh_token"]}
            ).status_code
            != 200
        )


@pytest.mark.integration
def test_logout_with_unknown_token_is_harmless(client_with_db, mechanic):
    # Ответ одинаковый, чтобы выход не стал способом проверять чужие токены.
    assert (
        client_with_db.post(LOGOUT, json={"refresh_token": "чужой-токен"}).status_code
        == 200
    )


# --- смена пароля ---------------------------------------------------------


@pytest.mark.integration
def test_password_change_requires_the_current_one(client_with_db, mechanic):
    tokens = _tokens(_login(client_with_db, mechanic.email))
    response = client_with_db.post(
        CHANGE,
        json={"current_password": "не тот", "new_password": "новый-надёжный"},
        headers=_auth(tokens["access_token"]),
    )
    assert response.status_code != 200


@pytest.mark.integration
def test_short_new_password_is_rejected(client_with_db, mechanic):
    tokens = _tokens(_login(client_with_db, mechanic.email))
    response = client_with_db.post(
        CHANGE,
        json={"current_password": PASSWORD, "new_password": "1234"},
        headers=_auth(tokens["access_token"]),
    )
    # 400, а не 422: в проекте ошибки разбора тела переводит свой обработчик
    # в `src/errors.py`, и весь API отвечает единообразно.
    assert response.status_code == 400
    assert str(settings.PASSWORD_MIN_LENGTH) in response.text


@pytest.mark.integration
def test_password_change_signs_out_every_device(client_with_db, mechanic):
    phone = _tokens(_login(client_with_db, mechanic.email))
    desktop = _tokens(_login(client_with_db, mechanic.email))

    response = client_with_db.post(
        CHANGE,
        json={"current_password": PASSWORD, "new_password": "новый-надёжный"},
        headers=_auth(phone["access_token"]),
    )
    assert response.status_code == 200

    # Смена пароля после кражи токена бессмысленна, если украденный токен
    # продолжает работать. Гасим и сессии, и уже выданные токены доступа.
    for tokens in (phone, desktop):
        assert (
            client_with_db.get(ME, headers=_auth(tokens["access_token"])).status_code
            == 401
        )
        assert (
            client_with_db.post(
                REFRESH, json={"refresh_token": tokens["refresh_token"]}
            ).status_code
            != 200
        )

    # А новый пароль работает.
    assert _login(client_with_db, mechanic.email, "новый-надёжный").status_code == 200


@pytest.mark.integration
def test_login_right_after_password_change_works(client_with_db, mechanic):
    """Вход и смена пароля в одну секунду не должны конфликтовать.

    `iat` в JWT целочисленный и округляется вниз, а `password_changed_at`
    писался с микросекундами — токен, выданный в ту же секунду, считался
    выпущенным раньше смены пароля. Человек входил и тут же получал 401.
    """
    tokens = _tokens(_login(client_with_db, mechanic.email))
    change = client_with_db.post(
        CHANGE,
        json={"current_password": PASSWORD, "new_password": "пароль-сразу-после"},
        headers=_auth(tokens["access_token"]),
    )
    assert change.status_code == 200

    # Вход происходит в ту же секунду, что и смена пароля.
    fresh = _tokens(_login(client_with_db, mechanic.email, "пароль-сразу-после"))
    assert (
        client_with_db.get(ME, headers=_auth(fresh["access_token"])).status_code == 200
    )


@pytest.mark.integration
def test_login_right_after_admin_reset_works(client_with_db, admin, mechanic):
    """Тот же случай, но пароль задаёт администратор."""
    tokens = _tokens(_login(client_with_db, admin.email))
    reset = client_with_db.post(
        f"/api/v1/auth/users/{mechanic.id}/password",
        json={"new_password": "выданный-админом"},
        headers=_auth(tokens["access_token"]),
    )
    assert reset.status_code == 200

    fresh = _tokens(_login(client_with_db, mechanic.email, "выданный-админом"))
    assert (
        client_with_db.get(ME, headers=_auth(fresh["access_token"])).status_code == 200
    )


# --- сброс пароля ---------------------------------------------------------


@pytest.mark.integration
def test_reset_request_does_not_reveal_who_exists(client_with_db, mechanic):
    known = client_with_db.post(RESET_REQUEST, json={"email": mechanic.email})
    unknown = client_with_db.post(
        RESET_REQUEST, json={"email": "нет-такого@example.ru"}
    )
    assert known.status_code == unknown.status_code == 200
    assert known.json()["description"] == unknown.json()["description"]


@pytest.mark.integration
def test_reset_link_sets_a_new_password(client_with_db, mechanic):
    token = create_password_reset_token(user_id=mechanic.id)
    response = client_with_db.post(
        RESET_CONFIRM, json={"token": token, "new_password": "пароль-из-письма"}
    )
    assert response.status_code == 200
    assert _login(client_with_db, mechanic.email, "пароль-из-письма").status_code == 200


@pytest.mark.integration
def test_reset_link_works_only_once(client_with_db, mechanic):
    """Одноразовость держится на отпечатке пароля, без отдельной таблицы."""
    token = create_password_reset_token(user_id=mechanic.id)
    client_with_db.post(
        RESET_CONFIRM, json={"token": token, "new_password": "пароль-из-письма"}
    )

    second_try = client_with_db.post(
        RESET_CONFIRM, json={"token": token, "new_password": "ещё-один-пароль"}
    )
    assert second_try.status_code != 200
    # Второй пароль не применился.
    assert _login(client_with_db, mechanic.email, "ещё-один-пароль").status_code != 200


@pytest.mark.integration
def test_access_token_cannot_reset_a_password(client_with_db, mechanic):
    # Иначе укравший токен доступа менял бы пароль, не зная старого.
    response = client_with_db.post(
        RESET_CONFIRM,
        json={
            "token": create_access_token(user_id=mechanic.id),
            "new_password": "чужой-пароль",
        },
    )
    assert response.status_code != 200


# --- сброс админом --------------------------------------------------------


@pytest.mark.integration
def test_admin_resets_employee_password(client_with_db, admin, mechanic):
    tokens = _tokens(_login(client_with_db, admin.email))
    response = client_with_db.post(
        f"/api/v1/auth/users/{mechanic.id}/password",
        json={"new_password": "выданный-админом"},
        headers=_auth(tokens["access_token"]),
    )
    assert response.status_code == 200
    assert _login(client_with_db, mechanic.email, "выданный-админом").status_code == 200


@pytest.mark.integration
def test_mechanic_cannot_reset_someone_elses_password(client_with_db, mechanic, admin):
    tokens = _tokens(_login(client_with_db, mechanic.email))
    response = client_with_db.post(
        f"/api/v1/auth/users/{admin.id}/password",
        json={"new_password": "захваченный-аккаунт"},
        headers=_auth(tokens["access_token"]),
    )
    assert response.status_code == 403
    assert _login(client_with_db, admin.email, "захваченный-аккаунт").status_code != 200
