from sqlalchemy import Column, Integer, String

from src.session import Base


class ReasonFault(Base):
    __tablename__ = "reason_fault"
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, unique=True)
