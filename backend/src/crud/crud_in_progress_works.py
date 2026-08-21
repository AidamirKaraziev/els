"""Текущие работы: то, что механики ведут прямо сейчас, — прорабу.

Соседка ленты сданных работ и повторяет её форму, но берёт незакрытое.
Отдельный модуль, а не ещё один режим `crud_submitted_works`: там каждая
ветка отбирает **сданное** и порядок задан датой сдачи, здесь — наоборот, и
пара «ещё не сдано» с параметром `only_open` в одном запросе означала бы
условие в каждой строке выборки.

Что считается текущей работой
-----------------------------
ТО — акт с заполненным `started_at` и пустым `finished_at`: за работу взялись
и не закончили. Статус в отборе не участвует, он отвечает на другой вопрос —
что с этой работой происходит.

Заявка — статус «В работе». Паузы у неё не бывает: колонки под момент
остановки нет и экрана, где механик мог бы её поставить, тоже. Заявка либо
идёт, либо уже сдана — а сданная живёт в другой ленте, вместе с «Проблемой».

Состояние собирается из статуса ровно тем же порядком проверок, что и
`maintenanceState` в телефоне механика (`frontend/lib/mechanic/data/tasks.dart`):
статус `5` — проблема, статус `2` при начатой работе — пауза, всё остальное —
работа идёт. Держать это правило в двух местах приходится (клиент-серверная
граница), но разойтись им нельзя: одна и та же запись обязана читаться
одинаково и у механика, и у прораба.
[[пауза по ТО - это «Принято» при начатой работе, а не новый статус]]

Порядок
-------
Сверху то, что требует вмешательства: проблемы, за ними паузы, ниже идущие
работы. Внутри группы первой стоит та, что стоит дольше — ключ сортировки
возрастает, а не убывает, как в ленте сданных.
"""

from typing import List, NamedTuple

from sqlalchemy import asc, case, func, literal
from sqlalchemy.orm import Session, aliased

from src.core.access import AccessScope, act_fact_scope_filter, order_scope_filter
from src.core.archiving import archive_filter
from src.models import ActFact, FaultCategory, Object, Order, UniversalUser
from src.schemas.in_progress_works import WorkState
from src.schemas.reports import WorkKind
from src.services.work_kind import order_kind_case

#: Статус «Проблема» из засеянного справочника (`core/db/init_db.py`).
STATUS_PROBLEM = 5

#: Статус «Принято». У начатого ТО означает паузу, а не «взял, но не начал».
STATUS_ACCEPTED = 2

#: Статус «В работе»: механик взялся за заявку и не закрыл её.
STATUS_IN_PROGRESS = 3

#: Сколько строк отдаём. Одновременно ведут единицы работ, и список на сотню
#: строк означал бы не занятость бригады, а сломанный процесс — такой список
#: незачем ни листать, ни грузить целиком. Полное число едет в `total`, и
#: раздел подписывает остаток словами «и ещё N».
LIMIT = 20

#: Вес состояния в сортировке: чем меньше, тем выше строка.
_STATE_ORDER = {
    WorkState.PROBLEM.value: 0,
    WorkState.PAUSED.value: 1,
    WorkState.RUNNING.value: 2,
}


class Feed(NamedTuple):
    """Строки и два числа к ним.

    `total` и `problems` считаются **до** обрезки списка: раздел подписывает
    остаток («и ещё N») и красит заголовок, если проблема есть, — и оба ответа
    обязаны быть про всю выборку, а не про её видимую часть.
    """

    rows: List
    total: int
    problems: int


class CrudInProgressWorks:
    """Не наследник `CRUDBase`: своей таблицы у ленты нет."""

    obj_name = "Текущие работы"

    def _maintenance_branch(self, db: Session, scope: AccessScope):
        mechanic = aliased(UniversalUser)

        state = case(
            (ActFact.status_id == STATUS_PROBLEM, literal(WorkState.PROBLEM.value)),
            (ActFact.status_id == STATUS_ACCEPTED, literal(WorkState.PAUSED.value)),
            else_=literal(WorkState.RUNNING.value),
        )
        # С какого момента работа в текущем состоянии. У проблемы момент
        # неизвестен, и наружу он не поедет (см. getter), но для сортировки
        # «дольше стоит — выше» нужно хоть что-то: берём начало работы.
        since = func.coalesce(ActFact.paused_at, ActFact.started_at)

        return (
            db.query(
                literal(WorkKind.MAINTENANCE.value).label("kind"),
                ActFact.id.label("work_id"),
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("object_address"),
                # Задание есть только у заявок: у ТО задание — это чек-лист.
                literal(None).label("task_text"),
                mechanic.name.label("performer"),
                state.label("state"),
                since.label("since"),
                ActFact.started_at.label("started_at"),
                ActFact.commentary.label("reason"),
                # Регламент и прогресс считаются из чек-листа в Python:
                # колонка хранит три исторические формы, и разбирать её в
                # обход `services/checklist` нельзя.
                ActFact.step_list_fact.label("step_list_fact"),
            )
            .outerjoin(Object, ActFact.object_id == Object.id)
            .outerjoin(mechanic, ActFact.main_mechanic_id == mechanic.id)
            .filter(
                ActFact.started_at.isnot(None),
                ActFact.finished_at.is_(None),
                act_fact_scope_filter(scope),
                archive_filter(ActFact),
            )
        )

    def _order_branch(self, db: Session, scope: AccessScope):
        creator = aliased(UniversalUser)
        executor = aliased(UniversalUser)

        # Момент, с которого заявка в работе. `in_progress_at` ставится при
        # переходе в статус «В работе» (`crud_order`), но у заявок, взятых до
        # появления этого кода, его нет вовсе — тот же `coalesce`, что спасает
        # ленту сданных от заявок без `done_at`.
        since = func.coalesce(Order.in_progress_at, Order.accepted_at, Order.created_at)

        return (
            db.query(
                order_kind_case(creator).label("kind"),
                Order.id.label("work_id"),
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("object_address"),
                Order.task_text.label("task_text"),
                executor.name.label("performer"),
                # Пауза и проблема — не про заявку: паузы у неё не бывает, а
                # «Проблема» её закрывает и уводит в ленту сданных.
                literal(WorkState.RUNNING.value).label("state"),
                since.label("since"),
                since.label("started_at"),
                # Причина есть только у вставшей работы, а заявка в работе не
                # стоит. `commentary` у заявки заполняют при закрытии.
                literal(None).label("reason"),
                literal(None).label("step_list_fact"),
            )
            .outerjoin(Object, Order.object_id == Object.id)
            .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
            .outerjoin(creator, Order.creator_id == creator.id)
            .outerjoin(executor, Order.executor_id == executor.id)
            .filter(
                Order.status_id == STATUS_IN_PROGRESS,
                order_scope_filter(scope),
                archive_filter(Order),
            )
        )

    def _feed(self, db: Session, scope: AccessScope):
        """Обе ветки одной выборкой.

        `UNION` по той же причине, что и в ленте сданных: порядок общий на два
        вида работ, и посчитать его можно только в базе. Склей мы списки в
        Python, вставшее ТО и вставшая заявка перестали бы видеть друг друга.
        """
        return (
            self._maintenance_branch(db, scope)
            .union_all(self._order_branch(db, scope))
            .subquery("in_progress_works")
        )

    def get_feed(self, *, db: Session, scope: AccessScope) -> Feed:
        """Текущие работы: сначала вставшие, потом идущие."""
        feed = self._feed(db, scope)
        weight = case(_STATE_ORDER, value=feed.c.state)

        counted = db.query(feed.c.state)
        total = counted.count()
        problems = counted.filter(feed.c.state == WorkState.PROBLEM.value).count()

        rows = (
            db.query(feed)
            .order_by(
                asc(weight),
                # Дольше стоит — выше: ключ возрастает. В ленте сданных
                # наоборот, там сверху свежее.
                asc(feed.c.since),
                # Третьим ключом id: две работы, начатые одной секундой,
                # иначе меняются местами от запроса к запросу.
                asc(feed.c.work_id),
            )
            .limit(LIMIT)
            .all()
        )
        return Feed(rows=rows, total=total, problems=problems)


crud_in_progress_works = CrudInProgressWorks()
