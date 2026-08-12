from fastapi import APIRouter, Depends, File, Query, Request, UploadFile
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.crud.crud_defective_act_photo import crud_defective_act_photo
from src.getters.defective_act_photo import getting_defective_act_photo
from src.templates_raise import get_raise

ROLES_UPLOAD = [ADMIN, FOREMAN, MECHANIC]
router = APIRouter()


@router.get(
    path="/defective-act-photo/{defective_act_id}",
    response_model=ListOfEntityResponse,
    name="get_defective_act_photos",
    summary="Получить список фото дефектного акта",
    tags=["Админ панель / Дефектные акты"],
)
def get_defective_act_photos(
    request: Request,
    session=Depends(deps.get_db),
    defective_act_id: int = Path(..., title="ID defective act"),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    data_q, code, _ = crud_defective_act_photo.get_photos_by_defective_act_id(
        db=session, defective_act_id=defective_act_id, scope=scope
    )
    get_raise(code=code)
    data = data_q.all()
    return ListOfEntityResponse(
        data=[getting_defective_act_photo(obj=datum, request=request) for datum in data]
    )


@router.post(
    path="/defective-act-photo/{defective_act_id}/",
    response_model=SingleEntityResponse,
    name="add_defective_act_photo",
    summary="Добавить фото к дефектному акту",
    tags=["Админ панель / Дефектные акты"],
)
def add_defective_act_photo(
    request: Request,
    file: UploadFile = File(...),
    current_user=Depends(deps.require(Permission.FILE_UPLOAD)),
    defective_act_id: int = Path(..., title="ID defective act"),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    photo_obj, code, _ = crud_defective_act_photo.add_photo(
        db=session,
        file=file,
        defective_act_id=defective_act_id,
        created_by_user_id=current_user.id,
        scope=scope,
    )
    get_raise(code=code)
    return SingleEntityResponse(
        data=getting_defective_act_photo(obj=photo_obj, request=request)
    )


@router.delete(
    path="/defective-act-photo/{defective_act_photo_id}/",
    name="delete_defective_act_photo",
    summary="Удалить фото дефектного акта (только из БД)",
    tags=["Админ панель / Дефектные акты"],
)
def delete_defective_act_photo(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.ACT_DELETE)),
    defective_act_photo_id: int = Path(..., title="ID defective act photo"),
    scope=Depends(deps.get_write_scope),
):
    text, code, _ = crud_defective_act_photo.delete_photo_by_id(
        db=session, defective_act_photo_id=defective_act_photo_id, scope=scope
    )
    get_raise(code=code)
    return text
