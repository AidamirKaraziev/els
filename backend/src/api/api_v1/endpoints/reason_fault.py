import logging

from fastapi import APIRouter, Depends, Path, Query, Request

from src.api import deps
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_reason_fault import crud_reason_fault
from src.crud.users.crud_universal_user import crud_universal_users
from src.getters.reason_fault import getting_reason_fault
from src.schemas.reason_fault import ReasonFaultCreate, ReasonFaultUpdate
from src.templates_raise import get_raise

ROLE_ADMIN_FOREMAN = [ADMIN, FOREMAN]
router = APIRouter()


# Вывод всех участков
@router.get(
    "/reason-fault/all",
    response_model=ListOfEntityResponse,
    name="get_reasons_faults",
    description="Получение списка всех причин неисправности",
    tags=["Админ панель / Причины неисправности"],
)
def get_reasons_faults(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_reason_fault.get_multi(db=session, page=None))
    data, paginator = crud_reason_fault.get_multi(db=session, page=page)
    return ListOfEntityResponse(
        data=[getting_reason_fault(datum) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    "/reason-fault/{reason_fault_id}",
    response_model=SingleEntityResponse,
    name="get_reason_fault",
    description="Вывод причины неисправности по идентификатору",
    tags=["Админ панель / Причины неисправности"],
)
def get_reason_fault(reason_fault_id: int, session=Depends(deps.get_db)):
    obj, code, indexes = crud_reason_fault.get_fault_by_id(
        db=session, fault_id=reason_fault_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_reason_fault(obj=obj))


# # Создание участка
@router.post(
    "/{reason_fault}",
    response_model=SingleEntityResponse,
    name="create_reason_fault",
    description="Создать причину неисправности",
    tags=["Админ панель / Причины неисправности"],
)
def create_reason_fault(
    request: Request,
    new_data: ReasonFaultCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLE_ADMIN_FOREMAN
    )
    get_raise(code=code)

    db_obj, code, index = crud_reason_fault.create_new(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=getting_reason_fault(db_obj))


# UPDATE
@router.put(
    "/reason-fault/{reason_fault_id}/",
    response_model=SingleEntityResponse,
    name="update_reason_fault",
    description="Изменить название причины неисправности",
    tags=["Админ панель / Причины неисправности"],
)
def update_reason_fault(
    request: Request,
    new_data: ReasonFaultUpdate,
    reason_fault_id: int = Path(..., title="Id причины неисправности"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    # проверку на роли
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLE_ADMIN_FOREMAN
    )
    get_raise(code=code)

    db_obj, code, index = crud_reason_fault.update(
        db=session, new_data=new_data, obj_id=reason_fault_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=getting_reason_fault(db_obj))


if __name__ == "__main__":
    logging.info("Running...")
