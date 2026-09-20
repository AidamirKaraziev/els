"""Виды ТО заводятся и переименовываются по REST, а не руками в БД.

У `types_acts` нет автоинкремента — справочник заливали с ручными id, поэтому
ручка продолжает нумерацию сама: следующий за наибольшим. Дубль имени — 409,
пустое имя — 422 (а не 400, как ошибки pydantic). Право — `DIRECTORY_WRITE`,
оно есть у админа и прораба.
"""

import uuid

import pytest
from sqlalchemy import func

from src.config import settings
from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.models import TypeAct

URL = f"{settings.API_V1_STR}/type-acts/"


def _name() -> str:
    return f"ТО-тест {uuid.uuid4().hex[:8]}"


def _max_id(db_session) -> int:
    return db_session.query(func.max(TypeAct.id)).scalar() or 0


def _add_kind(db_session, name=None, id=None) -> TypeAct:
    kind = TypeAct(id=id or _max_id(db_session) + 1, name=name or _name())
    db_session.add(kind)
    db_session.flush()
    return kind


class TestCreate:
    @pytest.mark.integration
    def test_id_is_next_after_largest(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        # Дырка в нумерации: следующий id идёт за наибольшим, а не за числом строк.
        largest = _add_kind(db_session, id=_max_id(db_session) + 10)
        name = _name()

        response = client_with_db.post(URL, json={"name": name})

        assert response.status_code == 200, response.text
        data = response.json()["data"]
        assert data == {"id": largest.id + 1, "name": name}
        assert db_session.query(TypeAct).get(largest.id + 1).name == name

    @pytest.mark.integration
    def test_name_is_stripped(self, client_with_db, as_role):
        as_role(ADMIN)
        name = _name()

        response = client_with_db.post(URL, json={"name": f"  {name}  "})

        assert response.status_code == 200
        assert response.json()["data"]["name"] == name

    @pytest.mark.integration
    @pytest.mark.parametrize("name", ["", "   "])
    def test_empty_name_is_422(self, client_with_db, as_role, db_session, name):
        as_role(ADMIN)
        before = _max_id(db_session)

        response = client_with_db.post(URL, json={"name": name})

        assert response.status_code == 422
        assert _max_id(db_session) == before

    @pytest.mark.integration
    def test_duplicate_name_is_409(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        existing = _add_kind(db_session)

        response = client_with_db.post(URL, json={"name": existing.name})

        assert response.status_code == 409
        assert (
            db_session.query(TypeAct).filter(TypeAct.name == existing.name).count() == 1
        )

    @pytest.mark.integration
    def test_foreman_can_create(self, client_with_db, as_role):
        as_role(FOREMAN)

        response = client_with_db.post(URL, json={"name": _name()})

        assert response.status_code == 200

    @pytest.mark.integration
    def test_mechanic_cannot_create(self, client_with_db, as_role):
        as_role(MECHANIC)

        response = client_with_db.post(URL, json={"name": _name()})

        assert response.status_code == 403


class TestRename:
    @pytest.mark.integration
    def test_renames(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        kind = _add_kind(db_session)
        new_name = _name()

        response = client_with_db.put(f"{URL}{kind.id}/", json={"name": new_name})

        assert response.status_code == 200, response.text
        assert response.json()["data"] == {"id": kind.id, "name": new_name}
        db_session.refresh(kind)
        assert kind.name == new_name

    @pytest.mark.integration
    def test_same_name_is_ok(self, client_with_db, as_role, db_session):
        # Сохранить форму, ничего не поменяв, — не ошибка.
        as_role(ADMIN)
        kind = _add_kind(db_session)

        response = client_with_db.put(f"{URL}{kind.id}/", json={"name": kind.name})

        assert response.status_code == 200

    @pytest.mark.integration
    def test_unknown_id_is_404(self, client_with_db, as_role, db_session):
        as_role(ADMIN)

        response = client_with_db.put(
            f"{URL}{_max_id(db_session) + 100}/", json={"name": _name()}
        )

        assert response.status_code == 404

    @pytest.mark.integration
    def test_taken_name_is_409(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        kind = _add_kind(db_session)
        other = _add_kind(db_session)

        response = client_with_db.put(f"{URL}{kind.id}/", json={"name": other.name})

        assert response.status_code == 409
        db_session.refresh(kind)
        assert kind.name != other.name

    @pytest.mark.integration
    def test_empty_name_is_422(self, client_with_db, as_role, db_session):
        as_role(ADMIN)
        kind = _add_kind(db_session)

        response = client_with_db.put(f"{URL}{kind.id}/", json={"name": " "})

        assert response.status_code == 422

    @pytest.mark.integration
    def test_mechanic_cannot_rename(self, client_with_db, as_role, db_session):
        kind = _add_kind(db_session)
        as_role(MECHANIC)

        response = client_with_db.put(f"{URL}{kind.id}/", json={"name": _name()})

        assert response.status_code == 403


@pytest.mark.integration
def test_list_still_returns_id_and_name(client_with_db, as_role, db_session):
    # Старый GET не тронут: список с id и name, как читает его фронт.
    as_role(MECHANIC)
    kind = _add_kind(db_session)

    response = client_with_db.get(URL)

    assert response.status_code == 200
    rows = response.json()["data"]
    assert {"id": kind.id, "name": kind.name} in rows
