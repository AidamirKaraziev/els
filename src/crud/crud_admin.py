from sqlalchemy.orm import Session

from src.core.roles import ADMIN
from src.crud.base_user import CRUDBaseUser
from src.models import Company, UniversalUser
from src.schemas.admin import AdminCreate
from src.schemas.client import ClientCreate
from src.schemas.universal_user import (
    EmployeeCreate,
    UniversalUserCompany,
    UniversalUserCreate,
    UniversalUserUpdate,
)

ROLE_LIST = [ADMIN]


class CrudAdmin(CRUDBaseUser[UniversalUser, UniversalUserCreate, UniversalUserUpdate]):
    def create_user_employee(
        self, db: Session, new_data: EmployeeCreate, current_user: UniversalUser
    ):
        # проверить есть ли такой юзер
        admin = (
            db.query(UniversalUser).filter(UniversalUser.id == current_user.id).first()
        )
        if admin is None:
            return None, -105, None
        # Проверить есть ли у него роль 1
        if admin.role_id != 1:
            return None, -1022, None
        db_obj, code, indexes = super().create_employee(db=db, new_data=new_data)
        return db_obj, code, indexes

    def create_user_admin(
        self, db: Session, new_data: AdminCreate, current_user: UniversalUser
    ):
        # проверить есть ли такой юзер
        admin = (
            db.query(UniversalUser).filter(UniversalUser.id == current_user.id).first()
        )
        if admin is None:
            return None, -105, None
        # Проверить есть ли у него роль 1
        if admin.role_id != 1:
            return None, -1022, None
        db_obj, code, indexes = super().create_admin(db=db, new_data=new_data)
        return db_obj, code, indexes

    def create_user_client(
        self, db: Session, new_data: ClientCreate, current_user: UniversalUser
    ):
        # проверить есть ли такой юзер
        admin = (
            db.query(UniversalUser).filter(UniversalUser.id == current_user.id).first()
        )
        if admin is None:
            return None, -105, None
        # Проверить есть ли у него роль 1
        if admin.role_id != 1:
            return None, -1022, None
        db_obj, code, indexes = super().create_client(db=db, new_data=new_data)
        return db_obj, code, indexes

    def change_company_for_client(
        self,
        *,
        db: Session,
        current_user: UniversalUser,
        company: UniversalUserCompany,
        client_id: int,
        role_list: list,
        client_list: list,
    ):
        # проверить роль админа
        code = self.check_role_list(current_user=current_user, role_list=role_list)
        if code != 0:
            return None, code, None
        # проверить роль меняемого
        client = self.get(db=db, id=client_id)
        if client is None:
            return None, -105, None
        if client.role_id not in client_list:
            return None, -1042, None

        # проверка division_id
        com = db.query(Company).filter(Company.id == company.company_id).first()
        if com is None:
            return None, -106, None
        if com.is_actual is False:
            return None, -1063, None

        # загрузка данных новых
        db.query(UniversalUser).filter(UniversalUser.id == client_id).update(
            {"company_id": company.company_id}
        )
        db.commit()
        return client, 0, None


crud_admin = CrudAdmin(UniversalUser)
