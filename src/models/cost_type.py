from sqlalchemy import Column, Integer, String

from src.session import Base


class CostType(Base):
    __tablename__ = "cost_types"
    id = Column(Integer, primary_key=True, autoincrement=False)
    name = Column(String, unique=True)
