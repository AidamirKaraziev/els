from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.schemas.defective_act_photo import DefectiveActPhotoGet
from src.utils.time_stamp import to_timestamp


def getting_defective_act_photo(
    obj, request: Optional[Request], config: Settings = settings
) -> Optional[DefectiveActPhotoGet]:
    if obj.created_at is not None:
        obj.created_at = to_timestamp(obj.created_at)

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

    return DefectiveActPhotoGet(
        id=obj.id,
        defective_act_id=obj.defective_act_id,
        photo=obj.photo,
        created_at=obj.created_at,
        created_by_user_id=obj.created_by_user_id,
    )
