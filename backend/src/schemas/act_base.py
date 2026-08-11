from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.factory_model import FactoryModelGet
from src.schemas.type_act import TypeActGet


class ActBaseBase(BaseModel):
    id: int = Field(..., title="ID шаблонного акта")
    factory_model_id: Optional[int]
    type_act_id: Optional[int]
    step_list: Optional[str]


class ActBaseCreate(BaseModel):
    factory_model_id: Optional[int]
    type_act_id: Optional[int]
    step_list: Optional[str]


class ActBaseUpdate(BaseModel):
    factory_model_id: Optional[int]
    type_act_id: Optional[int]
    step_list: Optional[str]


class ActBaseGet(BaseModel):
    id: int = Field(..., title="ID шаблонного акта")
    factory_model_id: Optional[FactoryModelGet]
    type_act_id: Optional[TypeActGet]
    step_list: Optional[str]
