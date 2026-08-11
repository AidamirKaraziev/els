# import sqlalchemy as sa
# from sqlalchemy import ForeignKey
# from sqlalchemy.ext.declarative import declarative_base
#
# from datetime import datetime
# from typing import TYPE_CHECKING
#
# from sqlalchemy import Boolean, Column, Integer, String, DateTime
# from sqlalchemy.orm import relationship
#
# from src.db.base_class import Base
#
# # if TYPE_CHECKING:
# #     from .item import Item  # noqa: F401
#
# # Base = declarative_base()
#
#
# class VerifCode(Base):
#     __tablename__ = 'verif_code'
#     id = Column(Integer, primary_key=True)
#     value = Column(String, nullable=True)
#     tel = Column(String)
#     created_at = Column(DateTime, default=datetime.utcnow)
#     actual = Column(Boolean, default=True)
