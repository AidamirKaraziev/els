import logging

from fastapi import APIRouter, Depends, Query, Request
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission, has_permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_order import STATUS_DONE, _object_display_label, crud_orders
from src.exceptions import InaccessibleEntity, UnprocessableEntity
from src.getters.order import getting_order
from src.schemas.order import OrderCreate, OrderGet, OrderUpdate
from src.schemas.statistics import TopBreakdownItem
from src.templates_raise import get_raise
from src.utils.time_stamp import datetime_from_timestamp

ROLES_ELIGIBLE = [ADMIN, FOREMAN, DISPATCHER]
ALL_EMPLOYER = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER]

router = APIRouter()


def _check_year_month_pair(year, month) -> None:
    """Год и месяц описывают один период, поодиночке они бессмысленны.

    Молча игнорировать половину фильтра нельзя: человек увидит не тот список
    и не поймёт, почему.
    """
    if (year is None) != (month is None):
        raise UnprocessableEntity(
            message="Год и месяц задаются только вместе",
            num=1292,
            description="Параметры year и month описывают один период.",
            path="$.query",
        )


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
    current_user=Depends(deps.require(Permission.STATISTICS_READ)),
    scope=Depends(deps.get_read_scope),
    year: int = Query(..., ge=1990, le=2100, title="Год отчёта"),
    month: int = Query(..., ge=1, le=12, title="Месяц отчёта (1–12)"),
):

    rows = crud_orders.get_top_breakdowns_by_month(
        db=session, scope=scope, year=year, month=month
    )
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
        "посчитаны в его счётчике.\n\n"
        "Архивных заявок в списке нет, для них есть "
        "отдельный вид — `only_archived=true`."
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
    only_archived: bool = Query(
        False,
        title="Только архивные",
        description=(
            "Отдельный вид «корзина»: заявки, убранные в архив. Без параметра "
            "их в списке нет."
        ),
    ),
    current_universal_user=Depends(deps.require(Permission.ORDER_READ)),
    scope=Depends(deps.get_read_scope),
):
    _check_year_month_pair(year, month)

    data, paginator = crud_orders.get_orders_filtered(
        db=session,
        scope=scope,
        page=page,
        object_id=object_id,
        year=year,
        month=month,
        only_breakdowns=only_breakdowns,
        only_archived=only_archived,
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
    current_universal_user=Depends(deps.require(Permission.ORDER_READ)),
    scope=Depends(deps.get_read_scope),
):
    obj, code, indexes = crud_orders.get_order_by_id(
        db=session, order_id=order_id, scope=scope
    )
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
    current_user=Depends(deps.require(Permission.ORDER_CREATE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, index = crud_orders.create_order(
        db=session, new_data=new_data, current_user=current_user, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_order(obj, request))


# UPDATE
@router.put(
    "/order/{order_id}/",
    response_model=SingleEntityResponse,
    name="update_order",
    description=(
        "Изменяет данные задачи.\n\n"
        "Перевод в статус «Выполнено» требует отдельного права `order:close`: "
        "заявку ведёт диспетчер, а закрывает тот, кто работал, — исполнитель "
        "или прораб. Попытка закрыть заявку без этого права отвечает `403`."
    ),
    tags=["Админ панель / Задачи"],
)
def update_order(
    request: Request,
    new_data: OrderUpdate,
    current_user=Depends(deps.require(Permission.ORDER_UPDATE)),
    order_id: int = Path(..., title="Id задачи"),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    # Закрытие заявки — не обычная правка. Права разделены (`ORDER_UPDATE` и
    # `ORDER_CLOSE`) именно ради этого случая, но проверять их зависимостью
    # нельзя: закрытие отличается от правки не адресом, а телом запроса.
    # До этой проверки право `ORDER_CLOSE` не спрашивала ни одна ручка, и
    # диспетчер закрывал заявки, хотя договорились, что не может.
    if new_data.status_id == STATUS_DONE and not has_permission(
        current_user.role_id, Permission.ORDER_CLOSE
    ):
        raise InaccessibleEntity(
            message="Закрывать заявки может исполнитель или прораб",
            num=1023,
            description=(
                "Диспетчер ведёт заявку, но перевести её в «Выполнено» должен "
                "тот, кто работал"
            ),
            path="$.body",
        )

    obj, code, indexes = crud_orders.update_order(
        db=session, new_data=new_data, order_id=order_id, scope=scope
    )
    get_raise(code=code)

    return SingleEntityResponse(data=getting_order(obj, request=request))


@router.post(
    "/order/{order_id}/archive/",
    response_model=SingleEntityResponse,
    name="archive_order",
    summary="Удалить заявку (в архив)",
    description=(
        "🗑 Мягкое удаление заявки. Запись остаётся в базе, но пропадает из "
        "списков и из ленты сданных работ.\n\n"
        "Настоящего `DELETE` у заявок нет намеренно: офлайн-клиенту об "
        "исчезнувшей строке сказать нечего, а заархивированная приезжает в "
        "`changed_since` с `is_actual=false` — по ней телефон и убирает "
        "заявку у себя.\n\n"
        "Право `order:archive` — админ и прораб; прораб ограничен своими "
        "участками. Повторное архивирование ничего не меняет."
    ),
    tags=["Админ панель / Задачи"],
)
def archive_order(
    request: Request,
    order_id: int = Path(..., title="Id задачи"),
    current_user=Depends(deps.require(Permission.ORDER_ARCHIVE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_orders.archive_order(
        db=session, order_id=order_id, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_order(obj, request=request))


@router.post(
    "/order/{order_id}/restore/",
    response_model=SingleEntityResponse,
    name="restore_order",
    summary="Вернуть заявку из архива",
    description="↩️ Возвращает удалённую заявку в обычные списки.",
    tags=["Админ панель / Задачи"],
)
def restore_order(
    request: Request,
    order_id: int = Path(..., title="Id задачи"),
    current_user=Depends(deps.require(Permission.ORDER_ARCHIVE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_orders.restore_order(
        db=session, order_id=order_id, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_order(obj, request=request))


@router.get(
    "/order/for-me",
    response_model=ListOfEntityResponse,
    name="get_orders",
    description=(
        "📋 Получение списка задач, которые назначены на пользователя.\n\n"
        "Все фильтры необязательные: без них ручка отдаёт всё за всё время, "
        "как раньше. Это главный список механика в телефоне, поэтому он "
        "обычно запрашивается с `only_open=true` и страницами — иначе через "
        "год работы в ответ уезжают сотни закрытых заявок.\n\n"
        "`year` и `month` задаются только вместе — период считается по дате "
        "создания заявки.\n\n"
        "`changed_since` — для синхронизации офлайн-клиента: отдаёт только "
        "заявки, изменившиеся после указанного времени. **Вместе с "
        "`only_open` его слать не нужно**: закрытая заявка просто исчезнет из "
        "ответа, и телефон никогда не узнает, что она закрылась.\n\n"
        "Архивные заявки в обычной выдаче не показываются, но в выдачу по "
        "`changed_since` попадают — с `is_actual=false`. Именно так телефон "
        "узнаёт, что заявку убрали."
    ),
    summary="Задачи для пользователя",
    tags=["Админ панель / Задачи"],
)
def get_orders_for_me(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(
        None,
        ge=1,
        title="Номер страницы",
        description="Без параметра выдача полная, без разбивки на страницы.",
    ),
    status_id: int = Query(None, ge=1, title="Только заявки с этим статусом"),
    only_open: bool = Query(
        False,
        title="Только незакрытые",
        description=(
            "Исключает «Выполнено» и «Проблема» — то, что механику уже не нужно делать."
        ),
    ),
    year: int = Query(None, ge=1990, le=2100, title="Год, вместе с month"),
    month: int = Query(None, ge=1, le=12, title="Месяц (1–12), вместе с year"),
    only_archived: bool = Query(
        False,
        title="Только архивные",
        description="Отдельный вид «корзина». С `changed_since` не нужен.",
    ),
    changed_since: int = Query(
        None,
        ge=0,
        title="Изменённые после этого времени",
        description="Время в секундах эпохи, как и остальные даты в ответах.",
    ),
    current_universal_user=Depends(deps.require(Permission.ORDER_READ)),
    scope=Depends(deps.get_read_scope),
):
    _check_year_month_pair(year, month)

    data, paginator = crud_orders.get_orders_for_me(
        db=session,
        executor_id=current_universal_user.id,
        scope=scope,
        page=page,
        status_id=status_id,
        only_open=only_open,
        only_archived=only_archived,
        year=year,
        month=month,
        changed_since=datetime_from_timestamp(changed_since),
    )
    return ListOfEntityResponse(
        data=[getting_order(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
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
    current_universal_user=Depends(deps.require(Permission.ORDER_READ)),
    scope=Depends(deps.get_read_scope),
):
    data, code, indexes = crud_orders.get_my_orders(
        db=session, creator_id=current_universal_user.id, scope=scope
    )
    get_raise(code=code)

    return ListOfEntityResponse(
        data=[getting_order(obj=datum, request=request) for datum in data]
    )


if __name__ == "__main__":
    logging.info("Running...")
