import logging

from fastapi import APIRouter, Depends, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta
from src.crud.crud_type_object import crud_type_object
from src.getters.type_object import get_type_objects

router = APIRouter()


# Вывод всех типов ОБЪЕКТОВ
@router.get(
    "/type-object/",
    response_model=ListOfEntityResponse,
    name="Список типов объектов",
    description="Получение списка всех типов объектов",
    tags=["Админ панель / Типы Объектов"],
)
def get_data(
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):
    logging.info(crud_type_object.get_multi(db=session, page=None))

    data, paginator = crud_type_object.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_type_objects(datum) for datum in data], meta=Meta(paginator=paginator)
    )


if __name__ == "__main__":
    logging.info("Running...")
