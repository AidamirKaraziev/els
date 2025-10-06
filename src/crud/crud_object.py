from typing import Optional
from sqlalchemy.orm import Session

from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.crud.base import CRUDBase
from src.utils.time_stamp import date_from_timestamp
from src.utils import pagination

from src.crud.users.crud_universal_user import crud_universal_users
from src.schemas.object import ObjectCreate, ObjectUpdate
from src.models import (
    Object,
    Organization,
    FactoryModel,
    Company,
    ContactPerson,
    Division,
    UniversalUser,
    Contract,
)


ROLE_RIGHTS = [ADMIN, FOREMAN]
ROLE_MECHANIC = [MECHANIC]
ROLE_FOREMAN = [FOREMAN]


class CrudObject(CRUDBase[Object, ObjectCreate, ObjectUpdate]):
    def create_object(self, db: Session, *, new_data: ObjectCreate):
        # проверка на организацию
        if new_data.organization_id is not None:
            org = (
                db.query(Organization)
                .filter(Organization.id == new_data.organization_id)
                .first()
            )
            if org is None:
                return None, -114, None  # нет организации
        # проверка на участок
        if new_data.division_id is not None:
            div = db.query(Division).filter(Division.id == new_data.division_id).first()
            if div is None:
                return None, -104, None  # нет участка
        # проверка на модель техники
        if new_data.factory_model_id is not None:
            fac = (
                db.query(FactoryModel)
                .filter(FactoryModel.id == new_data.factory_model_id)
                .first()
            )
            if fac is None:
                return None, -115, None  # нет Модели техники
        # проверка на заводской номер
        if new_data.factory_number is not None:
            fac_num = (
                db.query(Object)
                .filter(Object.factory_number == new_data.factory_number)
                .first()
            )
            if fac_num is not None:
                return None, -1151, None  # номер техники уже существует
        # проверка на регистрационный номер
        if new_data.registration_number is not None:
            reg = (
                db.query(Object)
                .filter(Object.registration_number == new_data.registration_number)
                .first()
            )
            if reg is not None:
                return None, -118, None  # регистрационный номер уже есть
        # проверка на компанию
        if new_data.company_id is not None:
            com = db.query(Company).filter(Company.id == new_data.company_id).first()
            if com is None:
                return None, -106, None  # нет компании
        # проверка на контактное лицо
        if new_data.contact_person_id is not None:
            pers = (
                db.query(ContactPerson)
                .filter(ContactPerson.id == new_data.contact_person_id)
                .first()
            )
            if pers is None:
                return None, -113, None  # нет контактное лицо
        # проверка на контракт
        if new_data.contract_id is not None:
            con = db.query(Contract).filter(Contract.id == new_data.contract_id).first()
            if con is None:
                return None, -1121, None  # нет компании
        # перевод дат в нужный формат
        if new_data.date_inspection is not None:
            new_data.date_inspection = date_from_timestamp(new_data.date_inspection)
        if new_data.planned_inspection is not None:
            new_data.planned_inspection = date_from_timestamp(
                new_data.planned_inspection
            )
        if new_data.period_inspection is not None:
            new_data.period_inspection = date_from_timestamp(new_data.period_inspection)

        # проверка на ответственный прораб
        if new_data.foreman_id is not None:
            foreman = (
                db.query(UniversalUser)
                .filter(UniversalUser.id == new_data.foreman_id)
                .first()
            )
            if foreman is None:
                return None, -105, None  # нет пользователя
            # проверка на роли прораба
            if foreman.role_id not in ROLE_FOREMAN:
                return None, -119, None

        # проверка на ответственный механик
        if new_data.mechanic_id is not None:
            mech = (
                db.query(UniversalUser)
                .filter(UniversalUser.id == new_data.mechanic_id)
                .first()
            )
            if mech is None:
                return None, -105, None  # нет пользователя
            #     проверка на роль механика
            if mech.role_id not in ROLE_MECHANIC:
                return None, -120, None

        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_object(
        self, db: Session, *, new_data: Optional[ObjectUpdate], object_id: int
    ):
        # проверить есть ли объект с таким id
        this_object = db.query(Object).filter(Object.id == object_id).first()
        if this_object is None:
            return None, -116, None

        # проверка на организацию
        if new_data.organization_id is not None:
            org = (
                db.query(Organization)
                .filter(Organization.id == new_data.organization_id)
                .first()
            )
            if org is None:
                return None, -114, None  # нет организации
        # проверка на участок
        if new_data.division_id is not None:
            div = db.query(Division).filter(Division.id == new_data.division_id).first()
            if div is None:
                return None, -104, None  # нет участка
        # проверка на модель техники
        if new_data.factory_model_id is not None:
            fac = (
                db.query(FactoryModel)
                .filter(FactoryModel.id == new_data.factory_model_id)
                .first()
            )
            if fac is None:
                return None, -115, None  # нет Модели техники
        # проверка на заводской номер
        if new_data.factory_number is not None:
            fac_num = (
                db.query(Object)
                .filter(Object.factory_number == new_data.factory_number)
                .first()
            )
            if fac_num is not None:
                return None, -1151, None  # номер техники уже существует
        # проверка на регистрационный номер
        if new_data.registration_number is not None:
            reg = (
                db.query(Object)
                .filter(Object.registration_number == new_data.registration_number)
                .first()
            )
            if reg is not None:
                return None, -118, None  # регистрационный номер уже есть
        # проверка на компанию
        if new_data.company_id is not None:
            com = db.query(Company).filter(Company.id == new_data.company_id).first()
            if com is None:
                return None, -106, None  # нет компании
        # проверка на контактное лицо
        if new_data.contact_person_id is not None:
            pers = (
                db.query(ContactPerson)
                .filter(ContactPerson.id == new_data.contact_person_id)
                .first()
            )
            if pers is None:
                return None, -113, None  # нет контактное лицо
        # проверка на контракт
        if new_data.contract_id is not None:
            con = db.query(Contract).filter(Contract.id == new_data.contract_id).first()
            if con is None:
                return None, -1121, None  # нет компании
        # перевод дат в нужный формат
        if new_data.date_inspection is not None:
            new_data.date_inspection = date_from_timestamp(new_data.date_inspection)
        if new_data.planned_inspection is not None:
            new_data.planned_inspection = date_from_timestamp(
                new_data.planned_inspection
            )
        if new_data.period_inspection is not None:
            new_data.period_inspection = date_from_timestamp(new_data.period_inspection)

        # проверка на ответственный прораб
        if new_data.foreman_id is not None:
            foreman = (
                db.query(UniversalUser)
                .filter(UniversalUser.id == new_data.foreman_id)
                .first()
            )
            if foreman is None:
                return None, -105, None  # нет пользователя
            # проверка на роли прораба
            if foreman.role_id not in ROLE_FOREMAN:
                return None, -119, None

        # проверка на ответственный механик
        if new_data.mechanic_id is not None:
            mech = (
                db.query(UniversalUser)
                .filter(UniversalUser.id == new_data.mechanic_id)
                .first()
            )
            if mech is None:
                return None, -105, None  # нет пользователя
            #     проверка на роль механика
            if mech.role_id not in ROLE_MECHANIC:
                return None, -120, None
        # обновление данных
        db_obj = super().update(db=db, db_obj=this_object, obj_in=new_data)
        return db_obj, 0, None

    def archiving_object(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        object_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=object_id)
        if obj is None:
            return None, -116, None
        # вызвать архивацию
        obj, code, indexes = super().archiving(db=db, db_obj=obj)
        return obj, code, None

    def unzipping_object(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        object_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=object_id)
        if obj is None:
            return None, -116, None
        # вызвать архивацию
        obj, code, indexes = super().unzipping(db=db, db_obj=obj)
        return obj, code, None

    def get_object_by_id(self, *, db: Session, object_id: int):
        obj = db.query(self.model).filter(self.model.id == object_id).first()
        if obj is None:
            return None, -116, None
        return obj, 0, None

    def get_objects_by_company_id(
        self, *, db: Session, company_id: int, page: Optional[int] = None
    ):
        objs = db.query(Object).filter(Object.company_id == company_id)
        return pagination.get_page(objs, page)

    def get_objects_by_foreman_id(
        self, *, db: Session, foreman_id: int, page: Optional[int] = None
    ):
        objs = db.query(Object).filter(Object.foreman_id == foreman_id)
        return pagination.get_page(objs, page)

    def get_objects_by_mechanic_id(
        self, *, db: Session, mechanic_id: int, page: Optional[int] = None
    ):
        objs = db.query(Object).filter(Object.mechanic_id == mechanic_id)
        return pagination.get_page(objs, page)

    def get_object_by_client_id(
        self, *, db: Session, client_id: int, page: Optional[int] = None
    ):
        """
        Получение объектов для клиента по id.
        """
        objs = (
            db.query(self.model)
            .join(Company, Company.id == self.model.company_id)
            .join(UniversalUser, self.model.company_id == UniversalUser.company_id)
            .filter(UniversalUser.company_id == client_id)
        )
        return pagination.get_page(objs, page)

    def get_all_objects(
        self,
        *,
        db: Session,
    ):
        return db.query(self.model)


crud_objects = CrudObject(Object)
