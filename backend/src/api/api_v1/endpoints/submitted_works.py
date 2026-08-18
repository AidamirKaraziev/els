from typing import List

from fastapi import APIRouter, Depends, Query
from fastapi.params import Path

from src.api import deps
from src.core.permissions import Permission
from src.core.response import ListOfEntityResponse, Meta, SingleEntityResponse
from src.crud.crud_submitted_works import crud_submitted_works
from src.getters.submitted_works import get_submitted_work
from src.schemas.reports import WorkKind
from src.schemas.submitted_works import SubmittedWork, UnreviewedCount
from src.templates_raise import get_raise
from src.utils.time_stamp import datetime_from_timestamp

router = APIRouter()

TAGS = ["Админ панель / Сданные работы"]


@router.get(
    path="/work/submitted",
    response_model=ListOfEntityResponse[SubmittedWork],
    name="submitted_works",
    summary="Лента сданных работ",
    description=(
        "🧾 Закрытые ТО и закрытые заявки одним списком, свежие сверху.\n\n"
        "Механик закрывает ТО сам, и работа засчитывается сразу — приёмки, "
        "блокирующей зачёт, в системе нет. Лента нужна прорабу, чтобы видеть, "
        "что за него сдали, и при желании проверить.\n\n"
        "Сданным считается ТО с датой закрытия акта и заявка в статусе "
        "«Выполнено».\n\n"
        "`only_unreviewed` — только те, где отметки «проверил» ещё нет: это "
        "ровно те записи, которые считает счётчик на главной. `kind` можно "
        "повторять, чтобы оставить несколько видов работ. `since` — работы, "
        "сданные позже этого времени."
    ),
    tags=TAGS,
)
def submitted_works(
    session=Depends(deps.get_db),
    page: int = Query(
        None,
        ge=1,
        title="Номер страницы",
        description="Без параметра выдача полная, без разбивки на страницы.",
    ),
    only_unreviewed: bool = Query(False, title="Только непросмотренные"),
    kind: List[WorkKind] = Query(None, title="Виды работ"),
    since: int = Query(
        None,
        ge=0,
        title="Сданные после этого времени",
        description="Время в секундах эпохи, как и остальные даты в ответах.",
    ),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    rows, paginator = crud_submitted_works.get_feed(
        db=session,
        scope=scope,
        page=page,
        only_unreviewed=only_unreviewed,
        kinds=[value.value for value in kind] if kind else None,
        since=datetime_from_timestamp(since),
    )

    return ListOfEntityResponse(
        data=[get_submitted_work(row) for row in rows],
        meta=Meta(paginator=paginator),
    )


@router.get(
    path="/work/submitted/unreviewed-count",
    response_model=SingleEntityResponse[UnreviewedCount],
    name="unreviewed_works_count",
    summary="Счётчик непросмотренных работ",
    description=(
        "Число для карточки на главной. Отдельной ручкой, а не длиной ленты: "
        "на главной нужен счётчик, а не список, и качать ради числа тридцать "
        "карточек незачем.\n\n"
        "Считается по той же области видимости, что и сама лента."
    ),
    tags=TAGS,
)
def unreviewed_works_count(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    scope=Depends(deps.get_read_scope),
):
    return SingleEntityResponse(
        data=UnreviewedCount(
            count=crud_submitted_works.count_unreviewed(db=session, scope=scope)
        )
    )


@router.post(
    path="/work/{kind}/{work_id}/reviewed/",
    response_model=SingleEntityResponse[UnreviewedCount],
    name="mark_work_reviewed",
    summary="Отметить работу проверенной",
    description=(
        "Гасит счётчик по одной работе. Саму работу отметка не меняет: она "
        "уже засчитана в момент закрытия.\n\n"
        "`kind` и `work_id` берутся из строки ленты. Повторная отметка ничего "
        "не меняет — ни времени, ни автора: первая отметка и есть ответ на "
        "вопрос «когда посмотрели».\n\n"
        "Право `work:review` есть у админа и прораба. Механику его не дали "
        "намеренно: править акт по своей работе он может, а закрывать "
        "прорабу счётчик за себя — нет.\n\n"
        "В ответе — счётчик непросмотренного после отметки, чтобы карточка на "
        "главной обновилась без второго запроса."
    ),
    tags=TAGS,
)
def mark_work_reviewed(
    kind: WorkKind = Path(..., title="Вид работы из строки ленты"),
    work_id: int = Path(..., title="ID акта или заявки"),
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.WORK_REVIEW)),
    scope=Depends(deps.get_write_scope),
    read_scope=Depends(deps.get_read_scope),
):
    obj, code, _ = crud_submitted_works.mark_reviewed(
        db=session,
        scope=scope,
        kind=kind.value,
        work_id=work_id,
        user_id=current_user.id,
    )
    get_raise(code=code)

    # Счётчик считаем областью чтения, а не записи: у прораба они разные —
    # смотрит он по всем участкам, а правит только свои, — и число в ответе
    # обязано совпасть с тем, что показывает лента.
    return SingleEntityResponse(
        data=UnreviewedCount(
            count=crud_submitted_works.count_unreviewed(db=session, scope=read_scope)
        )
    )
