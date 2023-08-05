from sqlalchemy import Boolean, Column, Integer, String, Date

from app.db.base_class import Base


class FaultCategory(Base):
    __tablename__ = 'fault_category'
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, unique=True)
