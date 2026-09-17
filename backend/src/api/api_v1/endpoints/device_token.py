"""Регистрация телефона для push.

Приложение получает токен у FCM после входа и отдаёт его сюда; при выходе —
снимает. Без токена push по заявкам этому человеку просто не уходит, всё
остальное работает как прежде. Список токенов наружу не отдаётся: это адреса
чужих телефонов.
"""

from fastapi import APIRouter, Depends

from src.api import deps
from src.core.response import SingleEntityResponse
from src.crud import crud_device_token
from src.schemas.device_token import DeviceTokenGet, DeviceTokenIn

router = APIRouter()


@router.post(
    "/device-token/",
    response_model=SingleEntityResponse[DeviceTokenGet],
    name="register_device_token",
    summary="Зарегистрировать телефон для push",
    description=(
        "Приложение зовёт после входа и при каждом обновлении токена FCM. "
        "Повтор с тем же токеном ничего не плодит; токен, пришедший под другим "
        "пользователем, перевешивается на него — телефон сменил хозяина."
    ),
    tags=["Мобильное приложение"],
)
def register_device_token(
    data: DeviceTokenIn,
    current_user=Depends(deps.get_current_user),
    session=Depends(deps.get_db),
):
    record = crud_device_token.upsert(
        session, user_id=current_user.id, token=data.token, platform=data.platform
    )
    return SingleEntityResponse(
        data=DeviceTokenGet(
            id=record.id, user_id=record.user_id, platform=record.platform
        )
    )


@router.delete(
    "/device-token/",
    response_model=SingleEntityResponse[bool],
    name="unregister_device_token",
    summary="Снять телефон с push",
    description=(
        "Приложение зовёт при выходе: после него задачи этого человека на "
        "телефон приходить не должны. `data: false` — такого токена за "
        "пользователем не было."
    ),
    tags=["Мобильное приложение"],
)
def unregister_device_token(
    data: DeviceTokenIn,
    current_user=Depends(deps.get_current_user),
    session=Depends(deps.get_db),
):
    deleted = crud_device_token.delete(
        session, user_id=current_user.id, token=data.token
    )
    return SingleEntityResponse(data=deleted)
