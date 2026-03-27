import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Path, Query, Request, UploadFile

from src.api import deps
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_division import crud_division
from src.crud.users.crud_universal_user import crud_universal_users
from src.exceptions import InaccessibleEntity, UnfoundEntity, UnprocessableEntity
from src.getters.division import get_division
from src.schemas.divisions import DivisionCreate, DivisionUpdate
from src.templates_raise import get_raise

PATH_MODEL = "division"
PATH_TYPE = "photo"
ROLE_ADMIN_FOREMAN = [ADMIN, FOREMAN]
router = APIRouter()


# Вывод всех участков
@router.get(
    "/divisions/",
    response_model=ListOfEntityResponse,
    name="Список Участков",
    description="Получение списка всех участков",
    tags=["Админ панель / Участки"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_division.get_multi(db=session, page=None))

    data, paginator = crud_division.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_division(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


# Создание участка
@router.post(
    "/divisions/",
    response_model=SingleEntityResponse,
    name="Создать участок",
    description="Создать участок",
    tags=["Админ панель / Участки"],
)
def create_divisions(
    request: Request,
    new_data: DivisionCreate,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    # проверку на роли
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLE_ADMIN_FOREMAN
    )
    # рассматриваем code, выводим ошибки
    get_raise(code=code)
    db_obj, code, index = crud_division.create_new(
        db=session, user=current_user, new_data=new_data
    )
    if code == -1:
        raise InaccessibleEntity(
            message="Вы не обладаете правами администратора или прораба",
            num=1,
            description="Вы не обладаете правами администратора или прораба!",
            path="$.body",
        )
    if code == -2:
        raise UnprocessableEntity(
            message="Участок с таким названием уже есть",
            num=2,
            description="Участок с таким названием уже есть",
            path="$.body",
        )
    return SingleEntityResponse(data=get_division(db_obj, request=request))


# UPDATE
@router.put(
    "/divisions/{division_id}/",
    response_model=SingleEntityResponse,
    name="Изменить название участка",
    description="Изменяет название участка",
    tags=["Админ панель / Участки"],
)
def update_division(
    request: Request,
    new_data: DivisionUpdate,
    division_id: int = Path(..., title="Id проекта"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    # проверку на роли
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLE_ADMIN_FOREMAN
    )
    # рассматриваем code, выводим ошибки
    get_raise(code=code)
    db_obj, code, index = crud_division.update(
        db=session, new_data=new_data, obj_id=division_id, user=current_user
    )
    if code == -1:
        raise InaccessibleEntity(
            message="Вы не обладаете правами администратора или прораба",
            num=1,
            description="Вы не обладаете правами администратора или прораба!",
            path="$.body",
        )
    if code == -2:
        raise UnfoundEntity(
            message="Участка с таким id нет!",
            num=2,
            description="Введите корректный id!",
            path="$.body",
        )
    if code == -3:
        raise UnprocessableEntity(
            message="Участок с таким названием уже есть",
            num=3,
            description="Участок с таким названием уже есть",
            path="$.body",
        )
    return SingleEntityResponse(data=get_division(db_obj, request=request))


# UPDATE PHOTO
@router.put(
    "/divisions/{division_id}/photo/",
    response_model=SingleEntityResponse,
    name="Изменить фотографию",
    description="Изменить фотографию в участке",
    tags=["Админ панель / Участки"],
)
def create_upload_file(
    request: Request,
    file: Optional[UploadFile] = File(None),
    division_id: int = Path(..., title="Id участка"),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):
    # проверку на роли
    code = crud_universal_users.check_role_list(
        current_user=current_user, role_list=ROLE_ADMIN_FOREMAN
    )
    # рассматриваем code, выводим ошибки
    get_raise(code=code)

    obj = crud_division.get(db=session, id=division_id)

    save_path = crud_division.adding_file(
        db=session, file=file, path_model=PATH_MODEL, path_type=PATH_TYPE, db_obj=obj
    )
    if not save_path:
        raise UnfoundEntity(
            message="Не отправлен загружаемый файл",
            num=2,
            description="Попробуйте загрузить файл еще раз",
            path="$.body",
        )
    return SingleEntityResponse(
        data=get_division(
            crud_division.get(db=session, id=division_id), request=request
        )
    )


if __name__ == "__main__":
    logging.info("Running...")
