import logging

from fastapi import APIRouter, Depends, Path, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.crud.crud_location import crud_location
from src.exceptions import UnfoundEntity, UnprocessableEntity
from src.getters.location import get_location
from src.schemas.location import LocationCreate, LocationUpdate

router = APIRouter()


# Вывод всех локаций
@router.get(
    "/locations/",
    response_model=ListOfEntityResponse,
    name="Список городов",
    description="Получение списка всех городов",
    tags=["Мобильное приложение / Города"],
)
def get_data(
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):
    logging.info(crud_location.get_multi(db=session, page=None))

    data, paginator = crud_location.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_location(datum) for datum in data], meta=Meta(paginator=paginator)
    )


# Создание локации
@router.post(
    "/locations/",
    response_model=SingleEntityResponse,
    name="Добавить Город",
    description="Добавить один город в базу данных ",
    tags=["Админ панель / Города"],
)
def create_locations(
    new_data: LocationCreate,
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):
    obj = crud_location.get_by_name_old(db=session, name=new_data.name)
    if obj is not None:
        raise UnprocessableEntity(
            message="Такой город уже есть в базе данных",
            num=1,
            description="Город с таким названием уже есть в базе данных!",
            path="$.body",
        )
    return SingleEntityResponse(
        data=get_location(crud_location.create(db=session, obj_in=new_data))
    )


# Апи удаляет город
@router.get(
    "/locations/{location_id}/",
    response_model=SingleEntityResponse,
    name="Удалить город",
    description="Полностью удаляет город",
    tags=["Админ панель / Города"],
)
def delete_location(
    location_id: int = Path(..., title="Id проекта"),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
    session=Depends(deps.get_db),
):
    if crud_location.get(db=session, id=location_id) is None:
        raise UnfoundEntity(
            message="Города с таким id нет!",
            num=1,
            description="Введите корректный id!",
            path="$.body",
        )
    return SingleEntityResponse(data=crud_location.remove(db=session, id=location_id))


# UPDATE
@router.put(
    "/locations/{location_id}/",
    response_model=SingleEntityResponse,
    name="Изменить название города",
    description="Изменяет название города",
    tags=["Админ панель / Города"],
)
def update_location(
    name: LocationUpdate,
    location_id: int = Path(..., title="Id проекта"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
):
    location, code, indexes = crud_location.update_location(
        db=session, location=name, location_id=location_id
    )
    if code == -1:
        raise UnfoundEntity(
            message="Города с таким id нет!",
            num=1,
            description="Введите корректный id!",
            path="$.body",
        )
    if code == -2:
        raise UnprocessableEntity(
            message="Город с таким названием уже есть!",
            num=2,
            description="Выберите другое название города!",
            path="$.body",
        )
    return SingleEntityResponse(data=get_location(db_obj=location))


if __name__ == "__main__":
    logging.info("Running...")
