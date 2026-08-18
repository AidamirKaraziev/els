from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.fault_category import getting_fault_category
from src.getters.object import get_object
from src.getters.reason_fault import getting_reason_fault
from src.getters.status import get_statuses
from src.getters.universal_user import get_universal_user
from src.models import Order
from src.schemas.order import OrderGet
from src.utils.time_stamp import to_timestamp, utc_to_timestamp


def getting_order(
    obj: Order, request: Optional[Request], config: Settings = settings
) -> Optional[OrderGet]:
    # Даты считаем в переменные, а не обратно в поля записи. Присваивание в
    # `obj.created_at` помечало загруженную заявку изменённой, и ближайший
    # flush в той же сессии писал в базу число вместо даты, попутно сдвигая
    # `updated_at` — метку, по которой телефон механика понимает, что
    # изменилось. То есть простое чтение списка выглядело бы как правка всех
    # заявок сразу.
    created_at = to_timestamp(obj.created_at)
    accepted_at = to_timestamp(obj.accepted_at)
    in_progress_at = to_timestamp(obj.in_progress_at)
    done_at = to_timestamp(obj.done_at)

    return OrderGet(
        id=obj.id,
        object_id=get_object(obj.object, request=request)
        if obj.object is not None
        else None,
        creator_id=get_universal_user(obj.creator, request=request)
        if obj.creator is not None
        else None,
        fault_category_id=getting_fault_category(obj.fault_category)
        if obj.fault_category is not None
        else None,
        task_text=obj.task_text,
        executor_id=get_universal_user(obj.executor, request=request)
        if obj.executor is not None
        else None,
        commentary=obj.commentary,
        reason_fault_id=getting_reason_fault(obj.reason_fault)
        if obj.reason_fault is not None
        else None,
        created_at=created_at,
        accepted_at=accepted_at,
        in_progress_at=in_progress_at,
        done_at=done_at,
        status_id=get_statuses(obj.status) if obj.status is not None else None,
        is_viewed=obj.is_viewed,
        # Считаем в переменную, а не в поле объекта: соседние строки этой
        # функции пишут метку прямо в загруженную запись, и любой flush после
        # этого попытается сохранить число в колонку с датой.
        updated_at=utc_to_timestamp(obj.updated_at),
        is_actual=obj.is_actual,
        # order_photo=getting_order_photo(obj=obj.order_photo, request=request) if obj.order_photo is not None else None
    )
