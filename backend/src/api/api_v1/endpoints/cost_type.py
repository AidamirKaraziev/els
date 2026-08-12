import logging

from fastapi import APIRouter, Depends, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta
from src.crud.crud_cost_type import crud_cost_types
from src.getters.cost_type import get_cost_types

router = APIRouter()


# Вывод всех типов цены
@router.get(
    "/cost-types/",
    response_model=ListOfEntityResponse,
    name="Список типов цен",
    description="Получение списка всех типов цен",
    tags=["Админ панель / Типы Цен"],
)
def get_data(
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):
    logging.info(crud_cost_types.get_multi(db=session, page=None))

    data, paginator = crud_cost_types.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_cost_types(datum) for datum in data], meta=Meta(paginator=paginator)
    )


if __name__ == "__main__":
    logging.info("Running...")
