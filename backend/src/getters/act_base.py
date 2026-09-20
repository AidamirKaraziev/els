from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.factory_model import get_factory_model
from src.getters.type_act import get_type_acts
from src.models.act_base import ActBase
from src.schemas.act_base import ActBaseByModelGet, ActBaseGet
from src.services.checklist import template_steps


def get_acts_bases(
    db_obj: ActBase, request: Optional[Request], config: Settings = settings
) -> Optional[ActBaseGet]:
    steps = template_steps(db_obj.step_list)
    return ActBaseGet(
        id=db_obj.id,
        factory_model_id=get_factory_model(db_obj.factory_model)
        if db_obj.factory_model is not None
        else None,
        type_act_id=get_type_acts(db_obj.type_act)
        if db_obj.type_act is not None
        else None,
        step_list=db_obj.step_list,
        steps=steps,
        steps_count=len(steps),
        deleted_at=db_obj.deleted_at,
    )


def get_act_base_by_model(db_obj: ActBase) -> ActBaseByModelGet:
    steps = template_steps(db_obj.step_list)
    return ActBaseByModelGet(
        type_act=get_type_acts(db_obj.type_act),
        template_id=db_obj.id,
        steps=steps,
        steps_count=len(steps),
        has_template=bool(steps),
        deleted_at=db_obj.deleted_at,
    )
