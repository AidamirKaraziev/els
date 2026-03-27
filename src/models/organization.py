from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from src.models import UniversalUser
from src.session import Base


class Organization(Base):
    __tablename__ = "organizations"
    id = Column(Integer, primary_key=True)
    title = Column(String, unique=True)
    director_id = Column(Integer, ForeignKey("universal_users.id", ondelete="SET NULL"))
    phone_office = Column(String)
    phone_dispatcher = Column(String)
    phone_accountant = Column(String)
    photo = Column(String)
    site = Column(String)
    email = Column(String)
    address = Column(String)
    is_actual = Column(Boolean, default=True)

    director = relationship(UniversalUser)
