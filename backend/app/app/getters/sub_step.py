from app.models import SubStep
from app.schemas.sub_step import SubStepGet


def get_sub_step(db_obj: SubStep) -> SubStepGet:
    return SubStepGet(
        id=db_obj.id,
        name=db_obj.name
    )
