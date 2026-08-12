"""Вход, обновление токена, выход и работа с паролем.

Пришло на смену `/cp/sign-in/` и `/cp/universal-user/me/`. Отличий три:
токенов теперь пара, сессию можно погасить, а пароль можно сменить, не
обращаясь к разработчику.
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, Path, Request, status
from sqlalchemy.orm import Session

from src.api import deps
from src.config import settings
from src.core.permissions import Permission
from src.core.response import BaseResponse, ListOfEntityResponse, SingleEntityResponse
from src.core.security import (
    InvalidTokenError,
    create_access_token,
    create_password_reset_token,
    decode_password_reset_token,
    token_matches_password,
    verify_password,
)
from src.crud.crud_refresh_session import (
    RefreshTokenInvalid,
    RefreshTokenReused,
    crud_refresh_sessions,
)
from src.crud.users.crud_universal_user import crud_universal_users
from src.exceptions import InaccessibleEntity, UnfoundEntity, UnprocessableEntity
from src.getters.universal_user import get_universal_user
from src.models import UniversalUser
from src.schemas.auth import (
    AdminPasswordReset,
    LoginRequest,
    PasswordChangeRequest,
    PasswordResetConfirm,
    PasswordResetRequest,
    RefreshRequest,
    SessionGet,
    TokenPair,
)
from src.schemas.universal_user import UniversalUserEntrance, UniversalUserGet
from src.services.mail import send_password_reset

_log = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Авторизация"])


def _device_marks(request: Request):
    """Чем помечаем сессию, чтобы человек узнал своё устройство в списке."""
    return (
        request.headers.get("user-agent"),
        request.client.host if request.client else None,
    )


def _token_pair(db: Session, *, user: UniversalUser, request: Request) -> TokenPair:
    user_agent, ip = _device_marks(request)
    refresh_token, _ = crud_refresh_sessions.create(
        db, user_id=user.id, user_agent=user_agent, ip_address=ip
    )
    return TokenPair(
        access_token=create_access_token(
            user_id=user.id, password_changed_at=user.password_changed_at
        ),
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post(
    "/login",
    response_model=SingleEntityResponse[TokenPair],
    name="Войти в систему",
    description=(
        "Возвращает пару токенов. Токен доступа кладётся в заголовок "
        "`Authorization: Bearer`, токен обновления хранится и используется "
        "только на `/auth/refresh`."
    ),
)
def login(
    data: LoginRequest,
    request: Request,
    db: Session = Depends(deps.get_db),
):
    user = crud_universal_users.authenticate(
        db=db,
        entrance_data=UniversalUserEntrance(email=data.email, password=data.password),
    )
    return SingleEntityResponse(data=_token_pair(db, user=user, request=request))


@router.post(
    "/refresh",
    response_model=SingleEntityResponse[TokenPair],
    name="Обновить токен доступа",
    description=(
        "Гасит предъявленный токен обновления и выдаёт новую пару. "
        "Запросы на обновление нельзя отправлять параллельно: второй придёт на "
        "уже погашенную сессию."
    ),
)
def refresh(
    data: RefreshRequest,
    request: Request,
    db: Session = Depends(deps.get_db),
):
    user_agent, ip = _device_marks(request)
    try:
        refresh_token, session = crud_refresh_sessions.rotate(
            db, token=data.refresh_token, user_agent=user_agent, ip_address=ip
        )
    except RefreshTokenReused:
        _log.warning("Повторное использование refresh-токена, сессии отозваны")
        raise InaccessibleEntity(
            message="Сессия завершена",
            num=136,
            description=(
                "Токен обновления был использован повторно. Все сессии "
                "завершены, войдите заново."
            ),
            path="$.body.refresh_token",
        ) from None
    except RefreshTokenInvalid:
        raise UnprocessableEntity(
            message="Требуется вход",
            num=137,
            description="Токен обновления недействителен или истёк",
            path="$.body.refresh_token",
        ) from None

    user = crud_universal_users.get(db, id=session.user_id)
    if user is None or user.is_active is False:
        # Сотрудника уволили, пока сессия была жива.
        crud_refresh_sessions.revoke_all_for_user(db, user_id=session.user_id)
        raise InaccessibleEntity(
            message="Доступ к системе закрыт",
            num=138,
            description="Обратитесь к администратору",
            path="$.body",
        )

    return SingleEntityResponse(
        data=TokenPair(
            access_token=create_access_token(
                user_id=user.id, password_changed_at=user.password_changed_at
            ),
            refresh_token=refresh_token,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )
    )


@router.post(
    "/logout",
    response_model=BaseResponse,
    name="Выйти",
    description="Гасит одну сессию — ту, чей токен обновления передан.",
)
def logout(data: RefreshRequest, db: Session = Depends(deps.get_db)):
    # Ответ одинаковый независимо от того, нашлась сессия или нет: выход не
    # должен превращаться в способ проверять чужие токены.
    crud_refresh_sessions.revoke(db, token=data.refresh_token)
    return BaseResponse(message="Ok", description="Сессия завершена")


@router.post(
    "/logout-all",
    response_model=BaseResponse,
    name="Выйти со всех устройств",
    description="Гасит все сессии текущего пользователя, включая текущую.",
)
def logout_all(
    db: Session = Depends(deps.get_db),
    current_user: UniversalUser = Depends(deps.get_current_user),
):
    count = crud_refresh_sessions.revoke_all_for_user(db, user_id=current_user.id)
    return BaseResponse(message="Ok", description=f"Завершено сессий: {count}")


@router.get(
    "/me",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Мой профиль",
    description="Данные текущего пользователя по токену доступа.",
)
def me(
    request: Request,
    current_user: UniversalUser = Depends(deps.get_current_user),
):
    return SingleEntityResponse(data=get_universal_user(current_user, request=request))


@router.get(
    "/sessions",
    response_model=ListOfEntityResponse[SessionGet],
    name="Мои устройства",
    description="Живые сессии текущего пользователя.",
)
def sessions(
    db: Session = Depends(deps.get_db),
    current_user: UniversalUser = Depends(deps.get_current_user),
):
    rows = crud_refresh_sessions.active_for_user(db, user_id=current_user.id)
    return ListOfEntityResponse(data=[SessionGet.from_orm(row) for row in rows])


@router.post(
    "/password/change",
    response_model=BaseResponse,
    name="Сменить пароль",
    description=(
        "Меняет пароль текущего пользователя. Все сессии и все выданные ранее "
        "токены доступа перестают действовать — придётся войти заново."
    ),
)
def change_password(
    data: PasswordChangeRequest,
    db: Session = Depends(deps.get_db),
    current_user: UniversalUser = Depends(deps.get_current_user),
):
    if not verify_password(data.current_password, current_user.hashed_password):
        raise UnprocessableEntity(
            message="Текущий пароль указан неверно",
            num=139,
            description="Проверьте текущий пароль",
            path="$.body.current_password",
        )
    crud_universal_users.set_password(
        db=db, user=current_user, raw_password=data.new_password
    )
    return BaseResponse(
        message="Ok", description="Пароль изменён, войдите заново на всех устройствах"
    )


@router.post(
    "/password/reset-request",
    response_model=BaseResponse,
    name="Забыли пароль",
    description=(
        "Отправляет ссылку для смены пароля. Ответ одинаковый независимо от "
        "того, заведён такой адрес или нет."
    ),
)
def request_password_reset(
    data: PasswordResetRequest, db: Session = Depends(deps.get_db)
):
    user = crud_universal_users.get_by_email(db=db, email=data.email)
    if user is not None and user.is_active is not False:
        send_password_reset(
            to=user.email,
            name=user.name,
            reset_token=create_password_reset_token(
                user_id=user.id, password_changed_at=user.password_changed_at
            ),
        )
    # Ответ не зависит от того, нашёлся человек или нет: иначе форма
    # «забыли пароль» превращается в способ выяснить, кто заведён в системе.
    return BaseResponse(
        message="Ok",
        description="Если такой адрес заведён, на него отправлена ссылка",
    )


@router.post(
    "/password/reset-confirm",
    response_model=BaseResponse,
    name="Задать новый пароль по ссылке",
    description="Принимает токен из письма и задаёт новый пароль.",
)
def confirm_password_reset(
    data: PasswordResetConfirm, db: Session = Depends(deps.get_db)
):
    expired_link = UnprocessableEntity(
        message="Ссылка недействительна",
        num=140,
        description="Ссылка устарела или уже использована. Запросите новую.",
        path="$.body.token",
    )

    try:
        payload = decode_password_reset_token(data.token)
    except InvalidTokenError:
        raise expired_link from None

    user = crud_universal_users.get(db, id=int(payload["sub"]))
    if user is None or user.is_active is False:
        raise expired_link

    # Одноразовость без отдельной таблицы: в токене лежит отпечаток пароля,
    # действовавшего на момент выпуска. Ссылкой воспользовались — пароль
    # сменился — отпечаток перестал совпадать, и повторно она не сработает.
    if not token_matches_password(payload, user.password_changed_at):
        raise expired_link

    crud_universal_users.set_password(db=db, user=user, raw_password=data.new_password)
    return BaseResponse(message="Ok", description="Пароль изменён, войдите с новым")


@router.post(
    "/users/{user_id}/password",
    response_model=BaseResponse,
    name="Сбросить пароль сотруднику",
    description=(
        "Задаёт сотруднику новый пароль и завершает все его сессии. "
        "Нужно право на изменение пользователей."
    ),
)
def reset_password_by_admin(
    data: AdminPasswordReset,
    user_id: int = Path(..., title="ID пользователя"),
    db: Session = Depends(deps.get_db),
    current_user: UniversalUser = Depends(deps.require(Permission.USER_UPDATE)),
):
    user = crud_universal_users.get(db, id=user_id)
    if user is None:
        raise UnfoundEntity(
            message="Нет такого пользователя!",
            num=105,
            description="Нет пользователя с таким id!",
            path="$.path.user_id",
        )
    crud_universal_users.set_password(db=db, user=user, raw_password=data.new_password)
    _log.info("Пароль пользователя %s сброшен админом %s", user.id, current_user.id)
    return BaseResponse(message="Ok", description="Пароль задан, сессии завершены")


@router.delete(
    "/sessions/{session_id}",
    response_model=BaseResponse,
    status_code=status.HTTP_200_OK,
    name="Завершить сессию",
    description="Гасит одно устройство из списка своих сессий.",
)
def revoke_session(
    session_id: int = Path(..., title="ID сессии"),
    db: Session = Depends(deps.get_db),
    current_user: UniversalUser = Depends(deps.get_current_user),
):
    from src.models import RefreshSession

    session: Optional[RefreshSession] = (
        db.query(RefreshSession)
        .filter(
            RefreshSession.id == session_id,
            # Чужую сессию погасить нельзя, поэтому фильтр по владельцу стоит
            # прямо в запросе, а не проверкой после выборки.
            RefreshSession.user_id == current_user.id,
        )
        .first()
    )
    if session is None:
        raise UnfoundEntity(
            message="Сессия не найдена",
            num=141,
            description="Такой сессии нет или она уже завершена",
            path="$.path.session_id",
        )
    if session.revoked_at is None:
        from datetime import datetime

        session.revoked_at = datetime.utcnow()
        db.add(session)
        db.commit()
    return BaseResponse(message="Ok", description="Сессия завершена")
