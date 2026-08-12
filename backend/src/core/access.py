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

from src.core.roles import Role
from src.models import UniversalUser


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


def can_access_object(scope: AccessScope, obj) -> bool:
    """Доступен ли конкретный объект (лифт) в этой области.

    Для одиночной проверки по id. Списки фильтруются запросом, а не этой
    функцией.
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
        )
    if scope.kind is ScopeKind.ASSIGNED:
        return obj.mechanic_id == scope.user_id or obj.foreman_id == scope.user_id
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
