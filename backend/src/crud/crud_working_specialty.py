from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import WorkingSpecialty
from src.schemas.working_specialty import WorkingSpecialtyCreate, WorkingSpecialtyUpdate


class CrudWorkingSpecialty(
    CRUDBase[WorkingSpecialty, WorkingSpecialtyCreate, WorkingSpecialtyUpdate]
):
    def update_working_specialty(
        self,
        db: Session,
        *,
        working_specialty: Optional[WorkingSpecialtyUpdate],
        working_specialty_id: int,
    ):
        # проверить есть ли специальность с таким id
        if (
            db.query(WorkingSpecialty)
            .filter(WorkingSpecialty.id == working_specialty_id)
            .first()
            is None
        ):
            return None, -1, None
        this_working_specialty = (
            db.query(WorkingSpecialty)
            .filter(WorkingSpecialty.id == working_specialty_id)
            .first()
        )

        # Check_name
        if this_working_specialty.name != working_specialty.name:
            if (
                db.query(WorkingSpecialty)
                .filter(WorkingSpecialty.name == working_specialty.name)
                .first()
                is not None
            ):
                return None, -2, None

        # Вот тут должно быть обновление базы данных
        db_obj = super().update(
            db=db, db_obj=this_working_specialty, obj_in=working_specialty
        )
        return db_obj, 0, None


crud_working_specialty = CrudWorkingSpecialty(WorkingSpecialty)
