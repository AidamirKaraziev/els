from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.static_url import static_base_url
from src.schemas.defective_act_photo import DefectiveActPhotoGet
from src.utils.time_stamp import to_timestamp


def getting_defective_act_photo(
    obj, request: Optional[Request], config: Settings = settings
) -> Optional[DefectiveActPhotoGet]:
    # Считаем в локальные переменные, а не в поля записи: один и тот же
    # снимок попадает в ответ дважды — своим у внутреннего акта и отобранным у
    # клиентского. Правка на месте приписала бы ему адрес статики второй раз.
    created_at = to_timestamp(obj.created_at) if obj.created_at is not None else None

    photo = obj.photo
    if request is not None and photo is not None:
        photo = static_base_url(request, config) + str(photo)

    return DefectiveActPhotoGet(
        id=obj.id,
        defective_act_id=obj.defective_act_id,
        photo=photo,
        created_at=created_at,
        created_by_user_id=obj.created_by_user_id,
    )
