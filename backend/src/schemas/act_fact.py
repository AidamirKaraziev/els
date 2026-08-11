from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from src.schemas.status import StatusGet


class ActFactBase(BaseModel):
    id: int
    object_id: Optional[int]
    act_base_id: Optional[int]
    step_list_fact: Optional[str]

    date_create: Optional[int]
    date_start: Optional[int]
    date_finish: Optional[int]

    foreman_id: Optional[int]
    main_mechanic_id: Optional[int]

    file: Optional[str]
    status_id: Optional[int]


class ActFactCreate(BaseModel):
    object_id: int
    act_base_id: int
    foreman_id: int
    main_mechanic_id: int


class ActFactUpdate(BaseModel):
    step_list_fact: Optional[str]
    started_at: Optional[int]
    finished_at: Optional[int]
    foreman_id: Optional[int]
    main_mechanic_id: Optional[int]
    status_id: Optional[int]


class ActFactGet(BaseModel):
    id: int
    object_id: Optional[int]
    act_base_id: Optional[int]
    step_list_fact: Optional[str]

    created_at: Optional[datetime]
    started_at: Optional[datetime]
    finished_at: Optional[datetime]

    foreman_id: Optional[int]
    main_mechanic_id: Optional[int]

    file: Optional[str]
    status_id: Optional[StatusGet]
