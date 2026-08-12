import logging

from fastapi import APIRouter, Depends, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta
from src.crud.crud_status import crud_status
from src.getters.status import get_statuses

router = APIRouter()


# Вывод всех Должностей
@router.get(
    "/statuses/",
    response_model=ListOfEntityResponse,
    name="Список статусов",
    description="Получение списка всех статусов",
    tags=["Админ панель / Статусы"],
)
def get_data(
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_status.get_multi(db=session, page=None))

    data, paginator = crud_status.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_statuses(datum) for datum in data], meta=Meta(paginator=paginator)
    )


if __name__ == "__main__":
    logging.info("Running...")
