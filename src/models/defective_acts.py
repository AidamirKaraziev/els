from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from src.models import PlannedTO, Status
from src.session import Base


class DefectiveAct(Base):
    __tablename__ = "defective_acts"
    id = Column(Integer, primary_key=True, autoincrement=True)

    planned_to_id = Column(Integer, ForeignKey("planned_to.id", ondelete="SET NULL"))
    month = Column(Integer, nullable=False)

    title = Column(String, nullable=False)
    description = Column(Text)

    responsible_user_id = Column(
        Integer, ForeignKey("universal_users.id", ondelete="SET NULL")
    )
    created_by_user_id = Column(
        Integer, ForeignKey("universal_users.id", ondelete="SET NULL")
    )

    status_id = Column(
        Integer, ForeignKey("statuses.id", ondelete="CASCADE"), default=1
    )

    pdf_file = Column(String)

    created_at = Column(DateTime, default=datetime.now, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.now, onupdate=datetime.now, nullable=False
    )

    planned_to = relationship(PlannedTO)
    responsible_user = relationship("UniversalUser", foreign_keys=[responsible_user_id])
    created_by_user = relationship("UniversalUser", foreign_keys=[created_by_user_id])
    status = relationship(Status)

    photos = relationship(
        "DefectiveActPhoto",
        back_populates="defective_act",
        cascade="all, delete-orphan",
    )
