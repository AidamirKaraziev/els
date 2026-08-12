from fastapi import APIRouter, Depends, Query, Request
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.crud.crud_defective_act import crud_defective_act
from src.getters.defective_act import getting_defective_act
from src.schemas.defective_act import (
    DefectiveActCreate,
    DefectiveActGet,
    DefectiveActStatusUpdate,
    DefectiveActUpdate,
)
from src.templates_raise import get_raise

ROLES_CREATE = [ADMIN, FOREMAN, MECHANIC]
ROLES_UPDATE_STATUS = [ADMIN, FOREMAN, MECHANIC]
ROLES_ADMIN_FOREMAN = [ADMIN, FOREMAN]
ROLES_ADMIN_ONLY = [ADMIN]


router = APIRouter()


@router.get(
    path="/defective-act/all",
    response_model=ListOfEntityResponse,
    name="get_defective_acts",
    description="Получение списка всех дефектных актов",
    tags=["Админ панель / Дефектные акты"],
)
def get_defective_acts(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    data, paginator = crud_defective_act.get_multi(db=session, scope=scope, page=page)
    return ListOfEntityResponse(
        data=[getting_defective_act(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/defective-act/by-planned-to/{planned_to_id}/",
    response_model=ListOfEntityResponse,
    name="get_defective_acts_by_planned_to",
    description="Получение списка дефектных актов по planned_to_id (опционально фильтр по месяцу)",
    tags=["Админ панель / Дефектные акты"],
)
def get_defective_acts_by_planned_to(
    request: Request,
    session=Depends(deps.get_db),
    planned_to_id: int = Path(..., title="ID planned_to"),
    month: int = Query(0, ge=0, le=12, title="Месяц (1–12), 0 = без фильтра"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    data_q, code, _ = crud_defective_act.get_by_planned_to_id(
        db=session, planned_to_id=planned_to_id, month=month, scope=scope
    )
    get_raise(code=code)
    data = data_q.all()
    return ListOfEntityResponse(
        data=[getting_defective_act(obj=datum, request=request) for datum in data]
    )


@router.get(
    path="/defective-act/{defective_act_id}/",
    response_model=SingleEntityResponse[DefectiveActGet],
    name="get_defective_act_by_id",
    description="Получение данных дефектного акта по id",
    tags=["Админ панель / Дефектные акты"],
)
def get_defective_act_by_id(
    request: Request,
    session=Depends(deps.get_db),
    defective_act_id: int = Path(..., title="ID defective act"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    obj, code, _ = crud_defective_act.get_defective_act_by_id(
        db=session, defective_act_id=defective_act_id, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_defective_act(obj, request))


@router.post(
    path="/defective-act/",
    response_model=SingleEntityResponse,
    name="create_defective_act",
    description="Создать дефектный акт",
    tags=["Админ панель / Дефектные акты"],
)
def create_defective_act(
    request: Request,
    new_data: DefectiveActCreate,
    current_user=Depends(deps.require(Permission.ACT_CREATE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, _ = crud_defective_act.create_defective_act(
        db=session, new_data=new_data, current_user=current_user, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_defective_act(obj, request))


@router.put(
    path="/defective-act/{defective_act_id}/",
    response_model=SingleEntityResponse,
    name="update_defective_act",
    description="Изменить дефектный акт (только админ)",
    tags=["Админ панель / Дефектные акты"],
)
def update_defective_act(
    request: Request,
    update_data: DefectiveActUpdate,
    current_user=Depends(deps.require(Permission.ACT_UPDATE)),
    defective_act_id: int = Path(..., title="ID defective act"),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, _ = crud_defective_act.update_defective_act(
        db=session,
        defective_act_id=defective_act_id,
        update_data=update_data,
        scope=scope,
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_defective_act(obj, request))


@router.put(
    path="/defective-act/{defective_act_id}/status/",
    response_model=SingleEntityResponse,
    name="update_defective_act_status",
    description="Изменить статус дефектного акта (админ, прораб, механик)",
    tags=["Админ панель / Дефектные акты"],
)
def update_defective_act_status(
    request: Request,
    new_data: DefectiveActStatusUpdate,
    current_user=Depends(deps.require(Permission.ACT_UPDATE)),
    defective_act_id: int = Path(..., title="ID defective act"),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, _ = crud_defective_act.update_status(
        db=session, defective_act_id=defective_act_id, new_data=new_data, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_defective_act(obj, request))


@router.post(
    path="/defective-act/{defective_act_id}/pdf/",
    response_model=SingleEntityResponse,
    name="generate_defective_act_pdf",
    description="Сформировать PDF дефектного акта (отдельным запросом, только админ и прораб)",
    tags=["Админ панель / Дефектные акты"],
)
def generate_defective_act_pdf(
    request: Request,
    current_user=Depends(deps.require(Permission.ACT_READ)),
    defective_act_id: int = Path(..., title="ID defective act"),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_read_scope),
):
    obj, code, _ = crud_defective_act.generate_pdf(
        db=session, defective_act_id=defective_act_id, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_defective_act(obj, request))
