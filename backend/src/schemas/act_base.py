from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from src.schemas.factory_model import FactoryModelGet
from src.schemas.type_act import TypeActGet

_STEP_LIST_DEPRECATED = (
    "Устарело: строка чек-листа как есть. Передавайте `steps` — список "
    "названий шагов, сервер сам пишет каноническую форму."
)


class ActBaseBase(BaseModel):
    id: int = Field(..., title="ID шаблонного акта")
    factory_model_id: Optional[int]
    type_act_id: Optional[int]
    step_list: Optional[str]


class ActBaseCreate(BaseModel):
    factory_model_id: Optional[int]
    type_act_id: Optional[int]
    steps: Optional[List[str]] = Field(
        None, title="Шаги чек-листа", description="Названия шагов по порядку"
    )
    step_list: Optional[str] = Field(None, description=_STEP_LIST_DEPRECATED)


class ActBaseUpdate(BaseModel):
    factory_model_id: Optional[int] = Field(None, description="Не передано — не меняем")
    type_act_id: Optional[int] = Field(None, description="Не передано — не меняем")
    steps: Optional[List[str]] = Field(
        None, title="Шаги чек-листа", description="Названия шагов по порядку"
    )
    step_list: Optional[str] = Field(None, description=_STEP_LIST_DEPRECATED)


class ActBaseGet(BaseModel):
    id: int = Field(..., title="ID шаблонного акта")
    factory_model_id: Optional[FactoryModelGet]
    type_act_id: Optional[TypeActGet]
    step_list: Optional[str] = Field(None, description=_STEP_LIST_DEPRECATED)
    steps: List[str] = Field([], title="Шаги чек-листа")
    steps_count: int = Field(0, title="Число шагов")
    deleted_at: Optional[datetime] = Field(
        None, title="Когда вид ТО убрали у модели; пусто — живой"
    )


class ActBaseByModelGet(BaseModel):
    """Вид ТО у модели — строка `acts_bases` глазами экрана «Шаблоны ТО»."""

    type_act: TypeActGet
    template_id: int = Field(..., title="ID строки acts_bases")
    steps: List[str] = Field([], title="Шаги чек-листа")
    steps_count: int = Field(0, title="Число шагов")
    has_template: bool = Field(..., title="Чек-лист заполнен")
    deleted_at: Optional[datetime] = Field(
        None, title="Когда вид ТО убрали у модели; пусто — живой"
    )
