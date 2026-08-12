import logging

from fastapi import APIRouter, Depends, Query, Request
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_act_fact import crud_acts_fact
from src.getters.act_fact import get_acts_facts
from src.schemas.act_fact import ActFactCreate, ActFactGet, ActFactUpdate
from src.templates_raise import get_raise

ROLES_ELIGIBLE = [ADMIN, FOREMAN]
PATH_MODEL = "act_fact"
PATH_TYPE = "file"

router = APIRouter()


@router.get(
    path="/all-acts-fact/",
    response_model=ListOfEntityResponse,
    name="Список Фактических Актов",
    description="Получение списка всех Фактических Актов",
    tags=["Админ панель / Фактические Акты"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    page: int = Query(1, title="Номер страницы"),
    current_user=Depends(deps.require(Permission.ACT_READ)),
):
    logging.info(crud_acts_fact.get_multi(db=session, page=None))

    data, paginator = crud_acts_fact.get_multi(db=session, page=page)

    return ListOfEntityResponse(
        data=[get_acts_facts(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/act-fact/{act_fact_id}/",
    response_model=SingleEntityResponse[ActFactGet],
    name="Получить данные фактического акта по id ",
    description="Получение данных фактического акта по id",
    tags=["Админ панель / Фактические Акты"],
)
def get_data(
    request: Request,
    session=Depends(deps.get_db),
    act_fact_id: int = Path(..., title="ID object"),
    current_universal_user=Depends(deps.require(Permission.ACT_READ)),
):
    obj, code, indexes = crud_acts_fact.get_act_fact_by_id(db=session, id=act_fact_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_facts(obj, request))


@router.post(
    path="/act-fact/",
    response_model=SingleEntityResponse,
    summary="Создает фактический акт",
    description="""
Добавить один акт факт в БД.
Который в последствии будет выполнять механик, заполняя данными о ходе выполнения работ.
""",
    tags=["Админ панель / Фактические Акты"],
)
def create_act_fact(
    request: Request,
    new_data: ActFactCreate,
    current_user=Depends(deps.require(Permission.ACT_CREATE)),
    session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора и Прораба

    obj, code, index = crud_acts_fact.create_act_fact(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_facts(obj, request))


@router.put(
    path="/act-fact/{act_fact_id}/",
    response_model=SingleEntityResponse,
    summary="Изменить данные фактического акта",
    description="""
Обновляет данные фактического акта по его идентификатору.

### Требования:
- Пользователь должен быть аутентифицирован.
- Доступ имеют только пользователи с ролями **Администратор**, **Прораб** или **Механик**.

### Параметры:
- **act_fact_id**: Идентификатор фактического акта.
- **update_data**: Объект с данными для обновления фактического акта.

### Схемы:
**ActFactUpdate**:
- `step_list_fact` (Optional[str]): Список выполненных шагов.
- `started_at` (Optional[int]): Время начала в формате timestamp.
- `finished_at` (Optional[int]): Время окончания в формате timestamp.
- `foreman_id` (Optional[int]): Идентификатор ответственного прораба.
- `main_mechanic_id` (Optional[int]): Идентификатор ответственного механика.
- `status_id` (Optional[int]): Идентификатор статуса.

**ActFactGet**:
- `id` (int): Идентификатор фактического акта.
- `object_id` (Optional[int]): Идентификатор объекта.
- `act_base_id` (Optional[int]): Идентификатор базового акта.
- `step_list_fact` (Optional[str]): Список выполненных шагов.
- `created_at` (Optional[datetime]): Время создания акта.
- `started_at` (Optional[datetime]): Время начала.
- `finished_at` (Optional[datetime]): Время окончания.
- `foreman_id` (Optional[int]): Идентификатор ответственного прораба.
- `main_mechanic_id` (Optional[int]): Идентификатор ответственного механика.
- `file` (Optional[str]): Ссылка на файл.
- `status_id` (Optional[StatusGet]): Идентификатор статуса.

### Возвращает:
- **SingleEntityResponse**: Объект с обновленными данными фактического акта.
            """,
    tags=["Админ панель / Фактические Акты"],
)
def update_act_fact(
    request: Request,
    update_data: ActFactUpdate,
    current_user=Depends(deps.require(Permission.ACT_UPDATE)),
    act_fact_id: int = Path(..., title="Id фактического акта"),
    session=Depends(deps.get_db),
):
    # проверка на роли

    obj, code, indexes = crud_acts_fact.update_act_fact(
        db=session, update_data=update_data, act_fact_id=act_fact_id
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_acts_facts(obj, request=request))


@router.get(
    path="/act-fact/by-object/{object_id}/",
    summary="Получение фактического акта по id объекта.",
    tags=["Админ панель / Фактические Акты"],
    response_model=ListOfEntityResponse,
)
def get_act_fact_by_object_id(
    request: Request,
    current_user=Depends(deps.require(Permission.ACT_READ)),
    object_id: int = Path(..., title="ID объекта"),
    session=Depends(deps.get_db),
):

    data, code, indexes = crud_acts_fact.get_act_fact_by_object_id(
        db=session, object_id=object_id
    )
    get_raise(code=code)

    return ListOfEntityResponse(
        data=[get_acts_facts(obj=datum, request=request) for datum in data]
    )


if __name__ == "__main__":
    logging.info("Running...")
