import logging
from mimetypes import guess_type
from os.path import isfile
from typing import Optional

from fastapi import APIRouter, Depends, File, Request, Response, UploadFile
from fastapi.params import Path

from src.api import deps
from src.core.response import SingleEntityResponse
from src.core.roles import ADMIN, CLIENT_ID, DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_admin import crud_admin
from src.crud.users.crud_universal_user import crud_universal_users
from src.exceptions import InaccessibleEntity, UnfoundEntity
from src.getters.universal_user import get_universal_user
from src.schemas.admin import AdminCreate
from src.schemas.client import ClientCreate
from src.schemas.universal_user import (
    EmployeeCreate,
    UniversalUserCompany,
    UniversalUserDivision,
    UniversalUserGet,
    UniversalUserUpdate,
)
from src.templates_raise import get_raise

PATH_MODEL = "universal_user"
PATH_TYPE_PHOTO = "photo"
PATH_TYPE_IDENTITY_CARD = "identity_card"
PATH_TYPE_QUALIFICATION = "qualification_file"

ROLES_ELIGIBLE = [ADMIN]
EMPLOYEE_LIST = [FOREMAN, MECHANIC, ENGINEER, DISPATCHER]
ALL_EMPLOYEE = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER]
ALL = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER, CLIENT_ID]
CLIENT_LIST = [CLIENT_ID]


router = APIRouter()


@router.get(
    "/static/{filename:path}", name="Получить статический файл", tags=["Инструменты"]
)
async def get_site(filename):
    filename = "static/" + filename
    if not isfile(filename):
        return Response(status_code=404)

    with open(filename, "rb") as f:
        content = f.read()

    content_type, _ = guess_type(filename)
    return Response(content, media_type=content_type)


# CREATE NEW EMPLOYEE
@router.post(
    "/cp/admin/create-employee/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Создать сотрудника",
    description="Создать сотрудника",
    tags=["Админ панель / Администратор"],
)
def create_employee_person(
    request: Request,
    new_data: EmployeeCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    db_obj, code, index = crud_admin.create_user_employee(
        db=session, current_user=current_user, new_data=new_data
    )
    get_raise(code)
    if code == -105:
        raise UnfoundEntity(
            message="Токен не распознан!",
            num=105,
            description="Такого пользователя не существует!",
            path="$.body",
        )
    if code == -1022:
        raise InaccessibleEntity(
            message="Вы не обладаете правами!",
            num=2,
            description="Пользователь не обладает правами, к созданию таких пользователей!",
            path="$.body",
        )
    if code == -1021:
        raise InaccessibleEntity(
            message="Неправильно выбрана должность!",
            num=2,
            description="Пользователь не обладает правами, к созданию таких пользователей!",
            path="$.body",
        )
    if code == -100:
        raise InaccessibleEntity(
            message="Пользователь с таким email уже есть!",
            num=2,
            description="Укажите другой email, для регистрации",
            path="$.body",
        )
    # проверка локации и зоны ответственности
    if code == -101:
        raise UnfoundEntity(
            message="Такого города нет!",
            num=4,
            description="Введен неправильный id города!",
            path="$.body",
        )
    if code == -102:
        raise UnfoundEntity(
            message="Такой Должности нет!",
            num=6,
            description="Выберете существующую должность!",
            path="$.body",
        )
    if code == -103:
        raise UnfoundEntity(
            message="Такой Специальности нет!",
            num=7,
            description="Выберете существующую Специальность!",
            path="$.body",
        )
    if code == -104:
        raise UnfoundEntity(
            message="Такого Участка нет!",
            num=8,
            description="Выберете существующую Участок или создайте новую!",
            path="$.body",
        )

    return SingleEntityResponse(data=get_universal_user(db_obj, request=request))


# CREATE NEW Admin
@router.post(
    "/cp/admin/create-admin/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Создать Администратора",
    description="Создать Администратора",
    tags=["Админ панель / Администратор"],
)
def create_admin_person(
    request: Request,
    new_data: AdminCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    db_obj, code, index = crud_admin.create_user_admin(
        db=session, current_user=current_user, new_data=new_data
    )
    get_raise(code)
    if code == -105:
        raise UnfoundEntity(
            message="Токен не распознан!",
            num=105,
            description="Такого пользователя не существует!",
            path="$.body",
        )
    if code == -1022:
        raise InaccessibleEntity(
            message="Вы не обладаете правами!",
            num=2,
            description="Пользователь не обладает правами, к созданию таких пользователей!",
            path="$.body",
        )

    if code == -100:
        raise InaccessibleEntity(
            message="Пользователь с таким email уже есть!",
            num=2,
            description="Укажите другой email, для регистрации",
            path="$.body",
        )

    # проверка локации и зоны ответственности
    if code == -101:
        raise UnfoundEntity(
            message="Такого города нет!",
            num=4,
            description="Введен неправильный id города!",
            path="$.body",
        )

    if code == -102:
        raise UnfoundEntity(
            message="Такой Должности нет!",
            num=6,
            description="Выберете существующую должность!",
            path="$.body",
        )
    if code == -1021:
        raise InaccessibleEntity(
            message="Неправильно выбрана должность!",
            num=2,
            description="Пользователь не обладает правами, к созданию таких пользователей!",
            path="$.body",
        )

    if code == -103:
        raise UnfoundEntity(
            message="Такой Специальности нет!",
            num=7,
            description="Выберете существующую Специальность!",
            path="$.body",
        )
    return SingleEntityResponse(data=get_universal_user(db_obj, request=request))


# CREATE NEW CLIENT
@router.post(
    "/cp/admin/create-client/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Создать клиента",
    description="Создать клиента",
    tags=["Админ панель / Администратор"],
)
def create_client_person(
    request: Request,
    new_data: ClientCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    db_obj, code, index = crud_admin.create_user_client(
        db=session, current_user=current_user, new_data=new_data
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(db_obj, request=request))


#  АПИ ПО ИЗМЕНЕНИЮ УЧАСТКА ДЛЯ СОТРУДНИКА
@router.put(
    "/cp/admin/{employee_id}/division/",
    response_model=SingleEntityResponse,
    name="Изменить участок для пользователя",
    description="Изменить участок для пользователя",
    tags=["Админ панель / Администратор"],
)
def update_dvision_for_employee(
    request: Request,
    new_data: UniversalUserDivision,
    employee_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_admin.change_division_for_employee(
        db=session,
        current_user=current_user,
        division=new_data,
        employee_id=employee_id,
        role_list=ROLES_ELIGIBLE,
        employee_list=EMPLOYEE_LIST,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# АПИ ПО АРХИВАЦИИ ПОЛЬЗОВАТЕЛЕЙ
@router.get(
    "/cp/admin/{id_user}/archive/",
    response_model=SingleEntityResponse,
    name="Заморозить сотрудника",
    description="Архивация пользователя, доступ к приложению замораживается",
    tags=["Админ панель / Администратор"],
)
def archiving_users(
    request: Request,
    id_user: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_admin.archiving_user(
        db=session,
        current_user=current_user,
        id_user=id_user,
        role_list=ROLES_ELIGIBLE,
        employee_list=ALL,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# АПИ ПО РАЗАРХИВАЦИИ ПОЛЬЗОВАТЕЛЕЙ
@router.get(
    "/cp/admin/{id_user}/unzip/",
    response_model=SingleEntityResponse,
    name="Разморозка сотрудника",
    description="Разархивация пользователя, доступ к приложению размораживается",
    tags=["Админ панель / Администратор"],
)
def unzipping_users(
    request: Request,
    id_user: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_admin.unzipping_user(
        db=session,
        current_user=current_user,
        id_user=id_user,
        role_list=ROLES_ELIGIBLE,
        employee_list=ALL,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


#  АПИ ПО ИЗМЕНЕНИЮ КОМПАНИИ ДЛЯ КЛИЕНТА
@router.put(
    "/cp/admin/{client_id}/company/",
    response_model=SingleEntityResponse,
    name="Изменить компании для клиента",
    description="Изменить компании для клиента",
    tags=["Админ панель / Администратор"],
)
def update_company_for_client(
    request: Request,
    new_data: UniversalUserCompany,
    client_id: int = Path(..., title="Id клиента"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_admin.change_company_for_client(
        db=session,
        current_user=current_user,
        company=new_data,
        client_id=client_id,
        role_list=ROLES_ELIGIBLE,
        client_list=CLIENT_LIST,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# UPDATE USERS
@router.put(
    "/cp/admin/universal-user/{user_id}/",
    response_model=SingleEntityResponse[UniversalUserGet],
    name="Изменить пользователя",
    description="Изменить данные пользователя",
    tags=["Админ панель / Администратор"],
)
def update_user(
    request: Request,
    new_data: UniversalUserUpdate,
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):

    obj, code, indexes = crud_admin.updating_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        new_data=new_data,
        role_list=ROLES_ELIGIBLE,
        changeable_list=ALL,
    )

    get_raise(code=code)

    return SingleEntityResponse(data=get_universal_user(obj, request=request))


# UPDATE photo
@router.put(
    "/cp/admin/universal-user/{user_id}/photo/",
    response_model=SingleEntityResponse,
    name="Изменить фото другому пользователю",
    description="Изменить фото для пользователя, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Администратор"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):

    save_path, code, indexes = crud_admin.updating_file_for_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        role_list=ROLES_ELIGIBLE,
        changeable_list=ALL,
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
    "/cp/admin/universal-user/{user_id}/identity-card/",
    response_model=SingleEntityResponse,
    name="Изменить удостоверение другому пользователю",
    description="Изменить удостоверение пользователю, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Администратор"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):

    save_path, code, indexes = crud_admin.updating_file_for_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        role_list=ROLES_ELIGIBLE,
        changeable_list=ALL_EMPLOYEE,
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
    "/cp/admin/universal-user/{user_id}/qualification-file/",
    response_model=SingleEntityResponse,
    name="Изменить ЦОК другому пользователю",
    description="Изменить ЦОК пользователю, если отправить пусто поле информация сбросится",
    tags=["Админ панель / Администратор"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    user_id: int = Path(..., title="Id пользователя"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):

    save_path, code, indexes = crud_admin.updating_file_for_user(
        db=session,
        current_user=current_user,
        user_id=user_id,
        role_list=ROLES_ELIGIBLE,
        changeable_list=ALL_EMPLOYEE,
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


@router.delete(
    path="/cp/admin/universal-user/{user_id}/",
    response_model=SingleEntityResponse,
    name="delete_universal_user",
    description="Удалить пользователя по id",
    tags=["Админ панель / Администратор"],
)
async def delete_universal_user(
    request: Request,
    user_id: int,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    response, code, indexes = crud_universal_users.delete_user_by_id(
        db=session, user_id=user_id, current_user_id=current_user.id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=response)


if __name__ == "__main__":
    logging.info("Running...")
