from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from src.models import Location
from src.session import Base


class Company(Base):
    __tablename__ = "company"
    id = Column(Integer, primary_key=True)
    name = Column(String)

    director_name = Column(String)
    cont_phone = Column(String)
    email = Column(String)
    cont_address = Column(String)
    photo = Column(String)
    location_id = Column(Integer, ForeignKey("locations.id", ondelete="SET NULL"))
    site = Column(String)

    is_actual = Column(Boolean, default=True)

    location = relationship(Location)
