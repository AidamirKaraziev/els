from typing import Optional

from sqlalchemy.orm import Session

from src.core.access import AccessScope, apply_object_scope, can_access_object
from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.crud.base import CRUDBase
from src.models import (
    Company,
    ContactPerson,
    Contract,
    Division,
    FactoryModel,
    Object,
    Organization,
    UniversalUser,
)
from src.schemas.object import ObjectCreate, ObjectUpdate
from src.utils import pagination
from src.utils.time_stamp import date_from_timestamp

ROLE_RIGHTS = [ADMIN, FOREMAN]
ROLE_MECHANIC = [MECHANIC]
ROLE_FOREMAN = [FOREMAN]


class CrudObject(CRUDBase[Object, ObjectCreate, ObjectUpdate]):
    # Запись вне области видимости — 403, см. `templates_raise.out_of_scope`.
    out_of_scope = -136

    def scoped_query(self, db: Session, scope: AccessScope):
        """Единственное место, где список объектов режется по области.

        Все выборки объектов начинаются отсюда. `scope` во всех читающих
        методах — обязательный именованный аргумент без значения по умолчанию:
        забытый фильтр должен ронять вызов на месте, а не тихо отдавать чужие
        лифты.
        """
        return apply_object_scope(db.query(self.model), scope)

    def create_object(self, db: Session, *, new_data: ObjectCreate, scope: AccessScope):
        # Новый лифт должен попадать в область того, кто его заводит: иначе
        # прораб создаёт объект на чужом участке и тут же перестаёт его видеть.
        # Схема создания несёт те же поля, что и модель, поэтому проверяется
        # той же функцией, что и готовая запись.
        if not can_access_object(scope, new_data):
            return None, self.out_of_scope, None
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
        self,
        db: Session,
        *,
        new_data: Optional[ObjectUpdate],
        object_id: int,
        scope: AccessScope,
    ):
        # проверить есть ли объект с таким id
        this_object = db.query(Object).filter(Object.id == object_id).first()
        if this_object is None:
            return None, -116, None
        # Область здесь на запись, а не на чтение: прораб видит все участки, а
        # правит только свои. Проверяется объект в его текущем виде — увести
        # чужой лифт к себе, подменив `division_id`, нельзя, потому что до
        # правки он уже вне области.
        if not can_access_object(scope, this_object):
            return None, self.out_of_scope, None

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

    def archiving_object(self, db: Session, *, object_id: int, scope: AccessScope):
        # Проверки роли здесь больше нет: право объявлено на ручке
        # (`Permission.OBJECT_UPDATE`), а CRUD отвечает только за область.
        obj = super().get(db=db, id=object_id)
        if obj is None:
            return None, -116, None
        if not can_access_object(scope, obj):
            return None, self.out_of_scope, None
        obj, code, indexes = super().archiving(db=db, db_obj=obj)
        return obj, code, None

    def unzipping_object(self, db: Session, *, object_id: int, scope: AccessScope):
        obj = super().get(db=db, id=object_id)
        if obj is None:
            return None, -116, None
        if not can_access_object(scope, obj):
            return None, self.out_of_scope, None
        obj, code, indexes = super().unzipping(db=db, db_obj=obj)
        return obj, code, None

    def get_multi(self, db: Session, *, scope: AccessScope, page: Optional[int] = None):
        """Список объектов. Перекрывает `CRUDBase.get_multi` ради `scope`.

        Сигнатура намеренно расходится с базовой: старый вызов без области
        упадёт `TypeError` при первом же запросе, а не отдаст всю таблицу.
        """
        return pagination.get_page(self.scoped_query(db, scope), page)

    def get_object_by_id(self, *, db: Session, object_id: int, scope: AccessScope):
        """Один объект по id.

        Разделяем «нет такого» и «не ваш»: 404 на чужую запись выглядел бы как
        пропавшие данные. Ищем без фильтра и сверяемся `can_access_object` —
        так список и одиночный запрос отвечают по одному правилу.
        """
        obj = db.query(self.model).filter(self.model.id == object_id).first()
        if obj is None:
            return None, -116, None
        if not can_access_object(scope, obj):
            return None, self.out_of_scope, None
        return obj, 0, None

    def get_objects_by_company_id(
        self,
        *,
        db: Session,
        company_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
    ):
        objs = self.scoped_query(db, scope).filter(Object.company_id == company_id)
        return pagination.get_page(objs, page)

    def get_objects_by_foreman_id(
        self,
        *,
        db: Session,
        foreman_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
    ):
        objs = self.scoped_query(db, scope).filter(Object.foreman_id == foreman_id)
        return pagination.get_page(objs, page)

    def get_objects_by_mechanic_id(
        self,
        *,
        db: Session,
        mechanic_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
    ):
        objs = self.scoped_query(db, scope).filter(Object.mechanic_id == mechanic_id)
        return pagination.get_page(objs, page)

    def get_object_by_client_id(
        self,
        *,
        db: Session,
        client_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
    ):
        """
        Получение объектов для клиента по id.
        """
        objs = (
            self.scoped_query(db, scope)
            .join(Company, Company.id == self.model.company_id)
            .join(UniversalUser, self.model.company_id == UniversalUser.company_id)
            .filter(UniversalUser.company_id == client_id)
        )
        return pagination.get_page(objs, page)

    def get_all_objects(self, *, db: Session, scope: AccessScope):
        return pagination.get_page(self.scoped_query(db, scope), None)


crud_objects = CrudObject(Object)
