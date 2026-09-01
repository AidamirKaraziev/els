"""Ручки программы обслуживания: форма, валидация, права, предложение.

Ограничения самой таблицы проверяет `test_models_maintenance_program`. Здесь
проверяется то, что видит фронт: полная раскладка приходит одним телом,
кривое тело даёт 422 со списком проблем, а не 500, и предложение по
умолчанию не выходит за пределы заведённых шаблонов чек-листов.
"""

import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID, DISPATCHER, FOREMAN, MECHANIC
from src.models import ActBase, FactoryModel, MaintenanceProgramItem

BASE = f"{settings.API_V1_STR}/maintenance-program"

#: id из `create_initial_data` (см. `src/core/db/init_db.py`): id вида ТО
#: равен периодичности в месяцах.
TO_1, TO_3, TO_6, TO_12 = 1, 3, 6, 12

#: Что предлагает правило на модели, где есть шаблоны на все виды.
FULL_CYCLE = [1, 1, 3, 1, 1, 6, 1, 1, 3, 1, 1, 12]


@pytest.fixture
def make_model(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(*, act_bases=()):
        number = next(counter)
        model = FactoryModel(factory=f"Завод {prefix}", model=f"М-{prefix}-{number}")
        db_session.add(model)
        db_session.flush()
        for type_act_id in act_bases:
            db_session.add(ActBase(factory_model_id=model.id, type_act_id=type_act_id))
        db_session.flush()
        return model

    return _make


def body(items=None, name="Стандартная"):
    items = items or [
        {"position": position, "type_act_id": type_act_id}
        for position, type_act_id in enumerate(FULL_CYCLE, start=1)
    ]
    return {"name": name, "items": items}


def _data(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


class TestAccess:
    """Читают все сотрудники, пишут админ и прораб."""

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "role",
        [ADMIN, FOREMAN, MECHANIC, DISPATCHER],
        ids=["админ", "прораб", "механик", "диспетчер"],
    )
    def test_employees_may_read_the_list(self, client_with_db, as_role, role):
        as_role(role)

        assert client_with_db.get(f"{BASE}/all/").status_code == 200

    @pytest.mark.integration
    def test_client_is_denied(self, client_with_db, as_role):
        as_role(CLIENT_ID)

        assert client_with_db.get(f"{BASE}/all/").status_code == 403

    @pytest.mark.integration
    def test_anonymous_is_denied(self, client_with_db):
        assert client_with_db.get(f"{BASE}/all/").status_code == 401

    @pytest.mark.integration
    @pytest.mark.parametrize("role", [ADMIN, FOREMAN], ids=["админ", "прораб"])
    def test_admin_and_foreman_may_write(
        self, client_with_db, as_role, make_model, role
    ):
        model = make_model()
        as_role(role)

        response = client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body())

        assert response.status_code == 200, response.text

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "role", [MECHANIC, DISPATCHER], ids=["механик", "диспетчер"]
    )
    def test_others_may_not_write(self, client_with_db, as_role, make_model, role):
        model = make_model()
        as_role(role)

        response = client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body())

        assert response.status_code == 403


class TestReadAndUpsert:
    @pytest.mark.integration
    def test_missing_program_is_404(self, client_with_db, as_role, make_model):
        model = make_model()
        as_role(ADMIN)

        assert client_with_db.get(f"{BASE}/by-model/{model.id}/").status_code == 404

    @pytest.mark.integration
    def test_missing_model_is_404(self, client_with_db, as_role):
        as_role(ADMIN)

        assert client_with_db.get(f"{BASE}/by-model/10000000/").status_code == 404

    @pytest.mark.integration
    def test_saved_program_comes_back_in_order(
        self, client_with_db, as_role, make_model
    ):
        model = make_model()
        as_role(ADMIN)
        client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body())

        data = _data(client_with_db.get(f"{BASE}/by-model/{model.id}/"))

        assert data["factory_model_id"] == model.id
        assert data["name"] == "Стандартная"
        assert [item["position"] for item in data["items"]] == list(range(1, 13))
        assert [item["type_act_id"] for item in data["items"]] == FULL_CYCLE
        assert data["items"][-1]["type_act_name"]

    @pytest.mark.integration
    def test_items_are_shuffled_back_into_order(
        self, client_with_db, as_role, make_model
    ):
        # Фронт вправе прислать позиции вперемешку: порядок задаёт `position`,
        # а не место в массиве.
        model = make_model()
        items = [
            {"position": position, "type_act_id": type_act_id}
            for position, type_act_id in enumerate(FULL_CYCLE, start=1)
        ][::-1]
        as_role(ADMIN)

        data = _data(
            client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body(items))
        )

        assert [item["position"] for item in data["items"]] == list(range(1, 13))

    @pytest.mark.integration
    def test_second_upsert_replaces_items(
        self, client_with_db, as_role, db_session, make_model
    ):
        model = make_model()
        as_role(ADMIN)
        client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body())

        second = [
            {"position": position, "type_act_id": TO_1} for position in range(1, 13)
        ]
        data = _data(
            client_with_db.put(
                f"{BASE}/by-model/{model.id}/", json=body(second, name="Только ТО1")
            )
        )

        assert data["name"] == "Только ТО1"
        assert {item["type_act_id"] for item in data["items"]} == {TO_1}
        # Старые позиции не остались висеть рядом с новыми.
        assert (
            db_session.query(MaintenanceProgramItem)
            .filter(MaintenanceProgramItem.program_id == data["id"])
            .count()
            == 12
        )


class TestValidation:
    """Кривое тело — всегда 422, ни одного 500."""

    @pytest.mark.integration
    @pytest.mark.parametrize(
        "items",
        [
            [{"position": p, "type_act_id": TO_1} for p in range(1, 12)],
            [{"position": p, "type_act_id": TO_1} for p in range(0, 12)],
            [{"position": p, "type_act_id": TO_1} for p in range(2, 14)],
            (
                [{"position": p, "type_act_id": TO_1} for p in range(1, 6)]
                + [{"position": p, "type_act_id": TO_1} for p in range(7, 14)]
            ),
            (
                [{"position": p, "type_act_id": TO_1} for p in range(1, 12)]
                + [{"position": 11, "type_act_id": TO_1}]
            ),
        ],
        ids=[
            "одиннадцать позиций",
            "нулевая позиция",
            "тринадцатая позиция",
            "пропуск в середине",
            "повтор позиции",
        ],
    )
    def test_broken_cycle_is_422(self, client_with_db, as_role, make_model, items):
        model = make_model()
        as_role(ADMIN)

        response = client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body(items))

        assert response.status_code == 422, response.text

    @pytest.mark.integration
    def test_unknown_type_act_is_422_and_names_positions(
        self, client_with_db, as_role, make_model
    ):
        model = make_model()
        items = [
            {"position": position, "type_act_id": TO_1} for position in range(1, 13)
        ]
        items[2]["type_act_id"] = 777
        items[8]["type_act_id"] = 777
        as_role(ADMIN)

        response = client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body(items))

        assert response.status_code == 422, response.text
        # Названы все плохие позиции разом, а не первая попавшаяся.
        assert "[777]" in response.json()["errors"][0]["message"]
        assert "[3, 9]" in response.json()["errors"][0]["message"]

    @pytest.mark.integration
    def test_all_problems_come_at_once(self, client_with_db, as_role, make_model):
        # Человек правит таблицу из двенадцати строк: возвращать её по одной
        # беде за запрос — это двенадцать заходов вместо одного.
        model = make_model()
        items = [{"position": p, "type_act_id": TO_1} for p in range(1, 12)]
        items[0]["type_act_id"] = 777
        as_role(ADMIN)

        response = client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body(items))

        assert response.status_code == 422, response.text
        messages = " ".join(e["message"] for e in response.json()["errors"])
        assert "11" in messages and "пропущены" in messages and "777" in messages

    @pytest.mark.integration
    def test_upsert_to_missing_model_is_404(self, client_with_db, as_role):
        as_role(ADMIN)

        response = client_with_db.put(f"{BASE}/by-model/10000000/", json=body())

        assert response.status_code == 404, response.text


class TestSuggestion:
    @pytest.mark.integration
    def test_full_set_of_templates_gives_the_whole_rule(
        self, client_with_db, as_role, make_model
    ):
        model = make_model(act_bases=(TO_1, TO_3, TO_6, TO_12))
        as_role(ADMIN)

        data = _data(client_with_db.get(f"{BASE}/by-model/{model.id}/suggestion/"))

        assert [item["type_act_id"] for item in data["items"]] == FULL_CYCLE
        assert data["missing_type_act_ids"] == []
        assert data["available_type_act_ids"] == [TO_1, TO_3, TO_6, TO_12]

    @pytest.mark.integration
    def test_suggestion_stays_within_existing_templates(
        self, client_with_db, as_role, make_model
    ):
        # Шаблоны только на ТО1 и ТО12: третья и шестая позиции опускаются до
        # ТО1, но недостающие виды названы — без них график не утвердить.
        model = make_model(act_bases=(TO_1, TO_12))
        as_role(ADMIN)

        data = _data(client_with_db.get(f"{BASE}/by-model/{model.id}/suggestion/"))

        assert [item["type_act_id"] for item in data["items"]] == [TO_1] * 11 + [TO_12]
        assert data["missing_type_act_ids"] == [TO_3, TO_6]

    @pytest.mark.integration
    def test_model_without_templates_gets_empty_positions(
        self, client_with_db, as_role, make_model
    ):
        model = make_model()
        as_role(ADMIN)

        data = _data(client_with_db.get(f"{BASE}/by-model/{model.id}/suggestion/"))

        assert [item["type_act_id"] for item in data["items"]] == [None] * 12
        assert data["available_type_act_ids"] == []
        assert data["missing_type_act_ids"] == [TO_1, TO_3, TO_6, TO_12]

    @pytest.mark.integration
    def test_suggestion_does_not_write_anything(
        self, client_with_db, as_role, make_model
    ):
        model = make_model(act_bases=(TO_1,))
        as_role(ADMIN)

        client_with_db.get(f"{BASE}/by-model/{model.id}/suggestion/")

        assert client_with_db.get(f"{BASE}/by-model/{model.id}/").status_code == 404

    @pytest.mark.integration
    def test_suggestion_works_when_program_exists(
        self, client_with_db, as_role, make_model
    ):
        # «Сбросить к предложенному» — ради этого предложение и отдельной
        # ручкой, а не полем в ответе по программе.
        model = make_model(act_bases=(TO_1, TO_3, TO_6, TO_12))
        as_role(ADMIN)
        client_with_db.put(
            f"{BASE}/by-model/{model.id}/",
            json=body([{"position": p, "type_act_id": TO_1} for p in range(1, 13)]),
        )

        data = _data(client_with_db.get(f"{BASE}/by-model/{model.id}/suggestion/"))

        assert [item["type_act_id"] for item in data["items"]] == FULL_CYCLE


class TestList:
    @pytest.mark.integration
    def test_list_returns_saved_programs(self, client_with_db, as_role, make_model):
        first, second = make_model(), make_model()
        as_role(ADMIN)
        for model in (first, second):
            client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body())

        data = _data(client_with_db.get(f"{BASE}/all/"))

        by_model = {row["factory_model_id"]: row for row in data}
        assert {first.id, second.id} <= set(by_model)
        assert len(by_model[first.id]["items"]) == 12

    @pytest.mark.integration
    def test_pages(self, client_with_db, as_role, make_model):
        as_role(ADMIN)
        for _ in range(2):
            model = make_model()
            client_with_db.put(f"{BASE}/by-model/{model.id}/", json=body())

        response = client_with_db.get(f"{BASE}/all/", params={"page": 1})

        assert response.status_code == 200, response.text
        paginator = response.json()["meta"]["paginator"]
        assert paginator["page"] == 1
        assert paginator["has_prev"] is False
