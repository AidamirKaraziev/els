from sqlalchemy.orm import Session

from src.core.roles import FOREMAN
from src.crud.base_user import CRUDBaseUser
from src.models import Division, UniversalUser
from src.schemas.universal_user import (
    EmployeeCreate,
    UniversalUserCreate,
    UniversalUserDivision,
    UniversalUserUpdate,
)

ROLE_FOREMAN = [FOREMAN]


class CrudForeman(
    CRUDBaseUser[UniversalUser, UniversalUserCreate, UniversalUserUpdate]
):
    def create_user_employee(
        self, db: Session, new_data: EmployeeCreate, current_user: UniversalUser
    ):
        # проверить есть ли такой юзер
        foreman = (
            db.query(UniversalUser).filter(UniversalUser.id == current_user.id).first()
        )
        if foreman is None:
            return None, -105, None
        # Проверить есть ли у него роль 1
        code = super().check_role_list(
            current_user=current_user, role_list=ROLE_FOREMAN
        )
        if code != 0:
            return None, code, None
        # if foreman.role_id != 2:
        #     return None, -1022, None
        db_obj, code, indexes = super().create_employee(db=db, new_data=new_data)
        return db_obj, code, indexes

    def change_division_id(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        division: UniversalUserDivision,
        role_list: list,
    ):
        # проверка роли
        code = super().check_role_list(current_user=current_user, role_list=role_list)
        if code != 0:
            return None, code, None
        # проверка division_id
        div = db.query(Division).filter(Division.id == division.division_id).first()
        if div is None:
            return None, -104, None
        if div.is_actual is False:
            return None, -1043, None
        # загрузка данных новых
        db.query(UniversalUser).filter(UniversalUser.id == current_user.id).update(
            {"division_id": division.division_id}
        )
        db.commit()
        user = super().get(db=db, id=current_user.id)
        return user, 0, None


crud_foreman = CrudForeman(UniversalUser)
