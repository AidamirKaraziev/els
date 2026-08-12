import logging

from fastapi import APIRouter, Depends, Path, Query, Request

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_step import crud_step
from src.getters.step import get_step
from src.schemas.step import StepCreate, StepUpdate
from src.templates_raise import get_raise

router = APIRouter()
ROLES_ELIGIBLE_ADMIN_FOREMAN = [ADMIN, FOREMAN]


# Вывод всех Step
@router.get(
    "/steps/",
    response_model=ListOfEntityResponse,
    name="Список Этапов",
    description="Получение списка всех названий Этапов",
    tags=["Админ панель / Название Этапов"],
)
def get_data(
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_step.get_multi(db=session, page=None))

    data, paginator = crud_step.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_step(datum) for datum in data], meta=Meta(paginator=paginator)
    )


# CREATE NEW STEPS
@router.post(
    "/steps/",
    response_model=SingleEntityResponse,
    name="Добавить название Этапа ",
    description="Добавить одно название этапа в базу данных ",
    tags=["Админ панель / Название Этапов"],
)
def create_steps(
    request: Request,
    new_data: StepCreate,
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):

    obj, code, index = crud_step.create_steps(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_step(db_obj=obj))


# UPDATE
@router.put(
    "/steps/{step_id}/",
    response_model=SingleEntityResponse,
    name="Изменить название этапа",
    description="Изменяет название этапа",
    tags=["Админ панель / Название Этапов"],
)
def update_steps(
    request: Request,
    new_data: StepUpdate,
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    step_id: int = Path(..., title="Id этапа"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    obj, code, indexes = crud_step.update_steps(
        db=session, new_data=new_data, step_id=step_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_step(obj))


# Апи удаляет название этапа
@router.get(
    "/steps/{step_id}/",
    response_model=SingleEntityResponse,
    name="Удалить название этапа",
    description="Полностью удаляет название этапа",
    tags=["Админ панель / Название Этапов"],
)
def delete_step(
    step_id: int = Path(..., title="Id этапа"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
):

    obj, code, indexes = crud_step.get_step(db=session, step_id=step_id)
    get_raise(code=code)

    return SingleEntityResponse(data=crud_step.remove(db=session, id=step_id))


if __name__ == "__main__":
    logging.info("Running...")
