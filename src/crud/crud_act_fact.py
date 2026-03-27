from typing import Optional

from sqlalchemy.orm import Session
from starlette import status

from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.crud.base import CRUDBase
from src.crud.crud_act_base import crud_acts_bases
from src.crud.crud_object import crud_objects
from src.crud.crud_status import crud_status
from src.models import (
    ActFact,
    Object,
    UniversalUser,
)
from src.schemas.act_fact import ActFactCreate, ActFactUpdate
from src.utils.time_stamp import date_from_timestamp

ROLE_RIGHTS = [ADMIN, FOREMAN]
ROLE_MECHANIC = [MECHANIC]
ROLE_FOREMAN = [FOREMAN]


class CrudActFact(CRUDBase[ActFact, ActFactCreate, ActFactUpdate]):
    obj_name = "Фактические акты"
    not_found_id = {
        "status_code": status.HTTP_404_NOT_FOUND,
        "detail": f"{obj_name}: не найден с таким id",
    }
    not_found_foreman = {
        "status_code": status.HTTP_403_FORBIDDEN,
        "detail": "Не найден прораб с таким id",
    }
    not_found_mechanic = {
        "status_code": status.HTTP_403_FORBIDDEN,
        "detail": "Не найден механик с таким id",
    }

    def get_act_fact_by_id(self, db: Session, id: int):
        act_fact = super().get(db=db, id=id)
        if not act_fact:
            return None, self.not_found_id, None
        return act_fact, 0, None

    def create_act_fact(self, db: Session, *, new_data: ActFactCreate):
        # проверка объекта
        obj, code, indexes = crud_objects.get_object_by_id(
            db=db, object_id=new_data.object_id
        )
        if code != 0:
            return None, code, None
        # проверка базовый акт
        act_base, code, indexes = crud_acts_bases.getting_act_base(
            db=db, act_base_id=new_data.act_base_id
        )
        if code != 0:
            return None, code, None
        # проверка на ответственный прораб
        foreman = (
            db.query(UniversalUser)
            .filter(
                UniversalUser.id == new_data.foreman_id,
                UniversalUser.role_id == FOREMAN,
            )
            .first()
        )
        if foreman is None:
            return None, self.not_found_foreman, None
        # проверка на ответственный механик
        mechanic = (
            db.query(UniversalUser)
            .filter(
                UniversalUser.id == new_data.main_mechanic_id,
                UniversalUser.role_id == MECHANIC,
            )
            .first()
        )
        if mechanic is None:
            return None, self.not_found_mechanic, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_act_fact(
        self, db: Session, *, update_data: Optional[ActFactUpdate], act_fact_id: int
    ):
        # проверить есть ли объект с таким id
        this_act_fact, code, indexes = self.get_act_fact_by_id(db=db, id=act_fact_id)
        if code != 0:
            return None, code, None
        # обновление выполненных шагов
        if update_data.step_list_fact:
            update_data.step_list_fact = update_data.step_list_fact
        # перевод дат в нужный формат
        if update_data.started_at is not None:
            update_data.started_at = date_from_timestamp(update_data.started_at)
        if update_data.finished_at is not None:
            update_data.finished_at = date_from_timestamp(update_data.finished_at)
        # проверка на ответственный прораб
        if update_data.foreman_id:
            foreman = (
                db.query(UniversalUser)
                .filter(
                    UniversalUser.id == update_data.foreman_id,
                    UniversalUser.role_id == FOREMAN,
                )
                .first()
            )
            if foreman is None:
                return None, self.not_found_foreman, None
        # проверка на ответственный механик
        if update_data.main_mechanic_id:
            mechanic = (
                db.query(UniversalUser)
                .filter(
                    UniversalUser.id == update_data.main_mechanic_id,
                    UniversalUser.role_id == MECHANIC,
                )
                .first()
            )
            if mechanic is None:
                return None, self.not_found_mechanic, None
        # проверка статуса
        if update_data.status_id:
            status, code, indexes = crud_status.getting_status(
                db=db, status_id=update_data.status_id
            )
            if code != 0:
                return None, code, None
        # обновление данных
        db_obj = super().update(db=db, db_obj=this_act_fact, obj_in=update_data)
        return db_obj, 0, None

    def get_act_fact_by_object_id(self, *, db: Session, object_id: int):
        act_bases = db.query(ActFact).join(Object).filter(Object.id == object_id).all()
        return act_bases, 0, None


crud_acts_fact = CrudActFact(ActFact)
