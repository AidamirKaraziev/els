from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.company import getting_company
from src.getters.division import get_division
from src.getters.location import get_location
from src.getters.role import get_roles
from src.getters.static_url import static_base_url
from src.getters.working_specialty import get_working_specialty
from src.models import UniversalUser
from src.schemas.universal_user import UniversalUserGet
from src.utils.time_stamp import to_timestamp


def get_universal_user(
    universal_user: UniversalUser,
    request: Optional[Request],
    config: Settings = settings,
) -> Optional[UniversalUserGet]:
    if request is not None:
        url = static_base_url(request, config)
        if universal_user.photo is not None:
            universal_user.photo = url + str(universal_user.photo)
        else:
            universal_user.photo = None
        if universal_user.identity_card is not None:
            universal_user.identity_card = url + str(universal_user.identity_card)
        else:
            universal_user.identity_card = None
        if universal_user.qualification_file is not None:
            universal_user.qualification_file = url + str(
                universal_user.qualification_file
            )
        else:
            universal_user.qualification_file = None
    if universal_user.birthday is not None:
        universal_user.birthday = to_timestamp(universal_user.birthday)
    if universal_user.date_of_employment is not None:
        universal_user.date_of_employment = to_timestamp(
            universal_user.date_of_employment
        )
    return UniversalUserGet(
        id=universal_user.id,
        name=universal_user.name,
        email=universal_user.email,
        contact_phone=universal_user.contact_phone,
        birthday=universal_user.birthday,
        photo=universal_user.photo,
        location_id=get_location(universal_user.location)
        if universal_user.location is not None
        else None,
        role_id=get_roles(universal_user.role)
        if universal_user.role is not None
        else None,
        working_specialty_id=get_working_specialty(universal_user.working_specialty)
        if universal_user.working_specialty is not None
        else None,
        identity_card=universal_user.identity_card,
        qualification_file=universal_user.qualification_file,
        company_id=getting_company(company=universal_user.company, request=request)
        if universal_user.company is not None
        else None,
        division_id=get_division(obj=universal_user.division, request=request)
        if universal_user.division is not None
        else None,
        date_of_employment=universal_user.date_of_employment,
        is_active=universal_user.is_active,
    )
