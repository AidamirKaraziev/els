from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from src.models import FactoryModel
from src.session import Base


class MaintenanceProgram(Base):
    """Программа обслуживания модели оборудования: какие ТО и в каком месяце.

    Годовой план (`planned_to`) знает только «в марте было ТО», но не знает,
    какое именно: вид работы выясняется, лишь когда по месяцу заведён факт.
    Программа отвечает на этот вопрос заранее — по ней график объекта
    показывает плановые ТО и находит шаблон чек-листа.

    Одна программа на модель: `factory_model_id` уникален.
    """

    __tablename__ = "maintenance_program"
    id = Column(Integer, primary_key=True)
    factory_model_id = Column(
        Integer,
        ForeignKey("factories_models.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    name = Column(String)

    #: Метка последней правки — как у `planned_to`: по ней телефон механика
    #: спрашивает «что изменилось с момента T».
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, index=True
    )

    factory_model = relationship(FactoryModel)
    items = relationship(
        "MaintenanceProgramItem",
        back_populates="program",
        cascade="all, delete-orphan",
        order_by="MaintenanceProgramItem.position",
    )


class MaintenanceProgramItem(Base):
    """Одна позиция программы: месяц 1–12 и вид ТО в нём.

    Позиции лежат отдельной таблицей, а не строкой из двенадцати имён: вид ТО
    должен быть внешним ключом на `types_acts`, иначе шаблон чек-листа по нему
    не найти.
    """

    __tablename__ = "maintenance_program_item"
    id = Column(Integer, primary_key=True)
    program_id = Column(
        Integer,
        ForeignKey("maintenance_program.id", ondelete="CASCADE"),
        nullable=False,
    )
    #: Месяц программы, 1–12.
    position = Column(Integer, nullable=False)
    #: Вид ТО. `RESTRICT`: справочник `types_acts` сидится с id, равным
    #: периодичности, и удаление вида из-под живых программ — это порча плана,
    #: а не штатная операция.
    type_act_id = Column(
        Integer, ForeignKey("types_acts.id", ondelete="RESTRICT"), nullable=False
    )

    program = relationship("MaintenanceProgram", back_populates="items")
    type_act = relationship("TypeAct")

    __table_args__ = (
        UniqueConstraint("program_id", "position", name="_program_position_uc"),
        CheckConstraint("position BETWEEN 1 AND 12", name="_program_position_range"),
    )
