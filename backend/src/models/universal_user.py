from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    func,
)
from sqlalchemy.orm import relationship

from src.models import Location
from src.models.company import Company
from src.models.division import Division
from src.models.role import Role
from src.models.working_specialty import WorkingSpecialty
from src.session import Base


class UniversalUser(Base):
    __tablename__ = "universal_users"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    email = Column(String, nullable=False)
    hashed_password = Column(String)
    contact_phone = Column(String)
    birthday = Column(Date)
    photo = Column(String)
    location_id = Column(Integer, ForeignKey("locations.id", ondelete="SET NULL"))
    role_id = Column(Integer, ForeignKey("roles.id", ondelete="SET NULL"))
    working_specialty_id = Column(
        Integer, ForeignKey("working_specialty.id", ondelete="SET NULL")
    )
    identity_card = Column(String)
    # Основной участок. Полный список участков — в `divisions` ниже: сотрудник
    # может вести несколько, и проверки доступа смотрят именно туда.
    division_id = Column(Integer, ForeignKey("divisions.id", ondelete="SET NULL"))
    company_id = Column(Integer, ForeignKey("company.id", ondelete="SET NULL"))
    qualification_file = Column(String)
    date_of_employment = Column(Date)
    is_active = Column(Boolean, default=True)

    # Гасит access-токены, выданные до смены пароля: сравниваем с `iat` токена.
    password_changed_at = Column(DateTime)
    # Защита от перебора пароля.
    failed_login_attempts = Column(Integer, nullable=False, server_default="0")
    locked_until = Column(DateTime)

    working_specialty = relationship(WorkingSpecialty)
    location = relationship(Location)
    role = relationship(Role)
    company = relationship(Company)
    division = relationship(Division)
    divisions = relationship(
        Division,
        secondary="user_divisions",
        order_by="Division.id",
        viewonly=False,
    )

    __table_args__ = (
        # Уникальность по нижнему регистру, а не по строке как есть. Прежнее
        # ограничение `(email, is_actual)` уникальности не давало вовсе: NULL в
        # булевом поле обходил его, а два адреса, различающиеся регистром,
        # считались разными — при этом вход искал по точному совпадению, и
        # человек, набравший адрес строчными, просто не заходил.
        Index(
            "uq_universal_users_email_lower",
            func.lower(email),
            unique=True,
        ),
    )
