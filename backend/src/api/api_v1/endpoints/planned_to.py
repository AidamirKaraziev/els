import logging

from fastapi import APIRouter, Depends, Query, Request
from fastapi.params import Path

from src.api import deps
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_object import crud_objects
from src.crud.crud_planned_to import crud_planned_to
from src.crud.users.crud_universal_user import crud_universal_users
from src.getters.planned_to import get_planned_to
from src.schemas.planned_to import (
    PlannedTOCreate,
    PlannedTOGet,
    PlannedTOUpdate,
    ScheduleExecutionStatsGet,
)
from src.templates_raise import get_raise

ROLES_ELIGIBLE = [ADMIN, FOREMAN]
router = APIRouter()


@router.get(
    path="/planned-to/schedule-execution-stats/",
    response_model=SingleEntityResponse[ScheduleExecutionStatsGet],
    name="schedule_execution_stats",
    description=(
        "Статистика выполнения графика ТО за отчётный месяц: по каждому участку (division) — "
        "ответственный прораб, доля завершённых работ (%). "
        "План — записи планового ТО на указанный год с заполненной ячейкой месяца; "
        "факт — связанный акт с датой окончания (finished_at) в этом календарном месяце."
    ),
    tags=["Админ панель / Плановые ТО"],
)
def get_schedule_execution_stats(
    session=Depends(deps.get_db),
    year: int = Query(..., ge=2000, le=2100, title="Отчётный год"),
    month: int = Query(..., ge=1, le=12, title="Отчётный месяц (1–12)"),
):
    data = crud_planned_to.get_schedule_execution_stats(
        db=session, year=year, month=month
    )
    return SingleEntityResponse(data=data)


@router.get(
    path="/all-planned-to/",
    response_model=ListOfEntityResponse,
    name="get_all_planned_to",
    description="Получение списка всех Плановых ТО",
    tags=["Админ панель / Плановые ТО"],
)
def get_all_planned_to(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_planned_to.get_multi(db=session, page=None))

    data, paginator = crud_planned_to.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_planned_to(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/planned-to/{planned_to_id}/",
    response_model=SingleEntityResponse[PlannedTOGet],
    name="get_planned_to_by_id",
    description="Получение данных планового ТО по id",
    tags=["Админ панель / Плановые ТО"],
)
def get_planned_to_by_id(
    request: Request,
    session=Depends(deps.get_db),
    planned_to_id: int = Path(..., title="ID planned TO"),
    # current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    obj, code, indexes = crud_planned_to.get_planed_to_by_id(
        db=session, planned_to_id=planned_to_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_planned_to(obj, request))


@router.get(
    path="/planned-to/by-object/{object_id}/",
    response_model=ListOfEntityResponse[PlannedTOGet],
    summary="Получить список плановых ТО по id объекта",
    description="Получить список плановых ТО по id объекта",
    tags=["Админ панель / Плановые ТО"],
)
def get_planned_to_by_obj_id(
    request: Request,
    session=Depends(deps.get_db),
    object_id: int = Path(..., title="ID объекта"),
    page: int = Query(1, title="Номер страницы"),
    # current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    cur_object, object_code, indexes = crud_objects.get_object_by_id(
        db=session, object_id=object_id
    )
    get_raise(code=object_code)

    logging.info(
        crud_planned_to.get_planed_to_by_object_id(
            db=session, page=None, object_id=object_id
        )
    )
    data, paginator = crud_planned_to.get_planed_to_by_object_id(
        db=session, page=page, object_id=object_id
    )

    return ListOfEntityResponse(
        data=[get_planned_to(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.post(
    path="/planned-to/",
    response_model=SingleEntityResponse,
    name="create_planned_to",
    description="Добавить плановое ТО в базу данных",
    tags=["Админ панель / Плановые ТО"],
)
def create_planned_to(
    request: Request,
    new_data: PlannedTOCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора и Прораба
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLES_ELIGIBLE
    )
    get_raise(code=code)

    obj, code, index = crud_planned_to.create_planned_to(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_planned_to(obj, request))


# UPDATE
@router.put(
    path="/planned-to/{planned_to_id}/",
    response_model=SingleEntityResponse,
    name="update_planned_to",
    description="Изменяет плановое ТО",
    tags=["Админ панель / Плановые ТО"],
)
def update_planned_to(
    request: Request,
    new_data: PlannedTOUpdate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    planned_to_id: int = Path(..., title="Id планового ТО"),
    session=Depends(deps.get_db),
):
    # проверка на роли
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLES_ELIGIBLE
    )
    get_raise(code=code)

    obj, code, indexes = crud_planned_to.update_planned_to(
        db=session, new_data=new_data, planned_to_id=planned_to_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_planned_to(obj, request=request))


if __name__ == "__main__":
    logging.info("Running...")
