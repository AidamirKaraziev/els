"""Роли на живых ручках: кому 200, кому 403.

Предыдущий тест следит, что доступ у ручки *объявлен*. Этот проверяет, что
объявлено правильно — на нескольких показательных ручках из каждой области.
Раньше любой залогиненный мог дёрнуть любую из них.
"""

import pytest

from src.core.roles import Role

# (метод, путь, кому можно) — «можно» здесь про право, а не про конкретную
# запись: 404 или 422 от несуществующего id нас устраивают, лишь бы не 403.
CASES = [
    # Справочники читает любой, кто вошёл, — включая клиента. Правит админ.
    ("GET", "/api/v1/roles/", set(Role)),
    ("POST", "/api/v1/locations/", {Role.ADMIN}),
    ("POST", "/api/v1/working-specialty/", {Role.ADMIN}),
    # Объекты создаёт и правит админ с прорабом.
    ("POST", "/api/v1/object/", {Role.ADMIN, Role.FOREMAN}),
    # Заявки: клиент заводит, диспетчер тоже, механик — нет.
    (
        "POST",
        "/api/v1/order/",
        {Role.ADMIN, Role.FOREMAN, Role.DISPATCHER, Role.CLIENT},
    ),
    # Люди: заводит админ и прораб, удаляет только админ.
    ("POST", "/api/v1/cp/admin/create-employee/", {Role.ADMIN, Role.FOREMAN}),
    ("DELETE", "/api/v1/cp/admin/universal-user/1/", {Role.ADMIN}),
    # Контрагенты закрыты от клиента и полевых сотрудников.
    ("POST", "/api/v1/company/", {Role.ADMIN, Role.FOREMAN}),
    (
        "GET",
        "/api/v1/all-organization/",
        {Role.ADMIN, Role.FOREMAN, Role.MECHANIC, Role.ENGINEER, Role.DISPATCHER},
    ),
    # Участки — структура организации, только админ.
    ("POST", "/api/v1/divisions/", {Role.ADMIN}),
    # Акты клиенту не видны вовсе.
    (
        "GET",
        "/api/v1/acts-bases/",
        {Role.ADMIN, Role.FOREMAN, Role.MECHANIC, Role.ENGINEER, Role.DISPATCHER},
    ),
]


def _call(client, method, path):
    return client.request(method, path, json={})


@pytest.mark.integration
@pytest.mark.parametrize("method, path, allowed", CASES)
@pytest.mark.parametrize("role", list(Role))
def test_role_access(client_with_db, as_role, method, path, allowed, role):
    as_role(role)
    response = _call(client_with_db, method, path)

    if role in allowed:
        assert response.status_code != 403, (
            f"{role.name} должен иметь доступ к {method} {path}, "
            f"а получил {response.status_code}"
        )
    else:
        assert response.status_code == 403, (
            f"{role.name} не должен иметь доступа к {method} {path}, "
            f"а получил {response.status_code}"
        )


@pytest.mark.integration
def test_user_without_role_is_locked_out(client_with_db, as_role):
    """Пользователь без роли не должен открывать систему.

    `role_id` в базе обнуляемый (`ondelete="SET NULL"`), так что это не
    выдумка: удаление роли оставит человека ровно в таком состоянии.
    Несуществующий id роли подставить нельзя — внешний ключ не даст.
    """
    as_role(None)
    assert _call(client_with_db, "GET", "/api/v1/roles/").status_code == 403


@pytest.mark.integration
def test_own_profile_is_open_to_everyone_logged_in(client_with_db, as_role):
    # Свой профиль не требует прав: иначе человек не увидит даже себя.
    for role in Role:
        as_role(role)
        assert client_with_db.get("/api/v1/auth/me").status_code == 200
