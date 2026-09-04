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
    # Считаем в локальные переменные, а не в поля записи: акт остаётся в
    # сессии, и записанная на место `created_at` метка времени ушла бы обратно
    # в базу целым числом при следующем же flush.
    created_at = to_timestamp(obj.created_at) if obj.created_at is not None else None
    updated_at = to_timestamp(obj.updated_at) if obj.updated_at is not None else None

    pdf_file = obj.pdf_file
    if request is not None and pdf_file is not None:
        pdf_file = static_base_url(request, config) + str(pdf_file)

    return DefectiveActGet(
        id=obj.id,
        object_id=obj.object_id,
        planned_to_id=get_planned_to(obj.planned_to, request=request)
        if obj.planned_to is not None
        else None,
        month=obj.month,
        act_fact_id=obj.act_fact_id,
        checklist_step_id=obj.checklist_step_id,
        order_id=obj.order_id,
        kind=obj.kind,
        state=obj.state,
        parent_id=obj.parent_id,
        client_title=obj.client_title,
        client_description=obj.client_description,
        title=obj.title,
        description=obj.description,
        responsible_user_id=get_universal_user(obj.responsible_user, request=request)
        if obj.responsible_user is not None
        else None,
        created_by_user_id=get_universal_user(obj.created_by_user, request=request)
        if obj.created_by_user is not None
        else None,
        status_id=get_statuses(obj.status) if obj.status is not None else None,
        pdf_file=pdf_file,
        created_at=created_at,
        updated_at=updated_at,
        photos=[
            getting_defective_act_photo(photo, request=request)
            for photo in (obj.photos or [])
        ],
        # Связь, а не копия: снимок лежит у первоисточника, здесь только отбор.
        client_photos=[
            getting_defective_act_photo(link.photo, request=request)
            for link in (obj.client_photos or [])
            if link.photo is not None
        ],
    )
