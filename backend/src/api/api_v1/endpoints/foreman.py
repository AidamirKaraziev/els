import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Request, UploadFile
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import SingleEntityResponse
from src.core.roles import DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_admin import crud_admin
from src.crud.crud_foreman import crud_foreman
from src.crud.users.crud_universal_user import crud_universal_users
from src.exceptions import UnfoundEntity
from src.getters.universal_user import get_universal_user
from src.schemas.universal_user import (
    EmployeeCreate,
    UniversalUserDivision,
    UniversalUserGet,
    UniversalUserUpdate,
)
from src.templates_raise import get_raise

PATH_MODEL = "universal_user"
PATH_TYPE_PHOTO = "photo"
PATH_TYPE_IDENTITY_CARD = "identity_card"
PATH_TYPE_QUALIFICATION = "qualification_file"
#
ROLES_ELIGIBLE = [FOREMAN]
EMPLOYEE_LIST = [MECHANIC, ENGINEER, DISPATCHER]
router = APIRouter()


# CREATE NEW EMPLOYEE
@router.post(
    "/cp/foreman/create-employee/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Создать сотрудника",
    description="Создать сотрудника",
    tags=["Админ панель / Прораб"],
)
def create_employee_person(
    request: Request,
    new_data: EmployeeCreate,
    current_user=Depends(deps.require(Permission.USER_CREATE)),
    session=Depends(deps.get_db),
):
    db_obj, code, index = crud_foreman.create_user_employee(
        db=session, current_user=current_user, new_data=new_data
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_universal_user(db_obj, request=request))


# UPDATE SELF
@router.put(
    "/cp/foreman/me/division/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Изменить участка",
    description="Изменить Участок текущего пользователя",
    tags=["Админ панель / Прораб"],
)
def update_user(
    request: Request,
    new_data: UniversalUserDivision,
    current_user=Depends(deps.get_current_user),
    session=Depends(deps.get_db),
):
    # проверка роли
    obj, code, indexes = crud_foreman.change_division_id(
        db=session,
        current_user=current_user,
        division=new_data,
        role_list=ROLES_ELIGIBLE,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


#  АПИ ПО ИЗМЕНЕНИЮ УЧАСТКА ДЛЯ СОТРУДНИКА
@router.put(
    "/cp/foreman/{employee_id}/division/",
    response_model=SingleEntityResponse,
    name="Изменить участок для пользователя",
    description="Изменить участок для пользователя",
    tags=["Админ панель / Прораб"],
)
def update_dvision_for_employee(
    request: Request,
    new_data: UniversalUserDivision,
    employee_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.require(Permission.USER_UPDATE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_admin.change_division_for_employee(
        db=session,
        current_user=current_user,
        division=new_data,
        employee_id=employee_id,
        role_list=ROLES_ELIGIBLE,
        employee_list=EMPLOYEE_LIST,
        scope=scope,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# АПИ ПО АРХИВАЦИИ ПОЛЬЗОВАТЕЛЕЙ
@router.get(
    "/cp/foreman/{id_user}/archive/",
    response_model=SingleEntityResponse,
    name="Заморозить сотрудника",
    description="Архивация пользователя, доступ к приложению замораживается",
    tags=["Админ панель / Прораб"],
)
def archiving_users(
    request: Request,
    id_user: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.require(Permission.USER_ARCHIVE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_admin.archiving_user(
        db=session,
        current_user=current_user,
        id_user=id_user,
        role_list=ROLES_ELIGIBLE,
        employee_list=EMPLOYEE_LIST,
        scope=scope,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# АПИ ПО РАЗАРХИВАЦИИ ПОЛЬЗОВАТЕЛЕЙ
@router.get(
    "/cp/foreman/{id_user}/unzip/",
    response_model=SingleEntityResponse,
    name="Разморозка сотрудника",
    description="Разархивация пользователя, доступ к приложению размораживается",
    tags=["Админ панель / Прораб"],
)
def unzipping_users(
    request: Request,
    id_user: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.require(Permission.USER_ARCHIVE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_admin.unzipping_user(
        db=session,
        current_user=current_user,
        id_user=id_user,
        role_list=ROLES_ELIGIBLE,
        employee_list=EMPLOYEE_LIST,
        scope=scope,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# UPDATE USERS
@router.put(
    "/cp/foreman/universal-user/{user_id}/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Изменить пользователя",
    description="Изменить данные пользователя",
    tags=["Админ панель / Прораб"],
)
def update_user(
    request: Request,
    new_data: UniversalUserUpdate,
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.require(Permission.USER_UPDATE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):

    obj, code, indexes = crud_admin.updating_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        new_data=new_data,
        role_list=ROLES_ELIGIBLE,
        changeable_list=EMPLOYEE_LIST,
        scope=scope,
    )

    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# UPDATE photo
@router.put(
    "/cp/foreman/universal-user/{user_id}/photo/",
    response_model=SingleEntityResponse,
    name="Изменить фото другому пользователю",
    description="Изменить фото для пользователя, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Прораб"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.require(Permission.USER_UPDATE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):

    save_path, code, indexes = crud_foreman.updating_file_for_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        role_list=ROLES_ELIGIBLE,
        changeable_list=EMPLOYEE_LIST,
        scope=scope,
        file=file,
        path_model=PATH_MODEL,
        path_type=PATH_TYPE_PHOTO,
    )
    get_raise(code=code)
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(
        data=get_universal_user(
            crud_universal_users.get(db=session, id=user_id), request=request
        )
    )


# UPDATE identity-card
@router.put(
    "/cp/foreman/universal-user/{user_id}/identity-card/",
    response_model=SingleEntityResponse,
    name="Изменить удостоверение другому пользователю",
    description="Изменить удостоверение пользователю, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Прораб"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.require(Permission.USER_UPDATE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):

    save_path, code, indexes = crud_foreman.updating_file_for_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        role_list=ROLES_ELIGIBLE,
        changeable_list=EMPLOYEE_LIST,
        scope=scope,
        file=file,
        path_model=PATH_MODEL,
        path_type=PATH_TYPE_IDENTITY_CARD,
    )
    get_raise(code=code)
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(
        data=get_universal_user(
            crud_universal_users.get(db=session, id=user_id), request=request
        )
    )


# UPDATE qualification_file
@router.put(
    "/cp/foreman/universal-user/{user_id}/qualification-file/",
    response_model=SingleEntityResponse,
    name="Изменить ЦОК другому пользователю",
    description="Изменить ЦОК пользователю, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Прораб"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.require(Permission.USER_UPDATE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):

    save_path, code, indexes = crud_foreman.updating_file_for_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        role_list=ROLES_ELIGIBLE,
        changeable_list=EMPLOYEE_LIST,
        scope=scope,
        file=file,
        path_model=PATH_MODEL,
        path_type=PATH_TYPE_QUALIFICATION,
    )
    get_raise(code=code)
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(
        data=get_universal_user(
            crud_universal_users.get(db=session, id=user_id), request=request
        )
    )


if __name__ == "__main__":
    logging.info("Running...")
