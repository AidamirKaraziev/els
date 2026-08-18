from typing import Optional

from fastapi import Request

from src.config import Settings, settings
from src.getters.static_url import static_base_url
from src.getters.status import get_statuses
from src.models import ActFact
from src.schemas.act_fact import ActFactGet, ChecklistGet, ChecklistStepGet
from src.schemas.maintenance import MaintenanceObject, MyMaintenanceItem
from src.services.checklist import dump_legacy, parse_checklist
from src.utils.time_stamp import utc_to_timestamp


def get_acts_facts(
    obj: ActFact, request: Optional[Request], config: Settings = settings
) -> ActFactGet:
    """Фактический акт наружу.

    Чек-лист уходит сразу в двух видах. `checklist` — каноническая форма, в
    которой акт и хранится; `step_list_fact` — та же самая, но собранная
    обратно в форму старых экранов. Экран графика у прораба работает в проде и
    читает именно её, поэтому хранение поменять можно, а ответ — нельзя.

    Считаем в переменные, а не в поля записи: присвоение в `obj.file` пометило
    бы акт изменённым, ближайший `flush` сохранил бы в базу полную ссылку
    вместо относительного пути, а `updated_at` двинулся бы от простого чтения —
    и телефон механика при каждой синхронизации качал бы всё заново.
    """
    file = obj.file
    if request is not None and file is not None:
        file = static_base_url(request, config) + str(file)

    checklist = parse_checklist(obj.step_list_fact)

    return ActFactGet(
        id=obj.id,
        object_id=obj.object_id,
        act_base_id=obj.act_base_id,
        step_list_fact=(
            dump_legacy(checklist) if obj.step_list_fact is not None else None
        ),
        checklist=ChecklistGet(
            title=checklist.title,
            steps=[
                ChecklistStepGet(
                    id=step.id,
                    title=step.title,
                    done=step.done,
                    comment=step.comment,
                )
                for step in checklist.steps
            ],
        ),
        created_at=obj.created_at,
        started_at=obj.started_at,
        finished_at=obj.finished_at,
        foreman_id=obj.foreman_id,
        main_mechanic_id=obj.main_mechanic_id,
        file=file,
        status_id=get_statuses(obj.status) if obj.status is not None else None,
        is_actual=obj.is_actual,
    )


def get_my_maintenance(obj: ActFact, year: str, month: int) -> MyMaintenanceItem:
    """Строка списка «мои ТО».

    Чек-лист разбирается здесь и наружу уходит только счётчиком: в поле лежит
    строка на сотни килобайт, и гнать её в список из тридцати ТО ради двух
    чисел — верный способ сделать экран механика неоткрываемым на телефоне.

    Год в графике строковый и набит руками, поэтому нечисловой разбирается в
    ноль, а не роняет весь список.
    """
    checklist = parse_checklist(obj.step_list_fact)

    return MyMaintenanceItem(
        act_id=obj.id,
        object=MaintenanceObject(
            id=obj.object.id, name=obj.object.name, address=obj.object.address
        )
        if obj.object is not None
        else None,
        year=int(year) if str(year).strip().isdigit() else 0,
        month=month,
        title=checklist.title,
        steps_total=checklist.total,
        steps_done=checklist.done,
        started_at=utc_to_timestamp(obj.started_at),
        finished_at=utc_to_timestamp(obj.finished_at),
        status_id=obj.status_id,
        updated_at=utc_to_timestamp(obj.updated_at),
        is_actual=obj.is_actual,
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
