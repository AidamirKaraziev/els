from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models.reason_fault import ReasonFault
from src.schemas.reason_fault import ReasonFaultCreate, ReasonFaultUpdate


class CrudReasonFault(CRUDBase[ReasonFault, ReasonFaultCreate, ReasonFaultUpdate]):
    not_found = -128
    is_exist = -1281

    def get_fault_by_id(self, *, db: Session, fault_id: int):
        obj, code, indexes = super().get_by_id(
            db=db, id=fault_id, not_found=self.not_found
        )
        return obj, code, indexes

    def create_new(self, db: Session, *, new_data: Optional[ReasonFaultCreate]):
        obj, code, indexes = super().get_by_name(
            db=db, name=new_data.name, is_exist=self.is_exist
        )
        if code != 0:
            return None, code, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update(
        self, db: Session, *, new_data: Optional[ReasonFaultUpdate], obj_id: int
    ):
        # проверить есть ли участок с таким id
        r_c = db.query(ReasonFault).filter(ReasonFault.id == obj_id).first()
        if r_c is None:
            return None, self.not_found, None
        # Check title
        if r_c.name != new_data.name:
            if (
                db.query(ReasonFault)
                .filter(ReasonFault.name == new_data.name, ReasonFault.id != obj_id)
                .first()
                is not None
            ):
                return None, self.is_exist, None
        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=r_c, obj_in=new_data)
        return db_obj, 0, None


crud_reason_fault = CrudReasonFault(ReasonFault)
