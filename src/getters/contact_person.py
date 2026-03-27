from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.company import getting_company
from src.models.contact_person import ContactPerson
from src.schemas.contact_person import ContactPersonGet


def get_contact_person(
    contact_person: ContactPerson,
    request: Optional[Request],
    config: Settings = settings,
) -> Optional[ContactPersonGet]:
    if request is not None:
        url = (
            request.url.hostname
            + ":"
            + str(settings.APP_PORT)
            + config.API_V1_STR
            + "/static/"
        )
        if contact_person.photo is not None:
            contact_person.photo = url + str(contact_person.photo)
        else:
            contact_person.photo = None
    return ContactPersonGet(
        id=contact_person.id,
        name=contact_person.name,
        company_id=getting_company(contact_person.company, request=request)
        if contact_person.company is not None
        else None,
        phone=contact_person.phone,
        email=contact_person.email,
        address=contact_person.address,
        photo=contact_person.photo,
        is_actual=contact_person.is_actual,
    )
