from sqlalchemy import Column, Integer, String

from src.session import Base


class FaultCategory(Base):
    __tablename__ = "fault_category"
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, unique=True)
