import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Union

from jose import jwt
from passlib.context import CryptContext

from src.config import Settings, settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


ALGORITHM = "HS256"


def create_token(
    subject: Union[str, Any],
    expires_delta: Optional[timedelta] = None,
    token_type: Optional[str] = None,
    nbf: Optional[datetime] = None,
    jti: Optional[str] = None,
    settings: Settings = settings,
    algorithm: str = ALGORITHM,
    **extra_args,
) -> str:

    now = datetime.utcnow()

    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    claim_extra_fields: List[str] = getattr(settings, "TOKEN_CLAIMS_EXTRA_FIELDS", [])

    checkable_fields: List[str] = ["exp", "nbf"]

    for field in checkable_fields:
        if field in settings.TOKEN_CHECKS and field not in claim_extra_fields:
            claim_extra_fields.append(field)

    to_encode: Dict[str, Any] = {"sub": str(subject), **extra_args}

    if "exp" in claim_extra_fields:
        to_encode["exp"] = expire
    if "iat" in claim_extra_fields:
        to_encode["iat"] = now
    if "nbf" in claim_extra_fields:
        to_encode["nbf"] = nbf if nbf is not None else now
    if "jti" in claim_extra_fields:
        to_encode["jti"] = jti if jti is not None else str(uuid.uuid4())

    if token_type is not None:
        to_encode["type"] = token_type
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=algorithm)
    return encoded_jwt


def create_token_universal_user(
    subject: Union[str, Any],
    expires_delta: Optional[timedelta] = None,
    token_type: Optional[str] = None,
    nbf: Optional[datetime] = None,
    jti: Optional[str] = None,
    settings: Settings = settings,
    algorithm: str = ALGORITHM,
    **extra_args,
) -> str:

    now = datetime.utcnow()

    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    claim_extra_fields: List[str] = getattr(settings, "TOKEN_CLAIMS_EXTRA_FIELDS", [])

    checkable_fields: List[str] = ["exp", "nbf"]

    for field in checkable_fields:
        if field in settings.TOKEN_CHECKS and field not in claim_extra_fields:
            claim_extra_fields.append(field)

    to_encode: Dict[str, Any] = {"sub": str(subject), **extra_args}

    if "exp" in claim_extra_fields:
        to_encode["exp"] = expire
    if "iat" in claim_extra_fields:
        to_encode["iat"] = now
    if "nbf" in claim_extra_fields:
        to_encode["nbf"] = nbf if nbf is not None else now
    if "jti" in claim_extra_fields:
        to_encode["jti"] = jti if jti is not None else str(uuid.uuid4())

    if token_type is not None:
        to_encode["type"] = token_type
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=algorithm)
    return encoded_jwt


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)
