from sqlalchemy import Column, Integer, String

from src.session import Base


class TypeAct(Base):
    __tablename__ = "types_acts"
    id = Column(Integer, primary_key=True, autoincrement=False)
    name = Column(String, unique=True)
