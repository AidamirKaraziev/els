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


def test_admin_can_do_everything():
    assert permissions_for(Role.ADMIN) == frozenset(Permission)


def test_unknown_role_gets_nothing():
    # `role_id` в базе обнуляемый: пользователь без роли не должен уронить
    # запрос, но и прав у него нет.
    assert permissions_for(None) == frozenset()
    assert permissions_for(0) == frozenset()
    assert permissions_for(999) == frozenset()


def test_dispatcher_runs_orders_but_cannot_close_them():
    # Согласовано: «видит всё, создаёт везде, закрывать не может».
    assert has_permission(Role.DISPATCHER, Permission.ORDER_CREATE)
    assert has_permission(Role.DISPATCHER, Permission.ORDER_UPDATE)
    assert not has_permission(Role.DISPATCHER, Permission.ORDER_CLOSE)


def test_order_is_closed_by_executor_or_foreman():
    for role in (Role.MECHANIC, Role.ENGINEER, Role.FOREMAN, Role.ADMIN):
        assert has_permission(role, Permission.ORDER_CLOSE), role


def test_mechanic_and_engineer_share_permissions():
    # Отличаются они не правами, а тем, на какие объекты их можно назначить.
    assert permissions_for(Role.MECHANIC) == permissions_for(Role.ENGINEER)


def test_client_can_only_create_orders():
    assert has_permission(Role.CLIENT, Permission.ORDER_CREATE)
    assert has_permission(Role.CLIENT, Permission.ORDER_READ)
    assert has_permission(Role.CLIENT, Permission.OBJECT_READ)
    for forbidden in (
        Permission.OBJECT_CREATE,
        Permission.OBJECT_UPDATE,
        Permission.ORDER_CLOSE,
        Permission.USER_READ,
        Permission.USER_CREATE,
        Permission.ACT_READ,
        Permission.DIRECTORY_WRITE,
        Permission.COUNTERPARTY_READ,
    ):
        assert not has_permission(Role.CLIENT, forbidden), forbidden


def test_only_admin_edits_directories():
    for role in (
        Role.FOREMAN,
        Role.MECHANIC,
        Role.ENGINEER,
        Role.DISPATCHER,
        Role.CLIENT,
    ):
        assert has_permission(role, Permission.DIRECTORY_READ), role
        assert not has_permission(role, Permission.DIRECTORY_WRITE), role


def test_only_admin_deletes_users():
    # Удаление пользователя обнуляет автора у его заявок, поэтому право
    # оставлено одному админу, а прораб может только архивировать.
    for role in Role:
        if role is Role.ADMIN:
            continue
        assert not has_permission(role, Permission.USER_DELETE), role
    assert has_permission(Role.FOREMAN, Permission.USER_ARCHIVE)


def test_foreman_manages_his_people():
    for permission in (
        Permission.USER_CREATE,
        Permission.USER_UPDATE,
        Permission.USER_ARCHIVE,
    ):
        assert has_permission(Role.FOREMAN, permission), permission
        assert not has_permission(Role.MECHANIC, permission), permission
        assert not has_permission(Role.DISPATCHER, permission), permission


# --- область видимости ----------------------------------------------------


def _user(role, *, user_id=10, divisions=(), division_id=None, company_id=None):
    return SimpleNamespace(
        id=user_id,
        role_id=int(role) if role is not None else None,
        divisions=[SimpleNamespace(id=i) for i in divisions],
        division_id=division_id,
        company_id=company_id,
    )


def _lift(*, division_id=None, foreman_id=None, mechanic_id=None, company_id=None):
    return SimpleNamespace(
        division_id=division_id,
        foreman_id=foreman_id,
        mechanic_id=mechanic_id,
        company_id=company_id,
    )


def test_admin_sees_and_changes_everything():
    admin = _user(Role.ADMIN)
    assert read_scope(admin).unrestricted
    assert write_scope(admin).unrestricted


def test_foreman_sees_everything_but_changes_his_divisions():
    foreman = _user(Role.FOREMAN, divisions=(1, 2))
    assert read_scope(foreman).unrestricted

    for_write = write_scope(foreman)
    assert for_write.kind is ScopeKind.DIVISIONS
    assert for_write.division_ids == frozenset({1, 2})
    assert can_access_object(for_write, _lift(division_id=1))
    assert not can_access_object(for_write, _lift(division_id=7))


def test_foreman_changes_lift_he_is_assigned_to_outside_his_division():
    foreman = _user(Role.FOREMAN, user_id=10, divisions=(1,))
    for_write = write_scope(foreman)
    assert can_access_object(for_write, _lift(division_id=99, foreman_id=10))


def test_main_division_counts_even_without_the_link():
    # Страховка от неполных данных: участок мог быть проставлен в обход связи.
    foreman = _user(Role.FOREMAN, divisions=(), division_id=5)
    assert write_scope(foreman).division_ids == frozenset({5})


def test_mechanic_sees_only_assigned_lifts():
    mechanic = _user(Role.MECHANIC, user_id=10, divisions=(1,))
    scope = read_scope(mechanic)
    assert scope.kind is ScopeKind.ASSIGNED
    assert can_access_object(scope, _lift(mechanic_id=10))
    # Свой участок сам по себе доступа не даёт — только личное назначение.
    assert not can_access_object(scope, _lift(division_id=1))


def test_engineer_sees_his_whole_division():
    engineer = _user(Role.ENGINEER, user_id=10, divisions=(1,))
    scope = read_scope(engineer)
    assert scope.kind is ScopeKind.DIVISIONS
    assert can_access_object(scope, _lift(division_id=1))
    assert can_access_object(scope, _lift(division_id=99, mechanic_id=10))
    assert not can_access_object(scope, _lift(division_id=99))


def test_dispatcher_works_across_all_divisions():
    dispatcher = _user(Role.DISPATCHER, divisions=(3,))
    assert read_scope(dispatcher).unrestricted
    assert write_scope(dispatcher).unrestricted


def test_client_sees_only_his_company():
    client = _user(Role.CLIENT, company_id=12)
    scope = read_scope(client)
    assert scope.kind is ScopeKind.COMPANY
    assert can_access_object(scope, _lift(company_id=12))
    assert not can_access_object(scope, _lift(company_id=3))
    # Компания и организация — разные вещи: клиент привязан к компании.
    assert not can_access_object(scope, _lift(division_id=1))


def test_user_without_role_sees_nothing():
    scope = read_scope(_user(None))
    assert scope.kind is ScopeKind.NOTHING
    assert scope.empty
    assert not can_access_object(scope, _lift(division_id=1, company_id=1))


@pytest.mark.parametrize(
    "user, is_empty",
    [
        (_user(Role.ENGINEER, divisions=()), True),
        (_user(Role.ENGINEER, divisions=(1,)), False),
        (_user(Role.CLIENT, company_id=None), True),
        (_user(Role.CLIENT, company_id=1), False),
        (_user(Role.ADMIN), False),
    ],
)
def test_scope_without_binding_is_empty(user, is_empty):
    # Инженер без участка и клиент без компании не должны видеть всё подряд.
    assert read_scope(user).empty is is_empty


def test_order_is_visible_to_its_author_and_executor():
    mechanic = _user(Role.MECHANIC, user_id=10)
    scope = read_scope(mechanic)

    someone_elses_lift = _lift(mechanic_id=77)
    assigned = SimpleNamespace(executor_id=10, creator_id=99, object=someone_elses_lift)
    created = SimpleNamespace(executor_id=77, creator_id=10, object=someone_elses_lift)
    foreign = SimpleNamespace(executor_id=77, creator_id=99, object=someone_elses_lift)

    # Объект переназначили другому, но своя работа должна остаться видимой.
    assert can_access_order(scope, assigned)
    assert can_access_order(scope, created)
    assert not can_access_order(scope, foreign)


def test_order_inherits_access_from_its_lift():
    client = _user(Role.CLIENT, user_id=10, company_id=12)
    scope = read_scope(client)

    own_company = SimpleNamespace(
        executor_id=None, creator_id=None, object=_lift(company_id=12)
    )
    other_company = SimpleNamespace(
        executor_id=None, creator_id=None, object=_lift(company_id=3)
    )
    assert can_access_order(scope, own_company)
    assert not can_access_order(scope, other_company)


def test_empty_scope_handles_missing_records():
    scope = AccessScope(
        kind=ScopeKind.ASSIGNED, user_id=1, division_ids=frozenset(), company_id=None
    )
    assert not can_access_object(scope, None)
    assert not can_access_order(scope, None)
