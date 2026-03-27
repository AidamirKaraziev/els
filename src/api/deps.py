from typing import Generator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, OAuth2PasswordBearer
from jose import jwt
from pydantic import ValidationError
from sqlalchemy.orm import Session

from src import models, schemas
from src.config import settings
from src.core import security
from src.crud.users.crud_universal_user import crud_universal_users
from src.session import SessionLocal

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/login/access-token"
)


def get_db() -> Generator:
    db = None
    try:
        db = SessionLocal()
        yield db
    finally:
        if db is not None:
            db.close()


ALGORITHM = "HS256"
security_1 = HTTPBearer()


def get_current_universal_user_by_bearer(
    db: Session = Depends(get_db), http_credentials=Depends(security_1)
):

    token = http_credentials.credentials
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = schemas.token.TokenPayload(**payload)
    except (jwt.JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        ) from None
    universal_user = crud_universal_users.get(db, id=token_data.sub)
    if not universal_user:
        raise HTTPException(status_code=404, detail="User not found")
    return universal_user


def get_current_universal_user(
    db: Session = Depends(get_db), token: str = Depends()
) -> models.UniversalUser:
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = schemas.token.TokenPayload(**payload)
    except (jwt.JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        ) from None
    universal_user = crud_universal_users.get(db, id=token_data.sub)
    if not universal_user:
        raise HTTPException(status_code=404, detail="User not found")
    return universal_user


def get_current_active_universal_user(
    current_universal_user: models.UniversalUser = Depends(get_current_universal_user),
) -> models.UniversalUser:
    if not crud_universal_users.is_active(current_universal_user):
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_universal_user
