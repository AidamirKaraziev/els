from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.company import getting_company
from src.getters.cost_type import get_cost_types
from src.getters.static_url import static_base_url
from src.getters.type_contract import get_type_contracts
from src.models.contract import Contract
from src.schemas.contract import ContractGet


def get_contract(
    obj: Contract, request: Optional[Request], config: Settings = settings
) -> Optional[ContractGet]:
    if request is not None:
        url = static_base_url(request, config)
        if obj.file is not None:
            obj.file = url + str(obj.file)

    return ContractGet(
        id=obj.id,
        company_id=getting_company(company=obj.company, request=request)
        if obj.company is not None
        else None,
        title=obj.title,
        validity_period=obj.validity_period,
        type_contract_id=get_type_contracts(obj.type_contract)
        if obj.type_contract is not None
        else None,
        cost_type_id=get_cost_types(obj.cost_type)
        if obj.cost_type is not None
        else None,
        file=obj.file,
        is_actual=obj.is_actual,
    )
