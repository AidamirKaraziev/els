from sqlalchemy import Column, Integer, String

from app.db.base_class import Base


class AreaOfResponsibility(Base):
    __tablename__ = 'area_of_responsibility'
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
