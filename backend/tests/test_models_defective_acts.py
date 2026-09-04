"""Дефектный акт: четыре точки входа и ограничения на уровне базы.

Проверяется не «SQLAlchemy умеет вставлять строки», а то, что база сама не даёт
завести испорченный акт: без объекта, с выдуманным состоянием, клиентский без
первоисточника. Эти правила должны держаться независимо от того, какая ручка их
нарушит. Отдельно проверяется бэкфилл `object_id` — тот самый SQL, которым
миграция закрывает накопленные записи.
"""

import importlib.util
from pathlib import Path

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from src.models import (
    ActFact,
    DefectiveAct,
    DefectiveActClientPhoto,
    DefectiveActPhoto,
    Object,
    Order,
    PlannedTO,
)

_MIGRATION = (
    Path(__file__).resolve().parent.parent
    / "alembic"
    / "versions"
    / "2026_09_04_1200-d8a6c3f95b21_defective_acts_four_entry_points.py"
)


def _load_migration():
    """`alembic/versions` — не пакет, ревизию грузим по пути."""
    spec = importlib.util.spec_from_file_location(
        "_defective_acts_migration", _MIGRATION
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _object(db_session, name: str) -> Object:
    obj = Object(name=name)
    db_session.add(obj)
    db_session.flush()
    return obj


def _act(db_session, obj: Object, **kwargs) -> DefectiveAct:
    act = DefectiveAct(object_id=obj.id, title="Стук в приводе", **kwargs)
    db_session.add(act)
    db_session.flush()
    return act


class TestDefectiveActEntryPoints:
    @pytest.mark.integration
    def test_act_can_be_raised_from_maintenance_work(self, db_session):
        obj = _object(db_session, "Лифт с работой по ТО")
        act_fact = ActFact(object_id=obj.id)
        db_session.add(act_fact)
        db_session.flush()

        act = _act(db_session, obj, act_fact_id=act_fact.id, checklist_step_id=4)
        db_session.refresh(act)

        assert act.act_fact_id == act_fact.id
        # Пункт чек-листа — номер внутри акта, не ссылка на справочник.
        assert act.checklist_step_id == 4
        assert act.planned_to_id is None and act.month is None

    @pytest.mark.integration
    def test_act_can_be_raised_from_an_order(self, db_session):
        obj = _object(db_session, "Лифт с заявкой")
        order = Order(object_id=obj.id, task_text="Не открываются двери")
        db_session.add(order)
        db_session.flush()

        act = _act(db_session, obj, order_id=order.id)
        db_session.refresh(act)

        assert act.order_id == order.id

    @pytest.mark.integration
    def test_act_can_be_raised_with_object_alone(self, db_session):
        # Четвёртый вход: механик заводит акт пунктом меню, обходом.
        obj = _object(db_session, "Лифт без работы и заявки")

        act = _act(db_session, obj)
        db_session.refresh(act)

        assert act.object_id == obj.id
        assert act.act_fact_id is None and act.order_id is None
        # Умолчания цикла: акт создан и он внутренний.
        assert act.state == "created"
        assert act.kind == "internal"

    @pytest.mark.integration
    def test_old_shape_with_planned_to_still_works(self, db_session):
        # Старый контракт: акт заводится по плановому ТО и месяцу.
        obj = _object(db_session, "Лифт со старым актом")
        planned = PlannedTO(year="2027", object_id=obj.id)
        db_session.add(planned)
        db_session.flush()

        act = _act(db_session, obj, planned_to_id=planned.id, month=8)
        db_session.refresh(act)

        assert (act.planned_to_id, act.month) == (planned.id, 8)

    @pytest.mark.integration
    def test_act_without_object_is_rejected(self, db_session):
        db_session.add(DefectiveAct(title="Ничей акт"))
        with pytest.raises(IntegrityError):
            db_session.flush()
        db_session.rollback()


class TestDefectiveActLifecycle:
    @pytest.mark.integration
    @pytest.mark.parametrize("state", ["created", "reviewed", "issued", "fixed"])
    def test_states_of_the_cycle_are_accepted(self, db_session, state: str):
        obj = _object(db_session, f"Лифт {state}")

        act = _act(db_session, obj, state=state)
        db_session.refresh(act)

        assert act.state == state

    @pytest.mark.integration
    def test_state_outside_the_cycle_is_rejected(self, db_session):
        obj = _object(db_session, "Лифт с выдуманным состоянием")

        db_session.add(DefectiveAct(object_id=obj.id, title="Акт", state="согласован"))
        with pytest.raises(IntegrityError):
            db_session.flush()
        db_session.rollback()

    @pytest.mark.integration
    def test_unknown_kind_is_rejected(self, db_session):
        obj = _object(db_session, "Лифт с третьим видом акта")

        db_session.add(DefectiveAct(object_id=obj.id, title="Акт", kind="внутренний"))
        with pytest.raises(IntegrityError):
            db_session.flush()
        db_session.rollback()

    @pytest.mark.integration
    def test_client_act_without_parent_is_rejected(self, db_session):
        # Клиентский акт без первоисточника — текст, за которым не стоит осмотра.
        obj = _object(db_session, "Лифт с висячим клиентским актом")

        db_session.add(DefectiveAct(object_id=obj.id, title="Акт", kind="client"))
        with pytest.raises(IntegrityError):
            db_session.flush()
        db_session.rollback()


class TestClientActPhotos:
    @pytest.mark.integration
    def test_one_photo_goes_into_two_client_acts(self, db_session):
        obj = _object(db_session, "Лифт с двумя клиентскими актами")
        internal = _act(db_session, obj)
        photo = DefectiveActPhoto(
            defective_act_id=internal.id, photo="defective_act/1/a.jpg"
        )
        db_session.add(photo)
        db_session.flush()

        first, second = (
            _act(
                db_session,
                obj,
                kind="client",
                parent_id=internal.id,
                client_title=title,
            )
            for title in ("Акт заказчику от августа", "Акт заказчику от сентября")
        )
        db_session.add_all(
            [
                DefectiveActClientPhoto(client_act_id=first.id, photo_id=photo.id),
                DefectiveActClientPhoto(client_act_id=second.id, photo_id=photo.id),
            ]
        )
        db_session.flush()

        # Снимок один, ссылок на него две: байты не копируются.
        assert [link.photo_id for link in first.client_photos] == [photo.id]
        assert [link.photo_id for link in second.client_photos] == [photo.id]

    @pytest.mark.integration
    def test_deleting_client_act_leaves_photo_and_source_alive(self, db_session):
        obj = _object(db_session, "Лифт с отзываемым клиентским актом")
        internal = _act(db_session, obj)
        photo = DefectiveActPhoto(
            defective_act_id=internal.id, photo="defective_act/2/a.jpg"
        )
        db_session.add(photo)
        db_session.flush()

        client_act = _act(db_session, obj, kind="client", parent_id=internal.id)
        db_session.add(
            DefectiveActClientPhoto(client_act_id=client_act.id, photo_id=photo.id)
        )
        db_session.flush()

        db_session.delete(client_act)
        db_session.flush()

        links = (
            db_session.query(DefectiveActClientPhoto)
            .filter(DefectiveActClientPhoto.photo_id == photo.id)
            .count()
        )
        assert links == 0
        # Первоисточник и сам снимок клиентский акт за собой не уносит.
        assert db_session.query(DefectiveActPhoto).get(photo.id) is not None
        assert db_session.query(DefectiveAct).get(internal.id) is not None


class TestBackfill:
    @pytest.mark.integration
    def test_object_is_taken_from_the_planned_maintenance(self, db_session):
        """Домиграционная строка: плановое ТО есть, объекта в акте нет.

        Таких строк в тестовой базе быть не может — она накачена миграциями
        целиком. Поэтому `NOT NULL` снимается прямо здесь: DDL в Postgres
        транзакционный, а фикстура `db_session` откатывает всю транзакцию,
        так что соседние тесты изменения не увидят.
        """
        obj = _object(db_session, "Лифт с домиграционным актом")
        planned = PlannedTO(year="2026", object_id=obj.id)
        db_session.add(planned)
        db_session.flush()

        db_session.execute(
            text("ALTER TABLE defective_acts ALTER COLUMN object_id DROP NOT NULL")
        )
        act = DefectiveAct(title="Старый акт", planned_to_id=planned.id, month=3)
        db_session.add(act)
        db_session.flush()
        assert act.object_id is None

        closed = _load_migration().backfill_object_id(db_session)

        db_session.refresh(act)
        assert closed == 1
        assert act.object_id == obj.id

    @pytest.mark.integration
    def test_act_without_planned_maintenance_stays_orphan(self, db_session):
        # Бэкфилл его не закрывает — в миграции такая строка удаляется.
        db_session.execute(
            text("ALTER TABLE defective_acts ALTER COLUMN object_id DROP NOT NULL")
        )
        act = DefectiveAct(title="Акт без планового ТО")
        db_session.add(act)
        db_session.flush()

        _load_migration().backfill_object_id(db_session)

        db_session.refresh(act)
        assert act.object_id is None
