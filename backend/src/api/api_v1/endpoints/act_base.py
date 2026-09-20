import logging
from typing import Optional

from fastapi import APIRouter, Depends, Path, Query, Request

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_act_base import crud_acts_bases
from src.crud.crud_factory_model import crud_factory_models
from src.crud.crud_object import crud_objects
from src.exceptions import ConflictEntity, UnfoundEntity
from src.getters.act_base import get_act_base_by_model, get_acts_bases
from src.schemas.act_base import ActBaseCreate, ActBaseUpdate
from src.templates_raise import get_raise

ROLES_ELIGIBLE = [ADMIN, FOREMAN]

router = APIRouter()


@router.get(
    path="/acts-bases/",
    response_model=ListOfEntityResponse,
    name="Список шаблонов актов",
    description=(
        "Получение списка всех шаблонов актов. `factory_model_id` — только "
        "шаблоны одной модели; убранные у модели виды ТО (`deleted_at`) "
        "скрыты, пока не попросят `include_deleted`."
    ),
    tags=["Админ панель / Шаблоны Актов"],
)
def get_data(
    request: Request,
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    factory_model_id: Optional[int] = Query(None, title="ID модели лифта"),
    include_deleted: bool = Query(False, title="Показать и убранные виды ТО"),
):
    if factory_model_id is not None:
        data = crud_acts_bases.list_by_model(
            db=session,
            factory_model_id=factory_model_id,
            include_deleted=include_deleted,
        )
        return ListOfEntityResponse(
            data=[get_acts_bases(datum, request=request) for datum in data]
        )

    data, paginator = crud_acts_bases.get_multi(db=session, page=page)
    if not include_deleted:
        data = [datum for datum in data if datum.deleted_at is None]

    return ListOfEntityResponse(
        data=[get_acts_bases(datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/acts-bases/by-model/{factory_model_id}/",
    response_model=ListOfEntityResponse,
    name="Виды ТО модели с шаблонами",
    description=(
        "Все виды ТО, заведённые у модели, по порядку видов — с шагами "
        "чек-листа, флагом `has_template` (шаги есть) и `deleted_at` у "
        "убранных видов: экран показывает их зачёркнутыми с кнопкой «Вернуть»."
    ),
    tags=["Админ панель / Шаблоны Актов"],
)
def get_by_model(
    factory_model_id: int = Path(..., title="ID модели лифта"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
):
    if crud_factory_models.get(db=session, id=factory_model_id) is None:
        raise UnfoundEntity(
            message="Модели лифта с таким id нет!",
            num=115,
            description="Введите корректный id модели!",
            path="$.path.factory_model_id",
        )
    data = crud_acts_bases.list_by_model(
        db=session, factory_model_id=factory_model_id, include_deleted=True
    )
    return ListOfEntityResponse(data=[get_act_base_by_model(datum) for datum in data])


@router.get(
    path="/act-base/{act_base_id}/",
    response_model=SingleEntityResponse,
    name="Шаблоны Актов",
    description="Получение данных Шаблонов Актов",
    tags=["Админ панель / Шаблоны Актов"],
)
def get_data(
    request: Request,
    act_base_id: int = Path(..., title="ID Шаблоны Актов"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    session=Depends(deps.get_db),
):
    obj, code, indexes = crud_acts_bases.getting_act_base(
        db=session, act_base_id=act_base_id
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_bases(obj, request=request))


@router.post(
    path="/act-base/",
    response_model=SingleEntityResponse,
    name="Добавить Шаблон Актов",
    description=(
        "Добавить Шаблон Актов в базу данных. Шаги передавайте списком "
        "`steps`; `step_list` строкой — устаревший путь."
    ),
    tags=["Админ панель / Шаблоны Актов"],
)
def create_act_base(
    request: Request,
    new_data: ActBaseCreate,
    current_user=Depends(deps.require(Permission.ACT_CREATE)),
    session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора

    obj, code, index = crud_acts_bases.create_act_base(db=session, new_data=new_data)
    if code == -1212:
        raise ConflictEntity(
            message="Этот вид ТО у модели уже был и удалён",
            num=1212,
            description="Верните его через restore, а не заводите заново!",
            path="$.body.type_act_id",
        )
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_bases(obj, request=request))


@router.put(
    path="/act-base/{act_base_id}/",
    response_model=SingleEntityResponse,
    name="Изменить Шаблоны Актов",
    description=(
        "Изменяет данные Шаблонов Актов. Не переданные поля не меняются; "
        "шаги — списком `steps`, `step_list` строкой — устаревший путь."
    ),
    tags=["Админ панель / Шаблоны Актов"],
)
def update_act_base(
    request: Request,
    new_data: ActBaseUpdate,
    current_user=Depends(deps.require(Permission.ACT_UPDATE)),
    act_base_id: int = Path(..., title="Id шаблона актов"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    obj, code, indexes = crud_acts_bases.update_act_base(
        db=session, new_data=new_data, act_base_id=act_base_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_acts_bases(obj, request=request))


def _act_base_or_404(session, act_base_id: int):
    db_obj = crud_acts_bases.get(db=session, id=act_base_id)
    if db_obj is None:
        raise UnfoundEntity(
            message="Шаблона с таким id нет!",
            num=121,
            description="Введите корректный id шаблона!",
            path="$.path.act_base_id",
        )
    return db_obj


@router.delete(
    path="/act-base/{act_base_id}/",
    response_model=SingleEntityResponse,
    name="Убрать вид ТО у модели",
    description=(
        "Мягкое удаление: строка остаётся, ставится `deleted_at`, мастер "
        "графика вид больше не предлагает. Если по шаблону в графике стоят "
        "ещё не начатые ТО — 409 с их числом; повтор с `force=true` удаляет "
        "всё равно (акты со снимком чек-листа уже созданы и не пострадают)."
    ),
    tags=["Админ панель / Шаблоны Актов"],
)
def delete_act_base(
    request: Request,
    act_base_id: int = Path(..., title="Id шаблона актов"),
    force: bool = Query(False, title="Удалить, даже если ТО стоят в графике"),
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):
    db_obj = _act_base_or_404(session, act_base_id)
    if db_obj.deleted_at is None and not force:
        pending = crud_acts_bases.pending_acts_count(db=session, act_base_id=db_obj.id)
        if pending:
            raise ConflictEntity(
                message=f"По этому шаблону в графике стоят {pending} ТО",
                num=1213,
                description="Повторите с force=true, чтобы убрать вид ТО всё равно.",
                path="$.path.act_base_id",
            )
    db_obj = crud_acts_bases.soft_delete(db=session, db_obj=db_obj)
    return SingleEntityResponse(data=get_acts_bases(db_obj, request=request))


@router.post(
    path="/act-base/{act_base_id}/restore/",
    response_model=SingleEntityResponse,
    name="Вернуть вид ТО модели",
    description="Снимает `deleted_at`; шаблон снова виден мастеру графика.",
    tags=["Админ панель / Шаблоны Актов"],
)
def restore_act_base(
    request: Request,
    act_base_id: int = Path(..., title="Id шаблона актов"),
    current_user=Depends(deps.require(Permission.DIRECTORY_WRITE)),
    session=Depends(deps.get_db),
):
    db_obj = crud_acts_bases.restore(
        db=session, db_obj=_act_base_or_404(session, act_base_id)
    )
    return SingleEntityResponse(data=get_acts_bases(db_obj, request=request))


@router.get(
    path="/act-base/by-object/{object_id}/",
    summary="Получение шаблона по id объекта.",
    tags=["Админ панель / Шаблоны Актов"],
    response_model=ListOfEntityResponse,
)
def get_act_base_by_object_id(
    request: Request,
    current_user=Depends(deps.require(Permission.ACT_READ)),
    object_id: int = Path(..., title="ID объекта"),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_read_scope),
):
    # Сами шаблоны — справочник по модели техники, резать их нечем и незачем.
    # А вот объект в запросе проверить надо: иначе по чужому лифту можно
    # узнать, какая на нём стоит техника.
    obj, code, indexes = crud_objects.get_object_by_id(
        db=session, object_id=object_id, scope=scope
    )
    get_raise(code=code)

    data, code, indexes = crud_acts_bases.get_act_base_by_object_id(
        db=session, object_id=object_id
    )
    get_raise(code=code)
    return ListOfEntityResponse(
        data=[get_acts_bases(datum, request=request) for datum in data],
    )


if __name__ == "__main__":
    logging.info("Running...")
