from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from src.models import Object, Status, UniversalUser
from src.models.fault_category import FaultCategory
from src.models.reason_fault import ReasonFault
from src.session import Base


class Order(Base):
    __tablename__ = "order"
    id = Column(Integer, primary_key=True)
    object_id = Column(Integer, ForeignKey(Object.id, ondelete="SET NULL"))
    creator_id = Column(Integer, ForeignKey(UniversalUser.id, ondelete="SET NULL"))
    fault_category_id = Column(
        Integer, ForeignKey(FaultCategory.id, ondelete="SET NULL")
    )
    task_text = Column(String)

    executor_id = Column(Integer, ForeignKey(UniversalUser.id, ondelete="SET NULL"))
    commentary = Column(String)
    reason_fault_id = Column(Integer, ForeignKey(ReasonFault.id, ondelete="SET NULL"))

    created_at = Column(DateTime)
    accepted_at = Column(DateTime)
    in_progress_at = Column(DateTime)
    done_at = Column(DateTime)

    status_id = Column(Integer, ForeignKey(Status.id, ondelete="CASCADE"), default=1)
    is_viewed = Column(Boolean, default=False)

    #: Метка последней правки — по ней телефон механика спрашивает «что
    #: изменилось с момента T» и не тянет весь список заново.
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, index=True
    )

    #: Отметка прораба «работу проверил». Приёмки, блокирующей зачёт, нет:
    #: работа считается сделанной сразу, а отметка лишь гасит счётчик
    #: непросмотренного в ленте сданных работ.
    reviewed_at = Column(DateTime, index=True)
    reviewed_by_id = Column(Integer, ForeignKey(UniversalUser.id, ondelete="SET NULL"))

    object = relationship(Object)
    creator = relationship("UniversalUser", foreign_keys=[creator_id])
    reviewed_by = relationship("UniversalUser", foreign_keys=[reviewed_by_id])
    fault_category = relationship(FaultCategory)
    executor = relationship("UniversalUser", foreign_keys=[executor_id])
    reason_fault = relationship(ReasonFault)
    status = relationship(Status)

    order_photo = relationship(
        "OrderPhoto", back_populates="order", uselist=False, lazy="joined"
    )
