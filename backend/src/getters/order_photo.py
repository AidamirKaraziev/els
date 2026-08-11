from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.schemas.order_photo import OrderPhotoGet


def getting_order_photo(
    obj: OrderPhotoGet, request: Optional[Request], config: Settings = settings
) -> Optional[OrderPhotoGet]:
    if request is not None:
        url = (
            request.url.hostname
            + ":"
            + str(settings.APP_PORT)
            + config.API_V1_STR
            + "/static/"
        )
        if obj.photo is not None:
            obj.photo = url + str(obj.photo)
        else:
            obj.photo = None
    return OrderPhotoGet(id=obj.id, order_id=obj.order_id, photo=obj.photo)
