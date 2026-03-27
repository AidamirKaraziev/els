from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import Organization, UniversalUser
from src.schemas.organization import OrganizationCreate, OrganizationUpdate


class CrudOrganization(CRUDBase[Organization, OrganizationCreate, OrganizationUpdate]):
    def create_organization(
        self, db: Session, *, new_data: Optional[OrganizationCreate]
    ):
        # проверка не существующих директоров
        if (
            db.query(UniversalUser)
            .filter(UniversalUser.id == new_data.director_id)
            .first()
            is None
        ):
            return None, -105, None

        # проверить есть ли с таким названием
        if (
            db.query(Organization).filter(Organization.title == new_data.title).first()
            is not None
        ):
            return None, -1141, None

        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_organization(
        self,
        db: Session,
        *,
        organization: Optional[OrganizationUpdate],
        organization_id: int,
    ):
        # проверить есть ли компания с таким id
        this_organization = (
            db.query(Organization).filter(Organization.id == organization_id).first()
        )
        if this_organization is None:
            return None, -114, None

        # Check_name
        if organization.title is not None:
            if this_organization.title != Organization.title:
                if (
                    db.query(Organization)
                    .filter(Organization.title == organization.title)
                    .first()
                    is not None
                ):
                    return None, -1141, None

        # проверка не существующих директоров
        if (
            db.query(UniversalUser)
            .filter(UniversalUser.id == organization.director_id)
            .first()
            is None
        ):
            return None, -105, None

        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=this_organization, obj_in=organization)
        return db_obj, 0, None

    def archiving_organization(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        organization_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=organization_id)
        if obj is None:
            return None, -114, None
        # вызвать архивацию
        obj, code, indexes = super().archiving(db=db, db_obj=obj)
        return obj, code, None

    def unzipping_organization(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        organization_id: int,
        role_list: list,
    ):
        # проверить роль
        code = crud_universal_users.check_role_list(
            current_user=current_user, role_list=role_list
        )
        if code != 0:
            return None, code, None
        # проверить есть ли такая компания
        obj = super().get(db=db, id=organization_id)
        if obj is None:
            return None, -114, None
        # вызвать архивацию
        obj, code, indexes = super().unzipping(db=db, db_obj=obj)
        return obj, code, None

    def get_org(self, *, db: Session, organization_id: int):
        org = db.query(Organization).filter(Organization.id == organization_id).first()
        if org is None:
            return None, -114, None
        return org, 0, None


crud_organizations = CrudOrganization(Organization)
