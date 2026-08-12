"""Приёмка по матрице прав: что каждая роль может, а где получает 403.

`test_role_access_on_endpoints` проверяет выборочные ручки, `test_permissions_and_scope`
— саму матрицу как таблицу. Здесь третье: обход **всех групп прав** по живым
ручкам, чтобы согласованное с заказчиком правило нельзя было потерять,
поправив одну зависимость.

Читается как приёмочный документ: строка таблицы — фраза из
«матрицы прав по ролям», и её видно рядом с ответом сервера.
"""

import pytest

from src.config import settings
from src.core.roles import Role

API = settings.API_V1_STR

EMPLOYEES = {Role.ADMIN, Role.FOREMAN, Role.MECHANIC, Role.ENGINEER, Role.DISPATCHER}
FIELD = {Role.ADMIN, Role.FOREMAN, Role.MECHANIC, Role.ENGINEER}

# (что проверяем, метод, путь, кому можно)
CASES = [
    # --- люди ---------------------------------------------------------
    ("список людей нужен всем сотрудникам, чтобы назначить исполнителя",
     "GET", "/cp/all-users/", EMPLOYEES),
    ("клиент до списка людей не допущен",
     "GET", "/cp/all-employee/", EMPLOYEES),
    ("заводит людей админ и прораб",
     "POST", "/cp/admin/create-employee/", {Role.ADMIN, Role.FOREMAN}),
    ("удаляет людей только админ — удаление обнуляет автора у заявок",
     "DELETE", "/cp/admin/universal-user/1/", {Role.ADMIN}),
    # Маршруты админа и прораба параллельные: у каждого свой префикс, и
    # внутри админского осталась проверка роли `[ADMIN]` с прежних времён.
    # Право `USER_ARCHIVE` у прораба есть, но пользуется он своей ручкой —
    # она проверяется отдельно, ниже: ей нужна настоящая цель.
    ("архивирует людей через админский маршрут только админ",
     "GET", "/cp/admin/1/archive/", {Role.ADMIN}),

    # --- объекты ------------------------------------------------------
    ("карточку лифта видит любой сотрудник и клиент",
     "GET", "/all-objects/", set(Role)),
    ("заводит лифты админ и прораб",
     "POST", "/object/", {Role.ADMIN, Role.FOREMAN}),
    ("правит лифты админ и прораб",
     "PUT", "/object/1/", {Role.ADMIN, Role.FOREMAN}),

    # --- заявки -------------------------------------------------------
    ("заявки видят все, включая клиента",
     "GET", "/order/all", set(Role)),
    ("заводит заявку клиент, диспетчер, прораб и админ, но не механик",
     "POST", "/order/", {Role.ADMIN, Role.FOREMAN, Role.DISPATCHER, Role.CLIENT}),
    ("ведёт заявку любой сотрудник, но не клиент",
     "PUT", "/order/1/", EMPLOYEES),

    # --- акты и ТО ----------------------------------------------------
    ("акты клиенту не видны вовсе",
     "GET", "/all-acts-fact/", EMPLOYEES),
    ("фактический акт заводит полевой сотрудник, не диспетчер",
     "POST", "/act-fact/", FIELD),
    ("плановые ТО читают все сотрудники",
     "GET", "/all-planned-to/", EMPLOYEES),
    ("график ТО правят админ и прораб",
     "POST", "/planned-to/", {Role.ADMIN, Role.FOREMAN}),
    ("дефектные ведомости клиенту не видны",
     "GET", "/defective-act/all", EMPLOYEES),

    # --- контрагенты и структура --------------------------------------
    ("контрагенты закрыты от клиента",
     "GET", "/all-organization/", EMPLOYEES),
    ("контрагентов правят админ и прораб",
     "POST", "/company/", {Role.ADMIN, Role.FOREMAN}),
    ("участки — структура организации, правит только админ",
     "POST", "/divisions/", {Role.ADMIN}),

    # --- справочники --------------------------------------------------
    ("справочники читает любой вошедший, включая клиента",
     "GET", "/roles/", set(Role)),
    ("справочники правит только админ",
     "POST", "/locations/", {Role.ADMIN}),

    # --- статистика ---------------------------------------------------
    ("статистику видят все, каждый по своей области",
     "GET", "/statistics/breakdowns?year=2026&month=5", set(Role)),
]


def _denied_by_scope(response) -> bool:
    """403 из-за области видимости, а не из-за права.

    Роли в этом тесте заводятся без участков и компании, поэтому запись,
    которую они имеют право менять, всё равно может оказаться вне области.
    Для приёмки прав это «доступ есть» — см. код 136 в `templates_raise`.
    """
    if response.status_code != 403:
        return False
    errors = response.json().get("errors") or []
    return any(error.get("code") == 136 for error in errors)


@pytest.mark.integration
@pytest.mark.parametrize("rule, method, path, allowed", CASES)
@pytest.mark.parametrize("role", list(Role))
def test_matrix_holds_on_live_endpoints(
    client_with_db, as_role, rule, method, path, allowed, role
):
    as_role(role)

    response = client_with_db.request(method, f"{API}{path}", json={})
    forbidden = response.status_code == 403 and not _denied_by_scope(response)

    if role in allowed:
        assert not forbidden, (
            f"{role.name} потерял доступ: {rule}\n{method} {path} → "
            f"{response.status_code}"
        )
    else:
        assert forbidden, (
            f"{role.name} получил лишний доступ: {rule}\n{method} {path} → "
            f"{response.status_code}"
        )


@pytest.mark.integration
@pytest.mark.parametrize(
    "role, can_close",
    [
        (Role.ADMIN, True),
        (Role.FOREMAN, True),
        (Role.MECHANIC, True),
        (Role.ENGINEER, True),
        (Role.DISPATCHER, False),
    ],
)
def test_dispatcher_cannot_close_an_order(client_with_db, as_role, role, can_close):
    """«Диспетчер ведёт заявку, но в „Выполнено“ переводит исполнитель».

    Право `ORDER_CLOSE` существовало с этапа 2, но до приёмки его не
    спрашивала ни одна ручка: закрытие отличается от обычной правки не
    адресом, а телом запроса, и зависимость на ручке его не ловила.
    """
    as_role(role)

    response = client_with_db.put(
        f"{API}/order/1/", json={"object_id": 1, "status_id": 4}
    )

    if can_close:
        # Заявки №1 в базе нет — важно лишь, что отказ не по праву.
        assert response.status_code != 403, response.text
    else:
        assert response.status_code == 403, (
            "диспетчер закрыл заявку, хотя договорились, что не может"
        )


@pytest.mark.integration
def test_dispatcher_still_leads_the_order(client_with_db, as_role):
    """Запрет точечный: всё остальное в заявке диспетчер менять может."""
    as_role(Role.DISPATCHER)

    response = client_with_db.put(
        f"{API}/order/1/", json={"object_id": 1, "status_id": 3}
    )

    assert response.status_code != 403, response.text


@pytest.mark.integration
def test_foreman_archives_a_mechanic_of_his_division(client_with_db, as_role, db_session):
    """Прораб «заводит, редактирует и архивирует сотрудников своих участков».

    Целью берётся настоящий механик: пользователь №1 — суперадмин, и отказ на
    нём означал бы «админа архивировать нельзя», а не «прорабу не положено».
    """
    import uuid

    from src.models import Division, UniversalUser

    division = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
    db_session.add(division)
    db_session.flush()

    mechanic = UniversalUser(
        name="Механик участка",
        email=f"mech-{uuid.uuid4().hex[:8]}@test",
        role_id=int(Role.MECHANIC),
        is_active=True,
        division_id=division.id,
    )
    db_session.add(mechanic)
    db_session.flush()

    as_role(Role.FOREMAN, division_id=division.id)

    response = client_with_db.get(f"{API}/cp/foreman/{mechanic.id}/archive/")

    assert response.status_code == 200, response.text


@pytest.mark.integration
def test_foreman_does_not_archive_someone_from_another_division(
    client_with_db, as_role, db_session
):
    """Область записи здесь тоже работает: чужой участок — 403 с кодом 136."""
    import uuid

    from src.models import Division, UniversalUser

    mine = Division(title=f"Мой {uuid.uuid4().hex[:6]}")
    other = Division(title=f"Чужой {uuid.uuid4().hex[:6]}")
    db_session.add_all([mine, other])
    db_session.flush()

    stranger = UniversalUser(
        name="Механик с чужого участка",
        email=f"mech-{uuid.uuid4().hex[:8]}@test",
        role_id=int(Role.MECHANIC),
        is_active=True,
        division_id=other.id,
    )
    db_session.add(stranger)
    db_session.flush()

    as_role(Role.FOREMAN, division_id=mine.id)

    response = client_with_db.get(f"{API}/cp/foreman/{stranger.id}/archive/")

    assert response.status_code == 403
    assert _denied_by_scope(response), "отказ должен быть по области, а не по праву"
