from sqlalchemy import Column, Integer, String

from src.session import Base


class WorkingSpecialty(Base):
    __tablename__ = "working_specialty"
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
