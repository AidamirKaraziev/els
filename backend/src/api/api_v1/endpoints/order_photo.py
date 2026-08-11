import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, Query, Request, UploadFile
from fastapi.params import Path

from src.api import deps
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, DISPATCHER, ENGINEER, FOREMAN, MECHANIC
from src.crud.crud_order_photo import crud_order_photo
from src.getters.order_photo import getting_order_photo
from src.schemas.order_photo import OrderPhotoGet
from src.templates_raise import get_raise

ROLES_ELIGIBLE = [ADMIN, FOREMAN, DISPATCHER]
ALL_EMPLOYER = [ADMIN, FOREMAN, MECHANIC, ENGINEER, DISPATCHER]
PATH_MODEL = "order_photo"
PATH_TYPE = "photo"
router = APIRouter()


@router.get(
    path="/order-photo/all",
    response_model=ListOfEntityResponse,
    name="get_order_photo",
    summary="Получение списка всех фотографий",
    description="Получение списка всех фотографий",
    tags=["Админ панель / Фотографии Задачи"],
)
def get_order_photo(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(default=1, title="Номер страницы"),
):
    logging.info(crud_order_photo.get_multi(db=session, page=None))

    data, paginator = crud_order_photo.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[getting_order_photo(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/order-photo/{order_id}",
    response_model=ListOfEntityResponse,
    name="get_photo_by_order_id",
    summary="Получение списка всех фотографий по номеру задачи",
    description="Получение списка всех фотографий по номеру задачи",
    tags=["Админ панель / Фотографии Задачи"],
)
def get_photo_by_order_id(
    request: Request,
    session=Depends(deps.get_db),
    order_id: int = Path(..., title="Id задачи"),
    page: int = Query(1, title="Номер страницы"),
):
    logging.info(crud_order_photo.get_photo_by_order_id(db=session, order_id=order_id))

    data, code, indexes = crud_order_photo.get_photo_by_order_id(
        db=session, order_id=order_id
    )
    get_raise(code=code)
    return ListOfEntityResponse(
        data=[getting_order_photo(obj=datum, request=request) for datum in data]
    )


@router.get(
    path="/order-photo/{order_photo_id}/",
    response_model=SingleEntityResponse[OrderPhotoGet],
    name="get_order_photo_by_id",
    summary="Получить фотографию по id",
    description="Получить фотографию по id",
    tags=["Админ панель / Фотографии Задачи"],
)
def get_order_photo_by_id(
    request: Request,
    session=Depends(deps.get_db),
    order_photo_id: int = Path(default=..., title="ID order_photo"),
    # current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    obj, code, indexes = crud_order_photo.get_photo_by_id(
        db=session, order_photo_id=order_photo_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=getting_order_photo(obj, request))


@router.post(
    path="/order-photo/{order_id}/",
    response_model=SingleEntityResponse,
    name="add_photo",
    summary="Добавить фотографию к задаче",
    description="Добавить фотографию к задаче",
    tags=["Админ панель / Фотографии Задачи"],
)
def add_photo(
    request: Request,
    file: Optional[UploadFile] = File(None),
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    order_id: int = Path(default=..., title="Id задачи"),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_order_photo.check_executor(
        db=session, order_id=order_id, executor_id=current_user.id
    )
    get_raise(code=code)

    obj, code, indexes = crud_order_photo.add_photo(
        db=session,
        file=file,
        path_model=PATH_MODEL,
        path_type=PATH_TYPE,
        order_id=order_id,
    )
    get_raise(code=code)

    data, code, indexes = crud_order_photo.get_photo_by_order_id(
        db=session, order_id=order_id
    )
    get_raise(code=code)
    return ListOfEntityResponse(
        data=[getting_order_photo(obj=datum, request=request) for datum in data]
    )


@router.delete(
    path="/order-photo/{order_photo_id}/",
    name="get_order_photo_by_id",
    summary="Удалить фотографию по id",
    description="""
Удаляет запись о фотографии задачи из базы данных по её ID.
Важно отметить, что физический файл фотографии, сохранённый на сервере, **не удаляется** —
удаляется только информация о фотографии из базы данных.

Используйте этот метод, если необходимо убрать запись о фотографии, но не удалять сам файл с сервера.

#### Пример использования:
- Удалить фотографию по `order_photo_id`.

#### Ответ:
- Успешное удаление возвращает текст подтверждения и статус 200.
- В случае ошибки возвращается соответствующий код ошибки и сообщение.
    """,
    tags=["Админ панель / Фотографии Задачи"],
)
def delete_order_photo_by_id(
    session=Depends(deps.get_db),
    order_photo_id: int = Path(default=..., title="ID order_photo"),
    # current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    text, code, indexes = crud_order_photo.delete_photo_by_photo_id(
        db=session, id=order_photo_id
    )
    get_raise(code=code)
    return text


if __name__ == "__main__":
    logging.info("Running...")
