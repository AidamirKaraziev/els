from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.company import getting_company
from src.getters.contact_person import get_contact_person
from src.getters.contract import get_contract
from src.getters.division import get_division
from src.getters.factory_model import get_factory_model
from src.getters.universal_user import get_universal_user
from src.models import Object
from src.schemas.object import ObjectGet
from src.utils.time_stamp import to_timestamp


def get_object(
    obj: Object, request: Optional[Request], config: Settings = settings
) -> Optional[ObjectGet]:
    if request is not None:
        url = (
            request.url.hostname
            + ":"
            + str(settings.APP_PORT)
            + config.API_V1_STR
            + "/static/"
        )
        if obj.letter_of_appointment is not None:
            obj.letter_of_appointment = url + str(obj.letter_of_appointment)
        else:
            obj.letter_of_appointment = None

        if obj.acceptance_certificate is not None:
            obj.acceptance_certificate = url + str(obj.acceptance_certificate)
        else:
            obj.acceptance_certificate = None

        if obj.act_pto is not None:
            obj.act_pto = url + str(obj.act_pto)
        else:
            obj.act_pto = None

    if obj.date_inspection:
        obj.date_inspection = to_timestamp(obj.date_inspection)
    if obj.planned_inspection:
        obj.planned_inspection = to_timestamp(obj.planned_inspection)
    if obj.period_inspection:
        obj.period_inspection = to_timestamp(obj.period_inspection)

    return ObjectGet(
        id=obj.id,
        name=obj.name,
        organization_id=obj.organization_id,
        division_id=get_division(obj.division, request=request)
        if obj.division is not None
        else None,
        address=obj.address,
        factory_model_id=get_factory_model(obj.factory_model)
        if obj.factory_model is not None
        else None,
        factory_number=obj.factory_number,
        registration_number=obj.registration_number,
        number_of_stops=obj.number_of_stops,
        lifting_heights=obj.lifting_heights,
        load_capacity=obj.load_capacity,
        width=obj.width,
        cost_nds=obj.cost_nds,
        cost_no_nds=obj.cost_no_nds,
        company_id=getting_company(obj.company_obj, request=request)
        if obj.company_obj is not None
        else None,
        contact_person_id=get_contact_person(obj.contact_person, request=request)
        if obj.contact_person is not None
        else None,
        contract_id=get_contract(obj.contract, request=request)
        if obj.contract is not None
        else None,
        date_inspection=obj.date_inspection,
        planned_inspection=obj.planned_inspection,
        period_inspection=obj.period_inspection,
        foreman_id=get_universal_user(obj.foreman, request=request)
        if obj.foreman is not None
        else None,
        mechanic_id=get_universal_user(obj.mechanic, request=request)
        if obj.mechanic is not None
        else None,
        letter_of_appointment=obj.letter_of_appointment,
        acceptance_certificate=obj.acceptance_certificate,
        act_pto=obj.act_pto,
        geo=obj.geo,
        is_actual=obj.is_actual,
    )
