from typing import Optional

from fastapi import APIRouter, Depends, File, Query, Request, UploadFile
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, SingleEntityResponse
from src.crud.crud_act_fact_step_photo import crud_act_fact_step_photo
from src.getters.act_fact_step_photo import getting_act_fact_step_photo
from src.schemas.act_fact_step_photo import ActFactStepPhotoGet
from src.templates_raise import get_raise

router = APIRouter()

TAGS = ["Админ панель / Фотографии шагов ТО"]


@router.post(
    path="/act-fact/{act_fact_id}/step/{step_id}/photo/",
    response_model=SingleEntityResponse[ActFactStepPhotoGet],
    name="add_act_fact_step_photo",
    summary="Приложить фотографию к шагу ТО",
    description=(
        "📷 Снимок к одному пункту регламента.\n\n"
        "`step_id` — номер шага из поля `checklist` в ответе по акту. Если в "
        "чек-листе такого номера нет, ручка отвечает 404: снимок без пункта "
        "негде показать и нечем найти.\n\n"
        "Раньше мобильное приложение клало байты снимка прямо в текстовое поле "
        "акта — строка разрасталась до сотен килобайт, и список ТО не "
        "открывался с телефона. Теперь файл лежит на диске, а в базе — путь."
    ),
    tags=TAGS,
)
def add_act_fact_step_photo(
    request: Request,
    file: Optional[UploadFile] = File(None),
    act_fact_id: int = Path(..., title="ID фактического акта"),
    step_id: int = Path(..., ge=1, title="Номер шага чек-листа"),
    current_user=Depends(deps.require(Permission.FILE_UPLOAD)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, _ = crud_act_fact_step_photo.add_photo(
        db=session,
        file=file,
        act_fact_id=act_fact_id,
        step_id=step_id,
        scope=scope,
    )
    get_raise(code=code)

    return SingleEntityResponse(
        data=getting_act_fact_step_photo(obj=obj, request=request)
    )


@router.get(
    path="/act-fact/{act_fact_id}/photos/",
    response_model=ListOfEntityResponse[ActFactStepPhotoGet],
    name="get_act_fact_step_photos",
    summary="Фотографии шагов ТО",
    description=(
        "Все снимки акта одним списком, по порядку загрузки. `step_id` в "
        "запросе оставляет снимки одного пункта — экран шага не должен "
        "выкачивать фотографии всего регламента."
    ),
    tags=TAGS,
)
def get_act_fact_step_photos(
    request: Request,
    act_fact_id: int = Path(..., title="ID фактического акта"),
    step_id: int = Query(None, ge=1, title="Только снимки этого шага"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_read_scope),
):
    query, code, _ = crud_act_fact_step_photo.get_photos_by_act_fact_id(
        db=session, act_fact_id=act_fact_id, scope=scope, step_id=step_id
    )
    get_raise(code=code)

    return ListOfEntityResponse(
        data=[
            getting_act_fact_step_photo(obj=datum, request=request)
            for datum in query.all()
        ]
    )


@router.delete(
    path="/act-fact-photo/{photo_id}/",
    name="delete_act_fact_step_photo",
    summary="Удалить фотографию шага ТО",
    description=(
        "Удаляет запись о фотографии из базы. Файл на сервере **остаётся** — "
        "так же, как у фотографий заявок.\n\n"
        "Право то же, что и на загрузку: механик снимает шаг в лифтовом "
        "помещении и должен сам убрать смазанный кадр, не дожидаясь админа. "
        "Дальше своих актов область видимости его всё равно не пустит."
    ),
    tags=TAGS,
)
def delete_act_fact_step_photo(
    photo_id: int = Path(..., title="ID фотографии шага"),
    current_user=Depends(deps.require(Permission.FILE_UPLOAD)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    text, code, _ = crud_act_fact_step_photo.delete_photo_by_id(
        db=session, photo_id=photo_id, scope=scope
    )
    get_raise(code=code)
    return text
