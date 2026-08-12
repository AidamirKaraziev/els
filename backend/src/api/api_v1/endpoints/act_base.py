import logging

from fastapi import APIRouter, Depends, Path, Query, Request

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_act_base import crud_acts_bases
from src.crud.crud_object import crud_objects
from src.getters.act_base import get_acts_bases
from src.schemas.act_base import ActBaseCreate, ActBaseUpdate
from src.templates_raise import get_raise

ROLES_ELIGIBLE = [ADMIN, FOREMAN]

router = APIRouter()


@router.get(
    path="/acts-bases/",
    response_model=ListOfEntityResponse,
    name="Список шаблонов актов",
    description="Получение списка всех шаблонов актов",
    tags=["Админ панель / Шаблоны Актов"],
)
def get_data(
    request: Request,
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_acts_bases.get_multi(db=session, page=None))

    data, paginator = crud_acts_bases.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_acts_bases(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/act-base/{act_base_id}/",
    response_model=SingleEntityResponse,
    name="Шаблоны Актов",
    description="Получение данных Шаблонов Актов",
    tags=["Админ панель / Шаблоны Актов"],
)
def get_data(
    request: Request,
    act_base_id: int = Path(..., title="ID Шаблоны Актов"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_acts_bases.getting_act_base(
        db=session, act_base_id=act_base_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_bases(obj, request=request))


@router.post(
    path="/act-base/",
    response_model=SingleEntityResponse,
    name="Добавить Шаблон Актов",
    description="Добавить Шаблон Актов в базу данных ",
    tags=["Админ панель / Шаблоны Актов"],
)
def create_act_base(
    request: Request,
    new_data: ActBaseCreate,
    current_user=Depends(deps.require(Permission.ACT_CREATE)),
    session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора

    obj, code, index = crud_acts_bases.create_act_base(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_bases(obj, request=request))


@router.put(
    path="/act-base/{act_base_id}/",
    response_model=SingleEntityResponse,
    name="Изменить Шаблоны Актов",
    description="Изменяет данные Шаблонов Актов",
    tags=["Админ панель / Шаблоны Актов"],
)
def update_act_base(
    request: Request,
    new_data: ActBaseUpdate,
    current_user=Depends(deps.require(Permission.ACT_UPDATE)),
    act_base_id: int = Path(..., title="Id шаблона актов"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    obj, code, indexes = crud_acts_bases.update_act_base(
        db=session, new_data=new_data, act_base_id=act_base_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_acts_bases(obj, request=request))


@router.get(
    path="/act-base/by-object/{object_id}/",
    summary="Получение шаблона по id объекта.",
    tags=["Админ панель / Шаблоны Актов"],
    response_model=ListOfEntityResponse,
)
def get_act_base_by_object_id(
    request: Request,
    current_user=Depends(deps.require(Permission.ACT_READ)),
    object_id: int = Path(..., title="ID объекта"),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_read_scope),
):
    # Сами шаблоны — справочник по модели техники, резать их нечем и незачем.
    # А вот объект в запросе проверить надо: иначе по чужому лифту можно
    # узнать, какая на нём стоит техника.
    obj, code, indexes = crud_objects.get_object_by_id(
        db=session, object_id=object_id, scope=scope
    )
    get_raise(code=code)

    data, code, indexes = crud_acts_bases.get_act_base_by_object_id(
        db=session, object_id=object_id
    )
    get_raise(code=code)
    return ListOfEntityResponse(
        data=[get_acts_bases(datum, request=request) for datum in data],
    )


if __name__ == "__main__":
    logging.info("Running...")
