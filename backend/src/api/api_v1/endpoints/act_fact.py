import logging

from fastapi import APIRouter, Depends, Query, Request
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.core.roles import ADMIN, FOREMAN
from src.crud.crud_act_fact import crud_acts_fact
from src.exceptions import UnprocessableEntity
from src.getters.act_fact import get_acts_facts, get_my_maintenance
from src.schemas.act_fact import ActFactCreate, ActFactGet, ActFactUpdate
from src.schemas.maintenance import MyMaintenanceItem
from src.templates_raise import get_raise
from src.utils.time_stamp import datetime_from_timestamp

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
    only_archived: bool = Query(
        False,
        title="Только архивные",
        description=(
            "Отдельный вид «корзина»: акты, убранные в архив. Без параметра "
            "их в списке нет."
        ),
    ),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    data, paginator = crud_acts_fact.get_multi(
        db=session, scope=scope, page=page, only_archived=only_archived
    )

    return ListOfEntityResponse(
        data=[get_acts_facts(obj=datum, request=request) for datum in data],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/act-fact/for-me",
    response_model=ListOfEntityResponse[MyMaintenanceItem],
    name="Мои плановые ТО",
    summary="Плановые ТО механика",
    description=(
        "🔧 Список плановых ТО, назначенных на текущего пользователя.\n\n"
        "Главный экран механика в телефоне. Механик привязан к ТО через "
        "механика объекта — отдельного назначения на конкретное ТО в системе "
        "нет.\n\n"
        "Чек-лист наружу не отдаётся: в списке приходит только «сделано N из "
        "M», а сами пункты — по адресу конкретного акта. Строка чек-листа "
        "весит сотни килобайт, и в списке из тридцати ТО экран бы не открылся."
        "\n\n"
        "`only_open` — незакрытые: те, у которых нет даты окончания. "
        "`changed_since` — для синхронизации офлайн-клиента; вместе с "
        "`only_open` его слать не нужно, иначе закрытое ТО просто исчезнет из "
        "ответа и телефон не узнает, что оно закрылось.\n\n"
        "Архивные ТО в обычной выдаче не показываются, но в выдачу по "
        "`changed_since` попадают — с `is_actual=false`. Так телефон и "
        "узнаёт, что запись убрали."
    ),
    tags=["Админ панель / Фактические Акты"],
)
def get_my_maintenance_list(
    session=Depends(deps.get_db),
    page: int = Query(
        None,
        ge=1,
        title="Номер страницы",
        description="Без параметра выдача полная, без разбивки на страницы.",
    ),
    year: int = Query(None, ge=1990, le=2100, title="Год графика, вместе с month"),
    month: int = Query(None, ge=1, le=12, title="Месяц (1–12), вместе с year"),
    only_open: bool = Query(False, title="Только незакрытые ТО"),
    only_archived: bool = Query(
        False,
        title="Только архивные",
        description="Отдельный вид «корзина». С `changed_since` не нужен.",
    ),
    changed_since: int = Query(
        None,
        ge=0,
        title="Изменённые после этого времени",
        description="Время в секундах эпохи, как и остальные даты в ответах.",
    ),
    current_universal_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    # Год и месяц описывают одну ячейку графика, поодиночке они бессмысленны.
    if (year is None) != (month is None):
        raise UnprocessableEntity(
            message="Год и месяц задаются только вместе",
            num=1292,
            description="Параметры year и month описывают один месяц графика.",
            path="$.query",
        )

    rows, paginator = crud_acts_fact.get_my_maintenance(
        db=session,
        mechanic_id=current_universal_user.id,
        scope=scope,
        page=page,
        year=year,
        month=month,
        only_open=only_open,
        only_archived=only_archived,
        changed_since=datetime_from_timestamp(changed_since),
    )

    return ListOfEntityResponse(
        data=[
            get_my_maintenance(act, cell_year, cell_month)
            for act, cell_year, cell_month in rows
        ],
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
    scope=Depends(deps.get_read_scope),
):
    obj, code, indexes = crud_acts_fact.get_act_fact_by_id(
        db=session, id=act_fact_id, scope=scope
    )
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
    scope=Depends(deps.get_write_scope),
):
    obj, code, index = crud_acts_fact.create_act_fact(
        db=session, new_data=new_data, scope=scope
    )
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

### Чек-лист
Присылать `checklist` — разобранный список пунктов с номерами. Номер шага
живёт вместе с актом: на него ссылается фотография шага
(`POST /act-fact/{id}/step/{step_id}/photo/`), поэтому переставлять и удалять
пункты после начала работ нельзя, а пункт без `id` считается новым.

Поле `step_list_fact` **устарело**, но принимается: экран графика у прораба
пишет чек-лист именно строкой. В базе оно всё равно сохраняется приведённым к
канонической форме, а в ответе отдаётся обратно в форме старых экранов.

### Состояние работы
`status_id` вместе с датами описывает, что с работой прямо сейчас: `3` — идёт,
`2` при заполненном `started_at` — приостановлена, `5` — проблема, `4` —
выполнена. `paused_at` — момент, когда работа встала; при возобновлении его
надо прислать пустым, иначе он останется от прошлой паузы. `commentary` —
комментарий ко всей работе, не путать с комментарием к пункту внутри
`checklist`.

### Схемы:
**ActFactUpdate**:
- `checklist` (Optional[ChecklistSet]): Чек-лист целиком, с номерами шагов.
- `step_list_fact` (Optional[str]): **Устарело.** Список шагов строкой.
- `started_at` (Optional[int]): Время начала в формате timestamp.
- `finished_at` (Optional[int]): Время окончания в формате timestamp.
- `paused_at` (Optional[int]): Время паузы в формате timestamp, пустое — работа идёт.
- `commentary` (Optional[str]): Комментарий ко всей работе.
- `foreman_id` (Optional[int]): Идентификатор ответственного прораба.
- `main_mechanic_id` (Optional[int]): Идентификатор ответственного механика.
- `status_id` (Optional[int]): Идентификатор статуса.

**ActFactGet**:
- `id` (int): Идентификатор фактического акта.
- `object_id` (Optional[int]): Идентификатор объекта.
- `act_base_id` (Optional[int]): Идентификатор базового акта.
- `checklist` (Optional[ChecklistGet]): Разобранный чек-лист.
- `step_list_fact` (Optional[str]): **Устарело.** Он же строкой, в форме старых экранов.
- `created_at` (Optional[datetime]): Время создания акта.
- `started_at` (Optional[datetime]): Время начала.
- `finished_at` (Optional[datetime]): Время окончания.
- `paused_at` (Optional[datetime]): Время паузы.
- `commentary` (Optional[str]): Комментарий ко всей работе.
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
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_acts_fact.update_act_fact(
        db=session, update_data=update_data, act_fact_id=act_fact_id, scope=scope
    )
    get_raise(code=code)

    return SingleEntityResponse(data=get_acts_facts(obj, request=request))


@router.post(
    path="/act-fact/{act_fact_id}/archive/",
    response_model=SingleEntityResponse,
    name="archive_act_fact",
    summary="Удалить фактический акт (в архив)",
    description=(
        "🗑 Мягкое удаление акта. Запись остаётся в базе, но пропадает из "
        "списков механика и из ленты сданных работ у прораба.\n\n"
        "Настоящего `DELETE` у актов нет намеренно: телефон механика узнаёт "
        "об удалении только по `is_actual=false` в выдаче по `changed_since`."
        "\n\n"
        "Ячейка графика ТО продолжает ссылаться на акт: график — это план, и "
        "из того, что запись убрали, он не меняется.\n\n"
        "Право `act:archive` — админ и прораб; прораб ограничен своими "
        "участками."
    ),
    tags=["Админ панель / Фактические Акты"],
)
def archive_act_fact(
    request: Request,
    act_fact_id: int = Path(..., title="Id фактического акта"),
    current_user=Depends(deps.require(Permission.ACT_ARCHIVE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_acts_fact.archive_act_fact(
        db=session, act_fact_id=act_fact_id, scope=scope
    )
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_facts(obj, request=request))


@router.post(
    path="/act-fact/{act_fact_id}/restore/",
    response_model=SingleEntityResponse,
    name="restore_act_fact",
    summary="Вернуть фактический акт из архива",
    description="↩️ Возвращает удалённый акт в обычные списки.",
    tags=["Админ панель / Фактические Акты"],
)
def restore_act_fact(
    request: Request,
    act_fact_id: int = Path(..., title="Id фактического акта"),
    current_user=Depends(deps.require(Permission.ACT_ARCHIVE)),
    session=Depends(deps.get_db),
    scope=Depends(deps.get_write_scope),
):
    obj, code, indexes = crud_acts_fact.restore_act_fact(
        db=session, act_fact_id=act_fact_id, scope=scope
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
    scope=Depends(deps.get_read_scope),
):
    data, code, indexes = crud_acts_fact.get_act_fact_by_object_id(
        db=session, object_id=object_id, scope=scope
    )
    get_raise(code=code)

    return ListOfEntityResponse(
        data=[get_acts_facts(obj=datum, request=request) for datum in data]
    )


if __name__ == "__main__":
    logging.info("Running...")
