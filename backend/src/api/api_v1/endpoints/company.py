import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Path, Query, Request, UploadFile

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, CLIENT_ID
from src.crud.crud_company import crud_company
from src.crud.users.crud_universal_user import crud_universal_users
from src.getters.company import getting_company
from src.getters.universal_user import get_universal_user
from src.schemas.company import CompanyCreate, CompanyGet, CompanyUpdate
from src.templates_raise import get_raise

ROLES_ELIGIBLE = [ADMIN]
ROLES_ELIGIBLE_ADMIN_CLIENT = [ADMIN, CLIENT_ID]

PATH_MODEL = "company"
PATH_TYPE = "photo"
router = APIRouter()


# Вывод всех Компаний
# GET-MULTY
@router.get(
    path="/all-company/",
    response_model=ListOfEntityResponse,
    name="Список Компаний",
    description="Получение списка всех компаний",
    tags=["Админ панель / Компании"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_READ)),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_company.get_multi(db=session, page=None))

    data, paginator = crud_company.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[getting_company(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


# CREATE NEW COMPANY
@router.post(
    path="/company/",
    response_model=SingleEntityResponse,
    name="Добавить Компанию",
    description="Добавить одну компанию в базу данных ",
    tags=["Админ панель / Компании"],
)
def create_company(
    request: Request,
    new_data: CompanyCreate,
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора

    company, code, index = crud_company.create_company(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=getting_company(company=company, request=request))


# GET ID
@router.get(
    path="/company/{company_id}/",
    response_model=SingleEntityResponse,
    name="Компания",
    description="Получение данных компании",
    tags=["Админ панель / Компании"],
)
def get_data(
    request: Request,
    company_id: int = Path(..., title="ID компании"),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_READ)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_company.get_company_by_id(
        db=session, company_id=company_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_company(obj, request=request))


# UPDATE
@router.put(
    path="/company/{company_id}/",
    response_model=SingleEntityResponse,
    name="Изменить данные компании",
    description="Изменяет изменяет данные компании",
    tags=["Админ панель / Компании"],
)
def update_company(
    request: Request,
    new_data: CompanyUpdate,
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    company_id: int = Path(..., title="Id проекта"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    company, code, indexes = crud_company.update_company(
        db=session, company=new_data, company_id=company_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=getting_company(company=company, request=request))


# UPDATE PHOTO
@router.put(
    path="/company/{company_id}/photo/",
    response_model=SingleEntityResponse[CompanyGet],
    name="Изменить фотографию",
    description="Изменить фотографию для компаний, если отправить пустой файл сбрасывает фото",
    tags=["Админ панель / Компании"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    company_id: int = Path(..., title="Id компании"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    obj, code, indexes = crud_company.get_company_by_id(
        db=session, company_id=company_id
    )
    get_raise(code=code)
    crud_company.adding_file(
        db=session, file=file, path_model=PATH_MODEL, path_type=PATH_TYPE, db_obj=obj
    )

    return SingleEntityResponse(
        data=getting_company(
            crud_company.get(db=session, id=company_id), request=request
        )
    )


# АПИ ПО АРХИВАЦИИ КОМПАНИИ
@router.get(
    path="/company/{company_id}/archive/",
    response_model=SingleEntityResponse,
    name="Заморозить компании",
    summary="Архивация компании",
    description="Архивация компании",
    tags=["Админ панель / Компании"],
)
def archiving_companies(
    request: Request,
    company_id: int = Path(..., title="Id КОМПАНИИ"),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_company.archiving_company(
        db=session,
        current_user=current_user,
        company_id=company_id,
        role_list=ROLES_ELIGIBLE,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=getting_company(obj, request=request))


# АПИ ПО РАЗАРХИВАЦИИ КОМПАНИИ
@router.get(
    path="/company/{company_id}/unzip/",
    response_model=SingleEntityResponse,
    summary="Разморозка компании",
    name="Разморозка компании",
    description="Разархивация Компании, доступ к приложению размораживается",
    tags=["Админ панель / Компании"],
)
def unzipping_companies(
    request: Request,
    company_id: int = Path(..., title="Id КОМПАНИИ"),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_company.unzipping_company(
        db=session,
        current_user=current_user,
        company_id=company_id,
        role_list=ROLES_ELIGIBLE,
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_company(obj, request=request))


@router.get(
    path="/company/clients/{company_id}/",
    response_model=ListOfEntityResponse,
    summary="Получить список клиентов для компании.",
    description="""
## Описание
Возвращает список клиентов, связанных с заданной компанией.

## Требования
- Пользователь должен быть аутентифицирован для выполнения данного запроса.

## Параметры
- **company_id**: Идентификатор компании.

## Ответ
Возвращает список пользователей, у которых роль клиента и которые связаны с этой компанией.
    """,
    tags=["Админ панель / Компании"],
)
def get_clients_by_company_id(
    request: Request,
    company_id: int,
    current_user=Depends(deps.require(Permission.COUNTERPARTY_READ)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_read_scope),
):
    data, code, indexes = crud_universal_users.get_clients_by_company_id(
        db=session, company_id=company_id, scope=scope
    )
    get_raise(code=code)

    return ListOfEntityResponse(
        data=[get_universal_user(datum, request=request) for datum in data]
    )


if __name__ == "__main__":
    logging.info("Running...")
