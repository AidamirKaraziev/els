"""Каждая роль видит ровно своё.

Тесты бьют по живым ручкам, а не по функциям области: `can_access_object`
сам по себе давно покрыт (`test_permissions_and_scope`), а этап 5 был про то,
подключён ли он к выдаче. Ошибка здесь не падает и не пишется в лог — ответ
приходит со статусом 200, просто записей в нём больше, чем положено.

Расклад один на все проверки:

* **участок А** — лифт `own_lift`, на нём механик `mechanic`;
* **участок Б** — лифт `other_lift`, он же принадлежит компании клиента;
* у каждого лифта по заявке.

Дальше каждая роль спрашивает список и должна увидеть ровно ожидаемое.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import (
    ActFact,
    Company,
    DefectiveAct,
    Division,
    Object,
    Order,
    PlannedTO,
)

API = settings.API_V1_STR


@pytest.fixture
def world(db_session):
    """Два участка, две компании, два лифта и по заявке на каждом."""
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def make_object(**kwargs):
        number = next(counter)
        obj = Object(
            name=f"Лифт {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            **kwargs,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    division_a = Division(title=f"Участок А {prefix}")
    division_b = Division(title=f"Участок Б {prefix}")
    company_mine = Company(name=f"Компания моя {prefix}")
    company_other = Company(name=f"Компания чужая {prefix}")
    db_session.add_all([division_a, division_b, company_mine, company_other])
    db_session.flush()

    own_lift = make_object(division_id=division_a.id, company_id=company_mine.id)
    other_lift = make_object(division_id=division_b.id, company_id=company_other.id)

    # `creator_id` обязателен в схеме ответа: заявка без автора роняет весь
    # список с 500. Это отдельный известный баг, здесь просто не наступаем на
    # него — суперадмин с id=1 заводится сидером.
    own_order = Order(
        object_id=own_lift.id,
        creator_id=1,
        created_at=datetime.datetime(2026, 5, 10),
        fault_category_id=2,
        task_text="своя заявка",
    )
    other_order = Order(
        object_id=other_lift.id,
        creator_id=1,
        created_at=datetime.datetime(2026, 5, 11),
        fault_category_id=2,
        task_text="чужая заявка",
    )
    db_session.add_all([own_order, other_order])
    db_session.flush()

    return {
        "division_a": division_a,
        "division_b": division_b,
        "company_mine": company_mine,
        "company_other": company_other,
        "own_lift": own_lift,
        "other_lift": other_lift,
        "own_order": own_order,
        "other_order": other_order,
    }


def _ids(response, key="id"):
    assert response.status_code == 200, response.text
    return {item[key] for item in response.json()["data"]}


def _login_on_division_a(as_role, world, role, db_session):
    """Сотрудник, привязанный к участку А и назначенный на его лифт."""
    user = as_role(role, division_id=world["division_a"].id)
    world["own_lift"].mechanic_id = user.id
    db_session.flush()
    return user


# --- объекты ---------------------------------------------------------------


@pytest.mark.integration
def test_admin_sees_every_lift(client_with_db, as_role, world):
    as_role(Role.ADMIN)
    seen = _ids(client_with_db.get(f"{API}/all-objects/"))
    assert {world["own_lift"].id, world["other_lift"].id} <= seen


@pytest.mark.integration
def test_mechanic_sees_only_lifts_he_is_assigned_to(
    client_with_db, as_role, world, db_session
):
    _login_on_division_a(as_role, world, Role.MECHANIC, db_session)

    seen = _ids(client_with_db.get(f"{API}/all-objects/"))

    assert seen == {world["own_lift"].id}, (
        "механик видит лифты, на которые его не назначали"
    )


@pytest.mark.integration
def test_engineer_sees_his_division_and_nothing_else(
    client_with_db, as_role, world, db_session
):
    as_role(Role.ENGINEER, division_id=world["division_a"].id)

    seen = _ids(client_with_db.get(f"{API}/all-objects/"))

    assert seen == {world["own_lift"].id}


@pytest.mark.integration
def test_client_sees_only_lifts_of_his_company(client_with_db, as_role, world):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)

    seen = _ids(client_with_db.get(f"{API}/all-objects/"))

    assert seen == {world["own_lift"].id}, "клиент видит лифты чужой компании"


@pytest.mark.integration
def test_foreman_sees_all_lifts_but_edits_only_his_own(
    client_with_db, as_role, world, db_session
):
    """Согласовано с заказчиком: «видит всё, меняет только свои участки»."""
    as_role(Role.FOREMAN, division_id=world["division_a"].id)

    seen = _ids(client_with_db.get(f"{API}/all-objects/"))
    assert {world["own_lift"].id, world["other_lift"].id} <= seen

    mine = client_with_db.put(
        f"{API}/object/{world['own_lift'].id}/", json={"name": "Переименован"}
    )
    assert mine.status_code == 200

    foreign = client_with_db.put(
        f"{API}/object/{world['other_lift'].id}/", json={"name": "Переименован"}
    )
    assert foreign.status_code == 403


@pytest.mark.integration
def test_user_without_role_sees_no_lifts(client_with_db, as_role, world):
    # `role_id` в базе обнуляемый: удаление роли оставит человека таким.
    as_role(None)
    response = client_with_db.get(f"{API}/all-objects/")
    # 403 по праву либо пустой список — но не чужие лифты.
    assert response.status_code == 403 or _ids(response) == set()


@pytest.mark.integration
def test_client_without_company_sees_nothing_not_everything(
    client_with_db, as_role, world
):
    """Незаполненная компания не должна открывать всю базу."""
    as_role(Role.CLIENT, company_id=None)

    assert _ids(client_with_db.get(f"{API}/all-objects/")) == set()


# --- прямой запрос чужой записи -------------------------------------------


@pytest.mark.integration
def test_foreign_lift_by_id_answers_403_not_data(client_with_db, as_role, world):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)

    own = client_with_db.get(f"{API}/object/{world['own_lift'].id}/")
    foreign = client_with_db.get(f"{API}/object/{world['other_lift'].id}/")

    assert own.status_code == 200
    assert foreign.status_code == 403, "чужой лифт отдаётся по прямому запросу"


@pytest.mark.integration
def test_missing_lift_is_still_404(client_with_db, as_role, world):
    """Область не должна превращать «нет такого» в «нет доступа»."""
    as_role(Role.ADMIN)
    assert client_with_db.get(f"{API}/object/99999999/").status_code == 404


# --- заявки ----------------------------------------------------------------


@pytest.mark.integration
def test_client_sees_only_orders_of_his_lifts(client_with_db, as_role, world):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)

    seen = _ids(client_with_db.get(f"{API}/order/all"))

    assert seen == {world["own_order"].id}


@pytest.mark.integration
def test_mechanic_keeps_his_own_order_after_the_lift_is_reassigned(
    client_with_db, as_role, world, db_session
):
    """Своя работа видна всегда — иначе теряется доступ к уже сделанному."""
    user = as_role(Role.MECHANIC)
    world["other_order"].executor_id = user.id
    db_session.flush()

    seen = _ids(client_with_db.get(f"{API}/order/all"))

    assert seen == {world["other_order"].id}


@pytest.mark.integration
def test_pagination_counter_matches_the_filtered_list(
    client_with_db, as_role, world, db_session
):
    """Фильтр стоит в запросе, поэтому счётчик считает видимое, а не всё.

    Проверка ради этого и написана: фильтрация после выборки дала бы страницу
    из одной записи при `total`, посчитанном по обеим.
    """
    as_role(Role.CLIENT, company_id=world["company_mine"].id)

    body = client_with_db.get(f"{API}/order/all", params={"page": 1}).json()

    assert len(body["data"]) == 1
    assert body["meta"]["paginator"]["total"] == 1


# --- акты, плановые ТО -----------------------------------------------------


@pytest.mark.integration
def test_engineer_sees_acts_of_his_division_only(
    client_with_db, as_role, world, db_session
):
    own_act = ActFact(object_id=world["own_lift"].id)
    other_act = ActFact(object_id=world["other_lift"].id)
    db_session.add_all([own_act, other_act])
    db_session.flush()

    as_role(Role.ENGINEER, division_id=world["division_a"].id)

    seen = _ids(client_with_db.get(f"{API}/all-acts-fact/"))

    assert seen == {own_act.id}


@pytest.mark.integration
def test_engineer_sees_planned_to_of_his_division_only(
    client_with_db, as_role, world, db_session
):
    own_plan = PlannedTO(year="2026", object_id=world["own_lift"].id)
    other_plan = PlannedTO(year="2026", object_id=world["other_lift"].id)
    db_session.add_all([own_plan, other_plan])
    db_session.flush()

    as_role(Role.ENGINEER, division_id=world["division_a"].id)

    seen = _ids(client_with_db.get(f"{API}/all-planned-to/"))

    assert seen == {own_plan.id}


@pytest.mark.integration
def test_defective_acts_follow_the_planned_to(
    client_with_db, as_role, world, db_session
):
    own_plan = PlannedTO(year="2026", object_id=world["own_lift"].id)
    other_plan = PlannedTO(year="2026", object_id=world["other_lift"].id)
    db_session.add_all([own_plan, other_plan])
    db_session.flush()

    mine = DefectiveAct(planned_to_id=own_plan.id, month=5, title="своя ведомость")
    foreign = DefectiveAct(
        planned_to_id=other_plan.id, month=5, title="чужая ведомость"
    )
    db_session.add_all([mine, foreign])
    db_session.flush()

    as_role(Role.ENGINEER, division_id=world["division_a"].id)

    seen = _ids(client_with_db.get(f"{API}/defective-act/all"))

    assert seen == {mine.id}


# --- пользователи ----------------------------------------------------------


@pytest.mark.integration
def test_employee_sees_colleagues_of_his_divisions(
    client_with_db, as_role, world, db_session
):
    """Список людей нужен, чтобы выбрать исполнителя, — но не весь.

    Границу держим по участкам: механик без назначений всё равно должен
    видеть коллег своего участка, иначе передать заявку будет некому.
    """
    from src.models import UniversalUser

    colleague = UniversalUser(
        name="Коллега по участку",
        email=f"colleague-{uuid.uuid4().hex[:8]}@test",
        role_id=int(Role.MECHANIC),
        is_active=True,
        division_id=world["division_a"].id,
    )
    stranger = UniversalUser(
        name="Человек с другого участка",
        email=f"stranger-{uuid.uuid4().hex[:8]}@test",
        role_id=int(Role.MECHANIC),
        is_active=True,
        division_id=world["division_b"].id,
    )
    db_session.add_all([colleague, stranger])
    db_session.flush()

    me = as_role(Role.ENGINEER, division_id=world["division_a"].id)

    seen = _ids(client_with_db.get(f"{API}/cp/all-users/"))

    assert colleague.id in seen
    assert me.id in seen, "человек должен видеть хотя бы себя"
    assert stranger.id not in seen


@pytest.mark.integration
def test_admin_still_sees_everyone(client_with_db, as_role, world, db_session):
    from src.models import UniversalUser

    somebody = UniversalUser(
        name="Кто-то",
        email=f"somebody-{uuid.uuid4().hex[:8]}@test",
        role_id=int(Role.MECHANIC),
        is_active=True,
        division_id=world["division_b"].id,
    )
    db_session.add(somebody)
    db_session.flush()

    as_role(Role.ADMIN)

    assert somebody.id in _ids(client_with_db.get(f"{API}/cp/all-users/"))


# --- статистика ------------------------------------------------------------


def _breakdowns(client, **params):
    params.setdefault("year", 2026)
    params.setdefault("month", 5)
    return client.get(f"{API}/statistics/breakdowns", params=params)


@pytest.mark.integration
def test_statistics_counts_only_what_the_role_can_see(
    client_with_db, as_role, world
):
    as_role(Role.CLIENT, company_id=world["company_mine"].id)

    data = _breakdowns(client_with_db).json()["data"]

    assert data["total_breakdowns"] == 1
    assert [item["object_id"] for item in data["items"]] == [world["own_lift"].id]


@pytest.mark.integration
def test_statistics_filter_cannot_widen_the_scope(client_with_db, as_role, world):
    """Запрошенный `company_id` чужой компании не открывает чужие цифры.

    Фильтры в параметрах — это выбор пользователя, область — граница, за
    которую он выйти не может.
    """
    as_role(Role.CLIENT, company_id=world["company_mine"].id)

    data = _breakdowns(
        client_with_db, company_id=world["company_other"].id
    ).json()["data"]

    assert data["total_breakdowns"] == 0
    assert data["items"] == []


@pytest.mark.integration
def test_statistics_and_order_list_agree(client_with_db, as_role, world):
    """Цифра в сводке и длина списка заявок должны сходиться.

    Разойдись они — виджет выглядит враньём, и объяснить это будет нечем.
    """
    as_role(Role.CLIENT, company_id=world["company_mine"].id)

    total = _breakdowns(client_with_db).json()["data"]["total_breakdowns"]
    orders = client_with_db.get(
        f"{API}/order/all",
        params={"year": 2026, "month": 5, "only_breakdowns": True},
    ).json()["data"]

    assert total == len(orders)
