"""Шаблоны чек-листов: шаги списком, канон в базе, мягкое удаление вида ТО.

Строка `acts_bases` — это «вид ТО у модели». Экран «Шаблоны ТО» читает их по
модели (`/acts-bases/by-model/`), пишет шаги списком `steps` (сервер сам
кладёт каноническую форму `services.checklist`), убирает вид мягко
(`deleted_at`) и возвращает через `restore`. Удалённый вид мастер графика и
программа ТО не предлагают. Старый путь — `step_list` строкой — жив.
"""

import json
import uuid

import pytest
from sqlalchemy import func

from src.config import settings
from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.crud.crud_maintenance_program import crud_maintenance_program
from src.crud.crud_schedule_plan import act_bases_by_type_act
from src.models import ActBase, ActFact, FactoryModel, TypeAct
from src.services.checklist import parse_checklist

API = settings.API_V1_STR
STEPS = ["Выключить вводное устройство", "Осмотреть канаты", "Проверить двери"]


def _model(db_session) -> FactoryModel:
    tag = uuid.uuid4().hex[:6]
    model = FactoryModel(factory=f"Завод {tag}", model=f"М-{tag}")
    db_session.add(model)
    db_session.flush()
    return model


def _kind(db_session) -> TypeAct:
    next_id = (db_session.query(func.max(TypeAct.id)).scalar() or 0) + 1
    kind = TypeAct(id=next_id, name=f"ТО-тест {uuid.uuid4().hex[:6]}")
    db_session.add(kind)
    db_session.flush()
    return kind


def _template(db_session, model, kind=None, step_list=None, deleted_at=None):
    row = ActBase(
        factory_model_id=model.id,
        type_act_id=(kind or _kind(db_session)).id,
        step_list=step_list,
        deleted_at=deleted_at,
    )
    db_session.add(row)
    db_session.flush()
    return row


class TestCreateWithSteps:
    @pytest.mark.integration
    def test_steps_are_stored_canonical_and_readable(
        self, client_with_db, as_role, db_session
    ):
        as_role(ADMIN)
        model, kind = _model(db_session), _kind(db_session)

        response = client_with_db.post(
            f"{API}/act-base/",
            json={
                "factory_model_id": model.id,
                "type_act_id": kind.id,
                "steps": [" Выключить вводное устройство ", "", "Осмотреть канаты"],
            },
        )

        assert response.status_code == 200, response.text
        data = response.json()["data"]
        assert data["steps"] == ["Выключить вводное устройство", "Осмотреть канаты"]
        assert data["steps_count"] == 2
        assert data["deleted_at"] is None

        stored = db_session.query(ActBase).get(data["id"]).step_list
        # Канон — та же форма, что у акта: парсер читает её без правок.
        assert json.loads(stored) == {
            "title": None,
            "steps": [
                {
                    "id": 1,
                    "title": "Выключить вводное устройство",
                    "done": False,
                    "comment": None,
                },
                {"id": 2, "title": "Осмотреть канаты", "done": False, "comment": None},
            ],
        }
        checklist = parse_checklist(stored)
        assert [step.title for step in checklist.steps] == data["steps"]

    @pytest.mark.integration
    def test_legacy_step_list_still_accepted(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        model, kind = _model(db_session), _kind(db_session)
        legacy = json.dumps(
            {"numberTo": "ТО-1", "stepListTO": json.dumps([{"text": "Шаг", "bool": False}])}
        )

        response = client_with_db.post(
            f"{API}/act-base/",
            json={"factory_model_id": model.id, "type_act_id": kind.id, "step_list": legacy},
        )

        assert response.status_code == 200, response.text
        data = response.json()["data"]
        assert data["step_list"] == legacy
        assert data["steps"] == ["Шаг"]

    @pytest.mark.integration
    def test_deleted_pair_is_409_pointing_to_restore(
        self, client_with_db, as_role, db_session
    ):
        as_role(ADMIN)
        model = _model(db_session)
        row = _template(db_session, model, deleted_at=func.now())

        response = client_with_db.post(
            f"{API}/act-base/",
            json={"factory_model_id": model.id, "type_act_id": row.type_act_id, "steps": []},
        )

        assert response.status_code == 409, response.text
        assert "удалён" in response.json()["errors"][0]["message"]


class TestUpdate:
    @pytest.mark.integration
    def test_partial_update_keeps_untouched_fields(
        self, client_with_db, as_role, db_session
    ):
        as_role(ADMIN)
        model = _model(db_session)
        row = _template(db_session, model)

        response = client_with_db.put(
            f"{API}/act-base/{row.id}/", json={"steps": STEPS}
        )

        assert response.status_code == 200, response.text
        data = response.json()["data"]
        assert data["steps"] == STEPS
        assert data["factory_model_id"]["id"] == model.id
        assert data["type_act_id"]["id"] == row.type_act_id

        # Правка без шагов не стирает чек-лист.
        other = _kind(db_session)
        response = client_with_db.put(
            f"{API}/act-base/{row.id}/", json={"type_act_id": other.id}
        )
        assert response.status_code == 200, response.text
        assert response.json()["data"]["steps"] == STEPS
        assert response.json()["data"]["type_act_id"]["id"] == other.id


class TestListByModel:
    @pytest.mark.integration
    def test_filter_by_model_hides_deleted_unless_asked(
        self, client_with_db, as_role, db_session
    ):
        as_role(FOREMAN)
        model, stranger = _model(db_session), _model(db_session)
        alive = _template(db_session, model)
        gone = _template(db_session, model, deleted_at=func.now())
        _template(db_session, stranger)

        response = client_with_db.get(
            f"{API}/acts-bases/", params={"factory_model_id": model.id}
        )
        assert response.status_code == 200, response.text
        assert [row["id"] for row in response.json()["data"]] == [alive.id]

        response = client_with_db.get(
            f"{API}/acts-bases/",
            params={"factory_model_id": model.id, "include_deleted": "true"},
        )
        ids = {row["id"] for row in response.json()["data"]}
        assert ids == {alive.id, gone.id}

    @pytest.mark.integration
    def test_by_model_marks_empty_and_deleted(self, client_with_db, as_role, db_session):
        as_role(FOREMAN)
        model = _model(db_session)
        filled = _template(db_session, model)
        client_with_db.put(f"{API}/act-base/{filled.id}/", json={"steps": STEPS})
        empty = _template(db_session, model)
        gone = _template(db_session, model, deleted_at=func.now())

        response = client_with_db.get(f"{API}/acts-bases/by-model/{model.id}/")

        assert response.status_code == 200, response.text
        by_template = {row["template_id"]: row for row in response.json()["data"]}
        assert set(by_template) == {filled.id, empty.id, gone.id}
        assert by_template[filled.id]["has_template"] is True
        assert by_template[filled.id]["steps_count"] == len(STEPS)
        assert by_template[filled.id]["type_act"]["id"] == filled.type_act_id
        assert by_template[empty.id]["has_template"] is False
        assert by_template[empty.id]["steps"] == []
        assert by_template[gone.id]["deleted_at"] is not None
        # Порядок — по виду ТО, как на экране.
        type_ids = [row["type_act"]["id"] for row in response.json()["data"]]
        assert type_ids == sorted(type_ids)

    @pytest.mark.integration
    def test_by_model_unknown_model_is_404(self, client_with_db, as_role):
        as_role(ADMIN)
        response = client_with_db.get(f"{API}/acts-bases/by-model/999999/")
        assert response.status_code == 404


class TestSoftDelete:
    @pytest.mark.integration
    def test_delete_marks_and_hides_from_schedule(
        self, client_with_db, as_role, db_session
    ):
        as_role(FOREMAN)
        model = _model(db_session)
        row = _template(db_session, model)

        response = client_with_db.delete(f"{API}/act-base/{row.id}/")

        assert response.status_code == 200, response.text
        assert response.json()["data"]["deleted_at"] is not None
        db_session.refresh(row)
        assert row.deleted_at is not None
        assert row.type_act_id not in act_bases_by_type_act(
            db_session, factory_model_id=model.id
        )
        assert row.type_act_id not in crud_maintenance_program.available_type_act_ids(
            db_session, factory_model_id=model.id
        )

    @pytest.mark.integration
    def test_pending_acts_warn_then_force(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        model = _model(db_session)
        row = _template(db_session, model)
        db_session.add(ActFact(act_base_id=row.id, status_id=1))
        db_session.add(ActFact(act_base_id=row.id, status_id=1))
        # Начатый акт предупреждения не даёт: график по нему уже не «на будущее».
        db_session.add(ActFact(act_base_id=row.id, status_id=2))
        db_session.flush()

        response = client_with_db.delete(f"{API}/act-base/{row.id}/")

        assert response.status_code == 409, response.text
        assert "2 ТО" in response.json()["errors"][0]["message"]
        db_session.refresh(row)
        assert row.deleted_at is None

        response = client_with_db.delete(
            f"{API}/act-base/{row.id}/", params={"force": "true"}
        )
        assert response.status_code == 200, response.text
        db_session.refresh(row)
        assert row.deleted_at is not None

    @pytest.mark.integration
    def test_restore_brings_it_back(self, client_with_db, as_role, db_session):
        as_role(FOREMAN)
        model = _model(db_session)
        row = _template(db_session, model, deleted_at=func.now())

        response = client_with_db.post(f"{API}/act-base/{row.id}/restore/")

        assert response.status_code == 200, response.text
        assert response.json()["data"]["deleted_at"] is None
        assert row.type_act_id in act_bases_by_type_act(
            db_session, factory_model_id=model.id
        )

    @pytest.mark.integration
    def test_delete_is_idempotent(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        row = _template(db_session, _model(db_session), deleted_at=func.now())
        db_session.add(ActFact(act_base_id=row.id, status_id=1))
        db_session.flush()

        response = client_with_db.delete(f"{API}/act-base/{row.id}/")

        assert response.status_code == 200, response.text

    @pytest.mark.integration
    def test_unknown_template_is_404(self, client_with_db, as_role):
        as_role(ADMIN)
        assert client_with_db.delete(f"{API}/act-base/999999/").status_code == 404
        assert client_with_db.post(f"{API}/act-base/999999/restore/").status_code == 404

    @pytest.mark.integration
    def test_mechanic_cannot_delete(self, client_with_db, as_role, db_session):
        as_role(MECHANIC)
        row = _template(db_session, _model(db_session))
        assert client_with_db.delete(f"{API}/act-base/{row.id}/").status_code == 403
        assert (
            client_with_db.post(f"{API}/act-base/{row.id}/restore/").status_code == 403
        )
