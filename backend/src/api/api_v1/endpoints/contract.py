import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Query, Request, UploadFile
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, CLIENT_ID, DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_company import crud_company
from src.crud.crud_contract import crud_contracts
from src.exceptions import UnfoundEntity
from src.getters.contract import get_contract
from src.schemas.contract import ContractCreate, ContractGet, ContractUpdate
from src.templates_raise import get_raise

PATH_MODEL = "contract"
PATH_TYPE = "file"

ROLE_ADMIN = [ADMIN]
EMPLOYEE_LIST = [FOREMAN, MECHANIC, ENGINEER, DISPATCHER]
ALL_EMPLOYEE = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER]
ALL = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER, CLIENT_ID]
CLIENT_LIST = [CLIENT_ID]


router = APIRouter()


# CREATE NEW COMPANY
@router.post(
    "/contract/",
    response_model=SingleEntityResponse,
    name="Добавить Договор",
    description="Добавить один Договор в базу данных ",
    tags=["Админ панель / Договор"],
)
def create_contract(
    request: Request,
    new_data: ContractCreate,
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    session=Depends(deps.get_db),
):

    contract, code, index = crud_contracts.create_contract(
        db=session,
        new_data=new_data,
        current_user=current_user,
        having_rights=ROLE_ADMIN,
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_contract(obj=contract, request=request))


@router.get(
    "/contract/sort-by-company/{company_id}/",
    response_model=ListOfEntityResponse,
    name="get_contract_by_company_id",
    description="Получение договоров по компании",
    tags=["Админ панель / Договор"],
)
def get_contract_by_company_id(
    request: Request,
    company_id: int = Path(..., title="ID модели техники"),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_READ)),
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    obj, code, indexes = crud_company.get_company_by_id(
        db=session, company_id=company_id
    )
    get_raise(code=code)

    data, paginator = crud_contracts.get_contract_by_company_id(
        db=session, page=page, company_id=company_id
    )

    return ListOfEntityResponse(
        data=[get_contract(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


# Вывод всех договоров
# GET-MULTY
@router.get(
    "/all-contract/",
    response_model=ListOfEntityResponse,
    name="Список Договоров",
    description="Получение списка всех Договоров",
    tags=["Админ панель / Договор"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_READ)),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_contracts.get_multi(db=session, page=None))

    data, paginator = crud_contracts.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_contract(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


# GET ID
@router.get(
    "/contract/{contract_id}/",
    response_model=SingleEntityResponse,
    name="Договор",
    description="Получение данных Договора",
    tags=["Админ панель / Договор"],
)
def get_data(
    request: Request,
    contract_id: int = Path(..., title="ID Договора"),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_READ)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_contracts.get(db=session, id=contract_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_contract(obj, request=request))


# UPDATE
@router.put(
    "/contract/{contract_id}/",
    response_model=SingleEntityResponse,
    name="Изменить данные Договора",
    description="Изменяет изменяет данные Договора",
    tags=["Админ панель / Договор"],
)
def update_contract(
    request: Request,
    new_data: ContractUpdate,
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    contract_id: int = Path(..., title="Id договора"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    contract, code, indexes = crud_contracts.update_contract(
        db=session, new_data=new_data, contract_id=contract_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_contract(obj=contract, request=request))


# UPDATE FILE
@router.put(
    "/contract/{contract_id}/file/",
    response_model=SingleEntityResponse[ContractGet],
    name="Изменить файл",
    description="Изменить файл для Договоров, если отправить пустой файл сбрасывает файл",
    tags=["Админ панель / Договор"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    contract_id: int = Path(..., title="Id Договора"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    obj, code, indexes = crud_contracts.get(db=session, id=contract_id)
    get_raise(code=code)
    save_path = crud_contracts.adding_file(
        db=session, file=file, path_model=PATH_MODEL, path_type=PATH_TYPE, db_obj=obj
    )
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(data=get_contract(obj, request=request))


# АПИ ПО АРХИВАЦИИ ДОГОВОРА
@router.get(
    "/contract/{contract_id}/archive/",
    response_model=SingleEntityResponse,
    name="Заморозить договор",
    description="Архивация договора",
    tags=["Админ панель / Договор"],
)
def archiving_contracts(
    request: Request,
    contract_id: int = Path(..., title="Id Договора"),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_contracts.archiving_contract(
        db=session,
        current_user=current_user,
        contract_id=contract_id,
        role_list=ROLE_ADMIN,
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_contract(obj, request=request))


# АПИ ПО РАЗАРХИВАЦИИ Договора
@router.get(
    "/contract/{contract_id}/unzip/",
    response_model=SingleEntityResponse,
    name="Разморозка договора",
    description="Разархивация Договора",
    tags=["Админ панель / Договор"],
)
def unzipping_contracts(
    request: Request,
    contract_id: int = Path(..., title="Id Договора"),
    current_user=Depends(deps.require(Permission.COUNTERPARTY_WRITE)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_contracts.unzipping_contract(
        db=session,
        current_user=current_user,
        contract_id=contract_id,
        role_list=ROLE_ADMIN,
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_contract(obj, request=request))


if __name__ == "__main__":
    logging.info("Running...")
