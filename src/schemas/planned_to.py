from typing import Optional

from pydantic import BaseModel

from src.schemas.act_fact import ActFactGet
from src.schemas.object import ObjectGet


class PlannedTOBase(BaseModel):
    id: int
    year: str
    object_id: Optional[ObjectGet]

    january_to_id: Optional[ActFactGet]
    february_to_id: Optional[ActFactGet]
    march_to_id: Optional[ActFactGet]
    april_to_id: Optional[ActFactGet]
    may_to_id: Optional[ActFactGet]
    june_to_id: Optional[ActFactGet]
    july_to_id: Optional[ActFactGet]
    august_to_id: Optional[ActFactGet]
    september_to_id: Optional[ActFactGet]
    october_to_id: Optional[ActFactGet]
    november_to_id: Optional[ActFactGet]
    december_to_id: Optional[ActFactGet]


class PlannedTOCreate(BaseModel):
    year: str
    object_id: int

    january_to_id: Optional[int]
    february_to_id: Optional[int]
    march_to_id: Optional[int]
    april_to_id: Optional[int]
    may_to_id: Optional[int]
    june_to_id: Optional[int]
    july_to_id: Optional[int]
    august_to_id: Optional[int]
    september_to_id: Optional[int]
    october_to_id: Optional[int]
    november_to_id: Optional[int]
    december_to_id: Optional[int]


class PlannedTOUpdate(BaseModel):
    january_to_id: Optional[int]
    february_to_id: Optional[int]
    march_to_id: Optional[int]
    april_to_id: Optional[int]
    may_to_id: Optional[int]
    june_to_id: Optional[int]
    july_to_id: Optional[int]
    august_to_id: Optional[int]
    september_to_id: Optional[int]
    october_to_id: Optional[int]
    november_to_id: Optional[int]
    december_to_id: Optional[int]


class PlannedTOGet(BaseModel):
    id: int
    year: str
    object_id: Optional[ObjectGet]

    january_to_id: Optional[ActFactGet]
    february_to_id: Optional[ActFactGet]
    march_to_id: Optional[ActFactGet]
    april_to_id: Optional[ActFactGet]
    may_to_id: Optional[ActFactGet]
    june_to_id: Optional[ActFactGet]
    july_to_id: Optional[ActFactGet]
    august_to_id: Optional[ActFactGet]
    september_to_id: Optional[ActFactGet]
    october_to_id: Optional[ActFactGet]
    november_to_id: Optional[ActFactGet]
    december_to_id: Optional[ActFactGet]
