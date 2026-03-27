from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import SubStep
from src.schemas.sub_step import SubStepCreate, SubStepUpdate


class CrudSubStep(CRUDBase[SubStep, SubStepCreate, SubStepUpdate]):
    def create_sub_steps(self, db: Session, *, new_data: Optional[SubStepCreate]):
        # проверка уникальности трех полей
        if db.query(SubStep).filter(SubStep.name == new_data.name).first() is not None:
            return None, -1261, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_sub_steps(
        self, db: Session, *, new_data: Optional[SubStepUpdate], sub_step_id: int
    ):
        # проверить есть ли model с таким id
        this_obj = db.query(SubStep).filter(SubStep.id == sub_step_id).first()
        if this_obj is None:
            return None, -126, None

        if new_data.name is not None:
            if (
                db.query(SubStep).filter(SubStep.name == new_data.name).first()
                is not None
            ):
                return None, -1261, None
        db_obj = super().update(db=db, db_obj=this_obj, obj_in=new_data)
        return db_obj, 0, None

    def get_sub_step(self, *, db: Session, sub_step_id: int):
        obj = db.query(SubStep).filter(SubStep.id == sub_step_id).first()
        if obj is None:
            return None, -126, None
        return obj, 0, None


crud_sub_step = CrudSubStep(SubStep)
