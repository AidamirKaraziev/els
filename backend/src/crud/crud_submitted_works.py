"""Лента сданных работ: закрытые ТО и закрытые заявки одним списком.

Механик закрывает ТО сам, и работа засчитывается сразу — приёмки, блокирующей
зачёт, в системе нет. Прорабу нужно другое: видеть, что за него сдали, и уметь
сказать «эту посмотрел». Отметка ничего не меняет в самой работе, она гасит
счётчик непросмотренного.

Почему `UNION`, а не два запроса и склейка в Python
--------------------------------------------------
Лента постраничная и упорядочена по дате сдачи. Склей мы два списка в Python —
на странице оказались бы первые тридцать ТО и первые тридцать заявок, а не
тридцать свежайших работ. Порядок и срез обязаны считаться в базе, а для этого
обе ветки должны прийти в одну выборку.

Отборы применяются **внутри веток**, до объединения: у ТО и заявки разные
колонки под одно и то же понятие, и после `UNION` фильтровать было бы нечем,
кроме общих имён.

Что считается сданным
---------------------
ТО — акт с заполненным `finished_at`: именно по нему считается выполнение
графика, и второй признак разошёлся бы с ним
([[выполнение считается по дате закрытия акта, а месяц берётся из плана]]).
Заявка — статус «Выполнено» **или** «Проблема». «Проблема» — это тоже отчёт о
выходе: механик съездил и рассказал, почему сделать не вышло. Прорабу такая
работа нужна в ленте даже раньше удавшейся, поэтому она и в счётчике
непросмотренного; отличается она полем `outcome`.

Дата сдачи у заявки берётся из `done_at`, а если его нет — из метки правки:
`done_at` ставится только на «Выполнено» (`crud_order`), и у «Проблемы» его не
бывает вовсе. Тот же `coalesce` заодно спасает старые закрытые заявки — годами
`done_at` не заполнялся из-за опечатки в схеме.
"""

import datetime
from typing import List, Optional, Sequence, Tuple

from sqlalchemy import case, func, literal
from sqlalchemy.orm import Session, aliased
from starlette import status

from src.core.access import (
    AccessScope,
    act_fact_scope_filter,
    can_access_act_fact,
    can_access_order,
    order_scope_filter,
)
from src.core.archiving import archive_filter
from src.models import ActFact, FaultCategory, Object, Order, UniversalUser
from src.schemas.reports import WorkKind
from src.schemas.submitted_works import WorkOutcome
from src.services.work_kind import order_kind_case
from src.utils import pagination

#: Статус «Выполнено» из засеянного справочника (`core/db/init_db.py`).
STATUS_DONE = 4

#: Статус «Проблема» оттуда же: механик выехал, но работу не сделал.
STATUS_PROBLEM = 5

#: Статусы, с которыми заявка считается сданной и попадает в ленту.
SUBMITTED_STATUSES = (STATUS_DONE, STATUS_PROBLEM)

#: Виды работ, которые приезжают из заявок. ТО — отдельная ветка.
ORDER_KINDS = frozenset(
    {WorkKind.BREAKDOWN.value, WorkKind.CLIENT_REQUEST.value, WorkKind.REQUEST.value}
)


class CrudSubmittedWorks:
    """Не наследник `CRUDBase`: своей таблицы у ленты нет, она из двух."""

    obj_name = "Сданные работы"
    not_found = {
        "status_code": status.HTTP_404_NOT_FOUND,
        "detail": f"{obj_name}: сданной работы с таким id нет",
    }
    # Запись существует, но лежит вне области видимости — 403.
    out_of_scope = -136

    def _maintenance_branch(
        self,
        db: Session,
        scope: AccessScope,
        *,
        only_unreviewed: bool,
        since: Optional[datetime.datetime],
    ):
        mechanic = aliased(UniversalUser)
        reviewer = aliased(UniversalUser)

        query = (
            db.query(
                literal(WorkKind.MAINTENANCE.value).label("kind"),
                ActFact.id.label("work_id"),
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("object_address"),
                # Название ТО лежит внутри чек-листа, а разбирать его в обход
                # `services/checklist` нельзя. Ленте хватает объекта и
                # исполнителя, пункты — на карточке акта.
                literal(None).label("task_text"),
                mechanic.name.label("performer"),
                # Акт «проблемой» не закрывают: у ТО есть только закрыт или нет.
                literal(WorkOutcome.DONE.value).label("outcome"),
                ActFact.finished_at.label("closed_at"),
                ActFact.reviewed_at.label("reviewed_at"),
                reviewer.name.label("reviewer"),
            )
            .outerjoin(Object, ActFact.object_id == Object.id)
            .outerjoin(mechanic, ActFact.main_mechanic_id == mechanic.id)
            .outerjoin(reviewer, ActFact.reviewed_by_id == reviewer.id)
            # Архивный акт в ленту не попадает: для прораба он удалён, и
            # отмечать «проверил» на удалённой работе незачем.
            .filter(
                ActFact.finished_at.isnot(None),
                act_fact_scope_filter(scope),
                archive_filter(ActFact),
            )
        )

        if only_unreviewed:
            query = query.filter(ActFact.reviewed_at.is_(None))
        if since is not None:
            query = query.filter(ActFact.finished_at >= since)
        return query

    def _order_branch(
        self,
        db: Session,
        scope: AccessScope,
        *,
        only_unreviewed: bool,
        since: Optional[datetime.datetime],
        kinds: Optional[Sequence[str]],
    ):
        creator = aliased(UniversalUser)
        executor = aliased(UniversalUser)
        reviewer = aliased(UniversalUser)

        kind = order_kind_case(creator)
        outcome = case(
            (Order.status_id == STATUS_PROBLEM, WorkOutcome.PROBLEM.value),
            else_=WorkOutcome.DONE.value,
        )
        closed_at = func.coalesce(Order.done_at, Order.updated_at)

        query = (
            db.query(
                kind.label("kind"),
                Order.id.label("work_id"),
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("object_address"),
                Order.task_text.label("task_text"),
                executor.name.label("performer"),
                outcome.label("outcome"),
                closed_at.label("closed_at"),
                Order.reviewed_at.label("reviewed_at"),
                reviewer.name.label("reviewer"),
            )
            .outerjoin(Object, Order.object_id == Object.id)
            .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
            .outerjoin(creator, Order.creator_id == creator.id)
            .outerjoin(executor, Order.executor_id == executor.id)
            .outerjoin(reviewer, Order.reviewed_by_id == reviewer.id)
            .filter(
                Order.status_id.in_(SUBMITTED_STATUSES),
                order_scope_filter(scope),
                archive_filter(Order),
            )
        )

        if only_unreviewed:
            query = query.filter(Order.reviewed_at.is_(None))
        if since is not None:
            query = query.filter(closed_at >= since)
        if kinds is not None:
            query = query.filter(kind.in_(sorted(set(kinds) & ORDER_KINDS)))
        return query

    def _feed(
        self,
        db: Session,
        scope: AccessScope,
        *,
        only_unreviewed: bool = False,
        kinds: Optional[Sequence[str]] = None,
        since: Optional[datetime.datetime] = None,
    ):
        """Объединённая выборка обеих веток подзапросом.

        Ветка, целиком отсечённая отбором по виду работы, в объединение не
        попадает: пустой `SELECT` ради симметрии — лишняя работа базе.
        """
        branches = []
        if kinds is None or WorkKind.MAINTENANCE.value in kinds:
            branches.append(
                self._maintenance_branch(
                    db, scope, only_unreviewed=only_unreviewed, since=since
                )
            )
        if kinds is None or set(kinds) & ORDER_KINDS:
            branches.append(
                self._order_branch(
                    db,
                    scope,
                    only_unreviewed=only_unreviewed,
                    since=since,
                    kinds=kinds,
                )
            )

        if not branches:
            # Отбор не оставил ни одной ветки — например, спросили вид работы,
            # которого не бывает. Пустая лента, а не исключение.
            return None

        united = branches[0]
        if len(branches) > 1:
            united = united.union_all(*branches[1:])
        return united.subquery("submitted_works")

    def get_feed(
        self,
        *,
        db: Session,
        scope: AccessScope,
        page: Optional[int] = None,
        only_unreviewed: bool = False,
        kinds: Optional[Sequence[str]] = None,
        since: Optional[datetime.datetime] = None,
    ) -> Tuple[List, Optional[object]]:
        """Свежие сданные работы сверху."""
        feed = self._feed(
            db, scope, only_unreviewed=only_unreviewed, kinds=kinds, since=since
        )
        if feed is None:
            return [], None

        query = db.query(feed).order_by(
            feed.c.closed_at.desc(),
            # Вторым ключом — id работы: без него две работы, закрытые одной
            # секундой, могли бы обменяться местами между страницами, и одна
            # пропала бы из ленты вовсе.
            feed.c.work_id.desc(),
        )
        return pagination.get_page(query, page)

    def count_unreviewed(self, *, db: Session, scope: AccessScope) -> int:
        """Сколько сданных работ ещё не смотрели.

        Отдельный запрос, а не длина ленты: на главной нужен счётчик, а не
        список, и качать ради числа тридцать карточек незачем.
        """
        feed = self._feed(db, scope, only_unreviewed=True)
        if feed is None:
            return 0
        return db.query(func.count()).select_from(feed).scalar() or 0

    def mark_reviewed(
        self,
        *,
        db: Session,
        scope: AccessScope,
        kind: str,
        work_id: int,
        user_id: int,
    ):
        """Ставит отметку «проверил». Повторная отметка ничего не меняет.

        Незакрытую работу отметить нельзя: в ленте её нет, и проверять пока
        нечего. Отвечаем 404, а не 422 — для того, кто смотрит ленту, такой
        работы там просто не существует. По той же причине не отмечается и
        заархивированная работа.
        """
        if kind == WorkKind.MAINTENANCE.value:
            work = db.query(ActFact).filter(ActFact.id == work_id).first()
            if work is None or work.finished_at is None or work.is_actual is False:
                return None, self.not_found, None
            if not can_access_act_fact(scope, work):
                return None, self.out_of_scope, None
        elif kind in ORDER_KINDS:
            work = db.query(Order).filter(Order.id == work_id).first()
            if (
                work is None
                or work.status_id not in SUBMITTED_STATUSES
                or work.is_actual is False
            ):
                return None, self.not_found, None
            if not can_access_order(scope, work):
                return None, self.out_of_scope, None
        else:
            # Дефектная ведомость — тоже `WorkKind`, но в ленте её нет:
            # отмечать проверенной нечего.
            return None, self.not_found, None

        if work.reviewed_at is None:
            work.reviewed_at = datetime.datetime.utcnow()
            work.reviewed_by_id = user_id
            db.add(work)
            db.commit()
            db.refresh(work)
        return work, 0, None


crud_submitted_works = CrudSubmittedWorks()
