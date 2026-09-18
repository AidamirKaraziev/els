from sqlalchemy import func
from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models.type_act import TypeAct
from src.schemas.type_act import TypeActCreate, TypeActUpdate


class CrudTypeAct(CRUDBase[TypeAct, TypeActCreate, TypeActUpdate]):
    # У `types_acts` нет автоинкремента: id раздавали руками при заливке
    # справочника. Продолжаем ту же нумерацию — следующий за наибольшим.
    def create_next(self, db: Session, *, name: str) -> TypeAct:
        next_id = (db.query(func.max(TypeAct.id)).scalar() or 0) + 1
        db_obj = TypeAct(id=next_id, name=name)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj


crud_type_acts = CrudTypeAct(TypeAct)
