from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import Company, Location, UniversalUser
from src.schemas.company import CompanyCreate, CompanyUpdate

DATA_FOLDER_COMPANY = "./static/photo_company/"


class CrudCompany(CRUDBase[Company, CompanyCreate, CompanyUpdate]):
    def create_company(self, db: Session, *, new_data: Optional[CompanyCreate]):
        # проверить есть ли с таким названием
        if db.query(Company).filter(Company.name == new_data.name).first() is not None:
            return None, -1061, None
        if new_data.location_id is not None:
            loc = db.query(Location).filter(Location.id == new_data.location_id).first()
            if loc is None:
                return None, -101, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_company(
        self, db: Session, *, company: Optional[CompanyUpdate], company_id: int
    ):
        # проверить есть ли компания с таким id
        this_company = db.query(Company).filter(Company.id == company_id).first()
        if this_company is None:
            return None, -106, None

        # Check_name
        if company.name is not None:
            if this_company.name != Company.name:
                if (
                    db.query(Company).filter(Company.name == company.name).first()
                    is not None
                ):
                    return None, -1061, None

        # Проверить города
        if company.location_id is not None:
            loc = db.query(Location).filter(Location.id == company.location_id).first()
            if loc is None:
                return None, -101, None

        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=this_company, obj_in=company)
        return db_obj, 0, None

    def archiving_company(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        company_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=company_id)
        if obj is None:
            return None, -106, None
        # вызвать архивацию
        obj, code, indexes = super().archiving(db=db, db_obj=obj)
        return obj, code, None

    def unzipping_company(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        company_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=company_id)
        if obj is None:
            return None, -106, None
        # вызвать архивацию
        obj, code, indexes = super().unzipping(db=db, db_obj=obj)
        return obj, code, None

    def get_company_by_id(self, *, db: Session, company_id: int):
        comp = db.query(Company).filter(Company.id == company_id).first()
        if comp is None:
            return None, -106, None
        return comp, 0, None


crud_company = CrudCompany(Company)
