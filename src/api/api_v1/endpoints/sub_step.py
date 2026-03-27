import logging

from fastapi import APIRouter, Depends, Path, Query, Request

from src.api import deps
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_sub_step import crud_sub_step
from src.crud.users.crud_universal_user import crud_universal_users
from src.getters.sub_step import get_sub_step
from src.schemas.sub_step import SubStepCreate, SubStepUpdate
from src.templates_raise import get_raise

router = APIRouter()
ROLES_ELIGIBLE_ADMIN_FOREMAN = [ADMIN, FOREMAN]


# Вывод всех Sub-Step
@router.get(
    "/sub-steps/",
    response_model=ListOfEntityResponse,
    name="Список подэтапов",
    description="Получение списка всех названий подэтапов",
    tags=["Админ панель / Название Подэтапов"],
)
def get_data(
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_sub_step.get_multi(db=session, page=None))

    data, paginator = crud_sub_step.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_sub_step(datum) for datum in data], meta=Meta(paginator=paginator)
    )


# CREATE NEW SUB-STEPS
@router.post(
    "/sub-steps/",
    response_model=SingleEntityResponse,
    name="Добавить название подэтапа ",
    description="Добавить одно название подэтапа в базу данных ",
    tags=["Админ панель / Название Подэтапов"],
)
def create_sub_steps(
    request: Request,
    new_data: SubStepCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN
    )
    get_raise(code=code)

    obj, code, index = crud_sub_step.create_sub_steps(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_sub_step(db_obj=obj))


# UPDATE
@router.put(
    "/sub-steps/{sub_step_id}/",
    response_model=SingleEntityResponse,
    name="Изменить название подэтапа",
    description="Изменяет название подэтапа",
    tags=["Админ панель / Название Подэтапов"],
)
def update_sub_steps(
    request: Request,
    new_data: SubStepUpdate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    sub_step_id: int = Path(..., title="Id подэтапа"),
    session=Depends(deps.get_db),
):
    # проверка на роли
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN
    )
    get_raise(code=code)

    obj, code, indexes = crud_sub_step.update_sub_steps(
        db=session, new_data=new_data, sub_step_id=sub_step_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_sub_step(obj))


# Апи удаляет название подэтапа
@router.get(
    "/sub-steps/{sub_step_id}/",
    response_model=SingleEntityResponse,
    name="Удалить название подэтапа",
    description="Полностью удаляет название подэтапа",
    tags=["Админ панель / Название Подэтапов"],
)
def delete_sub_step(
    sub_step_id: int = Path(..., title="Id подэтапа"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN
    )
    get_raise(code=code)

    obj, code, indexes = crud_sub_step.get_sub_step(db=session, sub_step_id=sub_step_id)
    get_raise(code=code)

    return SingleEntityResponse(data=crud_sub_step.remove(db=session, id=sub_step_id))


if __name__ == "__main__":
    logging.info("Running...")
