from src.models import Step
from src.schemas.step import StepGet


def get_step(db_obj: Step) -> StepGet:
    return StepGet(id=db_obj.id, name=db_obj.name)
