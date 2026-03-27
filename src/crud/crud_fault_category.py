from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models.fault_category import FaultCategory
from src.schemas.fault_category import FaultCategoryCreate, FaultCategoryUpdate


class CrudFaultCategory(
    CRUDBase[FaultCategory, FaultCategoryCreate, FaultCategoryUpdate]
):
    not_found = -127
    is_exist = -1271

    def get_fault_by_id(self, *, db: Session, fault_id: int):
        obj, code, indexes = super().get_by_id(
            db=db, id=fault_id, not_found=self.not_found
        )
        return obj, code, indexes

    def create_new(self, db: Session, *, new_data: Optional[FaultCategoryCreate]):
        obj, code, indexes = super().get_by_name(
            db=db, name=new_data.name, is_exist=self.is_exist
        )
        if code != 0:
            return None, code, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update(
        self, db: Session, *, new_data: Optional[FaultCategoryUpdate], obj_id: int
    ):
        # проверить есть ли участок с таким id
        f_c = db.query(FaultCategory).filter(FaultCategory.id == obj_id).first()
        if f_c is None:
            return None, self.not_found, None
        # Check title
        if f_c.name != new_data.name:
            if (
                db.query(FaultCategory)
                .filter(FaultCategory.name == new_data.name, FaultCategory.id != obj_id)
                .first()
                is not None
            ):
                return None, self.is_exist, None
        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=f_c, obj_in=new_data)
        return db_obj, 0, None


crud_fault_category = CrudFaultCategory(FaultCategory)
