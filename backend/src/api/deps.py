"""Зависимости FastAPI: сессия базы, текущий пользователь, права, область.

Проверка прав живёт здесь, а не в CRUD, намеренно — см. `src/core/permissions.py`.
"""

from typing import Generator, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from src.core.access import AccessScope, read_scope, write_scope
from src.core.permissions import Permission, permissions_for
from src.core.security import (
    InvalidTokenError,
    decode_access_token,
    token_issued_at,
)
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import UniversalUser
from src.session import SessionLocal

# `auto_error=False`, потому что своя ошибка нужнее готовой: FastAPI на
# отсутствующий заголовок отвечает 403, а перехватчик на фронте будет
# обновлять токен по 401. Разнобой между «нет токена» и «токен протух»
# означал бы, что после протухания человека выкидывает на экран входа вместо
# тихого обновления.
bearer_scheme = HTTPBearer(
    description="Токен доступа из /api/v1/auth/login", auto_error=False
)


def get_db() -> Generator:
    db = None
    try:
        db = SessionLocal()
        yield db
    finally:
        if db is not None:
            db.close()


def get_current_user(
    db: Session = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> UniversalUser:
    """Пользователь из токена.

    Кроме подписи проверяется то, чего раньше не проверял никто:

    * пользователь ещё работает (`is_active`) — иначе уволенный сотрудник
      ходил бы по системе до истечения токена;
    * токен выпущен не раньше последней смены пароля — иначе смена пароля
      после кражи ничего не давала.
    """
    invalid = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Не удалось проверить токен доступа",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if credentials is None:
        raise invalid

    try:
        payload = decode_access_token(credentials.credentials)
    except InvalidTokenError:
        raise invalid from None

    user = crud_universal_users.get(db, id=int(payload["sub"]))
    if user is None:
        # Именно 401, а не 404: пользователя удалили, но токен на руках
        # остался. Для клиента это «войдите заново», а не «нет такой записи».
        raise invalid

    if user.is_active is False:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Доступ к системе закрыт администратором",
        )

    if user.password_changed_at is not None:
        if token_issued_at(payload) < user.password_changed_at:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Пароль был изменён, войдите заново",
                headers={"WWW-Authenticate": "Bearer"},
            )

    return user


# Прежнее имя. На него завязаны 133 ручки, и переводить их на права — работа
# этапа 4; до тех пор они получают хотя бы честную проверку активности и
# смены пароля, чего раньше не было.
#
# Здесь же лежали две функции, выглядевшие рабочими, но нерабочие:
# `get_current_universal_user` был объявлен с пустым `Depends()`, а
# `get_current_active_universal_user` звал несуществующий метод `is_active`.
# Обе удалены.
get_current_universal_user_by_bearer = get_current_user


def require(*permissions: Permission):
    """Зависимость, пускающая только с перечисленными правами.

    Требуются **все** перечисленные права, а не любое из них: так безопаснее
    ошибиться. Использование:

        user = Depends(require(Permission.OBJECT_UPDATE))
    """

    def dependency(
        current_user: UniversalUser = Depends(get_current_user),
    ) -> UniversalUser:
        granted = permissions_for(current_user.role_id)
        missing = [p for p in permissions if p not in granted]
        if missing:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Недостаточно прав для этого действия",
            )
        return current_user

    return dependency


def get_read_scope(
    current_user: UniversalUser = Depends(get_current_user),
) -> AccessScope:
    return read_scope(current_user)


def get_write_scope(
    current_user: UniversalUser = Depends(get_current_user),
) -> AccessScope:
    return write_scope(current_user)


def forbid_out_of_scope(detail: str = "Нет доступа к этой записи") -> HTTPException:
    """Единый отказ по области видимости.

    Отвечаем 403, а не 404: 404 строже (не подтверждает существование записи),
    но на фронте выглядит как пропавшие данные, и разбираться с этим будет
    человек, у которого «вчера работало».
    """
    return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail)
