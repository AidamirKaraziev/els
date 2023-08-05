from typing import Optional
from fastapi import Request

from app.core.config import Settings, settings

from app.utils.time_stamp import to_timestamp

from app.schemas.order import OrderGet
from app.models import Order

from app.getters.object import get_object
from app.getters.universal_user import get_universal_user
from app.getters.fault_category import getting_fault_category
from app.getters.reason_fault import getting_reason_fault
from app.getters.status import get_statuses

from app.getters.order_photo import getting_order_photo


def getting_order(obj: Order, request: Optional[Request], config: Settings = settings) -> Optional[OrderGet]:
    if obj.created_at is not None:
        obj.created_at = to_timestamp(obj.created_at)
    if obj.accepted_at is not None:
        obj.accepted_at = to_timestamp(obj.accepted_at)
    if obj.in_progress_at is not None:
        obj.in_progress_at = to_timestamp(obj.in_progress_at)
    if obj.done_at is not None:
        obj.done_at = to_timestamp(obj.done_at)

    # obj.date_inspection = to_timestamp(obj.date_inspection)
    # obj.date_inspection = to_timestamp(obj.date_inspection)

    return OrderGet(
        id=obj.id,
        object_id=get_object(obj.object, request=request) if obj.object is not None else None,
        creator_id=get_universal_user(obj.creator, request=request) if obj.creator is not None else None,
        fault_category_id=getting_fault_category(obj.fault_category)if obj.fault_category is not None else None,
        task_text=obj.task_text,

        executor_id=get_universal_user(obj.executor, request=request) if obj.executor is not None else None,
        commentary=obj.commentary,
        reason_fault_id=getting_reason_fault(obj.reason_fault)if obj.reason_fault is not None else None,

        created_at=obj.created_at,
        accepted_at=obj.accepted_at,
        in_progress_at=obj.in_progress_at,
        done_at=obj.done_at,

        status_id=get_statuses(obj.status)if obj.status is not None else None,
        is_viewed=obj.is_viewed,
        order_photo=getting_order_photo(obj=obj.order_photo, request=request) if obj.order_photo is not None else None
    )
