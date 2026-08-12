from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.company import getting_company
from src.getters.location import get_location
from src.getters.role import get_roles
from src.getters.static_url import static_base_url
from src.getters.working_specialty import get_working_specialty
from src.models import UniversalUser
from src.schemas.client import ClientGet
from src.utils.time_stamp import to_timestamp


def get_client(
    client: UniversalUser, request: Optional[Request], config: Settings = settings
) -> Optional[ClientGet]:
    if request is not None:
        url = static_base_url(request, config)
        if client.photo is not None:
            client.photo = url + str(client.photo)
        else:
            client.photo = None
    client.birthday = to_timestamp(client.birthday)
    return ClientGet(
        id=client.id,
        name=client.name,
        email=client.email,
        contact_phone=client.contact_phone,
        birthday=client.birthday,
        photo=client.photo,
        location_id=get_location(client.location)
        if client.location is not None
        else None,
        role_id=get_roles(client.role) if client.role is not None else None,
        working_specialty_id=get_working_specialty(client.working_specialty)
        if client.working_specialty is not None
        else None,
        identity_card=client.identity_card,
        company_id=getting_company(company=client.company, request=request)
        if client.company is not None
        else None,
        is_active=client.is_active,
    )
