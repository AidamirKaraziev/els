from src.crud.base import CRUDBase
from src.models import CostType
from src.schemas.cost_type import CostTypeCreate, CostTypeUpdate


class CrudCostType(CRUDBase[CostType, CostTypeCreate, CostTypeUpdate]):
    pass


crud_cost_types = CrudCostType(CostType)
