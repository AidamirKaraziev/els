from app.models import Status
from app.schemas.status import StatusGet


def get_statuses(db_obj: Status) -> StatusGet:
    return StatusGet(
        id=db_obj.id,
        name=db_obj.name
    )
