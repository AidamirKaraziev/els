from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    true,
)
from sqlalchemy.orm import relationship

from src.models import Object
from src.session import Base


class PlannedTO(Base):
    __tablename__ = "planned_to"
    id = Column(Integer, primary_key=True)
    year = Column(String)
    object_id = Column(Integer, ForeignKey("objects.id", ondelete="SET NULL"))
    january_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    february_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    march_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    april_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    may_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    june_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    july_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    august_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    september_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    october_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    november_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))
    december_to_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))

    #: Мягкое удаление: запись уходит из списков, но остаётся в базе и
    #: доезжает до телефона с `is_actual=false`. Настоящий `DELETE` офлайн-
    #: клиенту сказать нечего — см. `src/core/archiving.py`.
    is_actual = Column(Boolean, default=True, nullable=False, server_default=true())

    #: Метка последней правки — по ней телефон механика спрашивает «что
    #: изменилось с момента T» и не тянет весь список заново.
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, index=True
    )

    object = relationship(Object)
    january_to = relationship("ActFact", foreign_keys=[january_to_id])
    february_to = relationship("ActFact", foreign_keys=[february_to_id])
    march_to = relationship("ActFact", foreign_keys=[march_to_id])
    april_to = relationship("ActFact", foreign_keys=[april_to_id])
    may_to = relationship("ActFact", foreign_keys=[may_to_id])
    june_to = relationship("ActFact", foreign_keys=[june_to_id])
    july_to = relationship("ActFact", foreign_keys=[july_to_id])
    august_to = relationship("ActFact", foreign_keys=[august_to_id])
    september_to = relationship("ActFact", foreign_keys=[september_to_id])
    october_to = relationship("ActFact", foreign_keys=[october_to_id])
    november_to = relationship("ActFact", foreign_keys=[november_to_id])
    december_to = relationship("ActFact", foreign_keys=[december_to_id])

    __table_args__ = (UniqueConstraint("year", "object_id", name="_year_object_uc"),)
