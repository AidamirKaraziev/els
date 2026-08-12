"""Матрица прав и область видимости.

Проверяется не «код работает», а согласованные с заказчиком правила из
заметки «матрица прав по ролям». Если правила поменяются — эти тесты должны
упасть первыми.
"""

from types import SimpleNamespace

import pytest

from src.core.access import (
    AccessScope,
    ScopeKind,
    can_access_object,
    can_access_order,
    read_scope,
    write_scope,
)
from src.core.permissions import Permission, has_permission, permissions_for
from src.core.roles import Role

# --- права ----------------------------------------------------------------


def test_админ_может_всё():
    assert permissions_for(Role.ADMIN) == frozenset(Permission)


def test_неизвестная_роль_не_получает_ничего():
    # `role_id` в базе обнуляемый: пользователь без роли не должен уронить
    # запрос, но и прав у него нет.
    assert permissions_for(None) == frozenset()
    assert permissions_for(0) == frozenset()
    assert permissions_for(999) == frozenset()


def test_диспетчер_ведёт_заявки_но_не_закрывает_их():
    # Согласовано: «видит всё, создаёт везде, закрывать не может».
    assert has_permission(Role.DISPATCHER, Permission.ORDER_CREATE)
    assert has_permission(Role.DISPATCHER, Permission.ORDER_UPDATE)
    assert not has_permission(Role.DISPATCHER, Permission.ORDER_CLOSE)


def test_закрыть_заявку_может_исполнитель_или_прораб():
    for role in (Role.MECHANIC, Role.ENGINEER, Role.FOREMAN, Role.ADMIN):
        assert has_permission(role, Permission.ORDER_CLOSE), role


def test_у_механика_и_инженера_права_совпадают():
    # Отличаются они не правами, а тем, на какие объекты их можно назначить.
    assert permissions_for(Role.MECHANIC) == permissions_for(Role.ENGINEER)


def test_клиент_только_заводит_заявки():
    assert has_permission(Role.CLIENT, Permission.ORDER_CREATE)
    assert has_permission(Role.CLIENT, Permission.ORDER_READ)
    assert has_permission(Role.CLIENT, Permission.OBJECT_READ)
    for запрещено in (
        Permission.OBJECT_CREATE,
        Permission.OBJECT_UPDATE,
        Permission.ORDER_CLOSE,
        Permission.USER_READ,
        Permission.USER_CREATE,
        Permission.ACT_READ,
        Permission.DIRECTORY_WRITE,
        Permission.COUNTERPARTY_READ,
    ):
        assert not has_permission(Role.CLIENT, запрещено), запрещено


def test_справочники_правит_только_админ():
    for role in (
        Role.FOREMAN,
        Role.MECHANIC,
        Role.ENGINEER,
        Role.DISPATCHER,
        Role.CLIENT,
    ):
        assert has_permission(role, Permission.DIRECTORY_READ), role
        assert not has_permission(role, Permission.DIRECTORY_WRITE), role


def test_удалять_людей_может_только_админ():
    # Удаление пользователя обнуляет автора у его заявок, поэтому право
    # оставлено одному админу, а прораб может только архивировать.
    for role in Role:
        if role is Role.ADMIN:
            continue
        assert not has_permission(role, Permission.USER_DELETE), role
    assert has_permission(Role.FOREMAN, Permission.USER_ARCHIVE)


def test_прораб_ведёт_своих_людей():
    for право in (
        Permission.USER_CREATE,
        Permission.USER_UPDATE,
        Permission.USER_ARCHIVE,
    ):
        assert has_permission(Role.FOREMAN, право), право
        assert not has_permission(Role.MECHANIC, право), право
        assert not has_permission(Role.DISPATCHER, право), право


# --- область видимости ----------------------------------------------------


def _пользователь(role, *, user_id=10, divisions=(), division_id=None, company_id=None):
    return SimpleNamespace(
        id=user_id,
        role_id=int(role) if role is not None else None,
        divisions=[SimpleNamespace(id=i) for i in divisions],
        division_id=division_id,
        company_id=company_id,
    )


def _объект(*, division_id=None, foreman_id=None, mechanic_id=None, company_id=None):
    return SimpleNamespace(
        division_id=division_id,
        foreman_id=foreman_id,
        mechanic_id=mechanic_id,
        company_id=company_id,
    )


def test_админ_видит_и_меняет_всё():
    админ = _пользователь(Role.ADMIN)
    assert read_scope(админ).unrestricted
    assert write_scope(админ).unrestricted


def test_прораб_видит_всё_а_меняет_свои_участки():
    прораб = _пользователь(Role.FOREMAN, divisions=(1, 2))
    assert read_scope(прораб).unrestricted

    на_запись = write_scope(прораб)
    assert на_запись.kind is ScopeKind.DIVISIONS
    assert на_запись.division_ids == frozenset({1, 2})
    assert can_access_object(на_запись, _объект(division_id=1))
    assert not can_access_object(на_запись, _объект(division_id=7))


def test_прораб_меняет_объект_где_назначен_даже_вне_своего_участка():
    прораб = _пользователь(Role.FOREMAN, user_id=10, divisions=(1,))
    на_запись = write_scope(прораб)
    assert can_access_object(на_запись, _объект(division_id=99, foreman_id=10))


def test_основной_участок_попадает_в_область_даже_без_связи():
    # Страховка от неполных данных: участок мог быть проставлен в обход связи.
    прораб = _пользователь(Role.FOREMAN, divisions=(), division_id=5)
    assert write_scope(прораб).division_ids == frozenset({5})


def test_механик_видит_только_назначенное():
    механик = _пользователь(Role.MECHANIC, user_id=10, divisions=(1,))
    область = read_scope(механик)
    assert область.kind is ScopeKind.ASSIGNED
    assert can_access_object(область, _объект(mechanic_id=10))
    # Свой участок сам по себе доступа не даёт — только личное назначение.
    assert not can_access_object(область, _объект(division_id=1))


def test_инженер_видит_весь_свой_участок():
    инженер = _пользователь(Role.ENGINEER, user_id=10, divisions=(1,))
    область = read_scope(инженер)
    assert область.kind is ScopeKind.DIVISIONS
    assert can_access_object(область, _объект(division_id=1))
    assert can_access_object(область, _объект(division_id=99, mechanic_id=10))
    assert not can_access_object(область, _объект(division_id=99))


def test_диспетчер_работает_по_всем_участкам():
    диспетчер = _пользователь(Role.DISPATCHER, divisions=(3,))
    assert read_scope(диспетчер).unrestricted
    assert write_scope(диспетчер).unrestricted


def test_клиент_видит_только_свою_компанию():
    клиент = _пользователь(Role.CLIENT, company_id=12)
    область = read_scope(клиент)
    assert область.kind is ScopeKind.COMPANY
    assert can_access_object(область, _объект(company_id=12))
    assert not can_access_object(область, _объект(company_id=3))
    # Компания и организация — разные вещи: клиент привязан к компании.
    assert not can_access_object(область, _объект(division_id=1))


def test_пользователь_без_роли_не_видит_ничего():
    область = read_scope(_пользователь(None))
    assert область.kind is ScopeKind.NOTHING
    assert область.empty
    assert not can_access_object(область, _объект(division_id=1, company_id=1))


@pytest.mark.parametrize(
    "пользователь, пусто",
    [
        (_пользователь(Role.ENGINEER, divisions=()), True),
        (_пользователь(Role.ENGINEER, divisions=(1,)), False),
        (_пользователь(Role.CLIENT, company_id=None), True),
        (_пользователь(Role.CLIENT, company_id=1), False),
        (_пользователь(Role.ADMIN), False),
    ],
)
def test_область_без_привязки_считается_пустой(пользователь, пусто):
    # Инженер без участка и клиент без компании не должны видеть всё подряд.
    assert read_scope(пользователь).empty is пусто


def test_заявка_видна_её_автору_и_исполнителю():
    механик = _пользователь(Role.MECHANIC, user_id=10)
    область = read_scope(механик)

    чужой_объект = _объект(mechanic_id=77)
    назначенная = SimpleNamespace(executor_id=10, creator_id=99, object=чужой_объект)
    своя = SimpleNamespace(executor_id=77, creator_id=10, object=чужой_объект)
    чужая = SimpleNamespace(executor_id=77, creator_id=99, object=чужой_объект)

    # Объект переназначили другому, но своя работа должна остаться видимой.
    assert can_access_order(область, назначенная)
    assert can_access_order(область, своя)
    assert not can_access_order(область, чужая)


def test_заявка_наследует_доступ_от_объекта():
    клиент = _пользователь(Role.CLIENT, user_id=10, company_id=12)
    область = read_scope(клиент)

    своя_компания = SimpleNamespace(
        executor_id=None, creator_id=None, object=_объект(company_id=12)
    )
    чужая_компания = SimpleNamespace(
        executor_id=None, creator_id=None, object=_объект(company_id=3)
    )
    assert can_access_order(область, своя_компания)
    assert not can_access_order(область, чужая_компания)


def test_пустая_область_не_ломается_на_отсутствующих_записях():
    область = AccessScope(
        kind=ScopeKind.ASSIGNED, user_id=1, division_ids=frozenset(), company_id=None
    )
    assert not can_access_object(область, None)
    assert not can_access_order(область, None)
