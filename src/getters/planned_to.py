from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.act_fact import get_acts_facts
from src.getters.object import get_object
from src.models import PlannedTO
from src.schemas.planned_to import PlannedTOGet


def get_planned_to(
    obj: PlannedTO, request: Optional[Request], config: Settings = settings
) -> Optional[PlannedTOGet]:
    return PlannedTOGet(
        id=obj.id,
        year=obj.year,
        object_id=get_object(obj.object, request=request)
        if obj.object is not None
        else None,
        january_to_id=get_acts_facts(obj.january_to, request=request)
        if obj.january_to is not None
        else None,
        february_to_id=get_acts_facts(obj.february_to, request=request)
        if obj.february_to is not None
        else None,
        march_to_id=get_acts_facts(obj.march_to, request=request)
        if obj.march_to is not None
        else None,
        april_to_id=get_acts_facts(obj.april_to, request=request)
        if obj.april_to is not None
        else None,
        may_to_id=get_acts_facts(obj.may_to, request=request)
        if obj.may_to is not None
        else None,
        june_to_id=get_acts_facts(obj.june_to, request=request)
        if obj.june_to is not None
        else None,
        july_to_id=get_acts_facts(obj.july_to, request=request)
        if obj.july_to is not None
        else None,
        august_to_id=get_acts_facts(obj.august_to, request=request)
        if obj.august_to is not None
        else None,
        september_to_id=get_acts_facts(obj.september_to, request=request)
        if obj.september_to is not None
        else None,
        october_to_id=get_acts_facts(obj.october_to, request=request)
        if obj.october_to is not None
        else None,
        november_to_id=get_acts_facts(obj.november_to, request=request)
        if obj.november_to is not None
        else None,
        december_to_id=get_acts_facts(obj.december_to, request=request)
        if obj.december_to is not None
        else None,
    )
