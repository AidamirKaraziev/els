from fastapi import APIRouter

from src.api.api_v1.endpoints import (
    act_base,
    act_fact,
    act_fact_step_photo,
    admin,
    auth,
    client,
    company,
    contact_person,
    contract,
    cost_type,
    defective_act,
    defective_act_photo,
    division,
    factory_model,
    fault_category,
    files,
    foreman,
    location,
    object,
    order,
    order_photo,
    organization,
    planned_to,
    reason_fault,
    reports,
    role,
    statistics,
    status,
    step,
    sub_step,
    type_act,
    type_contract,
    type_object,
    universal_user,
    working_specialty,
)

api_router = APIRouter()


# Первым — чтобы вход было видно в начале схемы, а не между справочниками.
api_router.include_router(auth.router)
api_router.include_router(planned_to.router)
api_router.include_router(universal_user.router)
api_router.include_router(admin.router)
api_router.include_router(foreman.router)
api_router.include_router(client.router)
api_router.include_router(division.router)
api_router.include_router(company.router)
api_router.include_router(location.router, tags=["Админ панель / Города"])
api_router.include_router(contact_person.router)
api_router.include_router(defective_act.router)
api_router.include_router(defective_act_photo.router)
api_router.include_router(type_contract.router)
api_router.include_router(type_act.router)
api_router.include_router(cost_type.router)
api_router.include_router(type_object.router)
api_router.include_router(status.router)
api_router.include_router(role.router)
api_router.include_router(working_specialty.router)
api_router.include_router(reason_fault.router)
api_router.include_router(fault_category.router)
api_router.include_router(factory_model.router)
api_router.include_router(contract.router)
api_router.include_router(organization.router)
api_router.include_router(object.router)
api_router.include_router(act_base.router)
api_router.include_router(act_fact.router)
api_router.include_router(act_fact_step_photo.router)
api_router.include_router(sub_step.router)
api_router.include_router(step.router)
api_router.include_router(order_photo.router)
api_router.include_router(order.router)
api_router.include_router(statistics.router)
api_router.include_router(reports.router)
api_router.include_router(files.router)
