from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import Step
from src.schemas.step import StepCreate, StepUpdate


class CrudStep(CRUDBase[Step, StepCreate, StepUpdate]):
    def create_steps(self, db: Session, *, new_data: Optional[StepCreate]):
        # проверка уникальности трех полей
        if db.query(Step).filter(Step.name == new_data.name).first() is not None:
            return None, -1251, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_steps(
        self, db: Session, *, new_data: Optional[StepUpdate], step_id: int
    ):
        # проверить есть ли model с таким id
        this_obj = db.query(Step).filter(Step.id == step_id).first()
        if this_obj is None:
            return None, -125, None

        if new_data.name is not None:
            if db.query(Step).filter(Step.name == new_data.name).first() is not None:
                return None, -1251, None
        db_obj = super().update(db=db, db_obj=this_obj, obj_in=new_data)
        return db_obj, 0, None

    def get_step(self, *, db: Session, step_id: int):
        obj = db.query(Step).filter(Step.id == step_id).first()
        if obj is None:
            return None, -125, None
        return obj, 0, None


crud_step = CrudStep(Step)
