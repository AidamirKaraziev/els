import datetime

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.crud.crud_fault_category import crud_fault_category
from src.crud.crud_object import crud_objects
from src.crud.crud_reason_fault import crud_reason_fault
from src.crud.crud_status import crud_status
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import Order, UniversalUser
from src.schemas.order import OrderCreate, OrderUpdate


class CrudOrder(CRUDBase[Order, OrderCreate, OrderUpdate]):
    not_found = -129
    is_exist = -1291

    def get_order_by_id(self, *, db: Session, order_id: int):
        obj = db.query(Order).filter(Order.id == order_id).first()
        if obj is None:
            return None, self.not_found, None
        return obj, 0, None

    def create_order(
        self, db: Session, *, new_data: OrderCreate, current_user: UniversalUser
    ):
        # проверка object_id
        obj, code, indexes = crud_objects.get_object_by_id(
            db=db, object_id=new_data.object_id
        )
        if code != 0:
            return None, code, None
        # проверка creator_id
        new_data.creator_id = current_user.id
        # проверка fault_category_id
        obj, code, indexes = crud_fault_category.get_fault_by_id(
            db=db, fault_id=new_data.fault_category_id
        )
        if code != 0:
            return None, code, None
        # проверка executor_id
        executor = db.query(UniversalUser).filter(
            UniversalUser.id == new_data.executor_id
        )
        if executor is None:
            return None, -130, None
        new_data.created_at = datetime.datetime.utcnow()
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_order(self, db: Session, *, new_data: OrderUpdate, order_id: int):
        # проверка order_id
        order, code, indexes = self.get_order_by_id(db=db, order_id=order_id)
        if code != 0:
            return None, code, None
        # проверить есть ли объект с таким id
        obj, code, indexes = crud_objects.get_object_by_id(
            db=db, object_id=new_data.object_id
        )
        if code != 0:
            return None, code, None
        if new_data.fault_category_id is not None:
            obj, code, indexes = crud_fault_category.get_fault_by_id(
                db=db, fault_id=new_data.fault_category_id
            )
            if code != 0:
                return None, code, None
        # проверка executor_id
        if new_data.executor_id == 0:
            new_data.executor_id = None
        if new_data.executor_id is not None:
            fact_executor, code, indexes = crud_universal_users.get_user_by_id(
                db=db, user_id=new_data.executor_id
            )
            if code != 0:
                return None, code, None
        if new_data.reason_fault_id is not None:
            obj, code, indexes = crud_reason_fault.get_fault_by_id(
                db=db, fault_id=new_data.reason_fault_id
            )
            if code != 0:
                return None, code, None
        if new_data.status_id is not None:
            obj, code, indexes = crud_status.getting_status(
                db=db, status_id=new_data.status_id
            )
            if code != 0:
                return None, code, None
        if new_data.status_id == 2:
            new_data.accepted_at = datetime.datetime.utcnow()
        if new_data.status_id == 3:
            new_data.in_progress_at = datetime.datetime.utcnow()
        if new_data.status_id == 4:
            new_data.dane_at = datetime.datetime.utcnow()

        # обновление данных
        db_obj = super().update(db=db, db_obj=order, obj_in=new_data)
        return db_obj, 0, None

    def get_my_orders(self, *, db: Session, creator_id: int):
        my_orders = db.query(self.model).filter(self.model.creator_id == creator_id)
        return my_orders, 0, None

    def get_orders_for_me(self, *, db: Session, executor_id: int):
        orders = db.query(self.model).filter(self.model.executor_id == executor_id)
        return orders, 0, None


crud_orders = CrudOrder(Order)
