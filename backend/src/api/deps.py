"""Зависимости FastAPI: сессия базы, текущий пользователь, права, область.

Проверка прав живёт здесь, а не в CRUD, намеренно — см. `src/core/permissions.py`.
"""

from typing import Generator, Optional

from fastapi import Depends, HTTPException, Query, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from src.core.access import AccessScope, read_scope, write_scope
from src.core.permissions import Permission, permissions_for
from src.core.security import (
    InvalidTokenError,
    decode_access_token,
    decode_file_token,
    token_matches_password,
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

    if not token_matches_password(payload, user.password_changed_at):
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


def get_link_requester(
    request: Request,
    token: Optional[str] = Query(
        None,
        title="Короткоживущий токен на этот файл",
        description=(
            "Альтернатива заголовку `Authorization` для случаев, когда его "
            "отправить нельзя: `<img src>` и переход по ссылке на скачивание. "
            "Выдаётся ручкой `POST /api/v1/files/link`."
        ),
    ),
    db: Session = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> UniversalUser:
    """Пользователь по заголовку либо по короткоживущему токену в адресе.

    Ставится на ручки, которые нужно уметь открыть в новой вкладке: отдача
    загруженного файла и выгрузка отчёта в PDF.

    Заголовок — основной путь, он же единственный безопасный. Токен в адресе
    существует потому, что браузер физически не может послать заголовок при
    загрузке картинки или переходе по ссылке; он привязан к одному пути и
    живёт минуту (`core.security.create_file_token`).

    Порядок важен: сначала заголовок. Иначе запрос с обоими способами сразу
    проверялся бы по более слабому.
    """
    if credentials is not None:
        return get_current_user(db=db, credentials=credentials)

    invalid = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Не удалось проверить токен доступа",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not token:
        raise invalid

    # Путь берём из самого запроса: токен выдан на конкретный адрес, и
    # сверять его надо с тем, что человек запрашивает сейчас, иначе одна
    # ссылка открывала бы любой файл.
    try:
        payload = decode_file_token(token, path=request.url.path)
    except InvalidTokenError:
        raise invalid from None

    user = crud_universal_users.get(db, id=int(payload["sub"]))
    if user is None or user.is_active is False:
        raise invalid
    return user


def get_link_scope(
    current_user: UniversalUser = Depends(get_link_requester),
) -> AccessScope:
    """Область видимости для запроса по ссылке с токеном.

    Отдельная от `get_read_scope` только источником пользователя: тот берёт
    его из заголовка, а к файлу можно прийти и с токеном в адресе. Правила
    области дальше те же самые.
    """
    return read_scope(current_user)


def forbid_out_of_scope(detail: str = "Нет доступа к этой записи") -> HTTPException:
    """Единый отказ по области видимости.

    Отвечаем 403, а не 404: 404 строже (не подтверждает существование записи),
    но на фронте выглядит как пропавшие данные, и разбираться с этим будет
    человек, у которого «вчера работало».
    """
    return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail)
