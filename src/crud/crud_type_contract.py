from src.crud.base import CRUDBase
from src.models import TypeContract
from src.schemas.type_contract import TypeContractCreate, TypeContractUpdate


class CrudTypeContract(CRUDBase[TypeContract, TypeContractCreate, TypeContractUpdate]):
    pass


crud_type_contract = CrudTypeContract(TypeContract)
