from sqlite3 import Date, Timestamp
from typing import Optional

from pydantic import BaseModel

from src.schemas.fault_category import FaultCategoryGet
from src.schemas.object import ObjectGet
from src.schemas.reason_fault import ReasonFaultGet
from src.schemas.status import StatusGet
from src.schemas.universal_user import UniversalUserGet


class OrderBase(BaseModel):
    id: int
    object_id: Optional[int]
    creator_id: int
    fault_category_id: Optional[int]
    task_text: Optional[str]

    executor_id: int
    commentary: Optional[str]
    reason_fault_id: Optional[int]

    created_at: Optional[Timestamp]
    accepted_at: Optional[Timestamp]
    in_progress_at: Optional[Timestamp]
    done_at: Optional[Timestamp]

    status_id: Optional[int]
    is_viewed: Optional[bool]


class OrderCreate(BaseModel):
    # id: int
    object_id: Optional[int]
    creator_id: Optional[int]
    fault_category_id: Optional[int]
    task_text: Optional[str]

    executor_id: int
    # commentary: Optional[str]
    # reason_fault_id: Optional[int]

    created_at: Optional[Timestamp] = None
    # accepted_at: Optional[Date]
    # in_progress_at: Optional[Date]
    # dane_at: Optional[Date]

    # status_id: Optional[int]


class OrderUpdate(BaseModel):
    object_id: Optional[int]
    fault_category_id: Optional[int]
    task_text: Optional[str]
    executor_id: Optional[int]
    commentary: Optional[str]
    reason_fault_id: Optional[int]
    created_at: Optional[Date]
    accepted_at: Optional[Date]
    in_progress_at: Optional[Date]
    done_at: Optional[Date]
    # Опечатка в имени, из-за которой `done_at` не заполнялся с самого начала:
    # `CRUDBase.update` переносит только те поля, чьи имена совпадают с
    # колонками модели, а колонка называется `done_at`. Поле оставлено, чтобы
    # клиент, который его шлёт, не получил 422 — но на запись оно не влияет.
    dane_at: Optional[Date]
    status_id: Optional[int]
    is_viewed: Optional[bool]


class OrderGet(BaseModel):
    id: int
    object_id: Optional[ObjectGet]
    creator_id: UniversalUserGet
    fault_category_id: Optional[FaultCategoryGet]
    task_text: Optional[str]

    executor_id: Optional[UniversalUserGet]
    commentary: Optional[str]
    reason_fault_id: Optional[ReasonFaultGet]

    created_at: Optional[int]
    accepted_at: Optional[int]
    in_progress_at: Optional[int]
    done_at: Optional[int]

    status_id: Optional[StatusGet]
    is_viewed: Optional[bool]

    #: Метка последней правки. Клиент запоминает наибольшую из полученных и
    #: присылает её обратно в `changed_since`.
    updated_at: Optional[int]
