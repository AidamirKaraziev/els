from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from src.session import Base


class DefectiveActPhoto(Base):
    __tablename__ = "defective_act_photo"

    id = Column(Integer, primary_key=True, autoincrement=True)
    defective_act_id = Column(
        Integer, ForeignKey("defective_acts.id", ondelete="CASCADE"), nullable=False
    )
    photo = Column(String)

    created_at = Column(DateTime, default=datetime.now, nullable=False)
    created_by_user_id = Column(
        Integer, ForeignKey("universal_users.id", ondelete="SET NULL")
    )

    defective_act = relationship("DefectiveAct", back_populates="photos", lazy="joined")
    created_by_user = relationship("UniversalUser", foreign_keys=[created_by_user_id])
