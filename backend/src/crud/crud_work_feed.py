"""Единая лента работ: заявки и акты ТО во всех статусах одним списком.

Третья лента по одному приёму с `crud_submitted_works` и
`crud_in_progress_works`: две ветки с общими колонками, `UNION ALL`, порядок и
срез считаются в базе. Отличие — здесь **все** статусы, поэтому статус едет
колонкой, а не подразумевается отбором ветки. Две старые ленты остаются
живыми ради клиентов, которые на них ходят, и не меняются.

Статус одним словом
-------------------
Заявка: её `status_id` из справочника (`core/db/init_db.py`), где 1 —
«Создано», 2 — «Принято», 3 — «В процессе», 4 — «Выполнено», 5 — «Проблема».
Заявка без статуса считается новой.

Акт ТО статусом почти не пользуется, у него состояние собирается из дат тем
же порядком проверок, что в телефоне механика и в ленте текущих работ:
закрыт (`finished_at`) → сдан; статус 5 → проблема; начат (`started_at`) →
в работе, и статус 2 при начатом означает паузу; есть механик, но не начат →
принят; иначе новый.
[[пауза по ТО - это «Принято» при начатой работе, а не новый статус]]

Участок работы
--------------
От объекта: работа привязана к лифту, и участок у неё есть даже когда
исполнителя ещё нет. Запасной вариант — участок исполнителя, для объектов,
у которых `division_id` не заполнен. Решение от 12.09.2026.

Внимание
--------
Три причины и только они: новая без исполнителя, стадия дольше порога, пауза
дольше часа. Пороги — те же, что у `WorkTiming` на экране
(`frontend/lib/screns/works/models/work_timing.dart`): полоса сводки, красный
таймер и блок «требуют внимания» обязаны сходиться в одном числе. Закрытые не
считаются — это история; отмеченные «проверил» тоже — прораб уже посмотрел, и
держать строку наверху до следующей перемены значит учить его не нажимать.

Считается в базе, а не на клиенте: блок стоит наверху ленты с курсором, и
собрать его на странице из тридцати строк нельзя — затянувшаяся заявка могла
остаться на третьей.

Курсор
------
Keyset по одному числовому ключу, а не номер страницы: лента живая, между
двумя запросами строки меняют порядок, и страница по смещению теряла бы
работу или показывала её дважды. Ключ — `(rank, sort_key, work_id, kind)`:
`rank` 0 у блока внимания, 1 у остальных; `sort_key` — секунды эпохи начала
стадии у блока (дольше стоит — выше) и **минус** секунды последней перемены у
остальных (свежее — выше). Один знак сравнения на оба порядка — ради того,
чтобы условие «после курсора» было одним сравнением кортежей.
"""

import base64
import datetime
import json
from typing import Dict, List, NamedTuple, Optional, Sequence, Tuple

from sqlalchemy import (
    DateTime,
    and_,
    case,
    cast,
    false,
    func,
    literal,
    null,
    or_,
    select,
    tuple_,
)
from sqlalchemy.orm import Session, aliased
from starlette import status as http_status

from src.core.access import (
    AccessScope,
    act_fact_scope_filter,
    apply_object_scope,
    apply_user_scope,
    can_access_act_fact,
    can_access_order,
    order_scope_filter,
)
from src.core.archiving import ArchiveView, apply_archive_view
from src.core.roles import Role
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import (
    ActFact,
    ContactPerson,
    DefectiveAct,
    Division,
    FactoryModel,
    FaultCategory,
    Object,
    Order,
    TypeObject,
    UniversalUser,
    WorkingSpecialty,
)
from src.schemas.reports import WorkKind
from src.schemas.work_feed import (
    CLOSED_STATUSES,
    AttentionReason,
    WorkSort,
    WorkStatus,
)
from src.services.work_kind import order_kind_case

#: Статусы из засеянного справочника.
STATUS_ACCEPTED = 2
STATUS_IN_PROGRESS = 3
STATUS_DONE = 4
STATUS_PROBLEM = 5

#: Виды работ, которые приезжают из заявок. ТО — отдельная ветка.
ORDER_KINDS = frozenset(
    {WorkKind.BREAKDOWN.value, WorkKind.CLIENT_REQUEST.value, WorkKind.REQUEST.value}
)

#: Пороги стадий — те же, что `WorkTiming` на экране.
FRESH_LIMIT = datetime.timedelta(hours=2)
ACCEPTED_LIMIT = datetime.timedelta(hours=4)
RUNNING_LIMIT = datetime.timedelta(hours=8)
PAUSED_LIMIT = datetime.timedelta(hours=1)

#: Страница по умолчанию и потолок. Тридцать — как у прежних лент.
DEFAULT_LIMIT = 30
MAX_LIMIT = 100

_CLOSED = [s.value for s in CLOSED_STATUSES]


class FeedFilters(NamedTuple):
    """Отбор ленты. Один объект, а не десяток аргументов: счётчики считают
    его же без одного условия, и передавать его целиком проще."""

    status: Optional[str] = None
    kind: Optional[str] = None
    search: str = ""
    section_id: Optional[int] = None
    performer_id: Optional[int] = None
    mine: bool = False
    my_division_ids: Sequence[int] = ()
    attention: Optional[str] = None
    updated_since: Optional[datetime.datetime] = None


class Feed(NamedTuple):
    rows: List
    next_cursor: Optional[str]
    attention_count: int
    by_status: Dict[str, int]
    by_kind: Dict[str, int]
    by_attention: Dict[str, int]
    sections: List[Tuple[int, Optional[str]]]


def encode_cursor(rank: int, sort_key: float, work_id: int, kind: str) -> str:
    raw = json.dumps([rank, sort_key, work_id, kind]).encode()
    return base64.urlsafe_b64encode(raw).decode()


def decode_cursor(cursor: str) -> Tuple[int, float, int, str]:
    """Ключ из курсора. Порченый курсор — `ValueError`, ручка отвечает 422."""
    try:
        rank, sort_key, work_id, kind = json.loads(base64.urlsafe_b64decode(cursor))
        return int(rank), float(sort_key), int(work_id), str(kind)
    except (ValueError, TypeError) as error:
        raise ValueError("bad cursor") from error


class CrudWorkFeed:
    """Не наследник `CRUDBase`: своей таблицы у ленты нет, она из двух."""

    obj_name = "Работы"
    not_found = {
        "status_code": http_status.HTTP_404_NOT_FOUND,
        "detail": f"{obj_name}: работы с таким id нет",
    }
    # Запись существует, но лежит вне области — 403.
    out_of_scope = -136

    # ------------------------------------------------------------------
    # Ветки
    # ------------------------------------------------------------------

    def _order_branch(self, db: Session, scope: AccessScope, view: ArchiveView):
        creator = aliased(UniversalUser)
        executor = aliased(UniversalUser)
        object_division = aliased(Division)
        performer_division = aliased(Division)

        status = case(
            (Order.status_id == STATUS_ACCEPTED, WorkStatus.ACCEPTED.value),
            (Order.status_id == STATUS_IN_PROGRESS, WorkStatus.RUNNING.value),
            (Order.status_id == STATUS_DONE, WorkStatus.SUBMITTED.value),
            (Order.status_id == STATUS_PROBLEM, WorkStatus.PROBLEM.value),
            else_=WorkStatus.FRESH.value,
        )
        # `done_at` ставится только на «Выполнено», у «Проблемы» его нет —
        # тот же `coalesce`, что в ленте сданных.
        closed_at = case(
            (
                Order.status_id.in_((STATUS_DONE, STATUS_PROBLEM)),
                func.coalesce(Order.done_at, Order.updated_at),
            ),
            else_=cast(null(), DateTime),
        )
        has_defect = (
            select(DefectiveAct.id).where(DefectiveAct.order_id == Order.id).exists()
        )

        query = (
            db.query(
                order_kind_case(creator).label("kind"),
                Order.id.label("work_id"),
                status.label("status"),
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("object_address"),
                TypeObject.name.label("object_type"),
                Order.task_text.label("task_text"),
                executor.id.label("performer_id"),
                executor.name.label("performer"),
                executor.contact_phone.label("performer_phone"),
                Order.created_at.label("created_at"),
                Order.accepted_at.label("accepted_at"),
                Order.in_progress_at.label("started_at"),
                # Паузы у заявки не бывает: колонки нет и экрана нет.
                cast(null(), DateTime).label("paused_at"),
                closed_at.label("closed_at"),
                Order.updated_at.label("updated_at"),
                has_defect.label("has_defect"),
                Order.commentary.label("comment"),
                Order.is_actual.label("is_actual"),
                func.coalesce(Object.division_id, executor.division_id).label(
                    "section_id"
                ),
                case(
                    (Object.division_id.isnot(None), object_division.title),
                    else_=performer_division.title,
                ).label("section"),
                Order.reviewed_at.label("reviewed_at"),
                literal(None).label("step_list_fact"),
            )
            .select_from(Order)
            .outerjoin(Object, Order.object_id == Object.id)
            .outerjoin(FactoryModel, Object.factory_model_id == FactoryModel.id)
            .outerjoin(TypeObject, FactoryModel.type_object_id == TypeObject.id)
            .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
            .outerjoin(creator, Order.creator_id == creator.id)
            .outerjoin(executor, Order.executor_id == executor.id)
            .outerjoin(object_division, Object.division_id == object_division.id)
            .outerjoin(
                performer_division, executor.division_id == performer_division.id
            )
            .filter(order_scope_filter(scope))
        )
        return apply_archive_view(query, Order, view)

    def _maintenance_branch(self, db: Session, scope: AccessScope, view: ArchiveView):
        mechanic = aliased(UniversalUser)
        object_division = aliased(Division)
        performer_division = aliased(Division)

        started = ActFact.started_at.isnot(None)
        finished = ActFact.finished_at.isnot(None)
        status = case(
            (finished, WorkStatus.SUBMITTED.value),
            (ActFact.status_id == STATUS_PROBLEM, WorkStatus.PROBLEM.value),
            (started, WorkStatus.RUNNING.value),
            (ActFact.main_mechanic_id.isnot(None), WorkStatus.ACCEPTED.value),
            else_=WorkStatus.FRESH.value,
        )
        # Пауза — статус «Принято» при начатой незакрытой работе. `paused_at`
        # сам по себе паузой не считается: телефон снимает её явным `null`,
        # но у старых записей дата могла остаться.
        paused_at = case(
            (
                and_(ActFact.status_id == STATUS_ACCEPTED, started, ~finished),
                ActFact.paused_at,
            ),
            else_=cast(null(), DateTime),
        )
        has_defect = (
            select(DefectiveAct.id)
            .where(DefectiveAct.act_fact_id == ActFact.id)
            .exists()
        )

        query = (
            db.query(
                literal(WorkKind.MAINTENANCE.value).label("kind"),
                ActFact.id.label("work_id"),
                status.label("status"),
                Object.id.label("object_id"),
                Object.name.label("object_name"),
                Object.address.label("object_address"),
                TypeObject.name.label("object_type"),
                # Задание есть только у заявок: у ТО задание — это чек-лист.
                literal(None).label("task_text"),
                mechanic.id.label("performer_id"),
                mechanic.name.label("performer"),
                mechanic.contact_phone.label("performer_phone"),
                ActFact.created_at.label("created_at"),
                # Момент принятия у акта не хранится.
                cast(null(), DateTime).label("accepted_at"),
                ActFact.started_at.label("started_at"),
                paused_at.label("paused_at"),
                ActFact.finished_at.label("closed_at"),
                ActFact.updated_at.label("updated_at"),
                has_defect.label("has_defect"),
                ActFact.commentary.label("comment"),
                ActFact.is_actual.label("is_actual"),
                func.coalesce(Object.division_id, mechanic.division_id).label(
                    "section_id"
                ),
                case(
                    (Object.division_id.isnot(None), object_division.title),
                    else_=performer_division.title,
                ).label("section"),
                ActFact.reviewed_at.label("reviewed_at"),
                ActFact.step_list_fact.label("step_list_fact"),
            )
            .select_from(ActFact)
            .outerjoin(Object, ActFact.object_id == Object.id)
            .outerjoin(FactoryModel, Object.factory_model_id == FactoryModel.id)
            .outerjoin(TypeObject, FactoryModel.type_object_id == TypeObject.id)
            .outerjoin(mechanic, ActFact.main_mechanic_id == mechanic.id)
            .outerjoin(object_division, Object.division_id == object_division.id)
            .outerjoin(
                performer_division, mechanic.division_id == performer_division.id
            )
            .filter(act_fact_scope_filter(scope))
        )
        return apply_archive_view(query, ActFact, view)

    # ------------------------------------------------------------------
    # Объединение и вычисляемые колонки
    # ------------------------------------------------------------------

    def _ranked(
        self,
        db: Session,
        scope: AccessScope,
        *,
        view: ArchiveView,
        now: datetime.datetime,
        sort: WorkSort,
    ):
        """Объединённая выборка плюс стадия, причина внимания и ключ порядка.

        `UNION` по той же причине, что в двух других лентах: порядок и срез
        общие на два вида работ, и посчитать их можно только в базе.
        """
        feed = (
            self._order_branch(db, scope, view)
            .union_all(self._maintenance_branch(db, scope, view))
            .subquery("work_feed")
        )
        c = feed.c

        is_fresh = c.status == WorkStatus.FRESH.value
        is_accepted = c.status == WorkStatus.ACCEPTED.value
        is_running = c.status == WorkStatus.RUNNING.value
        is_paused = and_(is_running, c.paused_at.isnot(None))
        accepted_since = func.coalesce(c.accepted_at, c.created_at)
        running_since = func.coalesce(c.started_at, c.created_at)
        last_change = func.coalesce(c.updated_at, c.created_at)

        # С какого момента длится стадия — по нему блок внимания упорядочен:
        # дольше стоит — выше.
        stage_since = case(
            (is_fresh, c.created_at),
            (is_accepted, accepted_since),
            (is_paused, c.paused_at),
            (is_running, running_since),
            else_=last_change,
        )
        attention = case(
            (or_(c.status.in_(_CLOSED), c.reviewed_at.isnot(None)), null()),
            (
                and_(is_fresh, c.performer_id.is_(None)),
                AttentionReason.UNASSIGNED.value,
            ),
            (
                and_(is_paused, c.paused_at < now - PAUSED_LIMIT),
                AttentionReason.PAUSED_LONG.value,
            ),
            (
                and_(is_fresh, c.created_at < now - FRESH_LIMIT),
                AttentionReason.OVERDUE.value,
            ),
            (
                and_(is_accepted, accepted_since < now - ACCEPTED_LIMIT),
                AttentionReason.OVERDUE.value,
            ),
            (
                and_(is_running, ~is_paused, running_since < now - RUNNING_LIMIT),
                AttentionReason.OVERDUE.value,
            ),
            else_=null(),
        )
        if sort is WorkSort.ATTENTION:
            rank = case((attention.isnot(None), 0), else_=1)
        else:
            rank = literal(1)
        # `date_part`, а не `extract`: в новых Postgres `extract` отдаёт
        # `numeric`, а курсор хранит число как float, и сравнение кортежей
        # обязано идти в одном типе.
        sort_key = case(
            (rank == 0, func.date_part("epoch", stage_since)),
            else_=-func.date_part("epoch", last_change),
        )

        return (
            select(
                feed,
                stage_since.label("stage_since"),
                attention.label("attention"),
                rank.label("rank"),
                sort_key.label("sort_key"),
            )
            .select_from(feed)
            .subquery("work_feed_ranked")
        )

    @staticmethod
    def _apply_filters(query, ranked, filters: FeedFilters, *, skip: str = ""):
        """Отбор ленты. `skip` — какое условие не применять: счётчик на чипсе
        считается по отбору без этого самого чипса."""
        c = ranked.c
        if filters.updated_since is not None:
            query = query.filter(c.updated_at > filters.updated_since)
        if filters.status is not None and skip != "status":
            query = query.filter(c.status == filters.status)
        if filters.kind is not None and skip != "kind":
            query = query.filter(c.kind == filters.kind)
        if filters.section_id is not None and skip != "section":
            query = query.filter(c.section_id == filters.section_id)
        if filters.performer_id is not None:
            query = query.filter(c.performer_id == filters.performer_id)
        if filters.mine:
            ids = sorted(set(filters.my_division_ids))
            query = query.filter(c.section_id.in_(ids) if ids else false())
        if filters.attention is not None and skip != "attention":
            query = query.filter(c.attention == filters.attention)
        if filters.search:
            needle = f"%{filters.search.strip()}%"
            query = query.filter(
                or_(c.object_name.ilike(needle), c.object_address.ilike(needle))
            )
        return query

    # ------------------------------------------------------------------
    # Наружу
    # ------------------------------------------------------------------

    def get_feed(
        self,
        *,
        db: Session,
        scope: AccessScope,
        filters: FeedFilters,
        only_archived: bool = False,
        sort: WorkSort = WorkSort.ATTENTION,
        cursor: Optional[str] = None,
        limit: int = DEFAULT_LIMIT,
        now: Optional[datetime.datetime] = None,
    ) -> Feed:
        now = now or datetime.datetime.utcnow()
        # Синхронизация перебивает архивный вид: клиенту, который спрашивает
        # «что изменилось», архивные нужны именно затем, чтобы узнать об
        # удалении.
        view = ArchiveView.choose(
            only_archived=only_archived, syncing=filters.updated_since is not None
        )
        ranked = self._ranked(db, scope, view=view, now=now, sort=sort)
        c = ranked.c

        def counted(column, skip):
            query = db.query(column, func.count()).select_from(ranked)
            query = self._apply_filters(query, ranked, filters, skip=skip)
            return {
                key: number
                for key, number in query.group_by(column).all()
                if key is not None
            }

        by_status = counted(c.status, "status")
        by_kind = counted(c.kind, "kind")
        by_attention = counted(c.attention, "attention")

        sections_query = db.query(c.section_id, c.section).select_from(ranked)
        sections_query = self._apply_filters(
            sections_query, ranked, filters, skip="section"
        ).filter(c.section_id.isnot(None))
        sections = sorted(
            set(sections_query.distinct().all()), key=lambda row: (row[1] or "", row[0])
        )

        page = self._apply_filters(
            db.query(ranked).select_from(ranked), ranked, filters
        )

        attention_count = 0
        if sort is WorkSort.ATTENTION:
            attention_count = page.filter(c.rank == 0).count()

        if cursor:
            rank, sort_key, work_id, kind = decode_cursor(cursor)
            page = page.filter(
                tuple_(c.rank, c.sort_key, c.work_id, c.kind)
                > tuple_(
                    literal(rank), literal(sort_key), literal(work_id), literal(kind)
                )
            )

        rows = (
            page.order_by(c.rank, c.sort_key, c.work_id, c.kind).limit(limit + 1).all()
        )
        next_cursor = None
        if len(rows) > limit:
            rows = rows[:limit]
            last = rows[-1]
            next_cursor = encode_cursor(
                last.rank, float(last.sort_key), last.work_id, last.kind
            )

        return Feed(
            rows=rows,
            next_cursor=next_cursor,
            attention_count=attention_count,
            by_status=by_status,
            by_kind=by_kind,
            by_attention=by_attention,
            sections=sections,
        )

    def get_item(
        self,
        *,
        db: Session,
        scope: AccessScope,
        kind: str,
        work_id: int,
        now: Optional[datetime.datetime] = None,
    ):
        """Одна строка ленты — ответ ручек действия."""
        ranked = self._ranked(
            db,
            scope,
            view=ArchiveView.ALL,
            now=now or datetime.datetime.utcnow(),
            sort=WorkSort.ATTENTION,
        )
        c = ranked.c
        query = db.query(ranked).filter(c.work_id == work_id)
        if kind == WorkKind.MAINTENANCE.value:
            query = query.filter(c.kind == kind)
        else:
            query = query.filter(c.kind != WorkKind.MAINTENANCE.value)
        return query.first()

    def get_employees(
        self, *, db: Session, scope: AccessScope, include_clients: bool = False
    ):
        """Кого можно назначить: живые сотрудники в области видимости.

        Не только механики: назначить можно и инженера-наладчика, а должность
        видна в списке — прораб выбирает по ней.

        `include_clients` — для формы «Новая работа»: задача бывает и на
        заказчика («оплатить», «дать доступ»). Должности у клиента нет —
        вместо неё «Заказчик», по этому слову форма кладёт его в свою группу.
        """
        is_client = UniversalUser.role_id == Role.CLIENT
        specialty = (
            case((is_client, literal("Заказчик")), else_=WorkingSpecialty.name)
            if include_clients
            else WorkingSpecialty.name
        )
        query = (
            db.query(
                UniversalUser.id,
                UniversalUser.name,
                specialty.label("specialty"),
                UniversalUser.division_id.label("section_id"),
                Division.title.label("section"),
                UniversalUser.contact_phone.label("phone"),
            )
            .outerjoin(
                WorkingSpecialty,
                UniversalUser.working_specialty_id == WorkingSpecialty.id,
            )
            .outerjoin(Division, UniversalUser.division_id == Division.id)
            .filter(UniversalUser.is_active.isnot(False))
        )
        if not include_clients:
            query = query.filter(or_(UniversalUser.role_id.is_(None), ~is_client))
        return apply_user_scope(query, scope).order_by(UniversalUser.name).all()

    # ------------------------------------------------------------------
    # Форма «Новая работа»
    # ------------------------------------------------------------------

    def get_new_work_objects(self, *, db: Session, scope: AccessScope):
        """Живые объекты области с тем, что показывает карточка выбора."""
        mechanic = aliased(UniversalUser)
        foreman = aliased(UniversalUser)
        query = (
            db.query(
                Object.id,
                Object.name,
                Object.address,
                TypeObject.name.label("type"),
                Object.factory_number,
                Object.registration_number,
                Object.division_id.label("section_id"),
                Division.title.label("section"),
                mechanic.id.label("mechanic_id"),
                mechanic.name.label("mechanic"),
                foreman.name.label("foreman"),
                ContactPerson.name.label("contact_name"),
                ContactPerson.phone.label("contact_phone"),
            )
            .select_from(Object)
            .outerjoin(FactoryModel, Object.factory_model_id == FactoryModel.id)
            .outerjoin(TypeObject, FactoryModel.type_object_id == TypeObject.id)
            .outerjoin(Division, Object.division_id == Division.id)
            .outerjoin(mechanic, Object.mechanic_id == mechanic.id)
            .outerjoin(foreman, Object.foreman_id == foreman.id)
            .outerjoin(ContactPerson, Object.contact_person_id == ContactPerson.id)
            .filter(Object.is_actual.isnot(False))
        )
        return apply_object_scope(query, scope).order_by(Object.name, Object.id).all()

    def get_categories(self, *, db: Session):
        """Весь справочник; что из него предлагать — решает форма по коду."""
        return db.query(FaultCategory).order_by(FaultCategory.id).all()

    def get_open_works(self, *, db: Session, scope: AccessScope):
        """Незакрытые заявки и акты по объектам области — под «В работе сейчас».

        Те же ветки, что у ленты: статус одним словом считается в одном месте.
        """
        view = ArchiveView.ACTUAL
        feed = (
            self._order_branch(db, scope, view)
            .union_all(self._maintenance_branch(db, scope, view))
            .subquery("open_works")
        )
        c = feed.c
        closed = [status.value for status in CLOSED_STATUSES]
        return (
            db.query(
                c.object_id,
                c.kind,
                c.status,
                c.task_text,
                c.step_list_fact,
                c.performer,
            )
            .filter(c.object_id.isnot(None), c.status.notin_(closed))
            .order_by(c.object_id, c.created_at)
            .all()
        )

    # ------------------------------------------------------------------
    # Действия
    # ------------------------------------------------------------------

    def _load(self, db: Session, scope: AccessScope, kind: str, work_id: int):
        """Запись под действие: 404 если нет или в архиве, 403 вне области."""
        if kind == WorkKind.MAINTENANCE.value:
            work = db.query(ActFact).filter(ActFact.id == work_id).first()
            can_access = can_access_act_fact
        elif kind in ORDER_KINDS:
            work = db.query(Order).filter(Order.id == work_id).first()
            can_access = can_access_order
        else:
            # Дефектная ведомость — тоже `WorkKind`, но в ленте её нет.
            return None, self.not_found
        if work is None or work.is_actual is False:
            return None, self.not_found
        if not can_access(scope, work):
            return None, self.out_of_scope
        return work, 0

    def assign(
        self,
        *,
        db: Session,
        scope: AccessScope,
        kind: str,
        work_id: int,
        performer_id: int,
        now: Optional[datetime.datetime] = None,
    ):
        """Назначить исполнителя. Новая заявка становится принятой.

        Отметка «проверил» сбрасывается: назначение — перемена, после которой
        прорабу стоит взглянуть на строку заново.
        """
        work, code = self._load(db, scope, kind, work_id)
        if code != 0:
            return None, code, None
        _, code, _ = crud_universal_users.get_user_by_reference(
            db=db, user_id=performer_id
        )
        if code != 0:
            return None, code, None

        if isinstance(work, Order):
            work.executor_id = performer_id
            if work.status_id is None or work.status_id < STATUS_ACCEPTED:
                work.status_id = STATUS_ACCEPTED
                work.accepted_at = now or datetime.datetime.utcnow()
        else:
            work.main_mechanic_id = performer_id
        work.reviewed_at = None
        work.reviewed_by_id = None
        db.add(work)
        db.commit()
        db.refresh(work)
        return work, 0, None

    def review(
        self,
        *,
        db: Session,
        scope: AccessScope,
        kind: str,
        work_id: int,
        user_id: int,
    ):
        """Отметить «проверил». В отличие от ленты сданных — на любой стадии:
        здесь отметка гасит блок внимания, а не только счётчик сданного.
        Повторная отметка ничего не меняет."""
        work, code = self._load(db, scope, kind, work_id)
        if code != 0:
            return None, code, None
        if work.reviewed_at is None:
            work.reviewed_at = datetime.datetime.utcnow()
            work.reviewed_by_id = user_id
            db.add(work)
            db.commit()
            db.refresh(work)
        return work, 0, None


crud_work_feed = CrudWorkFeed()
