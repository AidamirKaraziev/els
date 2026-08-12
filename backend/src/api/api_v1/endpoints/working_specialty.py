import logging

from fastapi import APIRouter, Depends, Path, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.crud.crud_working_specialty import crud_working_specialty
from src.exceptions import UnfoundEntity, UnprocessableEntity
from src.getters.working_specialty import get_working_specialty
from src.schemas.working_specialty import WorkingSpecialtyCreate, WorkingSpecialtyUpdate

router = APIRouter()


# Вывод всех специальностей
@router.get(
    "/working-specialty/",
    response_model=ListOfEntityResponse,
    name="Список специальностей",
    description="Получение списка всех специальностей",
    tags=["Админ панель / Специальности"],
)
def get_data(
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):
    logging.info(crud_working_specialty.get_multi(db=session, page=None))

    data, paginator = crud_working_specialty.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_working_specialty(datum) for datum in data],
        meta=Meta(paginator=paginator),
    )


# Создание специальности
@router.post(
    "/working-specialty/",
    response_model=SingleEntityResponse,
    name="Добавить Специальность",
    description="Добавить одну специальность в базу данных ",
    tags=["Админ панель / Специальности"],
)
def create_working_specialty(
    new_data: WorkingSpecialtyCreate,
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
):
    obj = crud_working_specialty.get_by_name_old(db=session, name=new_data.name)
    if obj is not None:
        raise UnprocessableEntity(
            message="Такая специальность уже есть в базе данных",
            num=1,
            description="Специальность с таким названием уже есть в базе данных!",
            path="$.body",
        )
    return SingleEntityResponse(
        data=get_working_specialty(
            crud_working_specialty.create(db=session, obj_in=new_data)
        )
    )


# Апи удаляет специальность
@router.get(
    "/working-specialty/{working_specialty_id}/",
    response_model=SingleEntityResponse,
    name="Удалить специальность",
    description="Полностью удаляет специальность",
    tags=["Админ панель / Специальности"],
)
def delete_working_specialty(
    working_specialty_id: int = Path(..., title="Id проекта"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
):
    if crud_working_specialty.get(db=session, id=working_specialty_id) is None:
        raise UnfoundEntity(
            message="Специальности с таким id нет!",
            num=1,
            description="Введите корректный id!",
            path="$.body",
        )
    return SingleEntityResponse(
        data=crud_working_specialty.remove(db=session, id=working_specialty_id)
    )


# Апи для изменения специальности
@router.put(
    "/working-specialty/{working_specialty_id}/",
    response_model=SingleEntityResponse,
    name="Изменить название специальности",
    description="Изменяет название специальности",
    tags=["Админ панель / Специальности"],
)
def update_working_specialty(
    name: WorkingSpecialtyUpdate,
    working_specialty_id: int = Path(..., title="Id проекта"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
):
    working_specialty, code, indexes = crud_working_specialty.update_working_specialty(
        db=session, working_specialty=name, working_specialty_id=working_specialty_id
    )
    if code == -1:
        raise UnfoundEntity(
            message="Специальности с таким id нет!",
            num=1,
            description="Введите корректный id!",
            path="$.body",
        )
    if code == -2:
        raise UnprocessableEntity(
            message="Специальность с таким названием уже есть!",
            num=2,
            description="Выберите другое название специальности!",
            path="$.body",
        )
    return SingleEntityResponse(data=get_working_specialty(db_obj=working_specialty))


if __name__ == "__main__":
    logging.info("Running...")
