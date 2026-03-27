from src.models.working_specialty import WorkingSpecialty
from src.schemas.working_specialty import WorkingSpecialtyGet


def get_working_specialty(db_obj: WorkingSpecialty) -> WorkingSpecialtyGet:
    return WorkingSpecialtyGet(id=db_obj.id, name=db_obj.name)
