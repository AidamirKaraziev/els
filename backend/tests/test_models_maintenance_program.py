"""Программа обслуживания: ограничения на уровне базы.

Проверяется не «SQLAlchemy умеет вставлять строки», а то, что база сама не даёт
завести испорченную программу: две программы на одну модель, два ТО в одном
месяце, месяц вне 1–12. Эти правила должны держаться независимо от того, какая
ручка их нарушит.
"""

import pytest
from sqlalchemy.exc import IntegrityError

from src.models import FactoryModel, MaintenanceProgram, MaintenanceProgramItem

# Виды ТО из `create_initial_data()`: id равен периодичности в месяцах
# (см. `src/core/db/init_db.py:check_type_acts`).
TO_1, TO_3, TO_6, TO_12 = 1, 3, 6, 12

# Годовая программа: раз в месяц ТО 1, кроме кварталов, полугодия и года.
YEAR = [TO_1, TO_1, TO_3, TO_1, TO_1, TO_6, TO_1, TO_1, TO_3, TO_1, TO_1, TO_12]


def _factory_model(db_session, model: str) -> FactoryModel:
    obj = FactoryModel(factory="Щербинский", model=model)
    db_session.add(obj)
    db_session.flush()
    return obj


def _program(db_session, model: str, positions=YEAR) -> MaintenanceProgram:
    program = MaintenanceProgram(
        factory_model_id=_factory_model(db_session, model).id,
        name=f"Программа {model}",
    )
    program.items = [
        MaintenanceProgramItem(position=position, type_act_id=type_act_id)
        for position, type_act_id in enumerate(positions, start=1)
    ]
    db_session.add(program)
    db_session.flush()
    return program


class TestMaintenanceProgram:
    @pytest.mark.integration
    def test_program_keeps_twelve_positions_in_order(self, db_session):
        program = _program(db_session, "ПП-0411Щ")
        db_session.refresh(program)

        assert program.id is not None
        assert [item.position for item in program.items] == list(range(1, 13))
        assert [item.type_act_id for item in program.items] == YEAR

    @pytest.mark.integration
    def test_model_cannot_have_two_programs(self, db_session):
        # Одна программа на модель: иначе непонятно, по какой строить график.
        program = _program(db_session, "ПП-0417Щ")

        db_session.add(
            MaintenanceProgram(factory_model_id=program.factory_model_id, name="Вторая")
        )
        with pytest.raises(IntegrityError):
            db_session.flush()
        db_session.rollback()

    @pytest.mark.integration
    def test_month_cannot_hold_two_maintenance_types(self, db_session):
        program = _program(db_session, "ПП-0421Щ")

        db_session.add(
            MaintenanceProgramItem(program_id=program.id, position=3, type_act_id=TO_6)
        )
        with pytest.raises(IntegrityError):
            db_session.flush()
        db_session.rollback()

    @pytest.mark.integration
    @pytest.mark.parametrize("position", [0, 13, -1])
    def test_position_outside_the_year_is_rejected(self, db_session, position: int):
        program = _program(db_session, f"ПП-{position}Щ", positions=[])

        db_session.add(
            MaintenanceProgramItem(
                program_id=program.id, position=position, type_act_id=TO_1
            )
        )
        with pytest.raises(IntegrityError):
            db_session.flush()
        db_session.rollback()

    @pytest.mark.integration
    def test_deleting_program_takes_its_positions(self, db_session):
        program = _program(db_session, "ПП-0431Щ")
        program_id = program.id

        db_session.delete(program)
        db_session.flush()

        left = (
            db_session.query(MaintenanceProgramItem)
            .filter(MaintenanceProgramItem.program_id == program_id)
            .count()
        )
        assert left == 0
