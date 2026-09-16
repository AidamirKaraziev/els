from typing import Dict, List

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.params import Path

from src.api import deps
from src.core.access import division_ids_of
from src.core.permissions import Permission
from src.core.response import SingleEntityResponse
from src.crud.crud_work_feed import (
    DEFAULT_LIMIT,
    MAX_LIMIT,
    FeedFilters,
    crud_work_feed,
)
from src.getters.work_feed import (
    get_new_work_category,
    get_new_work_object,
    get_new_work_open_item,
    get_work_employee,
    get_work_feed_item,
    get_work_section,
)
from src.schemas.reports import WorkKind
from src.schemas.work_feed import (
    AssignBody,
    AttentionReason,
    NewWorkContext,
    NewWorkOpenItem,
    WorkCounts,
    WorkFeed,
    WorkFeedItem,
    WorkSort,
    WorkStatus,
)
from src.templates_raise import get_raise
from src.utils.time_stamp import datetime_from_timestamp

router = APIRouter()

TAGS = ["Админ панель / Работы"]


@router.get(
    path="/work/feed",
    response_model=SingleEntityResponse[WorkFeed],
    name="work_feed",
    summary="Единая лента работ",
    description=(
        "🗂 Заявки и акты ТО во всех статусах одним списком — под экран "
        "«Работы» прораба и админа.\n\n"
        "Заменяет три ручки разом: `/order/all`, `/work/in-progress` и "
        "`/work/submitted`. Те остаются живыми и помечены устаревшими.\n\n"
        "`status` — одно слово: `fresh` (создана, никто не взял), `accepted` "
        "(назначена или взята, не начата), `running` (идёт; пауза — тот же "
        "статус с заполненным `paused_at`), `submitted` (сдана), `problem` "
        "(механик выехал и сделать не смог). У заявки это её статус, у акта "
        "состояние собирается из дат тем же правилом, что в телефоне "
        "механика.\n\n"
        "`attention` — почему строка требует внимания: `unassigned` — новая "
        "без исполнителя, `overdue` — стадия дольше порога (новая ждёт "
        "дольше 2 ч, принятая лежит дольше 4 ч, идёт дольше 8 ч), "
        "`paused_long` — на паузе дольше часа. Закрытые и отмеченные "
        "«проверил» внимания не требуют. Считается на момент запроса.\n\n"
        "Порядок: `sort=attention` (по умолчанию) — сверху блок «требуют "
        "внимания», дольше стоит — выше, за ним остальные по последней "
        "перемене; `attention_count` говорит, сколько первых строк — блок. "
        "`sort=updated` — просто по последней перемене.\n\n"
        "Страницы — курсором: `next_cursor` из ответа передаётся как есть в "
        "`cursor`; пустой — страница последняя. Курсор — не номер страницы: "
        "лента живая, и между запросами строки меняют порядок.\n\n"
        "`updated_since` — что изменилось после этого времени, включая "
        "архивные (с `is_actual=false`): так экран обновляет строки на месте, "
        "не перечитывая ленту.\n\n"
        "`counts` — числа на чипсы, каждое по отбору **без** своего чипса. "
        "`sections` — участки строк ленты, `employees` — кого можно назначить, "
        "`my_sections` — участки того, кто спрашивает, под чипс «Мои участки».\n\n"
        "Участок работы — от объекта; если у объекта его нет — от исполнителя.\n\n"
        "Видимость — область чтения: прораб видит все участки."
    ),
    tags=TAGS,
)
def work_feed(
    session=Depends(deps.get_db),
    status: WorkStatus = Query(None, title="Статус"),
    kind: WorkKind = Query(None, title="Вид работы"),
    search: str = Query("", title="Поиск по названию и адресу объекта"),
    only_archived: bool = Query(
        False,
        title="Только архив",
        description="Отдельный вид «корзина». С `updated_since` не нужен.",
    ),
    section_id: int = Query(None, title="Только этот участок"),
    performer_id: int = Query(None, title="Только этот исполнитель"),
    mine: bool = Query(False, title="Только участки того, кто спрашивает"),
    attention: AttentionReason = Query(None, title="Только эта причина внимания"),
    sort: WorkSort = Query(WorkSort.ATTENTION, title="Порядок"),
    cursor: str = Query(None, title="Курсор из прошлого ответа"),
    limit: int = Query(DEFAULT_LIMIT, ge=1, le=MAX_LIMIT, title="Строк на странице"),
    updated_since: int = Query(
        None,
        ge=0,
        title="Изменённые после этого времени",
        description="Секунды эпохи, как и остальные даты в ответах.",
    ),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    my_sections = sorted(division_ids_of(current_user))
    filters = FeedFilters(
        status=status.value if status else None,
        kind=kind.value if kind else None,
        search=search,
        section_id=section_id,
        performer_id=performer_id,
        mine=mine,
        my_division_ids=my_sections,
        attention=attention.value if attention else None,
        updated_since=datetime_from_timestamp(updated_since),
    )
    try:
        feed = crud_work_feed.get_feed(
            db=session,
            scope=scope,
            filters=filters,
            only_archived=only_archived,
            sort=sort,
            cursor=cursor,
            limit=limit,
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail="Курсор не читается") from error

    return SingleEntityResponse(
        data=WorkFeed(
            items=[get_work_feed_item(row) for row in feed.rows],
            counts=WorkCounts(
                by_status=feed.by_status,
                by_kind=feed.by_kind,
                by_attention=feed.by_attention,
            ),
            attention_count=feed.attention_count,
            next_cursor=feed.next_cursor,
            sections=[get_work_section(row) for row in feed.sections],
            employees=[
                get_work_employee(row)
                for row in crud_work_feed.get_employees(db=session, scope=scope)
            ],
            my_sections=my_sections,
        )
    )


@router.get(
    path="/work/new/context",
    response_model=SingleEntityResponse[NewWorkContext],
    name="new_work_context",
    summary="Справочники для формы «Новая работа»",
    description=(
        "📝 Всё, что нужно форме, одним ответом: объекты области с механиком, "
        "прорабом и контактом; категории заявок с кодом и флагом поломки; "
        "кого можно назначить — сотрудники ленты плюс заказчики; открытые "
        "работы по объектам, чтобы не завести дубль.\n\n"
        "Создание — как раньше, `POST /order/`; `executor_id` там теперь "
        "необязателен: без него заявка ложится в ленту «Новой»."
    ),
    tags=TAGS,
)
def new_work_context(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.ORDER_CREATE)),
    scope=Depends(deps.get_read_scope),
):
    open_works: Dict[int, List[NewWorkOpenItem]] = {}
    for row in crud_work_feed.get_open_works(db=session, scope=scope):
        open_works.setdefault(row.object_id, []).append(get_new_work_open_item(row))
    return SingleEntityResponse(
        data=NewWorkContext(
            objects=[
                get_new_work_object(row)
                for row in crud_work_feed.get_new_work_objects(db=session, scope=scope)
            ],
            categories=[
                get_new_work_category(category)
                for category in crud_work_feed.get_categories(db=session)
            ],
            employees=[
                get_work_employee(row)
                for row in crud_work_feed.get_employees(
                    db=session, scope=scope, include_clients=True
                )
            ],
            open_works=open_works,
            my_sections=sorted(division_ids_of(current_user)),
            author=current_user.name,
        )
    )


def _item_response(session, scope, kind: WorkKind, work_id: int):
    row = crud_work_feed.get_item(
        db=session, scope=scope, kind=kind.value, work_id=work_id
    )
    return SingleEntityResponse(data=get_work_feed_item(row))


@router.post(
    path="/work/{kind}/{work_id}/assign/",
    response_model=SingleEntityResponse[WorkFeedItem],
    name="assign_work",
    summary="Назначить исполнителя",
    description=(
        "Назначает исполнителя на заявку или механика на акт ТО. Новая заявка "
        "становится принятой (`accepted`, `accepted_at` — сейчас); у остальных "
        "статус не меняется. Отметка «проверил» сбрасывается.\n\n"
        "`kind` и `work_id` — из строки ленты. Область — запись: прораб "
        "назначает на своих участках. В ответе — обновлённая строка ленты."
    ),
    tags=TAGS,
)
def assign_work(
    body: AssignBody,
    kind: WorkKind = Path(..., title="Вид работы из строки ленты"),
    work_id: int = Path(..., title="ID акта или заявки"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.ORDER_UPDATE)),
    scope=Depends(deps.get_write_scope),
    read_scope=Depends(deps.get_read_scope),
):
    _, code, _ = crud_work_feed.assign(
        db=session,
        scope=scope,
        kind=kind.value,
        work_id=work_id,
        performer_id=body.performer_id,
    )
    get_raise(code=code)
    return _item_response(session, read_scope, kind, work_id)


@router.post(
    path="/work/{kind}/{work_id}/review/",
    response_model=SingleEntityResponse[WorkFeedItem],
    name="review_work",
    summary="Отметить работу проверенной",
    description=(
        "Ставит отметку «проверил» на работе в любом статусе: строка уходит из "
        "блока «требуют внимания» до следующей перемены статуса — смена "
        "статуса отметку сбрасывает. Повторная отметка ничего не меняет.\n\n"
        "Та же отметка, что у `POST /work/{kind}/{work_id}/reviewed/` в ленте "
        "сданных, и тот же счётчик `unreviewed-count` её видит. В ответе — "
        "обновлённая строка ленты."
    ),
    tags=TAGS,
)
def review_work(
    kind: WorkKind = Path(..., title="Вид работы из строки ленты"),
    work_id: int = Path(..., title="ID акта или заявки"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.WORK_REVIEW)),
    scope=Depends(deps.get_write_scope),
    read_scope=Depends(deps.get_read_scope),
):
    _, code, _ = crud_work_feed.review(
        db=session,
        scope=scope,
        kind=kind.value,
        work_id=work_id,
        user_id=current_user.id,
    )
    get_raise(code=code)
    return _item_response(session, read_scope, kind, work_id)
