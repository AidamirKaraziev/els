from src.models import SubStep
from src.schemas.sub_step import SubStepGet


def get_sub_step(db_obj: SubStep) -> SubStepGet:
    return SubStepGet(id=db_obj.id, name=db_obj.name)
