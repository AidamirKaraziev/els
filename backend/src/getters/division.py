from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.static_url import static_base_url
from src.models import Division
from src.schemas.divisions import DivisionGet


def get_division(
    obj: Division, request: Optional[Request], config: Settings = settings
) -> Optional[DivisionGet]:
    if request is not None:
        url = static_base_url(request, config)
        if obj.photo is not None:
            obj.photo = url + str(obj.photo)
        else:
            obj.photo = None
    return DivisionGet(
        id=obj.id, title=obj.title, photo=obj.photo, is_actual=obj.is_actual
    )
