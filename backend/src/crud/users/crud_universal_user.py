from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from src.config import settings
from src.core.access import AccessScope, can_access_user
from src.core.roles import ADMIN, CLIENT_ID
from src.core.security import (
    get_password_hash,
    validate_password_strength,
    verify_password,
)
from src.crud.base_user import CRUDBaseUser
from src.exceptions import UnprocessableEntity
from src.models import Division, Location, UniversalUser, WorkingSpecialty
from src.schemas.foreman import ForemanCreate
from src.schemas.universal_user import (
    UniversalUserCreate,
    UniversalUserEntrance,
    UniversalUserUpdate,
)
from src.utils import pagination
from src.utils.time_stamp import date_from_timestamp

ADMIN_LIST = [ADMIN]


class CrudUniversalUser(
    CRUDBaseUser[UniversalUser, UniversalUserCreate, UniversalUserUpdate]
):
    # Запись вне области видимости — 403, см. `templates_raise.out_of_scope`.
    out_of_scope = -136

    def create_foreman(
        self, db: Session, *, current_user: UniversalUser, new_data: ForemanCreate
    ):
        # проверить есть ли такой current_user
        admin = (
            db.query(UniversalUser).filter(UniversalUser.id == current_user.id).first()
        )
        if admin is None:
            return None, -1, None
        # проверить должность current_user
        if current_user.role_id != 1:
            return None, -2, None
        # проверка есть ли такой email in db
        if self.get_by_email(db=db, email=new_data.email) is not None:
            return None, -3, None  # have email in db
        psw, code = self._hash_new_password(new_data.password)
        if code != 0:
            return None, code, None
        new_data.password = psw

        # Проверить дату дня рождения
        if new_data.birthday is not None:
            new_data.birthday = date_from_timestamp(new_data.birthday)

        if new_data.location_id is not None:
            loc = db.query(Location).filter(Location.id == new_data.location_id).first()
            if loc is None:
                return None, -4, None  # нет города

        if new_data.role_id != 2:
            return None, -5, None

        if new_data.working_specialty_id is not None:
            spec = (
                db.query(WorkingSpecialty)
                .filter(WorkingSpecialty.id == new_data.working_specialty_id)
                .first()
            )
            if spec is None:
                return None, -6, None
        # Проверить участок
        if new_data.division_id is not None:
            div = db.query(Division).filter(Division.id == new_data.division_id).first()
            if div is None:
                return None, -7, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def authenticate(
        self, *, db: Session, entrance_data: UniversalUserEntrance
    ) -> UniversalUser:
        """Проверяет логин и пароль. Единственный вход в систему.

        Раньше здесь была ещё и вторая копия в `CRUDBaseUser`, причём с другой
        проверкой доступа. Осталась одна.
        """
        user = self.get_by_email(db=db, email=entrance_data.email)

        if user is not None and self._is_locked(user):
            raise UnprocessableEntity(
                message="Слишком много попыток входа",
                num=1,
                description=(
                    "Вход временно заблокирован. Попробуйте через "
                    f"{settings.LOGIN_LOCKOUT_MINUTES} минут."
                ),
                path="$.body",
            )

        password_ok = user is not None and verify_password(
            plain_password=entrance_data.password,
            hashed_password=user.hashed_password,
        )
        if not password_ok:
            if user is not None:
                self._register_failed_attempt(db=db, user=user)
            # Один и тот же текст на «нет такого email» и «неверный пароль»:
            # иначе форма входа превращается в способ узнать, кто заведён
            # в системе.
            raise UnprocessableEntity(
                message="Неверный логин или пароль",
                num=1,
                description="Неверный логин или пароль",
                path="$.body",
            )

        if user.is_active is False:
            raise UnprocessableEntity(
                message="Вам отказано в доступе",
                num=1,
                description="Администратор ограничил вам доступ",
                path="$.body",
            )

        self._reset_failed_attempts(db=db, user=user)
        return user

    def set_password(
        self, *, db: Session, user: UniversalUser, raw_password: str
    ) -> UniversalUser:
        """Задаёт пароль и завершает все сессии пользователя.

        Сессии гасятся всегда — и при добровольной смене, и при сбросе
        админом. Смена пароля после кражи токена не имеет смысла, если
        украденный токен продолжает работать.

        `password_changed_at` заодно гасит все ранее выданные токены доступа:
        `deps.get_current_user` сравнивает с ним время выпуска токена.
        """
        from src.crud.crud_refresh_session import crud_refresh_sessions

        validate_password_strength(raw_password)

        user.hashed_password = get_password_hash(raw_password)
        # Без микросекунд: отпечаток пароля в токене считается по целым
        # секундам (`core.security.password_stamp`), и дробная часть в базе
        # ничего не даёт, а сравнение делает хрупким.
        user.password_changed_at = datetime.utcnow().replace(microsecond=0)
        user.failed_login_attempts = 0
        user.locked_until = None
        db.add(user)
        db.commit()
        db.refresh(user)

        crud_refresh_sessions.revoke_all_for_user(db, user_id=user.id)
        return user

    def _is_locked(self, user: UniversalUser) -> bool:
        return user.locked_until is not None and user.locked_until > datetime.utcnow()

    def _register_failed_attempt(self, *, db: Session, user: UniversalUser) -> None:
        user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
        if user.failed_login_attempts >= settings.LOGIN_MAX_FAILED_ATTEMPTS:
            user.locked_until = datetime.utcnow() + timedelta(
                minutes=settings.LOGIN_LOCKOUT_MINUTES
            )
            user.failed_login_attempts = 0
        db.add(user)
        db.commit()

    def _reset_failed_attempts(self, *, db: Session, user: UniversalUser) -> None:
        if user.failed_login_attempts or user.locked_until:
            user.failed_login_attempts = 0
            user.locked_until = None
            db.add(user)
            db.commit()

    def get_by_email(self, db: Session, *, email: str) -> Optional[UniversalUser]:
        """Ищет по email без учёта регистра.

        В базе есть адреса вида `Голдобин@mail.ru` и `Zarja@rambler.ru`.
        Поиск по точному совпадению строки означал, что человек, набравший
        свой адрес строчными буквами, просто не мог войти.
        """
        return (
            db.query(UniversalUser)
            .filter(func.lower(UniversalUser.email) == func.lower(email))
            .first()
        )

    def get_user_by_reference(self, db: Session, *, user_id: int):
        """Существует ли такой человек — для проверки ссылок на него.

        Области здесь намеренно нет. Это не выдача данных, а проверка, что
        указанный исполнитель или ответственный вообще заведён: назначить
        инженера можно на объект любого участка, и фильтр по области сломал бы
        согласованное правило, ничего не защитив — id и так пришёл от клиента.
        """
        user = db.query(UniversalUser).filter(UniversalUser.id == user_id).first()
        if user is None:
            return None, -130, None
        return user, 0, None

    def get_user_by_id(self, db: Session, *, user_id: int, scope: AccessScope):
        user = db.query(UniversalUser).filter(UniversalUser.id == user_id).first()
        if user is None:
            return None, -130, None
        if not can_access_user(scope, user):
            return None, self.out_of_scope, None
        return user, 0, None

    def get_user_by_role_id(
        self,
        *,
        db: Session,
        role_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
    ):
        objs = self.scoped_query(db, scope).filter(UniversalUser.role_id == role_id)
        return pagination.get_page(objs, page)

    def delete_user_by_id(
        self, *, db: Session, user_id: int, current_user_id: int, scope: AccessScope
    ):
        user, code, indexes = self.get_user_by_id(db=db, user_id=user_id, scope=scope)
        if code != 0:
            return None, code, None
        if user.id == current_user_id:
            return None, -1301, None
        self.remove(db=db, id=user_id)
        return f"Юзер с id {user_id} - удален!", 0, None

    def get_clients_by_company_id(
        self, *, db: Session, company_id: int, scope: AccessScope
    ):
        from src.crud.crud_company import crud_company

        # проверка на компанию
        company, code, indexes = crud_company.get_company_by_id(
            db=db, company_id=company_id
        )
        if code != 0:
            return None, code, None
        clients = (
            self.scoped_query(db, scope)
            .filter(
                UniversalUser.company_id == company_id,
                UniversalUser.role_id == CLIENT_ID,
            )
            .order_by(UniversalUser.id)
            .all()
        )
        return clients, 0, None


crud_universal_users = CrudUniversalUser(UniversalUser)
