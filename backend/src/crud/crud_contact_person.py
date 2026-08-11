from typing import List, Optional, Tuple

from sqlalchemy.orm import Session

from src.core.response import Paginator
from src.core.roles import ADMIN, CLIENT_ID, FOREMAN
from src.crud.base import CRUDBase, ModelType
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import Company, ContactPerson, UniversalUser
from src.schemas.contact_person import ContactPersonCreate, ContactPersonUpdate
from src.utils import pagination

DATA_FOLDER_CONTACT_PERSON = "./static/photo_contact_person/"
ADMIN_FOREMAN_LIST = [ADMIN, FOREMAN, CLIENT_ID]


class CrudContactPerson(
    CRUDBase[ContactPerson, ContactPersonCreate, ContactPersonUpdate]
):
    def create_contact_person(
        self,
        db: Session,
        *,
        new_data: Optional[ContactPersonCreate],
        user: UniversalUser,
    ):
        # проверка ролей юзера
        if user.role_id not in ADMIN_FOREMAN_LIST:
            return None, -1, None

        # проверить есть ли такой персонаж
        if (
            db.query(ContactPerson)
            .filter(ContactPerson.phone == new_data.phone)
            .first()
            is not None
        ):
            return None, -2, None
        # проверить уникальность телефона
        # не надо скорее всего

        # проверить есть ли с таким названием
        if db.query(Company).filter(Company.id == new_data.company_id).first() is None:
            return None, -3, None

        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_contact_person(
        self,
        db: Session,
        *,
        new_data: Optional[ContactPersonUpdate],
        contact_person_id: int,
        user: UniversalUser,
    ):
        # проверка ролей юзера
        if user.role_id not in ADMIN_FOREMAN_LIST:
            return None, -1, None
        # проверить есть ли контактного лица с таким id
        this_contact_person = (
            db.query(ContactPerson)
            .filter(ContactPerson.id == contact_person_id)
            .first()
        )
        if this_contact_person is None:
            return None, -2, None
        # Check phone
        if this_contact_person.phone != new_data.phone:
            if (
                db.query(ContactPerson)
                .filter(ContactPerson.phone == new_data.phone)
                .first()
                is not None
            ):
                return None, -3, None
        # проверка компаний

        if new_data.company_id is not None:
            com = db.query(Company).filter(Company.id == new_data.company_id).first()
            if com is None:
                return None, -4, None
        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=this_contact_person, obj_in=new_data)
        return db_obj, 0, None

    # Функция добавления фото
    def updating_photo(self):
        pass

    def archiving_contact_person(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        contact_person_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=contact_person_id)
        if obj is None:
            return None, -113, None
        # вызвать архивацию
        obj, code, indexes = super().archiving(db=db, db_obj=obj)
        return obj, code, None

    def unzipping_contact_person(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        contact_person_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=contact_person_id)
        if obj is None:
            return None, -113, None
        # вызвать архивацию
        obj, code, indexes = super().unzipping(db=db, db_obj=obj)
        return obj, code, None

    def get_contact_person_by_company_id(
        self, *, db: Session, company_id: int, page: Optional[int] = None
    ) -> Tuple[List[ModelType], Paginator]:
        objs = db.query(ContactPerson).filter(ContactPerson.company_id == company_id)
        return pagination.get_page(objs, page)


crud_contact_person = CrudContactPerson(ContactPerson)
