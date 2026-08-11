from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.factory_model import get_factory_model
from src.getters.type_act import get_type_acts
from src.models.act_base import ActBase
from src.schemas.act_base import ActBaseGet


def get_acts_bases(
    db_obj: ActBase, request: Optional[Request], config: Settings = settings
) -> Optional[ActBaseGet]:
    return ActBaseGet(
        id=db_obj.id,
        factory_model_id=get_factory_model(db_obj.factory_model)
        if db_obj.factory_model is not None
        else None,
        type_act_id=get_type_acts(db_obj.type_act)
        if db_obj.type_act is not None
        else None,
        step_list=db_obj.step_list,
    )
