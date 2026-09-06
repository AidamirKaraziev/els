"""Область видимости: над какими записями человек работает.

Право отвечает на вопрос «можно ли ему такое действие вообще»
(`src/core/permissions.py`), область — «над какими именно записями». Прораб
имеет право менять объекты, но только на своих участках; механик — только те,
куда его назначили; клиент — только лифты своей компании.

Область считается один раз из строки пользователя и дальше применяется
**фильтром к запросу**, а не проверкой после выборки: иначе постраничная
выдача врёт — на странице десять записей, из них видно три.

Согласованные правила: [[матрица прав по ролям]] в vault.
"""

from dataclasses import dataclass
from enum import Enum
from typing import FrozenSet, Optional

from sqlalchemy import false, or_, select, true

from src.core.roles import Role
from src.models import (
    ActFact,
    ActFactStepPhoto,
    DefectiveAct,
    Object,
    Order,
    OrderPhoto,
    PlannedTO,
    UniversalUser,
    UserDivision,
)


class ScopeKind(str, Enum):
    """Что человеку доступно."""

    #: Всё без ограничений — админ, а также чтение для прораба и диспетчера.
    ALL = "all"
    #: Записи своих участков.
    DIVISIONS = "divisions"
    #: Только то, куда человек назначен лично.
    ASSIGNED = "assigned"
    #: Записи своей компании — для клиента.
    COMPANY = "company"
    #: Ничего. Роль неизвестна или не заполнена.
    NOTHING = "nothing"


@dataclass(frozen=True)
class AccessScope:
    kind: ScopeKind
    user_id: int
    division_ids: FrozenSet[int]
    company_id: Optional[int]

    @property
    def unrestricted(self) -> bool:
        return self.kind is ScopeKind.ALL

    @property
    def empty(self) -> bool:
        """Область, в которой заведомо ничего нет.

        Случается не только у неизвестной роли: механик без назначений и
        клиент без компании тоже не видят ничего — и это правильнее, чем
        показать им всё.
        """
        if self.kind is ScopeKind.NOTHING:
            return True
        if self.kind is ScopeKind.DIVISIONS and not self.division_ids:
            return True
        if self.kind is ScopeKind.COMPANY and self.company_id is None:
            return True
        return False


def division_ids_of(user: UniversalUser) -> FrozenSet[int]:
    """Участки сотрудника: связь плюс основной участок.

    Основной `division_id` добавляется на случай, если связь почему-то не
    заполнена — например, участок назначили в обход нового кода. Потерять
    доступ к своему участку хуже, чем лишний раз его подтвердить.
    """
    ids = {division.id for division in user.divisions}
    if user.division_id is not None:
        ids.add(user.division_id)
    return frozenset(ids)


def read_scope(user: UniversalUser) -> AccessScope:
    """Что человек видит."""
    return _scope(user, for_write=False)


def write_scope(user: UniversalUser) -> AccessScope:
    """Что человек может менять.

    У прораба и диспетчера уже, чем видимость: они смотрят по всем участкам,
    а правят только своё. Заказчик сформулировал это как «видит всё, меняет
    только своё».
    """
    return _scope(user, for_write=True)


def _scope(user: UniversalUser, *, for_write: bool) -> AccessScope:
    divisions = division_ids_of(user)
    try:
        role = Role(user.role_id)
    except (ValueError, TypeError):
        role = None

    if role is Role.ADMIN:
        kind = ScopeKind.ALL
    elif role is Role.FOREMAN:
        kind = ScopeKind.DIVISIONS if for_write else ScopeKind.ALL
    elif role is Role.DISPATCHER:
        # Диспетчерская — единая точка приёма: заявку он заводит по любому
        # объекту, поэтому и на запись ограничений по участку нет.
        kind = ScopeKind.ALL
    elif role is Role.ENGINEER:
        kind = ScopeKind.DIVISIONS
    elif role is Role.MECHANIC:
        kind = ScopeKind.ASSIGNED
    elif role is Role.CLIENT:
        kind = ScopeKind.COMPANY
    else:
        kind = ScopeKind.NOTHING

    return AccessScope(
        kind=kind,
        user_id=user.id,
        division_ids=divisions,
        company_id=user.company_id,
    )


# ---------------------------------------------------------------------------
# Фильтры запроса
# ---------------------------------------------------------------------------
#
# Каждая сущность режется ровно одной функцией `apply_*_scope`, и вызывается
# она в CRUD, а не в ручках. Причина в цене ошибки: забытый фильтр ничего не
# ломает — ответ приходит, статус 200, в логах чисто, просто данных больше,
# чем положено.
#
# Фильтруем запросом, а не проверкой после выборки: выдача постраничная, и
# проверка на выходе дала бы страницу, где из десяти записей видно три, а
# `total` считал бы все десять.


def personal_work_object_ids(scope: AccessScope):
    """Подзапрос с id лифтов, где у человека своя работа или своя заявка.

    Заявка и работа по ТО давно видны исполнителю, даже если объект назначен
    не ему (`order_scope_filter`, `act_fact_scope_filter`): механика послали
    на чужой лифт — работу он видит. Сам лифт при этом не открывался, и
    получалась щель: заявку видно, а объект под ней — нет. На дефекте «с
    объекта» она вылезала наружу — объект в списке у механика есть, а
    `POST /defective-act/` с его `object_id` отвечал 403.
    """
    return (
        select(Order.object_id)
        .where(
            or_(
                Order.executor_id == scope.user_id,
                Order.creator_id == scope.user_id,
            )
        )
        .correlate(None)
        .union(
            select(ActFact.object_id)
            .where(
                or_(
                    ActFact.main_mechanic_id == scope.user_id,
                    ActFact.foreman_id == scope.user_id,
                )
            )
            .correlate(None)
        )
    )


def object_scope_filter(scope: AccessScope):
    """SQL-условие «этот лифт человеку виден».

    Повторяет `can_access_object` один в один: список и одиночная проверка по
    id обязаны отвечать одинаково, иначе запись из списка открывается с 403.
    """
    if scope.kind is ScopeKind.ALL:
        return true()
    if scope.kind is ScopeKind.DIVISIONS:
        return or_(
            Object.division_id.in_(sorted(scope.division_ids)),
            Object.foreman_id == scope.user_id,
            Object.mechanic_id == scope.user_id,
            Object.id.in_(personal_work_object_ids(scope)),
        )
    if scope.kind is ScopeKind.ASSIGNED:
        return or_(
            Object.mechanic_id == scope.user_id,
            Object.foreman_id == scope.user_id,
            Object.id.in_(personal_work_object_ids(scope)),
        )
    if scope.kind is ScopeKind.COMPANY and scope.company_id is not None:
        # Компания клиента, а не `organization_id` — это наше юрлицо по
        # договору. Поля стоят рядом, перепутать легко, ошибка тихая.
        return Object.company_id == scope.company_id
    return false()


def visible_object_ids(scope: AccessScope):
    """Подзапрос с id доступных лифтов — для всего, что висит на объекте.

    `correlate(None)` обязателен: без него SQLAlchemy склеит подзапрос с
    внешним запросом, если тот уже присоединил `objects` (так делает
    статистика), и условие превратится в тавтологию — то есть в утечку.
    """
    return (
        select(Object.id).where(object_scope_filter(scope)).correlate(None)
    ).scalar_subquery()


def apply_object_scope(query, scope: AccessScope):
    """Список лифтов по области видимости."""
    return query.filter(object_scope_filter(scope))


def order_scope_filter(scope: AccessScope):
    """SQL-условие «эта заявка человеку видна»."""
    if scope.kind is ScopeKind.ALL:
        return true()
    if scope.kind is ScopeKind.NOTHING:
        return false()
    return or_(
        Order.object_id.in_(visible_object_ids(scope)),
        # Своя заявка видна всегда: иначе механик потеряет доступ к уже
        # выполненной работе, если объект переназначат другому.
        Order.executor_id == scope.user_id,
        Order.creator_id == scope.user_id,
    )


def apply_order_scope(query, scope: AccessScope):
    """Список заявок: доступ наследуется от объекта плюс личное участие."""
    return query.filter(order_scope_filter(scope))


def visible_order_ids(scope: AccessScope):
    """Подзапрос с id доступных заявок — для фотографий заявок."""
    return (
        select(Order.id).where(order_scope_filter(scope)).correlate(None)
    ).scalar_subquery()


def apply_order_photo_scope(query, scope: AccessScope):
    """Список фотографий заявок. Наследует доступ от заявки целиком."""
    if scope.kind is ScopeKind.ALL:
        return query
    return query.filter(OrderPhoto.order_id.in_(visible_order_ids(scope)))


def act_fact_scope_filter(scope: AccessScope):
    """SQL-условие «этот акт человеку виден» — от объекта плюс своё участие.

    Условие отдельно от `apply_act_fact_scope`, потому что лента сданных
    работ строит `UNION` и фильтрует ветку сама, а не через `Query`.
    """
    if scope.kind is ScopeKind.ALL:
        return true()
    if scope.kind is ScopeKind.NOTHING:
        return false()
    return or_(
        ActFact.object_id.in_(visible_object_ids(scope)),
        ActFact.foreman_id == scope.user_id,
        ActFact.main_mechanic_id == scope.user_id,
    )


def apply_act_fact_scope(query, scope: AccessScope):
    """Список фактических актов: от объекта плюс свои акты."""
    return query.filter(act_fact_scope_filter(scope))


def visible_act_fact_ids(scope: AccessScope):
    """Подзапрос с id доступных актов — для фотографий шагов."""
    return (
        select(ActFact.id).where(act_fact_scope_filter(scope)).correlate(None)
    ).scalar_subquery()


def apply_act_fact_step_photo_scope(query, scope: AccessScope):
    """Снимки шагов чек-листа. Наследуют доступ от акта целиком."""
    if scope.kind is ScopeKind.ALL:
        return query
    if scope.kind is ScopeKind.NOTHING:
        return query.filter(false())
    return query.filter(ActFactStepPhoto.act_fact_id.in_(visible_act_fact_ids(scope)))


def apply_planned_to_scope(query, scope: AccessScope):
    """Список плановых ТО: целиком по объекту, личного участия у ТО нет."""
    if scope.kind is ScopeKind.ALL:
        return query
    if scope.kind is ScopeKind.NOTHING:
        return query.filter(false())
    return query.filter(PlannedTO.object_id.in_(visible_object_ids(scope)))


def defective_act_scope_filter(scope: AccessScope):
    """SQL-условие «эта дефектная ведомость человеку видна».

    Ось доступа — объект, а не плановое ТО: акт заводится из четырёх мест, и
    у трёх из них `planned_to_id` пуст. Через ТО такой акт не увидел бы никто,
    кроме автора и ответственного.
    """
    if scope.kind is ScopeKind.ALL:
        return true()
    if scope.kind is ScopeKind.NOTHING:
        return false()
    return or_(
        DefectiveAct.object_id.in_(visible_object_ids(scope)),
        DefectiveAct.responsible_user_id == scope.user_id,
        DefectiveAct.created_by_user_id == scope.user_id,
    )


def apply_defective_act_scope(query, scope: AccessScope):
    """Список дефектных ведомостей: по объекту, плюс свои."""
    return query.filter(defective_act_scope_filter(scope))


def visible_defective_act_ids(scope: AccessScope):
    """Подзапрос с id доступных ведомостей — для их фотографий."""
    return (
        select(DefectiveAct.id).where(defective_act_scope_filter(scope)).correlate(None)
    ).scalar_subquery()


def apply_user_scope(query, scope: AccessScope):
    """Список людей.

    Считается по участкам, а не по назначению на объекты: список коллег нужен,
    чтобы выбрать исполнителя, и механик, видящий пустой список, не сможет
    передать заявку. Себя человек видит в любом случае — иначе не откроется
    собственный профиль.

    Клиенту список людей и так не положен (у роли нет `USER_READ`), поэтому
    для него здесь остаётся только он сам.
    """
    if scope.kind is ScopeKind.ALL:
        return query
    if scope.kind is ScopeKind.NOTHING:
        return query.filter(UniversalUser.id == scope.user_id)
    if scope.kind is ScopeKind.COMPANY:
        return query.filter(
            or_(
                UniversalUser.id == scope.user_id,
                UniversalUser.company_id == scope.company_id,
            )
        )

    divisions = sorted(scope.division_ids)
    return query.filter(
        or_(
            UniversalUser.id == scope.user_id,
            UniversalUser.division_id.in_(divisions),
            UniversalUser.id.in_(
                select(UserDivision.user_id)
                .where(UserDivision.division_id.in_(divisions))
                .correlate(None)
                .scalar_subquery()
            ),
        )
    )


# ---------------------------------------------------------------------------
# Одиночные проверки по id
# ---------------------------------------------------------------------------


def has_personal_work_on_object(db, scope: AccessScope, object_id) -> bool:
    """Есть ли у человека на этом лифте своя работа или своя заявка.

    Пара к `personal_work_object_ids`: тот режет список, эта отвечает про одну
    запись. Условие у них общее — иначе объект из списка открывался бы с 403.
    """
    if db is None or object_id is None:
        return False
    return db.query(
        select(Object.id)
        .where(Object.id == object_id)
        .where(Object.id.in_(personal_work_object_ids(scope)))
        .exists()
    ).scalar()


def can_access_object(scope: AccessScope, obj, db=None) -> bool:
    """Доступен ли конкретный объект (лифт) в этой области.

    Для одиночной проверки по id. Списки фильтруются запросом, а не этой
    функцией.

    `db` необязателен: без него «своя работа или заявка на этом лифте» не
    проверяется, и ответ получается строже, чем у списка. Передавать его надо
    везде, где сессия под рукой; там, где её нет, вызывающий уже проверил
    личное участие по своей оси — так делают `can_access_order` и
    `can_access_act_fact`.
    """
    if scope.kind is ScopeKind.ALL:
        return True
    if scope.kind is ScopeKind.NOTHING or obj is None:
        return False
    if scope.kind is ScopeKind.DIVISIONS:
        return (
            obj.division_id in scope.division_ids
            or obj.foreman_id == scope.user_id
            or obj.mechanic_id == scope.user_id
            or has_personal_work_on_object(db, scope, getattr(obj, "id", None))
        )
    if scope.kind is ScopeKind.ASSIGNED:
        return (
            obj.mechanic_id == scope.user_id
            or obj.foreman_id == scope.user_id
            or has_personal_work_on_object(db, scope, getattr(obj, "id", None))
        )
    if scope.kind is ScopeKind.COMPANY:
        return scope.company_id is not None and obj.company_id == scope.company_id
    return False


def can_access_order(scope: AccessScope, order) -> bool:
    """Доступна ли заявка. Наследует доступ от объекта, плюс личное участие."""
    if scope.kind is ScopeKind.ALL:
        return True
    if scope.kind is ScopeKind.NOTHING or order is None:
        return False
    if order.executor_id == scope.user_id or order.creator_id == scope.user_id:
        # Свою заявку человек видит всегда: иначе механик потеряет доступ к
        # уже выполненной работе, если объект переназначат другому.
        return True
    return can_access_object(scope, order.object)


def can_access_act_fact(scope: AccessScope, act) -> bool:
    """Доступен ли фактический акт. Как заявка: объект плюс личное участие."""
    if scope.kind is ScopeKind.ALL:
        return True
    if scope.kind is ScopeKind.NOTHING or act is None:
        return False
    if act.foreman_id == scope.user_id or act.main_mechanic_id == scope.user_id:
        return True
    return can_access_object(scope, act.object)


def can_access_planned_to(scope: AccessScope, planned) -> bool:
    """Доступно ли плановое ТО. Целиком наследует доступ от объекта."""
    if scope.kind is ScopeKind.ALL:
        return True
    if scope.kind is ScopeKind.NOTHING or planned is None:
        return False
    return can_access_object(scope, planned.object)


def can_access_defective_act(scope: AccessScope, act) -> bool:
    """Доступна ли дефектная ведомость: через объект, плюс своё участие."""
    if scope.kind is ScopeKind.ALL:
        return True
    if scope.kind is ScopeKind.NOTHING or act is None:
        return False
    if (
        act.responsible_user_id == scope.user_id
        or act.created_by_user_id == scope.user_id
    ):
        return True
    return can_access_object(scope, act.object)


def can_access_user(scope: AccessScope, user) -> bool:
    """Виден ли человек. Правила те же, что у `apply_user_scope`."""
    if scope.kind is ScopeKind.ALL:
        return True
    if user is None:
        return False
    if user.id == scope.user_id:
        return True
    if scope.kind is ScopeKind.NOTHING:
        return False
    if scope.kind is ScopeKind.COMPANY:
        return scope.company_id is not None and user.company_id == scope.company_id
    if user.division_id in scope.division_ids:
        return True
    return any(division.id in scope.division_ids for division in user.divisions)
