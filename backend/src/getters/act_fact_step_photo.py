from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.static_url import static_base_url
from src.models import ActFactStepPhoto
from src.schemas.act_fact_step_photo import ActFactStepPhotoGet
from src.utils.time_stamp import utc_to_timestamp


def getting_act_fact_step_photo(
    obj: ActFactStepPhoto, request: Optional[Request], config: Settings = settings
) -> ActFactStepPhotoGet:
    """Снимок шага наружу.

    Считаем в переменные, а не в поля записи: присвоение пометило бы снимок
    изменённым, и ближайший `flush` сохранил бы в базу полную ссылку вместо
    относительного пути.
    """
    photo = obj.photo
    if request is not None and photo is not None:
        photo = static_base_url(request, config) + str(photo)

    return ActFactStepPhotoGet(
        id=obj.id,
        act_fact_id=obj.act_fact_id,
        step_id=obj.step_id,
        photo=photo,
        created_at=utc_to_timestamp(obj.created_at),
    )
