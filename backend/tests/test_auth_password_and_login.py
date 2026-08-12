"""Пароли, вход и защита от перебора.

Проверяется то, чего в системе не было вовсе: регистронезависимый вход,
блокировка после серии неудач, отказ заблокированному сотруднику и
невозможность войти под аккаунтом с принудительно сброшенным паролем.
"""

from datetime import timedelta

import pytest

from src.config import settings
from src.core.security import (
    ACCESS_TOKEN_TYPE,
    InvalidTokenError,
    WeakPasswordError,
    create_access_token,
    decode_access_token,
    generate_refresh_token,
    get_password_hash,
    hash_refresh_token,
    is_password_usable,
    make_unusable_password_hash,
    validate_password_strength,
    verify_password,
)
from src.exceptions import UnprocessableEntity

# --- пароли ---------------------------------------------------------------


def test_password_is_checked_against_its_own_hash():
    hashed = get_password_hash("правильный-пароль")
    assert verify_password("правильный-пароль", hashed)
    assert not verify_password("другой-пароль", hashed)


def test_empty_hash_does_not_raise():
    # В базе есть строки без пароля — раньше такая проверка кидала исключение
    # прямо в обработчике запроса.
    assert not verify_password("что угодно", None)
    assert not verify_password("что угодно", "")


def test_unusable_hash_matches_no_password():
    hashed = make_unusable_password_hash()
    assert not is_password_usable(hashed)
    assert not verify_password("", hashed)
    assert not verify_password("1", hashed)
    assert not verify_password(hashed, hashed)


def test_short_password_is_rejected():
    with pytest.raises(WeakPasswordError):
        validate_password_strength("1")
    with pytest.raises(WeakPasswordError):
        validate_password_strength("a" * (settings.PASSWORD_MIN_LENGTH - 1))
    validate_password_strength("a" * settings.PASSWORD_MIN_LENGTH)


# --- токены ---------------------------------------------------------------


def test_access_token_decodes_back():
    token = create_access_token(user_id=42)
    payload = decode_access_token(token)
    assert payload["sub"] == "42"
    assert payload["type"] == ACCESS_TOKEN_TYPE


def test_tampered_token_is_rejected():
    token = create_access_token(user_id=1)
    with pytest.raises(InvalidTokenError):
        decode_access_token(token[:-3] + "aaa")


def test_expired_token_is_rejected():
    token = create_access_token(user_id=1, expires_delta=timedelta(seconds=-10))
    with pytest.raises(InvalidTokenError):
        decode_access_token(token)


def test_refresh_token_is_not_accepted_as_access():
    # Refresh — не JWT вовсе, подсунуть его в заголовок нельзя.
    with pytest.raises(InvalidTokenError):
        decode_access_token(generate_refresh_token())


def test_refresh_tokens_differ_and_hash_is_stable():
    first, second = generate_refresh_token(), generate_refresh_token()
    assert first != second
    assert hash_refresh_token(first) == hash_refresh_token(first)
    assert hash_refresh_token(first) != hash_refresh_token(second)


# --- вход -----------------------------------------------------------------


@pytest.fixture
def mechanic(db_session):
    from src.core.roles import Role
    from src.models import UniversalUser

    user = UniversalUser(
        name="Тестовый механик",
        email="Mehanik@Example.Ru",
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


def _sign_in(db_session, email, password):
    from src.crud.users.crud_universal_user import crud_universal_users
    from src.schemas.universal_user import UniversalUserEntrance

    return crud_universal_users.authenticate(
        db=db_session,
        entrance_data=UniversalUserEntrance(email=email, password=password),
    )


@pytest.mark.integration
def test_login_ignores_email_case(db_session, mechanic):
    # В боевой базе есть адреса вида `Голдобин@mail.ru`: раньше человек,
    # набравший свой адрес строчными, войти не мог.
    for spelling in ("Mehanik@Example.Ru", "mehanik@example.ru", "MEHANIK@EXAMPLE.RU"):
        assert _sign_in(db_session, spelling, "надёжный-пароль").id == mechanic.id


@pytest.mark.integration
def test_wrong_password_is_rejected(db_session, mechanic):
    with pytest.raises(UnprocessableEntity):
        _sign_in(db_session, mechanic.email, "не тот пароль")


@pytest.mark.integration
def test_unknown_email_gives_the_same_message(db_session, mechanic):
    # Разные тексты превратили бы форму входа в способ узнать, кто заведён.
    try:
        _sign_in(db_session, "нет-такого@example.ru", "пароль")
    except UnprocessableEntity as no_such_user:
        try:
            _sign_in(db_session, mechanic.email, "не тот пароль")
        except UnprocessableEntity as wrong_password:
            assert no_such_user.message == wrong_password.message


@pytest.mark.integration
def test_archived_employee_cannot_log_in(db_session, mechanic):
    mechanic.is_active = False
    db_session.commit()
    with pytest.raises(UnprocessableEntity):
        _sign_in(db_session, mechanic.email, "надёжный-пароль")


@pytest.mark.integration
def test_login_locks_after_failed_attempts(db_session, mechanic):
    for _ in range(settings.LOGIN_MAX_FAILED_ATTEMPTS):
        with pytest.raises(UnprocessableEntity):
            _sign_in(db_session, mechanic.email, "не тот пароль")

    db_session.refresh(mechanic)
    assert mechanic.locked_until is not None

    # Даже правильный пароль теперь не проходит.
    with pytest.raises(UnprocessableEntity) as locked:
        _sign_in(db_session, mechanic.email, "надёжный-пароль")
    assert "заблокирован" in locked.value.description.lower()


@pytest.mark.integration
def test_successful_login_resets_the_counter(db_session, mechanic):
    with pytest.raises(UnprocessableEntity):
        _sign_in(db_session, mechanic.email, "не тот пароль")
    db_session.refresh(mechanic)
    assert mechanic.failed_login_attempts == 1

    _sign_in(db_session, mechanic.email, "надёжный-пароль")
    db_session.refresh(mechanic)
    assert mechanic.failed_login_attempts == 0
    assert mechanic.locked_until is None


@pytest.mark.integration
def test_account_with_reset_password_cannot_log_in(db_session, mechanic):
    # То, что миграция делает с админом, у которого был пароль «1».
    mechanic.hashed_password = make_unusable_password_hash()
    db_session.commit()
    with pytest.raises(UnprocessableEntity):
        _sign_in(db_session, mechanic.email, "надёжный-пароль")
