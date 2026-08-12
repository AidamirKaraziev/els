"""Пароли, вход и защита от перебора.

Проверяется то, чего в системе не было вовсе: регистронезависимый вход,
блокировка после серии неудач, отказ заблокированному сотруднику и
невозможность войти под аккаунтом с принудительно сброшенным паролем.
"""

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


def test_пароль_проверяется_по_своему_хешу():
    hashed = get_password_hash("правильный-пароль")
    assert verify_password("правильный-пароль", hashed)
    assert not verify_password("другой-пароль", hashed)


def test_проверка_пароля_не_падает_на_пустом_хеше():
    # В базе есть строки без пароля — раньше такая проверка кидала исключение
    # прямо в обработчике запроса.
    assert not verify_password("что угодно", None)
    assert not verify_password("что угодно", "")


def test_невозможный_хеш_не_подходит_ни_к_какому_паролю():
    hashed = make_unusable_password_hash()
    assert not is_password_usable(hashed)
    assert not verify_password("", hashed)
    assert not verify_password("1", hashed)
    assert not verify_password(hashed, hashed)


def test_короткий_пароль_не_принимается():
    with pytest.raises(WeakPasswordError):
        validate_password_strength("1")
    with pytest.raises(WeakPasswordError):
        validate_password_strength("a" * (settings.PASSWORD_MIN_LENGTH - 1))
    validate_password_strength("a" * settings.PASSWORD_MIN_LENGTH)


# --- токены ---------------------------------------------------------------


def test_access_токен_разбирается_обратно():
    token = create_access_token(user_id=42)
    payload = decode_access_token(token)
    assert payload["sub"] == "42"
    assert payload["type"] == ACCESS_TOKEN_TYPE


def test_испорченный_токен_не_проходит():
    token = create_access_token(user_id=1)
    with pytest.raises(InvalidTokenError):
        decode_access_token(token[:-3] + "aaa")


def test_просроченный_токен_не_проходит():
    from datetime import timedelta

    token = create_access_token(user_id=1, expires_delta=timedelta(seconds=-10))
    with pytest.raises(InvalidTokenError):
        decode_access_token(token)


def test_refresh_токен_не_принимается_вместо_access():
    # Refresh — не JWT вовсе, подсунуть его в заголовок нельзя.
    with pytest.raises(InvalidTokenError):
        decode_access_token(generate_refresh_token())


def test_refresh_токены_разные_и_хеш_повторяем():
    first, second = generate_refresh_token(), generate_refresh_token()
    assert first != second
    assert hash_refresh_token(first) == hash_refresh_token(first)
    assert hash_refresh_token(first) != hash_refresh_token(second)


# --- вход -----------------------------------------------------------------


@pytest.fixture
def пользователь(db_session):
    from src.core.roles import MECHANIC
    from src.models import UniversalUser

    user = UniversalUser(
        name="Тестовый механик",
        email="Mehanik@Example.Ru",
        hashed_password=get_password_hash("надёжный-пароль"),
        role_id=MECHANIC,
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    yield user
    db_session.delete(user)
    db_session.commit()


def _войти(db_session, email, password):
    from src.crud.users.crud_universal_user import crud_universal_users
    from src.schemas.universal_user import UniversalUserEntrance

    return crud_universal_users.authenticate(
        db=db_session,
        entrance_data=UniversalUserEntrance(email=email, password=password),
    )


@pytest.mark.integration
def test_вход_не_зависит_от_регистра_email(db_session, пользователь):
    # В боевой базе есть адреса вида `Голдобин@mail.ru`: раньше человек,
    # набравший свой адрес строчными, войти не мог.
    for написание in ("Mehanik@Example.Ru", "mehanik@example.ru", "MEHANIK@EXAMPLE.RU"):
        assert _войти(db_session, написание, "надёжный-пароль").id == пользователь.id


@pytest.mark.integration
def test_неверный_пароль_не_пускает(db_session, пользователь):
    with pytest.raises(UnprocessableEntity):
        _войти(db_session, пользователь.email, "не тот пароль")


@pytest.mark.integration
def test_несуществующий_email_отвечает_тем_же_текстом(db_session, пользователь):
    # Разные тексты превратили бы форму входа в способ узнать, кто заведён.
    try:
        _войти(db_session, "нет-такого@example.ru", "пароль")
    except UnprocessableEntity as нет_пользователя:
        try:
            _войти(db_session, пользователь.email, "не тот пароль")
        except UnprocessableEntity as неверный_пароль:
            assert нет_пользователя.message == неверный_пароль.message


@pytest.mark.integration
def test_заблокированный_сотрудник_не_входит(db_session, пользователь):
    пользователь.is_active = False
    db_session.commit()
    with pytest.raises(UnprocessableEntity):
        _войти(db_session, пользователь.email, "надёжный-пароль")


@pytest.mark.integration
def test_после_серии_неудач_вход_блокируется(db_session, пользователь):
    for _ in range(settings.LOGIN_MAX_FAILED_ATTEMPTS):
        with pytest.raises(UnprocessableEntity):
            _войти(db_session, пользователь.email, "не тот пароль")

    db_session.refresh(пользователь)
    assert пользователь.locked_until is not None

    # Даже правильный пароль теперь не проходит.
    with pytest.raises(UnprocessableEntity) as заблокировано:
        _войти(db_session, пользователь.email, "надёжный-пароль")
    assert "заблокирован" in заблокировано.value.description.lower()


@pytest.mark.integration
def test_удачный_вход_обнуляет_счётчик_неудач(db_session, пользователь):
    with pytest.raises(UnprocessableEntity):
        _войти(db_session, пользователь.email, "не тот пароль")
    db_session.refresh(пользователь)
    assert пользователь.failed_login_attempts == 1

    _войти(db_session, пользователь.email, "надёжный-пароль")
    db_session.refresh(пользователь)
    assert пользователь.failed_login_attempts == 0
    assert пользователь.locked_until is None


@pytest.mark.integration
def test_аккаунт_со_сброшенным_паролем_не_пускает(db_session, пользователь):
    # То, что миграция делает с админом, у которого был пароль «1».
    пользователь.hashed_password = make_unusable_password_hash()
    db_session.commit()
    with pytest.raises(UnprocessableEntity):
        _войти(db_session, пользователь.email, "надёжный-пароль")
