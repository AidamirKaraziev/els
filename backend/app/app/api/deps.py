from typing import Generator

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, HTTPBearer
from jose import jwt
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app import crud, models, schemas
from app.core import security
from app.core.config import settings
from app.db.session import SessionLocal


from app.crud.crud_universal_user import crud_universal_users

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
# security_2 = HTTPBearer()


def get_current_universal_user_by_bearer(db: Session = Depends(get_db), http_credentials=Depends(security_1)):

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
        )
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
        )
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

# ORIGINAL 1
# def get_current_user_by_bearer(db: Session = Depends(get_db), http_credentials=Depends(security_1)):
#
#     token = http_credentials.credentials
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.token.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials",
#         )
#     user = crud.user.get(db, id=token_data.sub)
#     if not user:
#         raise HTTPException(status_code=404, detail="User not found")
#     return user

# ORIGINAL 2
# def get_current_user(
#         db: Session = Depends(get_db), token: str = Depends()
# ) -> models.User:
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.token.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials",
#         )
#     user = crud.user.get(db, id=token_data.sub)
#     if not user:
#         raise HTTPException(status_code=404, detail="User not found")
#     return user
#
# ORIGINAL 3
# def get_current_active_user(
#         current_user: models.User = Depends(get_current_user),
# ) -> models.User:
#     if not crud.user.is_active(current_user):
#         raise HTTPException(status_code=400, detail="Inactive user")
#     return current_user


# def get_current_active_superuser(
#         current_user: models.User = Depends(get_current_user),
# ) -> models.User:
#     if not crud.user.is_superuser(current_user):
#         raise HTTPException(
#             status_code=400, detail="The user doesn't have enough privileges"
#         )
#     return current_user

#
# def get_current_moderator(
#         db: Session = Depends(get_db), token: str = Depends()
# ) -> models.Moderator:
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY_MODERATOR, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.token.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials",
#         )
#     moderator = crud_moderator.get(db, id=token_data.sub)
#     if not moderator:
#         raise HTTPException(status_code=404, detail="moderator not found")
#     return moderator
#
#
# def get_current_moderator_by_bearer(db: Session = Depends(get_db), http_credentials=Depends(security_1)):
#
#     token = http_credentials.credentials
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY_MODERATOR, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.token.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials",
#         )
#     moderator = crud_moderator.get(db=db, id=token_data.sub)
#     if not moderator:
#         raise HTTPException(status_code=404, detail="moderator not found")
#     return moderator


# TestUser SuperUser
# def get_current_super_user_by_bearer(db: Session = Depends(get_db), http_credentials=Depends(security_1)):
#
#     token = http_credentials.credentials
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY_MODERATOR, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.token.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials",
#         )
#     super_user = crud_super_users.get(db=db, id=token_data.sub)
#     if not super_user:
#         raise HTTPException(status_code=404, detail="test_user not found")
#     return super_user


# Универсальный токен для входа Механиков
# def get_current_mechanic(
#         db: Session = Depends(get_db), token: str = Depends()
# ) -> models.Mechanic:
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY_MECHANIC, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.token.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials",
#         )
#     mechanic = crud_mechanic.get(db, id=token_data.sub)
#     if not mechanic:
#         raise HTTPException(status_code=404, detail="mechanic not found")
#     return mechanic

#
# def get_current_mechanic_by_bearer(db: Session = Depends(get_db), http_credentials=Depends(security_2)):
#
#     token = http_credentials.credentials
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY_MECHANIC, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.token.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials!!!!!!!!!",
#         )
#     mechanic = crud_mechanic.get(db=db, id=token_data.sub)
#     if not mechanic:
#         raise HTTPException(status_code=404, detail="mechanic not found")
#     return mechanic




# Из старого, возможно норм
# def get_current_user(
#     db: Session = Depends(get_db), token: str = Depends(reusable_oauth2)
# ) -> models.User:
#     try:
#         payload = jwt.decode(
#             token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
#         )
#         token_data = schemas.TokenPayload(**payload)
#     except (jwt.JWTError, ValidationError):
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Could not validate credentials",
#         )
#     user = crud.user.get(db, id=token_data.sub)
#     if not user:
#         raise HTTPException(status_code=404, detail="User not found")
#     return user

#
# reusable_oauth2 = OAuth2PasswordBearer(
#     tokenUrl=f"{settings.API_V1_STR}/login/access-token"
# )
#
#
# def get_db() -> Generator:
#     try:
#         db = SessionLocal()
#         yield db
#     finally:
#         db.close()
#
#

#
# def get_current_active_user(
#     current_user: models.User = Depends(get_current_user),
# ) -> models.User:
#     if not crud.user.is_active(current_user):
#         raise HTTPException(status_code=400, detail="Inactive user")
#     return current_user
#
#
# def get_current_active_superuser(
#     current_user: models.User = Depends(get_current_user),
# ) -> models.User:
#     if not crud.user.is_superuser(current_user):
#         raise HTTPException(
#             status_code=400, detail="The user doesn't have enough privileges"
#         )
#     return current_user
