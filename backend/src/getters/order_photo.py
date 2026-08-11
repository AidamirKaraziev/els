from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.static_url import static_base_url
from src.schemas.order_photo import OrderPhotoGet


def getting_order_photo(
    obj: OrderPhotoGet, request: Optional[Request], config: Settings = settings
) -> Optional[OrderPhotoGet]:
    if request is not None:
        url = static_base_url(request, config)
        if obj.photo is not None:
            obj.photo = url + str(obj.photo)
        else:
            obj.photo = None
    return OrderPhotoGet(id=obj.id, order_id=obj.order_id, photo=obj.photo)
