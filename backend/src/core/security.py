"""Пароли и токены.

Здесь только криптография и формат токенов — ни базы, ни HTTP. Проверка
пользователя живёт в `src/api/deps.py`, работа с сессиями — в
`src/crud/crud_refresh_session.py`.

Токенов два вида, и они устроены по-разному намеренно:

* **access** — JWT, живёт минуты, в базу за самим токеном не ходим;
* **refresh** — случайная строка, в базе лежит только её SHA-256. Утечка дампа
  не даёт возможности войти, а отзыв работает по-настоящему, а не «до
  истечения срока».
"""

import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from src.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"

ACCESS_TOKEN_TYPE = "access"
PASSWORD_RESET_TOKEN_TYPE = "password_reset"
FILE_TOKEN_TYPE = "file"

# Столько байт случайности в refresh-токене. 48 байт — 64 символа в
# url-safe base64, перебору не поддаётся.
REFRESH_TOKEN_BYTES = 48


class InvalidTokenError(Exception):
    """Токен не разобран: подпись, срок или не тот тип."""


class WeakPasswordError(ValueError):
    """Пароль не проходит по требованиям."""


# --- пароли ---------------------------------------------------------------


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: Optional[str]) -> bool:
    """Проверяет пароль, не падая на пустом и на невозможном хеше.

    `hashed_password` может быть `None` (данные из старой базы) или строкой,
    которая заведомо не хеш — так помечены аккаунты с принудительным сбросом.
    В обоих случаях ответ «нет», а не исключение.
    """
    if not hashed_password:
        return False
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except ValueError:
        # passlib кидает ValueError на строке, которую не смог разобрать как
        # хеш. Для нас это просто «пароль не подошёл».
        return False


def make_unusable_password_hash() -> str:
    """Хеш, под который не подходит ни один пароль.

    Ставится аккаунтам с принудительным сбросом: войти нельзя, но сама учётная
    запись жива и все связи с заявками и актами целы. Восклицательный знак в
    начале не встречается в bcrypt-хешах, поэтому такие строки видно глазами.
    """
    return "!" + secrets.token_urlsafe(32)


def is_password_usable(hashed_password: Optional[str]) -> bool:
    return bool(hashed_password) and not hashed_password.startswith("!")


def validate_password_strength(password: str) -> None:
    """Кидает `WeakPasswordError`, если пароль короче минимума.

    Вызывается при задании нового пароля. Существующие пароли не трогаем:
    проверка на входе выкинула бы из системы половину пользователей.
    """
    if len(password) < settings.PASSWORD_MIN_LENGTH:
        raise WeakPasswordError(
            f"Пароль короче {settings.PASSWORD_MIN_LENGTH} символов"
        )


# --- access-токен ---------------------------------------------------------


def password_stamp(password_changed_at: Optional[datetime]) -> str:
    """Отпечаток текущего пароля — метка, меняющаяся при каждой смене.

    Кладётся в токен и сверяется **на точное совпадение**. Сравнивать времена
    («токен выпущен раньше смены пароля») нельзя: `iat` в JWT целочисленный и
    округляется вниз, поэтому вход в ту же секунду, что и смена пароля, попадал
    бы в неоднозначность. Либо человек не может войти после смены пароля, либо
    украденный токен переживает её — в зависимости от того, в какую сторону
    округлить. Точное равенство убирает вопрос целиком.
    """
    if password_changed_at is None:
        return "0"
    return str(int(password_changed_at.timestamp()))


def create_access_token(
    user_id: int,
    password_changed_at: Optional[datetime] = None,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """JWT с идентификатором пользователя и отпечатком его пароля.

    Роль в токен намеренно не кладём. Права всё равно считаются по свежей
    строке пользователя — иначе повышение или понижение в должности доезжало
    бы до системы только после перевыпуска токена.
    """
    now = datetime.utcnow()
    expire = now + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload = {
        "sub": str(user_id),
        "type": ACCESS_TOKEN_TYPE,
        "pwd": password_stamp(password_changed_at),
        "iat": now,
        "exp": expire,
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Разбирает access-токен. Кидает `InvalidTokenError` на всём подозрительном."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise InvalidTokenError(str(exc)) from exc

    if payload.get("type") != ACCESS_TOKEN_TYPE:
        # Иначе refresh-токеном можно было бы ходить по обычным ручкам.
        raise InvalidTokenError("Ожидался токен доступа")
    if payload.get("sub") is None:
        raise InvalidTokenError("В токене нет идентификатора пользователя")
    return payload


def token_matches_password(
    payload: dict, password_changed_at: Optional[datetime]
) -> bool:
    """Выпущен ли токен под тот пароль, который стоит сейчас.

    У токенов, выпущенных до появления отпечатка, поля `pwd` нет — такие не
    проходят. При выкате все и так входят заново.
    """
    return payload.get("pwd") == password_stamp(password_changed_at)


# --- токен сброса пароля --------------------------------------------------


def create_password_reset_token(
    user_id: int, password_changed_at: Optional[datetime] = None
) -> str:
    """Токен для ссылки «забыли пароль».

    Отдельной таблицы под него нет намеренно: одноразовость даёт тот же
    отпечаток пароля. Ссылкой воспользовались — пароль сменился — отпечаток
    в токене больше не совпадает с текущим, и повторно ссылка не сработает.
    """
    now = datetime.utcnow()
    payload = {
        "sub": str(user_id),
        "type": PASSWORD_RESET_TOKEN_TYPE,
        "pwd": password_stamp(password_changed_at),
        "iat": now,
        "exp": now + timedelta(hours=settings.PASSWORD_RESET_TOKEN_EXPIRE_HOURS),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)


def decode_password_reset_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise InvalidTokenError(str(exc)) from exc

    if payload.get("type") != PASSWORD_RESET_TOKEN_TYPE:
        # Иначе обычным токеном доступа можно было бы менять пароль без знания
        # старого.
        raise InvalidTokenError("Ожидался токен сброса пароля")
    if payload.get("sub") is None:
        raise InvalidTokenError("В токене нет идентификатора пользователя")
    return payload


# --- токен на скачивание файла --------------------------------------------


def create_file_token(user_id: int, path: str) -> str:
    """Токен для ссылки, которую можно открыть в новой вкладке.

    `path` — полный путь запроса (`/api/v1/static/objects/12/...` или
    `/api/v1/statistics/breakdowns/export`), а не только имя файла: тогда одна
    и та же ссылка работает и для загруженных файлов, и для собираемых на
    лету выгрузок.

    Нужен потому, что заголовок `Authorization` браузер отправить не может ни
    в `<img src>`, ни при переходе по ссылке на скачивание. Токен кладётся в
    адрес — со всеми вытекающими: он попадёт в журнал доступа nginx, в историю
    браузера и в `Referer`. Отсюда два ограничения.

    **Он привязан к одному пути.** Утёкшая ссылка открывает ровно этот файл,
    а не всю систему: боевым токеном доступа она не является и другие ручки ей
    не открыть.

    **Он живёт секунды.** К моменту, когда журнал кто-то прочитает, токен уже
    мёртв. Строго одноразовым его не делаем: одноразовость требует состояния
    на сервере (таблица использованных токенов плюс её чистка), а против
    журнала помогает ровно так же, как короткий срок.
    """
    now = datetime.utcnow()
    payload = {
        "sub": str(user_id),
        "type": FILE_TOKEN_TYPE,
        "path": path,
        "iat": now,
        "exp": now + timedelta(seconds=settings.FILE_TOKEN_EXPIRE_SECONDS),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)


def decode_file_token(token: str, path: str) -> dict:
    """Разбирает токен и сверяет, что он выдан **на этот** путь запроса."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise InvalidTokenError(str(exc)) from exc

    if payload.get("type") != FILE_TOKEN_TYPE:
        # Иначе боевым токеном доступа можно было бы ходить по адресам с
        # `?token=`, то есть светить его в журналах и в истории браузера.
        raise InvalidTokenError("Ожидался токен на скачивание файла")
    if payload.get("sub") is None:
        raise InvalidTokenError("В токене нет идентификатора пользователя")
    if payload.get("path") != path:
        raise InvalidTokenError("Токен выдан на другой файл")
    return payload


# --- refresh-токен --------------------------------------------------------


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(REFRESH_TOKEN_BYTES)


def hash_refresh_token(token: str) -> str:
    """SHA-256 в hex — то, что хранится в базе вместо самого токена.

    Здесь не bcrypt: токен и так случайный, растягивать его незачем, а искать
    сессию по хешу надо одним индексированным запросом.
    """
    return hashlib.sha256(token.encode()).hexdigest()
