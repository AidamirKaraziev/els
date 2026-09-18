import logging

from fastapi import APIRouter, Depends, Path, Query

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.crud.crud_type_act import crud_type_acts
from src.exceptions import ConflictEntity, UnfoundEntity, UnprocessableEntity
from src.getters.type_act import get_type_acts
from src.schemas.type_act import TypeActCreate, TypeActUpdate

router = APIRouter()


# Вывод всех типов АКТОВ
@router.get(
    "/type-acts/",
    response_model=ListOfEntityResponse,
    name="Список типов актов",
    description="Получение списка всех типов актов",
    tags=["Админ панель / Типы Актов"],
)
def get_data(
    current_user=Depends(deps.require(Permission.DIRECTORY_READ)),
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_type_acts.get_multi(db=session, page=None))

    data, paginator = crud_type_acts.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_type_acts(datum) for datum in data], meta=Meta(paginator=paginator)
    )


# Имя вида ТО: без пробелов по краям, пустое не принимаем. Ошибки pydantic
# приложение отдаёт как 400, а пустое имя — это 422 по контракту этапа.
def _clean_name(name: str) -> str:
    name = name.strip()
    if not name:
        raise UnprocessableEntity(
            message="Название вида ТО не может быть пустым",
            num=1,
            description="Введите название вида ТО!",
            path="$.body.name",
        )
    return name


def _raise_if_taken(session, name: str, except_id: int = None):
    obj = crud_type_acts.get_by_name_old(db=session, name=name)
    if obj is not None and obj.id != except_id:
        raise ConflictEntity(
            message="Вид ТО с таким названием уже есть",
            num=2,
            description="Выберите другое название вида ТО!",
            path="$.body.name",
        )


# Создание вида ТО
@router.post(
    "/type-acts/",
    response_model=SingleEntityResponse,
    name="Добавить вид ТО",
    description="Добавить один вид ТО (тип акта) в справочник",
    tags=["Админ панель / Типы Актов"],
)
def create_type_act(
    new_data: TypeActCreate,
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):
    name = _clean_name(new_data.name)
    _raise_if_taken(session, name)
    return SingleEntityResponse(
        data=get_type_acts(crud_type_acts.create_next(db=session, name=name))
    )


# Переименование вида ТО
@router.put(
    "/type-acts/{type_act_id}/",
    response_model=SingleEntityResponse,
    name="Переименовать вид ТО",
    description="Изменяет название вида ТО (типа акта)",
    tags=["Админ панель / Типы Актов"],
)
def update_type_act(
    new_data: TypeActUpdate,
    type_act_id: int = Path(..., title="Id вида ТО"),
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):
    db_obj = crud_type_acts.get(db=session, id=type_act_id)
    if db_obj is None:
        raise UnfoundEntity(
            message="Вида ТО с таким id нет!",
            num=1,
            description="Введите корректный id!",
            path="$.path.type_act_id",
        )
    name = _clean_name(new_data.name)
    _raise_if_taken(session, name, except_id=db_obj.id)
    updated = crud_type_acts.update(db=session, db_obj=db_obj, obj_in={"name": name})
    return SingleEntityResponse(data=get_type_acts(updated))


if __name__ == "__main__":
    logging.info("Running...")
