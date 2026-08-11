from sqlalchemy import Column, Integer, String

from src.session import Base


class TypeContract(Base):
    __tablename__ = "types_contracts"
    id = Column(Integer, primary_key=True, autoincrement=False)
    name = Column(String, unique=True)
