from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.universal_user import get_universal_user
from src.models import Organization
from src.schemas.organization import OrganizationGet


def get_organization(
    organization: Organization, request: Optional[Request], config: Settings = settings
) -> Optional[OrganizationGet]:
    if request is not None:
        url = (
            request.url.hostname
            + ":"
            + str(settings.APP_PORT)
            + config.API_V1_STR
            + "/static/"
        )
        if organization.photo is not None:
            organization.photo = url + str(organization.photo)
        else:
            organization.photo = None
    return OrganizationGet(
        id=organization.id,
        title=organization.title,
        director_id=get_universal_user(organization.director, request=request)
        if organization.director is not None
        else None,
        phone_office=organization.phone_office,
        phone_dispatcher=organization.phone_dispatcher,
        phone_accountant=organization.phone_accountant,
        photo=organization.photo,
        site=organization.site,
        email=organization.email,
        address=organization.address,
        is_actual=organization.is_actual,
    )
