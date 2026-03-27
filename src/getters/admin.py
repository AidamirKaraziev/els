from typing import Optional

from fastapi import Request

from config import Settings, settings
from src.getters.location import get_location
from src.getters.role import get_roles
from src.getters.working_specialty import get_working_specialty
from src.models import UniversalUser
from src.schemas.universal_user import UniversalUserGet
from src.utils.time_stamp import to_timestamp


def get_admin(
    admin: UniversalUser, request: Optional[Request], config: Settings = settings
) -> Optional[UniversalUserGet]:
    if request is not None:
        url = (
            request.url.hostname
            + ":"
            + str(settings.APP_PORT)
            + config.API_V1_STR
            + "/static/"
        )
        if admin.photo is not None:
            admin.photo = url + str(admin.photo)
        else:
            admin.photo = None
    admin.birthday = to_timestamp(admin.birthday)
    return UniversalUserGet(
        id=admin.id,
        name=admin.name,
        email=admin.email,
        contact_phone=admin.contact_phone,
        birthday=admin.birthday,
        photo=admin.photo,
        location_id=get_location(admin.location)
        if admin.location is not None
        else None,
        role_id=get_roles(admin.role) if admin.role is not None else None,
        working_specialty_id=get_working_specialty(admin.working_specialty)
        if admin.working_specialty is not None
        else None,
        identity_card=admin.identity_card,
        is_actual=admin.is_actual,
    )
