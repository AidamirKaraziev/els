from src.models import TypeContract
from src.schemas.type_contract import TypeContractGet


def get_type_contracts(db_obj: TypeContract) -> TypeContractGet:
    return TypeContractGet(id=db_obj.id, name=db_obj.name)
