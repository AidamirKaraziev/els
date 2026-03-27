from sqlalchemy import Column, ForeignKey, Integer, String, UniqueConstraint
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
