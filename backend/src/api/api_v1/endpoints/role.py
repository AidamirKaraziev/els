import logging

from fastapi import APIRouter, Depends, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta
from src.crud.crud_role import crud_role
from src.getters.role import get_roles

router = APIRouter()


# Вывод всех Должностей
@router.get(
    "/roles/",
    response_model=ListOfEntityResponse,
    name="Список Должностей",
    description="Получение списка всех Должностей",
    tags=["Админ панель / Должности"],
)
def get_data(
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):
    logging.info(crud_role.get_multi(db=session, page=None))

    data, paginator = crud_role.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_roles(datum) for datum in data], meta=Meta(paginator=paginator)
    )


if __name__ == "__main__":
    logging.info("Running...")
