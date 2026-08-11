from sqlalchemy import Column, Integer, String

from src.session import Base


class Step(Base):
    __tablename__ = "steps"
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
