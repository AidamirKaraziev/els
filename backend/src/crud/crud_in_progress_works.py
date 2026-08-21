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

from typing import List

from sqlalchemy import asc, case, func, literal
from sqlalchemy.orm import Session, aliased

from src.core.access import AccessScope, act_fact_scope_filter
from src.core.archiving import archive_filter
from src.models import ActFact, Object, UniversalUser
from src.schemas.in_progress_works import WorkState
from src.schemas.reports import WorkKind

#: Статус «Проблема» из засеянного справочника (`core/db/init_db.py`).
STATUS_PROBLEM = 5

#: Статус «Принято». У начатого ТО означает паузу, а не «взял, но не начал».
STATUS_ACCEPTED = 2

#: Вес состояния в сортировке: чем меньше, тем выше строка.
_STATE_ORDER = {
    WorkState.PROBLEM.value: 0,
    WorkState.PAUSED.value: 1,
    WorkState.RUNNING.value: 2,
}


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

    def get_feed(self, *, db: Session, scope: AccessScope) -> List:
        """Текущие работы: сначала вставшие, потом идущие.

        Без страниц: одновременно ведут единицы работ, и разбивка ради них
        только заставила бы экран считать страницы там, где их не бывает.
        """
        query = self._maintenance_branch(db, scope)

        feed = query.subquery("in_progress_works")
        weight = case(_STATE_ORDER, value=feed.c.state)
        return (
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
            .all()
        )


crud_in_progress_works = CrudInProgressWorks()
