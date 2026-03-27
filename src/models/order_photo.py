from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from src.models import Order
from src.session import Base


class OrderPhoto(Base):
    __tablename__ = "order_photo"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(
        Integer, ForeignKey(Order.id, ondelete="SET NULL"), nullable=False
    )
    order = relationship("Order", back_populates="order_photo", lazy="joined")

    photo = Column(String)
