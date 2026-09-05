"""Ручки дефектных актов: четыре точки входа, лента по объекту, клиентский акт.

Проверяем через живые ручки, а не через CRUD: половина правил этапа — про
контракт (что можно не присылать) и про доступ (чужая ссылка не должна дать
завести акт на чужом лифте), а это видно только на границе.

Расклад один на все проверки: два участка, два лифта, у своего есть работа по
ТО, аварийная заявка и плановое ТО. Механик привязан к участку А и назначен на
свой лифт — всё, что лежит на чужом, для него не существует.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import (
    ActBase,
    ActFact,
    Company,
    DefectiveAct,
    DefectiveActPhoto,
    Division,
    Object,
    Order,
    PlannedTO,
    TypeAct,
)

API = settings.API_V1_STR


@pytest.fixture
def world(db_session):
    """Два лифта на разных участках и все четыре привязки у своего."""
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
    company = Company(name=f"Компания {prefix}")
    db_session.add_all([division_a, division_b, company])
    db_session.flush()

    own_lift = make_object(division_id=division_a.id, company_id=company.id)
    other_lift = make_object(division_id=division_b.id, company_id=company.id)

    own_act_fact = ActFact(object_id=own_lift.id)
    other_act_fact = ActFact(object_id=other_lift.id)
    own_plan = PlannedTO(year="2026", object_id=own_lift.id)
    # `creator_id` обязателен в схеме ответа; суперадмин с id=1 заводится сидером.
    own_order = Order(
        object_id=own_lift.id,
        creator_id=1,
        created_at=datetime.datetime(2026, 5, 10),
        fault_category_id=2,
        task_text="своя заявка",
    )
    db_session.add_all([own_act_fact, other_act_fact, own_plan, own_order])
    db_session.flush()

    return {
        "division_a": division_a,
        "own_lift": own_lift,
        "other_lift": other_lift,
        "own_act_fact": own_act_fact,
        "other_act_fact": other_act_fact,
        "own_plan": own_plan,
        "own_order": own_order,
    }


@pytest.fixture
def mechanic(as_role, world, db_session):
    """Механик участка А, назначенный на свой лифт."""
    user = as_role(Role.MECHANIC, division_id=world["division_a"].id)
    world["own_lift"].mechanic_id = user.id
    db_session.flush()
    return user


def _create(client, **body):
    return client.post(f"{API}/defective-act/", json={"title": "трос", **body})


# --- четыре точки входа ----------------------------------------------------


@pytest.mark.integration
def test_act_can_be_created_from_the_object_alone(client_with_db, world, mechanic):
    """Пункт меню: известен только лифт."""
    response = _create(client_with_db, object_id=world["own_lift"].id)

    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["object_id"] == world["own_lift"].id
    assert data["month"] is None
    assert data["state"] == "created"
    assert data["kind"] == "internal"


@pytest.mark.integration
def test_act_from_the_work_carries_its_object(client_with_db, world, mechanic):
    response = _create(
        client_with_db, act_fact_id=world["own_act_fact"].id, checklist_step_id=3
    )

    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["act_fact_id"] == world["own_act_fact"].id
    assert data["checklist_step_id"] == 3
    assert data["object_id"] == world["own_lift"].id


@pytest.mark.integration
def test_act_from_the_order_carries_its_object(client_with_db, world, mechanic):
    response = _create(client_with_db, order_id=world["own_order"].id)

    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["order_id"] == world["own_order"].id
    assert data["object_id"] == world["own_lift"].id


@pytest.fixture
def work_of_a_known_kind(db_session, world):
    """Работа по ТО, у которой шаблон и вид ТО заполнены.

    В `world` работа заведена голой: `act_base_id` там пуст, и вид ТО у неё
    взяться неоткуда. Здесь достраивается вторая — та, что видел бы прораб.
    """
    # id у `types_acts` не автоинкрементный — назначается руками.
    kind = TypeAct(id=next_type_act_id(db_session), name=f"ТО-1 {uuid.uuid4().hex[:8]}")
    db_session.add(kind)
    db_session.flush()

    base = ActBase(type_act_id=kind.id)
    db_session.add(base)
    db_session.flush()

    work = ActFact(object_id=world["own_lift"].id, act_base_id=base.id)
    db_session.add(work)
    db_session.flush()
    return {"kind": kind, "work": work}


def next_type_act_id(db_session):
    largest = db_session.query(TypeAct).order_by(TypeAct.id.desc()).first()
    return (largest.id + 1) if largest is not None else 1


@pytest.mark.integration
def test_work_defect_carries_the_kind_of_maintenance(
    client_with_db, world, mechanic, work_of_a_known_kind
):
    """Вид ТО разворачивается в ответе: цепочку с фронта пройти нечем."""
    response = _create(client_with_db, act_fact_id=work_of_a_known_kind["work"].id)

    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["type_act"] == {
        "id": work_of_a_known_kind["kind"].id,
        "name": work_of_a_known_kind["kind"].name,
    }


@pytest.mark.integration
def test_order_defect_has_no_kind_of_maintenance(client_with_db, world, mechanic):
    """У акта по заявке работы по ТО нет вовсе — поле пустое, а не выдумано."""
    response = _create(client_with_db, order_id=world["own_order"].id)

    assert response.status_code == 200, response.text
    assert response.json()["data"]["type_act"] is None


@pytest.mark.integration
def test_work_without_a_template_does_not_break_the_feed(
    client_with_db, world, mechanic
):
    """`act_base_id` снимается по `SET NULL` — лента такую запись переживает."""
    created = _create(client_with_db, act_fact_id=world["own_act_fact"].id)
    assert created.status_code == 200, created.text

    feed = client_with_db.get(
        f"{API}/defective-act/by-object/{world['own_lift'].id}/?year=2026"
    )

    assert feed.status_code == 200, feed.text
    assert [row["type_act"] for row in feed.json()["data"]] == [None]


@pytest.mark.integration
def test_old_body_still_works(client_with_db, world, mechanic):
    """Старый клиент шлёт плановое ТО и месяц — и получает прежний результат."""
    response = _create(client_with_db, planned_to_id=world["own_plan"].id, month=5)

    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["month"] == 5
    assert data["object_id"] == world["own_lift"].id


@pytest.mark.integration
def test_act_without_any_link_is_refused(client_with_db, world, mechanic):
    assert _create(client_with_db).status_code == 422


@pytest.mark.integration
def test_conflicting_links_are_refused(client_with_db, world, mechanic, db_session):
    """Две привязки на разные лифты — ошибка вызывающего, а не выбор старшей."""
    world["other_lift"].mechanic_id = mechanic.id
    db_session.flush()

    response = _create(
        client_with_db,
        object_id=world["own_lift"].id,
        act_fact_id=world["other_act_fact"].id,
    )

    assert response.status_code == 422


@pytest.mark.integration
def test_foreign_link_does_not_create_anything(client_with_db, world, mechanic):
    """Чужая работа по ТО не даёт завести акт на чужом лифте."""
    response = _create(client_with_db, act_fact_id=world["other_act_fact"].id)

    assert response.status_code == 403


# --- лента и счётчик -------------------------------------------------------


@pytest.fixture
def acts_of_two_years(world, db_session):
    """Два акта своего лифта за 2026 и один за 2025."""
    made = []
    for created_at in (
        datetime.datetime(2026, 3, 1),
        datetime.datetime(2026, 7, 1),
        datetime.datetime(2025, 7, 1),
    ):
        act = DefectiveAct(
            object_id=world["own_lift"].id,
            title=f"акт {created_at.year}",
            created_at=created_at,
            updated_at=created_at,
        )
        db_session.add(act)
        made.append(act)
    db_session.flush()
    return made


@pytest.mark.integration
def test_feed_by_object_is_cut_by_year(
    client_with_db, world, mechanic, acts_of_two_years
):
    response = client_with_db.get(
        f"{API}/defective-act/by-object/{world['own_lift'].id}/?year=2026"
    )

    assert response.status_code == 200, response.text
    seen = {item["id"] for item in response.json()["data"]}
    assert seen == {acts_of_two_years[0].id, acts_of_two_years[1].id}


@pytest.mark.integration
def test_counter_matches_the_feed(client_with_db, world, mechanic, acts_of_two_years):
    response = client_with_db.get(
        f"{API}/defective-act/by-object/{world['own_lift'].id}/count/?year=2026"
    )

    assert response.status_code == 200, response.text
    assert response.json()["data"] == 2


@pytest.mark.integration
def test_feed_of_a_foreign_lift_is_forbidden(client_with_db, world, mechanic):
    response = client_with_db.get(
        f"{API}/defective-act/by-object/{world['other_lift'].id}/?year=2026"
    )

    assert response.status_code == 403


# --- состояние -------------------------------------------------------------


@pytest.mark.integration
def test_state_moves(client_with_db, world, mechanic):
    act_id = _create(client_with_db, object_id=world["own_lift"].id).json()["data"]["id"]

    response = client_with_db.put(
        f"{API}/defective-act/{act_id}/state/", json={"state": "fixed"}
    )

    assert response.status_code == 200, response.text
    assert response.json()["data"]["state"] == "fixed"


@pytest.mark.integration
def test_unknown_state_is_refused(client_with_db, world, mechanic):
    act_id = _create(client_with_db, object_id=world["own_lift"].id).json()["data"]["id"]

    response = client_with_db.put(
        f"{API}/defective-act/{act_id}/state/", json={"state": "починили"}
    )

    assert response.status_code == 422


# --- оформление клиенту ----------------------------------------------------


@pytest.fixture
def act_with_photos(world, mechanic, db_session):
    act = DefectiveAct(object_id=world["own_lift"].id, title="износ троса")
    db_session.add(act)
    db_session.flush()
    photos = [
        DefectiveActPhoto(defective_act_id=act.id, photo=f"defective_act/{n}.jpg")
        for n in (1, 2)
    ]
    db_session.add_all(photos)
    db_session.flush()
    return act, photos


@pytest.mark.integration
def test_issue_to_client_creates_a_second_record(
    client_with_db, db_session, act_with_photos
):
    act, photos = act_with_photos

    response = client_with_db.post(
        f"{API}/defective-act/{act.id}/issue-to-client/",
        json={
            "client_title": "Требуется замена троса",
            "client_description": "Смотри фото",
            "photo_ids": [photos[0].id],
        },
    )

    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["id"] != act.id
    assert data["kind"] == "client"
    assert data["parent_id"] == act.id
    assert data["client_title"] == "Требуется замена троса"
    assert [photo["id"] for photo in data["client_photos"]] == [photos[0].id]
    # Первоисточник не правится, но отмечается оформленным.
    db_session.refresh(act)
    assert act.state == "issued"
    assert act.title == "износ троса"


@pytest.mark.integration
def test_client_texts_default_to_the_internal_ones(client_with_db, act_with_photos):
    act, _ = act_with_photos

    response = client_with_db.post(
        f"{API}/defective-act/{act.id}/issue-to-client/", json={"photo_ids": []}
    )

    assert response.status_code == 200, response.text
    assert response.json()["data"]["client_title"] == "износ троса"


@pytest.mark.integration
def test_foreign_photo_cannot_be_issued(
    client_with_db, db_session, world, act_with_photos
):
    act, _ = act_with_photos
    stranger = DefectiveAct(object_id=world["own_lift"].id, title="другой акт")
    db_session.add(stranger)
    db_session.flush()
    stranger_photo = DefectiveActPhoto(
        defective_act_id=stranger.id, photo="defective_act/9.jpg"
    )
    db_session.add(stranger_photo)
    db_session.flush()

    response = client_with_db.post(
        f"{API}/defective-act/{act.id}/issue-to-client/",
        json={"photo_ids": [stranger_photo.id]},
    )

    assert response.status_code == 422


@pytest.mark.integration
def test_client_acts_stay_out_of_the_feed(client_with_db, world, act_with_photos):
    act, photos = act_with_photos
    client_with_db.post(
        f"{API}/defective-act/{act.id}/issue-to-client/",
        json={"photo_ids": [photos[0].id]},
    )

    year = datetime.datetime.utcnow().year
    response = client_with_db.get(
        f"{API}/defective-act/by-object/{world['own_lift'].id}/?year={year}"
    )

    assert response.status_code == 200, response.text
    assert {item["id"] for item in response.json()["data"]} == {act.id}


# --- PDF -------------------------------------------------------------------


@pytest.mark.integration
def test_pdf_is_built_for_an_act_without_planned_to(client_with_db, act_with_photos):
    """Акт, заведённый по объекту: планового ТО нет, а лист собраться обязан."""
    act, _ = act_with_photos

    response = client_with_db.post(f"{API}/defective-act/{act.id}/pdf/")

    assert response.status_code == 200, response.text
    assert response.json()["data"]["pdf_file"]


@pytest.mark.integration
def test_pdf_of_the_client_act_takes_its_own_texts(
    client_with_db, db_session, act_with_photos
):
    act, photos = act_with_photos
    issued = client_with_db.post(
        f"{API}/defective-act/{act.id}/issue-to-client/",
        json={
            "client_title": "Требуется замена троса",
            "photo_ids": [photos[0].id],
        },
    ).json()["data"]

    response = client_with_db.post(f"{API}/defective-act/{issued['id']}/pdf/")

    assert response.status_code == 200, response.text
    assert response.json()["data"]["pdf_file"]


@pytest.mark.integration
def test_pdf_of_a_foreign_act_is_refused(client_with_db, world, db_session, mechanic):
    stranger = DefectiveAct(object_id=world["other_lift"].id, title="чужой акт")
    db_session.add(stranger)
    db_session.flush()

    response = client_with_db.post(f"{API}/defective-act/{stranger.id}/pdf/")

    assert response.status_code in (403, 404)
