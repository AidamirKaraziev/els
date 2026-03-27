from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import TypeObject
from src.schemas.type_object import TypeObjectCreate, TypeObjectUpdate


class CrudTypeObject(CRUDBase[TypeObject, TypeObjectCreate, TypeObjectUpdate]):
    def get_type_object_by_id(self, *, db: Session, type_object_id: int):
        obj = db.query(TypeObject).filter(TypeObject.id == type_object_id).first()
        if obj is None:
            return None, -132, None
        return obj, 0, None


crud_type_object = CrudTypeObject(TypeObject)
