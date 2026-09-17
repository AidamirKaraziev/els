from pydantic import BaseModel, Field


class DeviceTokenIn(BaseModel):
    """Тело регистрации и снятия токена — одно и то же."""

    token: str = Field(..., min_length=1, max_length=4096, title="Токен FCM")
    platform: str = Field("android", max_length=16, title="Платформа")


class DeviceTokenGet(BaseModel):
    id: int
    user_id: int
    platform: str
