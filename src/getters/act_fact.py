from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.status import get_statuses
from src.models import ActFact
from src.schemas.act_fact import ActFactGet


def get_acts_facts(
    obj: ActFact, request: Optional[Request], config: Settings = settings
) -> ActFactGet:
    if request is not None:
        url = (
            request.url.hostname
            + ":"
            + str(settings.APP_PORT)
            + config.API_V1_STR
            + "/static/"
        )
        if obj.file is not None:
            obj.file = url + str(obj.file)
        else:
            obj.file = None

    return ActFactGet(
        id=obj.id,
        object_id=obj.object_id,
        act_base_id=obj.act_base_id,
        step_list_fact=obj.step_list_fact,
        created_at=obj.created_at,
        started_at=obj.started_at,
        finished_at=obj.finished_at,
        foreman_id=obj.foreman_id,
        main_mechanic_id=obj.main_mechanic_id,
        file=obj.file,
        status_id=get_statuses(obj.status) if obj.status is not None else None,
    )


# def get_acts_facts(obj: ActFact, request: Optional[Request],
#                    config: Settings = settings) -> ActFactGet:
#     if request is not None:
#         url = request.url.hostname + config.API_V1_STR + "/static/"
#         if obj.file is not None:
#             obj.file = url + str(obj.file)
#         else:
#             obj.file = None
#
#     return ActFactGet(
#         id=obj.id,
#         object_id=get_object(obj.object, request=request) if obj.object is not None else None,
#         act_base_id=get_acts_bases(obj.act_base, request=request) if obj.act_base is not None else None,
#         step_list_fact=obj.step_list_fact,
#         created_at=obj.created_at,
#         started_at=obj.started_at,
#         finished_at=obj.finished_at,
#         foreman_id=get_universal_user(obj.foreman, request=request) if obj.foreman is not None else None,
#         main_mechanic_id=get_universal_user(obj.main_mechanic, request=request) if obj.main_mechanic is not None else None,
#         file=obj.file,
#         status_id=get_statuses(obj.status) if obj.status is not None else None,
#     )
