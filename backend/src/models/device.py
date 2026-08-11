# from datetime import datetime
# from typing import TYPE_CHECKING
#
#
# from sqlalchemy import Boolean, Column, Integer, String, Enum, ForeignKey, DateTime
# from sqlalchemy.dialects.postgresql import INET
# from sqlalchemy.orm import relationship
#
# from src.db.base_class import Base
#
# # from src.models.user import User
#
#
# class Device(Base):
#     # __tablename__ = 'device'
#     id = Column(Integer, primary_key=True, index=True)
#     ip_address = Column(INET(), nullable=True)
#     x_real_ip = Column(INET(), nullable=True)
#     user_agent = Column(String(), nullable=True)
#     accept_language = Column(String(), nullable=True)
#     created = Column(DateTime(), nullable=True, default=datetime.utcnow)
#     detected_os = Column(String(), nullable=True)
#
#     user_id = Column(Integer(), ForeignKey(User.id, ondelete="CASCADE"), nullable=False)
#
#     user = relationship(User, back_populates='devices')
#     firebase_tokens = relationship("FirebaseToken", cascade="all, delete-orphan", back_populates="device")
