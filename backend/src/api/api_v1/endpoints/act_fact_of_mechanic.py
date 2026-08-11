# import logging
# from typing import Optional
#
# from fastapi import APIRouter, Depends, Request, UploadFile, File, Query
# from fastapi.params import Path
#
# from src.api import deps
#
# from src.crud.crud_universal_user import crud_universal_users
# from src.core.response import ListOfEntityResponse, SingleEntityResponse, Meta
# from src.core.templates_raise import get_raise
# from src.core.roles import ADMIN, FOREMAN
#
# from src.crud.crud_act_fact import crud_acts_fact
# from src.getters.act_fact import get_acts_facts
#
# from src.schemas.act_fact import ActFactCreate, ActFactUpdate, ActFactGet
#
#
# ROLES_ELIGIBLE = [ADMIN, FOREMAN]
# PATH_MODEL = "act_fact"
# PATH_TYPE = "file"
#
# router = APIRouter()
#
#
# # апи вывода по айди фактического акта
#
#
# # GET-MULTY
# @router.get('/list-mechanic/',
#             response_model=ListOfEntityResponse,
#             name='Список механиков участвующих в работе',
#             description='Получение списка механиков участвующих в работе',
#             tags=['Админ панель / Список Механиков']
#             )
# def get_data(
#         request: Request,
#         session=Depends(deps.get_db),
#         act_fact_id: int = Path(..., title='ID факт акта'),
#         page: int = Query(1, title="Номер страницы")
# ):
#     logging.info(crud_acts_fact.get_multi(db=session, page=None))
#
#     data, paginator = crud_acts_fact.get_multi(db=session, page=page)
#
#     return ListOfEntityResponse(data=[get_acts_facts(obj=datum, request=request) for datum in data],
#                                 meta=Meta(paginator=paginator))
#
#
# # GET BY ID
# @router.get('/act-fact/{act_fact_id}/',
#             response_model=SingleEntityResponse[ActFactGet],
#             name='Получить данные фактического акта по id ',
#             description='Получение данных фактического акта по id',
#             tags=['Админ панель / Фактические Акты']
#             )
# def get_data(
#         request: Request,
#         session=Depends(deps.get_db),
#         act_fact_id: int = Path(..., title='ID object'),
#         # current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
# ):
#     obj, code, indexes = crud_acts_fact.getting_act_fact(db=session, act_fact_id=act_fact_id)
#     get_raise(code=code)
#     return SingleEntityResponse(data=get_acts_facts(obj, request))
#
#
# # CREATE NEW ACT FACT
# @router.post('/act-fact/',
#              response_model=SingleEntityResponse,
#              name='Добавить акт факт',
#              description='Добавить один акт факт в базу данных ',
#              tags=['Админ панель / Фактические Акты']
#              )
# def create_act_fact(
#         request: Request,
#         new_data: ActFactCreate,
#         current_user=Depends(deps.get_current_universal_user_by_bearer),
#         session=Depends(deps.get_db),
# ):
#     # сделать проверку на роль Администратора и Прораба
#     code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
#     get_raise(code=code)
#
#     obj, code, index = crud_acts_fact.create_act_fact(db=session, new_data=new_data)
#     get_raise(code=code)
#     return SingleEntityResponse(data=get_acts_facts(obj, request))
#
#
# # UPDATE
# @router.put('/act-fact/{act_fact_id}/',
#             response_model=SingleEntityResponse,
#             name='Изменить данные фактического акта',
#             description='Изменяет изменяет данные фактического акта',
#             tags=['Админ панель / Фактические Акты'])
# def update_act_fact(
#         request: Request,
#         new_data: ActFactUpdate,
#         current_user=Depends(deps.get_current_universal_user_by_bearer),
#         act_fact_id: int = Path(..., title='Id фактического акта'),
#         session=Depends(deps.get_db)
# ):
#     # проверка на роли
#     code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
#     get_raise(code=code)
#
#     obj, code, indexes = crud_acts_fact.update_act_fact(db=session, new_data=new_data, act_fact_id=act_fact_id)
#     get_raise(code=code)
#
#     return SingleEntityResponse(data=get_acts_facts(obj, request=request))
#
#
# # UPDATE FILE
# @router.put("/act-fact/{act_fact_id}/file/",
#             response_model=SingleEntityResponse[ActFactGet],
#             name='Изменить файл',
#             description='Изменить файл для фактического акта, если отправить пустой файл сбрасывается',
#             tags=['Админ панель / Фактические Акты'],
#             )
# def create_upload_file(
#         request: Request,
#         file: Optional[UploadFile] = File(None),
#         current_user=Depends(deps.get_current_universal_user_by_bearer),
#         act_fact_id: int = Path(..., title='Id фактический акт'),
#         session=Depends(deps.get_db),
#         ):
#     # проверка на роли
#     code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
#     get_raise(code=code)
#
#     obj, code, indexes = crud_acts_fact.getting_act_fact(db=session, act_fact_id=act_fact_id)
#     get_raise(code=code)
#     crud_acts_fact.adding_file(db=session, file=file, path_model=PATH_MODEL, path_type=PATH_TYPE, db_obj=obj)
#
#     return SingleEntityResponse(data=get_acts_facts(crud_acts_fact.get(db=session, id=act_fact_id), request=request))
#
#
# if __name__ == "__main__":
#     logging.info('Running...')
