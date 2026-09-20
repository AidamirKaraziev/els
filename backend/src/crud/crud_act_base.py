from datetime import datetime
from typing import Dict, List, Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import ActFact, FactoryModel, Object, TypeAct
from src.models.act_base import ActBase
from src.schemas.act_base import ActBaseCreate, ActBaseUpdate
from src.services.checklist import template_from_steps

#: Акт только создан графиком, механик за него не брался — статус «создан».
STATUS_CREATED = 1


def _step_list(new_data) -> Dict[str, Optional[str]]:
    """Чек-лист для записи в базу — из `steps` или из устаревшего `step_list`.

    `steps` главнее: это новая форма, и её сервер приводит к канону. Ни того
    ни другого — поле не трогаем, чтобы PUT с одним `type_act_id` не стирал
    шаги.
    """
    if new_data.steps is not None:
        return {"step_list": template_from_steps(new_data.steps)}
    if new_data.step_list is not None:
        return {"step_list": new_data.step_list}
    return {}


class CrudActBase(CRUDBase[ActBase, ActBaseCreate, ActBaseUpdate]):
    def _pair_taken(
        self, db: Session, *, factory_model_id, type_act_id, except_id=None
    ) -> Optional[ActBase]:
        """Строка с той же парой «модель + вид ТО», в том числе удалённая."""
        query = db.query(ActBase).filter(
            ActBase.factory_model_id == factory_model_id,
            ActBase.type_act_id == type_act_id,
        )
        if except_id is not None:
            query = query.filter(ActBase.id != except_id)
        return query.first()

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
        taken = self._pair_taken(
            db,
            factory_model_id=new_data.factory_model_id,
            type_act_id=new_data.type_act_id,
        )
        if taken is not None:
            # -1212 — пара есть, но удалена: её возвращают, а не заводят заново.
            return None, (-1212 if taken.deleted_at is not None else -1211), None
        db_obj = ActBase(
            factory_model_id=new_data.factory_model_id,
            type_act_id=new_data.type_act_id,
            **_step_list(new_data),
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj, 0, None

    def update_act_base(
        self, db: Session, *, new_data: ActBaseUpdate, act_base_id: int
    ):
        # проверка есть ли такой шаблон актов
        this_act_base = db.query(ActBase).filter(ActBase.id == act_base_id).first()
        if this_act_base is None:
            return None, -121, None
        factory_model_id = new_data.factory_model_id
        if factory_model_id is None:
            factory_model_id = this_act_base.factory_model_id
        elif (
            db.query(FactoryModel).filter(FactoryModel.id == factory_model_id).first()
            is None
        ):
            return None, -115, None
        type_act_id = new_data.type_act_id
        if type_act_id is None:
            type_act_id = this_act_base.type_act_id
        elif db.query(TypeAct).filter(TypeAct.id == type_act_id).first() is None:
            return None, -122, None
        # проверка на уникальность factory_model_id & type_act_id
        if (
            self._pair_taken(
                db,
                factory_model_id=factory_model_id,
                type_act_id=type_act_id,
                except_id=this_act_base.id,
            )
            is not None
        ):
            return None, -1211, None
        db_obj = super().update(
            db=db,
            db_obj=this_act_base,
            obj_in={
                "factory_model_id": factory_model_id,
                "type_act_id": type_act_id,
                **_step_list(new_data),
            },
        )
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
            .filter(Object.id == object_id, ActBase.deleted_at.is_(None))
            .all()
        )
        return act_bases, 0, None

    def list_by_model(
        self, db: Session, *, factory_model_id: int, include_deleted: bool
    ) -> List[ActBase]:
        """Виды ТО модели по порядку видов; удалённые — по просьбе."""
        query = db.query(ActBase).filter(ActBase.factory_model_id == factory_model_id)
        if not include_deleted:
            query = query.filter(ActBase.deleted_at.is_(None))
        return query.order_by(ActBase.type_act_id, ActBase.id).all()

    def pending_acts_count(self, db: Session, *, act_base_id: int) -> int:
        """Сколько актов по шаблону стоит в графике и ещё не начато."""
        return (
            db.query(ActFact.id)
            .filter(
                ActFact.act_base_id == act_base_id,
                ActFact.status_id == STATUS_CREATED,
                ActFact.is_actual.is_(True),
            )
            .count()
        )

    def soft_delete(self, db: Session, *, db_obj: ActBase) -> ActBase:
        if db_obj.deleted_at is None:
            db_obj.deleted_at = datetime.now()
            db.commit()
            db.refresh(db_obj)
        return db_obj

    def restore(self, db: Session, *, db_obj: ActBase) -> ActBase:
        if db_obj.deleted_at is not None:
            db_obj.deleted_at = None
            db.commit()
            db.refresh(db_obj)
        return db_obj


crud_acts_bases = CrudActBase(ActBase)
