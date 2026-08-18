from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from src.models.company import Company
from src.models.contact_person import ContactPerson
from src.models.contract import Contract
from src.models.division import Division
from src.models.factory_model import FactoryModel
from src.models.organization import Organization
from src.session import Base


class Object(Base):
    __tablename__ = "objects"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    organization_id = Column(
        Integer, ForeignKey("organizations.id", ondelete="SET NULL")
    )
    division_id = Column(Integer, ForeignKey("divisions.id", ondelete="SET NULL"))
    address = Column(String)
    # type_object_id = Column(Integer, ForeignKey("type_objects.id", ondelete="SET NULL"))  # (lift, lift_mr)

    factory_model_id = Column(
        Integer, ForeignKey("factories_models.id", ondelete="SET NULL")
    )
    factory_number = Column(String, unique=True)
    registration_number = Column(String, unique=True)

    number_of_stops = Column(Integer)
    lifting_heights = Column(Integer)
    load_capacity = Column(Integer)
    width = Column(Integer)

    cost_nds = Column(
        Integer
    )  # цены не особенно нужны потому что это цены объекта получаются
    cost_no_nds = Column(Integer)

    company_id = Column(Integer, ForeignKey("company.id", ondelete="SET NULL"))
    contact_person_id = Column(
        Integer, ForeignKey("contact_persons.id", ondelete="SET NULL")
    )
    contract_id = Column(Integer, ForeignKey("contracts.id", ondelete="SET NULL"))

    date_inspection = Column(Date)
    planned_inspection = Column(Date)
    period_inspection = Column(Date)

    foreman_id = Column(Integer, ForeignKey("universal_users.id", ondelete="SET NULL"))
    mechanic_id = Column(Integer, ForeignKey("universal_users.id", ondelete="SET NULL"))
    letter_of_appointment = Column(String)  # приказ о назначении

    #: Метка последней правки — по ней телефон механика спрашивает «что
    #: изменилось с момента T» и не тянет весь список заново.
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, index=True
    )

    acceptance_certificate = Column(String)
    act_pto = Column(String)
    geo = Column(String)
    is_actual = Column(Boolean, default=True)

    organization = relationship(Organization)
    division = relationship(Division)
    factory_model = relationship(FactoryModel)
    company_obj = relationship(Company)
    contract = relationship(Contract)
    contact_person = relationship(ContactPerson)
    foreman = relationship("UniversalUser", foreign_keys=[foreman_id])
    mechanic = relationship("UniversalUser", foreign_keys=[mechanic_id])
    __table_args__ = (
        UniqueConstraint(
            "factory_number", "registration_number", name="_factory_and_reg_number_uc"
        ),
    )
