import logging

from fastapi import APIRouter, Depends, Query, Request
from fastapi.params import Path

from src.api import deps
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_order import _object_display_label, crud_orders
from src.crud.users.crud_universal_user import crud_universal_users
from src.exceptions import UnprocessableEntity
from src.getters.order import getting_order
from src.schemas.order import OrderCreate, OrderGet, OrderUpdate
from src.schemas.statistics import TopBreakdownItem
from src.templates_raise import get_raise

ROLES_ELIGIBLE = [ADMIN, FOREMAN, DISPATCHER]
ALL_EMPLOYER = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER]

router = APIRouter()


@router.get(
    "/order/statistics/top-breakdowns",
    response_model=ListOfEntityResponse[TopBreakdownItem],
    name="top_breakdowns_statistics",
    deprecated=True,
    summary="Топ поломок (устарел)",
    description=(
        "**Устарел, используйте `GET /statistics/breakdowns`.**\n\n"
        "Считает все заявки подряд, включая плановые ТО, ПТО, капремонт и "
        "ложные вызовы, поэтому числа здесь завышены. Ручка оставлена живой "
        "ради клиентов, которые уже на неё ходят, и не меняется.\n\n"
        "Топ поломок по объектам за выбранный месяц и год: число заявок (order) "
        "по дате создания, группировка по объекту, сортировка по убыванию счётчика."
    ),
    tags=["Админ панель / Задачи"],
)
def get_top_breakdowns_statistics(
    session=Depends(deps.get_db),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    year: int = Query(..., ge=1990, le=2100, title="Год отчёта"),
    month: int = Query(..., ge=1, le=12, title="Месяц отчёта (1–12)"),
):
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ALL_EMPLOYER
    )
    get_raise(code=code)

    rows = crud_orders.get_top_breakdowns_by_month(db=session, year=year, month=month)
    data = [
        TopBreakdownItem(
            object_id=row.id,
            object_number=_object_display_label(row.name, row.id),
            client=row.client_name,
            responsible_mechanic=row.mechanic_name,
            breakdown_count=int(row.breakdown_count),
        )
        for row in rows
    ]
    return ListOfEntityResponse(data=data)


# GET-MULTY
@router.get(
    "/order/all",
    response_model=ListOfEntityResponse,
    name="get_orders",
    description=(
        "Получение списка всех задач.\n\n"
        "Все фильтры необязательные: без них ручка работает как раньше.\n\n"
        "`year` и `month` задаются только вместе — период считается по дате "
        "создания заявки. Связка с `object_id` и `only_breakdowns` нужна для "
        "перехода из виджета «Топ поломок»: показать те самые заявки, которые "
        "посчитаны в его счётчике."
    ),
    tags=["Админ панель / Задачи"],
)
def get_orders(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    object_id: int = Query(None, title="Только заявки этого объекта"),
    year: int = Query(None, ge=1990, le=2100, title="Год, вместе с month"),
    month: int = Query(None, ge=1, le=12, title="Месяц (1–12), вместе с year"),
    only_breakdowns: bool = Query(
        False,
        title="Только поломки",
        description=(
            "Исключает плановые ТО, ПТО, капремонт и ложные вызовы — тот же "
            "отбор, что в статистике."
        ),
    ),
    # current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    # Год и месяц описывают один период, поодиночке они бессмысленны.
    # Молча игнорировать половину фильтра нельзя: человек увидит не тот
    # список и не поймёт, почему.
    if (year is None) != (month is None):
        raise UnprocessableEntity(
            message="Год и месяц задаются только вместе",
            num=1292,
            description="Параметры year и month описывают один период.",
            path="$.query",
        )

    data, paginator = crud_orders.get_orders_filtered(
        db=session,
        page=page,
        object_id=object_id,
        year=year,
        month=month,
        only_breakdowns=only_breakdowns,
    )

    return ListOfEntityResponse(
        data=[getting_order(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


# GET BY ID
@router.get(
    "/order/{order_id}/",
    response_model=SingleEntityResponse[OrderGet],
    name="get_order_by_id",
    description="Получение данных задачи по id",
    tags=["Админ панель / Задачи"],
)
def get_order_by_id(
    request: Request,
    session=Depends(deps.get_db),
    order_id: int = Path(..., title="ID order"),
    current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    obj, code, indexes = crud_orders.get_order_by_id(db=session, order_id=order_id)
    get_raise(code=code)
    return SingleEntityResponse(data=getting_order(obj, request))


# CREATE NEW OBJECT
@router.post(
    path="/order/",
    response_model=SingleEntityResponse,
    name="create_order",
    description="Создать задачу",
    tags=["Админ панель / Задачи"],
)
def create_order(
    request: Request,
    new_data: OrderCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора и Прораба
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLES_ELIGIBLE
    )
    get_raise(code=code)

    obj, code, index = crud_orders.create_order(
        db=session, new_data=new_data, current_user=current_user
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_order(obj, request))


# UPDATE
@router.put(
    "/order/{order_id}/",
    response_model=SingleEntityResponse,
    name="update_order",
    description="Изменяет изменяет данные задачи",
    tags=["Админ панель / Задачи"],
)
def update_order(
    request: Request,
    new_data: OrderUpdate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    order_id: int = Path(..., title="Id задачи"),
    session=Depends(deps.get_db),
):
    # проверка на роли
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ALL_EMPLOYER
    )
    get_raise(code=code)

    obj, code, indexes = crud_orders.update_order(
        db=session, new_data=new_data, order_id=order_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=getting_order(obj, request=request))


@router.get(
    "/order/for-me",
    response_model=ListOfEntityResponse,
    name="get_orders",
    description="📋 Получение списка всех задач, которые назначены на пользователя",
    summary="Задачи для пользователя",
    tags=["Админ панель / Задачи"],
)
def get_orders_for_me(
    request: Request,
    session=Depends(deps.get_db),
    current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    data, code, indexes = crud_orders.get_orders_for_me(
        db=session, executor_id=current_universal_user.id
    )
    get_raise(code=code)
    return ListOfEntityResponse(
        data=[getting_order(obj=datum, request=request) for datum in data]
    )


@router.get(
    "/order/my",
    response_model=ListOfEntityResponse,
    name="get_orders",
    description="📋 Получение списка всех задач, которые создал пользователь",
    summary="📋 Список задач созданных пользователем",
    tags=["Админ панель / Задачи"],
)
def get_my_orders(
    request: Request,
    session=Depends(deps.get_db),
    current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    data, code, indexes = crud_orders.get_my_orders(
        db=session, creator_id=current_universal_user.id
    )
    get_raise(code=code)

    return ListOfEntityResponse(
        data=[getting_order(obj=datum, request=request) for datum in data]
    )


if __name__ == "__main__":
    logging.info("Running...")
