import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Query, Request, UploadFile
from fastapi.params import Path
from sqlalchemy.orm import Session

from src.api import deps
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.security import create_access_token
from src.crud.crud_company import crud_company
from src.crud.crud_role import crud_role
from src.crud.users.crud_universal_user import crud_universal_users
from src.exceptions import UnfoundEntity
from src.getters.universal_user import get_universal_user
from src.schemas.token import TokenBase
from src.schemas.universal_user import (
    UniversalUserEntrance,
    UniversalUserGet,
    UniversalUserUpdate,
)
from src.templates_raise import get_raise

PATH_MODEL = "universal_user"
PATH_TYPE_PHOTO = "photo"
PATH_TYPE_IDENTITY_CARD = "identity_card"
PATH_TYPE_QUALIFICATION = "qualification_file"

router = APIRouter()


# SIGN-IN
# Вход по почте и паролю
@router.post(
    path="/cp/sign-in/",
    response_model=SingleEntityResponse[TokenBase],
    name="Войти в админ панель",
    description="Войти в админ панель",
    tags=["Вход / Админ панель"],
)
def entrance(
    entrance_data: UniversalUserEntrance,
    session: Session = Depends(deps.get_db),
):
    db_obj = crud_universal_users.authenticate(db=session, entrance_data=entrance_data)
    # Временно: ручка уезжает в /auth/login на этапе 3, там же появится
    # refresh-токен. Пока отдаём только access, чтобы фронт не встал.
    token = create_access_token(user_id=db_obj.id)
    return SingleEntityResponse(data=TokenBase(token=token))


@router.get(
    "/cp/all-users/",
    response_model=ListOfEntityResponse,
    name="Список пользователей",
    description="Получение списка всех пользователей",
    tags=["Админ панель / Пользователь"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_universal_users.get_multi(db=session, page=None))

    data, paginator = crud_universal_users.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_universal_user(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    "/universal-user/sort-by-role/{role_id}/",
    response_model=ListOfEntityResponse,
    name="get_users_by_role_id",
    description="Получение пользователей по роли",
    tags=["Админ панель / Пользователь"],
)
def get_users_by_role_id(
    request: Request,
    role_id: int = Path(..., title="ID модели техники"),
    # current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
    page: Optional[int] = Query(None, title="Номер страницы"),
):
    obj, code, indexes = crud_role.get_role_by_id(db=session, role_id=role_id)
    get_raise(code=code)
    data, paginator = crud_universal_users.get_user_by_role_id(
        db=session, page=page, role_id=role_id
    )

    return ListOfEntityResponse(
        data=[get_universal_user(datum, request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    "/cp/all-employee/",
    response_model=ListOfEntityResponse,
    name="Список сотрудников",
    description="Получение списка всех сотрудников",
    tags=["Админ панель / Пользователь"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_universal_users.get_multi_employee(db=session, page=None))

    data, paginator = crud_universal_users.get_multi_employee(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_universal_user(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    "/cp/client/{company_id}/",
    response_model=ListOfEntityResponse,
    name="Список клиентов определенной компании",
    description="Список клиентов определенной компании",
    tags=["Админ панель / Пользователь"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    company_id: int = Path(..., title="ID user"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    page: int = Query(1, title="Номер страницы"),
):
    # проверка компании
    comp, code, indexes = crud_company.get_company_by_id(
        db=session, company_id=company_id
    )
    get_raise(code=code)

    logging.info(
        crud_universal_users.get_multi_client_by_company(
            db=session, company_id=company_id, page=None
        )
    )

    data, paginator = crud_universal_users.get_multi_client_by_company(
        db=session, page=page, company_id=company_id
    )

    return ListOfEntityResponse(
        data=[get_universal_user(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    "/cp/all-client/",
    response_model=ListOfEntityResponse,
    name="Список клиентов ",
    description="Список клиентов",
    tags=["Админ панель / Пользователь"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    page: int = Query(1, title="Номер страницы"),
):
    # проверка компании

    logging.info(crud_universal_users.get_multi_clients(db=session, page=None))

    data, paginator = crud_universal_users.get_multi_clients(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_universal_user(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    "/cp/universal-user/me/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Получить данные профиля ",
    description="Получение всех  данных профиля, по токену",
    tags=["Админ панель / Пользователь"],
)
def get_data(
    request: Request,
    current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    return SingleEntityResponse(
        data=get_universal_user(current_universal_user, request=request)
    )


@router.get(
    "/cp/universal-user/{user_id}/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Получить данные профиля по id ",
    description="Получение данных профиля по id",
    tags=["Админ панель / Пользователь"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    user_id: int = Path(..., title="ID user"),
    current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    user = crud_universal_users.get(db=session, id=user_id)
    if user is None:
        raise UnfoundEntity(
            message="Нет такого пользователя!",
            num=105,
            description="Нет пользователя с таким id!",
            path="$.body",
        )
    return SingleEntityResponse(data=get_universal_user(user, request=request))


@router.put(
    "/cp/universal-user/me/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Изменить пользователя",
    description="Изменить данные текущего пользователя",
    tags=["Админ панель / Пользователь"],
)
def update_user(
    request: Request,
    new_data: UniversalUserUpdate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    role_list = [current_user.role_id]
    changeable_list = role_list
    obj, code, indexes = crud_universal_users.updating_user(
        db=session,
        current_user=current_user,
        user_id=current_user.id,
        new_data=new_data,
        role_list=role_list,
        changeable_list=changeable_list,
    )

    get_raise(code=code)
    return SingleEntityResponse(data=get_universal_user(obj, request=request))


@router.put(
    "/cp/universal-user/me/photo/",
    response_model=SingleEntityResponse,
    name="Изменить фото",
    description="Изменить фото для пользователя, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Пользователь"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    save_path = crud_universal_users.adding_file(
        db=session,
        file=file,
        path_model=PATH_MODEL,
        path_type=PATH_TYPE_PHOTO,
        db_obj=current_user,
    )
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(data=get_universal_user(current_user, request=request))


@router.put(
    "/cp/universal-user/me/identity-card/",
    response_model=SingleEntityResponse,
    name="Изменить удостоверение",
    description="Изменить удостоверение для пользователя, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Пользователь"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    save_path = crud_universal_users.adding_file(
        db=session,
        file=file,
        path_model=PATH_MODEL,
        path_type=PATH_TYPE_IDENTITY_CARD,
        db_obj=current_user,
    )
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(data=get_universal_user(current_user, request=request))


@router.put(
    "/cp/universal-user/me/qualification-file/",
    response_model=SingleEntityResponse,
    name="Изменить ЦОК",
    description="Изменить ЦОК для пользователя, если отправить пустое поле - информация сбросится",
    tags=["Админ панель / Пользователь"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    save_path = crud_universal_users.adding_file(
        db=session,
        file=file,
        path_model=PATH_MODEL,
        path_type=PATH_TYPE_QUALIFICATION,
        db_obj=current_user,
    )
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(data=get_universal_user(current_user, request=request))


if __name__ == "__main__":
    logging.info("Running...")
