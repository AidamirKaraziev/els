"""Чек-лист акта по API: хранение каноническое, ответ — прежний.

Экран графика у прораба работает в проде: он читает `step_list_fact` строкой в
своей форме (`numberTo` / `stepListTO`) и пересохраняет её целиком. Поменять
хранение было можно, поломать этот ответ — нет.

Телефон механика работает с полем `checklist` — разобранным, с номерами шагов,
на которые ссылаются фотографии.
"""

import json
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, Role
from src.models import ActFact, Object

URL = settings.API_V1_STR


def _legacy(steps, number="ТО-1"):
    """Ровно то, что кладёт в базу экран графика."""
    return json.dumps(
        {"numberTo": number, "stepListTO": json.dumps(steps, ensure_ascii=False)},
        ensure_ascii=False,
    )


LEGACY_STEPS = [
    {"text": "Осмотр станции управления", "bool": False},
    {"text": "Проверить тормоз", "bool": False},
]


@pytest.fixture
def act(db_session):
    suffix = uuid.uuid4().hex[:8]
    obj = Object(
        name="Лифт с чек-листом",
        factory_number=f"F-{suffix}",
        registration_number=f"R-{suffix}",
    )
    db_session.add(obj)
    db_session.flush()
    act_fact = ActFact(object_id=obj.id)
    db_session.add(act_fact)
    db_session.flush()
    return act_fact


def _put(client, act_id, body):
    return client.put(f"{URL}/act-fact/{act_id}/", json=body)


def _get(client, act_id):
    response = client.get(f"{URL}/act-fact/{act_id}/")
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.mark.integration
def test_old_screen_writes_its_form_and_the_base_keeps_the_canonical_one(
    client_with_db, as_role, db_session, act
):
    as_role(ADMIN)

    response = _put(client_with_db, act.id, {"step_list_fact": _legacy(LEGACY_STEPS)})
    assert response.status_code == 200, response.text

    db_session.refresh(act)
    stored = json.loads(act.step_list_fact)
    assert stored["title"] == "ТО-1"
    assert stored["steps"] == [
        {"id": 1, "title": "Осмотр станции управления", "done": False, "comment": None},
        {"id": 2, "title": "Проверить тормоз", "done": False, "comment": None},
    ]


@pytest.mark.integration
def test_old_screen_reads_back_its_own_form(client_with_db, as_role, act):
    """Хранение поменялось, ответ — нет: иначе экран графика в проде ослепнет."""
    as_role(ADMIN)
    _put(client_with_db, act.id, {"step_list_fact": _legacy(LEGACY_STEPS)})

    legacy = json.loads(_get(client_with_db, act.id)["step_list_fact"])

    assert legacy["numberTo"] == "ТО-1"
    assert [step["text"] for step in json.loads(legacy["stepListTO"])] == [
        "Осмотр станции управления",
        "Проверить тормоз",
    ]


@pytest.mark.integration
def test_python_repr_from_the_base_is_read_and_straightened(
    client_with_db, as_role, db_session, act
):
    """Часть строк попала в базу через `str(...)` — с одинарными кавычками."""
    as_role(ADMIN)
    act.step_list_fact = str({"numberTo": "ТО-2", "stepListTO": str(LEGACY_STEPS)})
    db_session.flush()

    data = _get(client_with_db, act.id)

    assert data["checklist"]["title"] == "ТО-2"
    assert len(data["checklist"]["steps"]) == 2
    # И наружу уходит уже валидный JSON, а не repr.
    assert json.loads(data["step_list_fact"])["numberTo"] == "ТО-2"


@pytest.mark.integration
def test_mechanic_marks_a_step_by_its_number(client_with_db, as_role, db_session, act):
    mechanic = as_role(Role.MECHANIC.value)
    act.main_mechanic_id = mechanic.id
    act.step_list_fact = _legacy(LEGACY_STEPS)
    db_session.flush()

    checklist = _get(client_with_db, act.id)["checklist"]
    checklist["steps"][1]["done"] = True
    checklist["steps"][1]["comment"] = "нет колодок"

    response = _put(client_with_db, act.id, {"checklist": checklist})

    assert response.status_code == 200, response.text
    steps = response.json()["data"]["checklist"]["steps"]
    assert steps[1] == {
        "id": 2,
        "title": "Проверить тормоз",
        "done": True,
        "comment": "нет колодок",
    }


@pytest.mark.integration
def test_a_new_step_takes_the_next_free_number(
    client_with_db, as_role, db_session, act
):
    """Освободившийся номер не переиспользуем: фото уехало бы к чужому пункту."""
    as_role(ADMIN)
    act.step_list_fact = _legacy(LEGACY_STEPS)
    db_session.flush()

    checklist = _get(client_with_db, act.id)["checklist"]
    checklist["steps"].append({"title": "Дописанный пункт", "done": False})

    steps = _put(client_with_db, act.id, {"checklist": checklist}).json()["data"][
        "checklist"
    ]["steps"]

    assert [step["id"] for step in steps] == [1, 2, 3]


@pytest.mark.integration
def test_writing_the_checklist_does_not_touch_the_rest_of_the_act(
    client_with_db, as_role, db_session, act
):
    as_role(ADMIN)
    before = act.status_id

    _put(client_with_db, act.id, {"step_list_fact": _legacy(LEGACY_STEPS)})

    db_session.refresh(act)
    assert act.status_id == before
    assert act.finished_at is None


@pytest.mark.integration
def test_reading_an_act_does_not_move_its_sync_mark(
    client_with_db, as_role, db_session, act
):
    """Геттер считает в переменные: чтение не должно выглядеть как правка.

    Иначе телефон механика по `changed_since` качал бы всё заново после
    каждого открытия карточки, а в колонке `file` вместо относительного пути
    оседала бы полная ссылка.
    """
    as_role(ADMIN)
    act.file = "act_fact/1/file/скан.pdf"
    db_session.flush()
    before = act.updated_at

    _get(client_with_db, act.id)
    db_session.flush()
    db_session.refresh(act)

    assert act.file == "act_fact/1/file/скан.pdf"
    assert act.updated_at == before


@pytest.mark.integration
def test_empty_checklist_stays_empty_and_not_null(client_with_db, as_role, act):
    """Пустой список — «не заполнено», и ручка обязана уметь это сказать."""
    as_role(ADMIN)

    data = _get(client_with_db, act.id)

    assert data["step_list_fact"] is None
    assert data["checklist"] == {"title": None, "steps": []}
