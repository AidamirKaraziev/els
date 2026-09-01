"""Доступ к программе обслуживания модели оборудования.

Здесь только работа с базой: проверки «модель существует», «вид ТО
существует» и сборка ответа живут в ручке и в геттере — так их видно в одном
месте вместе с кодами ошибок.
"""

from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy.orm import Session, joinedload

from src.core.response import Paginator
from src.crud.base import CRUDBase
from src.models import (
    ActBase,
    FactoryModel,
    MaintenanceProgram,
    MaintenanceProgramItem,
    TypeAct,
)
from src.utils import pagination


class CrudMaintenanceProgram(CRUDBase):
    def get_by_model(
        self, db: Session, *, factory_model_id: int
    ) -> Optional[MaintenanceProgram]:
        return (
            db.query(MaintenanceProgram)
            .options(joinedload(MaintenanceProgram.items))
            .filter(MaintenanceProgram.factory_model_id == factory_model_id)
            .first()
        )

    def list_all(
        self, db: Session, *, page: Optional[int] = None
    ) -> Tuple[List[MaintenanceProgram], Optional[Paginator]]:
        query = (
            db.query(MaintenanceProgram)
            .options(joinedload(MaintenanceProgram.items))
            .order_by(MaintenanceProgram.id)
        )
        return pagination.get_page(query, page)

    def factory_model_exists(self, db: Session, *, factory_model_id: int) -> bool:
        return (
            db.query(FactoryModel.id)
            .filter(FactoryModel.id == factory_model_id)
            .first()
            is not None
        )

    def existing_type_act_ids(self, db: Session, *, ids) -> set:
        rows = db.query(TypeAct.id).filter(TypeAct.id.in_(list(ids))).all()
        return {row[0] for row in rows}

    def available_type_act_ids(self, db: Session, *, factory_model_id: int) -> set:
        """Виды ТО, на которые у модели есть шаблон чек-листа.

        Без шаблона (`acts_bases`) вид ТО предлагать нельзя: по нему нечего
        показать механику — решение заказчика №7.
        """
        rows = (
            db.query(ActBase.type_act_id)
            .filter(
                ActBase.factory_model_id == factory_model_id,
                ActBase.type_act_id.isnot(None),
            )
            .distinct()
            .all()
        )
        return {row[0] for row in rows}

    def upsert_by_model(
        self, db: Session, *, factory_model_id: int, data
    ) -> MaintenanceProgram:
        """Завести программу или заменить её позиции целиком.

        Позиции не сверяются по одной, а выбрасываются и пишутся заново:
        программа — это цикл, и «дописать март» без остальных одиннадцати
        месяцев смысла не имеет.
        """
        program = self.get_by_model(db=db, factory_model_id=factory_model_id)
        if program is None:
            program = MaintenanceProgram(factory_model_id=factory_model_id)
            db.add(program)

        program.name = data.name
        # Старые позиции сносим отдельным flush: если просто заменить список,
        # SQLAlchemy вставит новые строки раньше, чем удалит старые, и
        # уникальность `(program_id, position)` из S1.1 сорвёт правку.
        if program.items:
            program.items = []
            db.flush()

        program.items = [
            MaintenanceProgramItem(position=item.position, type_act_id=item.type_act_id)
            for item in sorted(data.items, key=lambda item: item.position)
        ]
        # Метку правки ставим руками: `onupdate` срабатывает, только когда
        # изменилось поле самой программы, а обычная правка меняет одни
        # позиции — и телефон механика такую правку не увидел бы.
        program.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(program)
        return program


crud_maintenance_program = CrudMaintenanceProgram(MaintenanceProgram)
