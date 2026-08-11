from sqlalchemy import Column, Integer, String

from src.session import Base


class Location(Base):
    __tablename__ = "locations"
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
