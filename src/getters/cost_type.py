from src.models import CostType
from src.schemas.cost_type import CostTypeGet


def get_cost_types(db_obj: CostType) -> CostTypeGet:
    return CostTypeGet(id=db_obj.id, name=db_obj.name)
