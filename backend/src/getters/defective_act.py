from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.defective_act_photo import getting_defective_act_photo
from src.getters.planned_to import get_planned_to
from src.getters.static_url import static_base_url
from src.getters.status import get_statuses
from src.getters.universal_user import get_universal_user
from src.models import DefectiveAct
from src.schemas.defective_act import DefectiveActGet
from src.utils.time_stamp import to_timestamp


def getting_defective_act(
    obj: DefectiveAct, request: Optional[Request], config: Settings = settings
) -> Optional[DefectiveActGet]:
    if obj.created_at is not None:
        obj.created_at = to_timestamp(obj.created_at)
    if obj.updated_at is not None:
        obj.updated_at = to_timestamp(obj.updated_at)

    if request is not None:
        url = static_base_url(request, config)
        if obj.pdf_file is not None:
            obj.pdf_file = url + str(obj.pdf_file)
        else:
            obj.pdf_file = None

    return DefectiveActGet(
        id=obj.id,
        planned_to_id=get_planned_to(obj.planned_to, request=request)
        if obj.planned_to is not None
        else None,
        month=obj.month,
        title=obj.title,
        description=obj.description,
        responsible_user_id=get_universal_user(obj.responsible_user, request=request)
        if obj.responsible_user is not None
        else None,
        created_by_user_id=get_universal_user(obj.created_by_user, request=request)
        if obj.created_by_user is not None
        else None,
        status_id=get_statuses(obj.status) if obj.status is not None else None,
        pdf_file=obj.pdf_file,
        created_at=obj.created_at,
        updated_at=obj.updated_at,
        photos=[
            getting_defective_act_photo(photo, request=request)
            for photo in (obj.photos or [])
        ],
    )
