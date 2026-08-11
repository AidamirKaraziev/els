from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import FactoryModel, Object, TypeAct
from src.models.act_base import ActBase
from src.schemas.act_base import ActBaseCreate, ActBaseUpdate


class CrudActBase(CRUDBase[ActBase, ActBaseCreate, ActBaseUpdate]):
    def create_act_base(self, db: Session, *, new_data: ActBaseCreate):
        # проверка на factory_model_id
        if (
            db.query(FactoryModel)
            .filter(FactoryModel.id == new_data.factory_model_id)
            .first()
            is None
        ):
            return None, -115, None
        # проверка на type_act_id
        if db.query(TypeAct).filter(TypeAct.id == new_data.type_act_id).first() is None:
            return None, -122, None
        # проверка на уникальность factory_model_id & type_act_id
        if (
            db.query(ActBase)
            .filter(
                ActBase.factory_model_id == new_data.factory_model_id,
                ActBase.type_act_id == new_data.type_act_id,
            )
            .first()
            is not None
        ):
            return (
                None,
                -1211,
                None,
            )  # в базе данных уже есть act_base с уникальными полями
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_act_base(
        self, db: Session, *, new_data: ActBaseUpdate, act_base_id: int
    ):
        # проверка есть ли такой шаблон актов
        this_act_base = db.query(ActBase).filter(ActBase.id == act_base_id).first()
        if this_act_base is None:
            return None, -121, None
        # проверка на factory_model_id
        if (
            db.query(FactoryModel)
            .filter(FactoryModel.id == new_data.factory_model_id)
            .first()
            is None
        ):
            return None, -115, None
        # проверка на type_act_id
        if db.query(TypeAct).filter(TypeAct.id == new_data.type_act_id).first() is None:
            return None, -122, None
        # проверка на уникальность factory_model_id & type_act_id
        if (
            db.query(ActBase)
            .filter(
                ActBase.factory_model_id == new_data.factory_model_id,
                ActBase.type_act_id == new_data.type_act_id,
            )
            .first()
            is not None
        ):
            return (
                None,
                -1211,
                None,
            )  # в базе данных уже есть act_base с уникальными полями
        db_obj = super().update(db=db, db_obj=this_act_base, obj_in=new_data)
        return db_obj, 0, None

    def getting_act_base(self, *, db: Session, act_base_id: int):
        a_b = db.query(ActBase).filter(ActBase.id == act_base_id).first()
        if a_b is None:
            return None, -121, None
        return a_b, 0, None

    def get_act_base_by_object_id(self, *, db: Session, object_id: int):
        act_bases = (
            db.query(ActBase)
            .join(FactoryModel)
            .join(Object)
            .filter(Object.id == object_id)
            .all()
        )
        return act_bases, 0, None


crud_acts_bases = CrudActBase(ActBase)
