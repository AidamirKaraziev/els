from fastapi import APIRouter, Depends

from src.api import deps
from src.core.permissions import Permission
from src.core.response import SingleEntityResponse
from src.crud.crud_in_progress_works import LIMIT, crud_in_progress_works
from src.getters.in_progress_works import get_in_progress_work
from src.schemas.in_progress_works import InProgressFeed

router = APIRouter()

TAGS = ["Админ панель / Текущие работы"]


@router.get(
    path="/work/in-progress",
    response_model=SingleEntityResponse[InProgressFeed],
    name="in_progress_works",
    summary="Работы, которые идут прямо сейчас",
    description=(
        "🔧 Что механики ведут в эту минуту: начатое и незакрытое ТО и "
        "заявки в статусе «В работе».\n\n"
        "Соседка ленты сданных работ. Та отвечает на вопрос «что за меня "
        "сдали», эта — «что происходит сейчас»: прораб видит паузу и "
        "проблему с причиной, не дожидаясь, пока работу закроют.\n\n"
        "`state` — что с работой: `running` — идёт, `paused` — механик "
        "приостановил, `problem` — сообщил, что сделать не вышло. `since` — "
        "с какого момента длится состояние; **у проблемы пусто**, момент её "
        "объявления в системе не хранится. `reason` — причина словами "
        "механика, `progress` — отмеченные пункты чек-листа.\n\n"
        "У заявки состояние всегда `running`: паузы у неё не бывает, а "
        "«Проблема» её закрывает и уводит в ленту сданных.\n\n"
        f"Страниц нет, но список обрезан: строк не больше {LIMIT}. "
        "`total` и `problems` считаются по всей выборке, до обрезки — по "
        "ним раздел подписывает остаток и красит заголовок. Порядок — "
        "сначала то, что требует вмешательства: проблемы, паузы, идущие "
        "работы; внутри группы дольше стоящая работа выше.\n\n"
        "Видимость **уже**, чем у ленты сданных: прораб видит работы своих "
        "участков, а не всех. Раздел — про то, во что можно вмешаться прямо "
        "сейчас, и чужая бригада в нём только шумит."
    ),
    tags=TAGS,
)
def in_progress_works(
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.ACT_READ)),
    # Область **записи**, а не чтения, и это не описка. У прораба они разные:
    # смотрит он по всем участкам, отвечает за свои. Лента сданных — про
    # «посмотреть», поэтому там область чтения; здесь раздел про «вмешаться»,
    # и граница у него та же, что у права вмешаться. Решение заказчика от 21
    # августа: в текущих работах прораб видит своих механиков.
    scope=Depends(deps.get_write_scope),
):
    feed = crud_in_progress_works.get_feed(db=session, scope=scope)

    return SingleEntityResponse(
        data=InProgressFeed(
            items=[get_in_progress_work(row) for row in feed.rows],
            total=feed.total,
            problems=feed.problems,
        )
    )
