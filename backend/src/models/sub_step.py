from sqlalchemy import Column, Integer, String

from src.session import Base


class SubStep(Base):
    __tablename__ = "sub_steps"
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
