from src.crud.base import CRUDBase
from src.models.type_act import TypeAct
from src.schemas.type_act import TypeActCreate, TypeActUpdate


class CrudTypeAct(CRUDBase[TypeAct, TypeActCreate, TypeActUpdate]):
    pass


crud_type_acts = CrudTypeAct(TypeAct)
