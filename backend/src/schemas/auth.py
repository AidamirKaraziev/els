from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, validator

from src.config import settings


class LoginRequest(BaseModel):
    # Тип `str`, а не `EmailStr`, намеренно: в базе живут адреса вроде
    # `Голдобин@mail.ru` и `Закора@mai.ru`. Строгая проверка не пустила бы этих
    # людей на вход, хотя их учётные записи рабочие.
    email: str = Field(..., title="Почта")
    password: str = Field(..., title="Пароль")


class TokenPair(BaseModel):
    access_token: str = Field(..., title="Токен доступа")
    refresh_token: str = Field(..., title="Токен обновления")
    token_type: str = Field("bearer", title="Тип токена")
    expires_in: int = Field(
        ..., title="Сколько секунд живёт токен доступа", example=1800
    )


class RefreshRequest(BaseModel):
    refresh_token: str = Field(..., title="Токен обновления")


class _NewPassword(BaseModel):
    new_password: str = Field(..., title="Новый пароль")

    @validator("new_password")
    def _at_least_min_length(cls, value: str) -> str:
        # Тот же порог, что и в `core.security.validate_password_strength`.
        # Здесь он нужен, чтобы отказ приходил разбором тела запроса, с
        # указанием поля, а не общей ошибкой.
        if len(value) < settings.PASSWORD_MIN_LENGTH:
            raise ValueError(
                f"Пароль должен быть не короче {settings.PASSWORD_MIN_LENGTH} символов"
            )
        return value


class PasswordChangeRequest(_NewPassword):
    current_password: str = Field(..., title="Текущий пароль")


class PasswordResetRequest(BaseModel):
    email: str = Field(..., title="Почта")


class PasswordResetConfirm(_NewPassword):
    token: str = Field(..., title="Токен из письма")


class AdminPasswordReset(_NewPassword):
    """Сброс пароля сотруднику администратором."""


class SessionGet(BaseModel):
    id: int
    created_at: datetime
    expires_at: datetime
    user_agent: Optional[str]
    ip_address: Optional[str]
    current: bool = Field(False, title="Это та сессия, из которой пришёл запрос")

    class Config:
        orm_mode = True
