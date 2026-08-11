from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import FactoryModel
from src.schemas.factory_model import FactoryModelCreate, FactoryModelUpdate
from src.utils import pagination


class CrudFactoryModel(CRUDBase[FactoryModel, FactoryModelCreate, FactoryModelUpdate]):
    def create_factory_model(
        self, db: Session, *, new_data: Optional[FactoryModelCreate]
    ):
        # проверка уникальности трех полей
        if (
            db.query(FactoryModel)
            .filter(
                FactoryModel.type_object_id == new_data.type_object_id,
                FactoryModel.factory == new_data.factory,
                FactoryModel.model == new_data.model,
            )
            .first()
            is not None
        ):
            return None, -1151, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_factory_model(
        self,
        db: Session,
        *,
        new_data: Optional[FactoryModelUpdate],
        factory_model_id: int,
    ):
        # проверить есть ли model с таким id
        this_model = (
            db.query(FactoryModel).filter(FactoryModel.id == factory_model_id).first()
        )
        if this_model is None:
            return None, -115, None

        type_obj = this_model.type_object_id
        factory = this_model.factory
        model = this_model.model

        if new_data.type_object_id is not None:
            type_obj = new_data.type_object_id
        if new_data.factory is not None:
            factory = new_data.factory
        if new_data.model is not None:
            model = new_data.model
        if (
            db.query(FactoryModel)
            .filter(
                FactoryModel.type_object_id == type_obj,
                FactoryModel.factory == factory,
                FactoryModel.model == model,
            )
            .first()
            is not None
        ):
            return None, -1151, None

        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=this_model, obj_in=new_data)
        return db_obj, 0, None

    def get_mod(self, *, db: Session, factory_model_id: int):
        mod = db.query(FactoryModel).filter(FactoryModel.id == factory_model_id).first()
        if mod is None:
            return None, -115, None
        return mod, 0, None

    def get_factory_model_by_type_obj_id(
        self, *, db: Session, type_object_id: int, page: Optional[int] = None
    ):
        objs = db.query(FactoryModel).filter(
            FactoryModel.type_object_id == type_object_id
        )
        return pagination.get_page(objs, page)


crud_factory_models = CrudFactoryModel(FactoryModel)
