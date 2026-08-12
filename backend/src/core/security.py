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


def create_access_token(user_id: int, expires_delta: Optional[timedelta] = None) -> str:
    """JWT с идентификатором пользователя.

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


def token_issued_at(payload: dict) -> datetime:
    """Момент выпуска токена — нужен, чтобы гасить токены при смене пароля."""
    return datetime.utcfromtimestamp(payload["iat"])


# --- refresh-токен --------------------------------------------------------


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(REFRESH_TOKEN_BYTES)


def hash_refresh_token(token: str) -> str:
    """SHA-256 в hex — то, что хранится в базе вместо самого токена.

    Здесь не bcrypt: токен и так случайный, растягивать его незачем, а искать
    сессию по хешу надо одним индексированным запросом.
    """
    return hashlib.sha256(token.encode()).hexdigest()
