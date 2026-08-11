from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.location import get_location
from src.getters.static_url import static_base_url
from src.models.company import Company
from src.schemas.company import CompanyGet


def getting_company(
    company: Company, request: Optional[Request], config: Settings = settings
) -> Optional[CompanyGet]:
    if request is not None:
        url = static_base_url(request, config)
        if company.photo is not None:
            company.photo = url + str(company.photo)
        else:
            company.photo = None
    return CompanyGet(
        id=company.id,
        name=company.name,
        director_name=company.director_name,
        cont_phone=company.cont_phone,
        cont_address=company.cont_address,
        photo=company.photo,
        email=company.email,
        site=company.site,
        location_id=get_location(company.location)
        if company.location is not None
        else None,
        is_actual=company.is_actual,
    )
