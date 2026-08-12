import logging

from fastapi import APIRouter, Depends, Path, Query, Request

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_fault_category import crud_fault_category
from src.getters.fault_category import getting_fault_category
from src.schemas.fault_category import FaultCategoryCreate, FaultCategoryUpdate
from src.templates_raise import get_raise

ROLE_ADMIN_FOREMAN = [ADMIN, FOREMAN]
router = APIRouter()


# Вывод всех участков
@router.get(
    "/fault-category/all",
    response_model=ListOfEntityResponse,
    name="get_all_categories",
    description="Получение списка всех категорий неисправности",
    tags=["Админ панель / Категории неисправности"],
)
def get_all_categories(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):
    logging.info(crud_fault_category.get_multi(db=session, page=None))
    data, paginator = crud_fault_category.get_multi(db=session, page=page)
    return ListOfEntityResponse(
        data=[getting_fault_category(datum) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    "/fault-category/{fault_category_id}",
    response_model=SingleEntityResponse,
    name="get_fault_category",
    description="Вывод категории неисправности по идентификатору",
    tags=["Админ панель / Категории неисправности"],
)
def get_fault_category(
    fault_category_id: int,
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):

    obj, code, indexes = crud_fault_category.get_fault_by_id(
        db=session, fault_id=fault_category_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=getting_fault_category(obj=obj))


# # Создание участка
@router.post(
    "/{fault_category}",
    response_model=SingleEntityResponse,
    name="create_fault_category",
    description="Создать категорию неисправности",
    tags=["Админ панель / Категории неисправности"],
)
def create_fault_category(
    request: Request,
    new_data: FaultCategoryCreate,
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):

    db_obj, code, index = crud_fault_category.create_new(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=getting_fault_category(db_obj))


# UPDATE
@router.put(
    "/fault-category/{fault_category_id}/",
    response_model=SingleEntityResponse,
    name="update_fault_category",
    description="Изменить название категории неисправности",
    tags=["Админ панель / Категории неисправности"],
)
def update_fault_category(
    request: Request,
    new_data: FaultCategoryUpdate,
    fault_category_id: int = Path(..., title="Id проекта"),
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):
    # проверку на роли

    db_obj, code, index = crud_fault_category.update(
        db=session, new_data=new_data, obj_id=fault_category_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_fault_category(db_obj))


if __name__ == "__main__":
    logging.info("Running...")
