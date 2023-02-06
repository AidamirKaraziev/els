from sqlalchemy import Boolean, Column, Integer, String, Date, ForeignKey, UniqueConstraint
# List append in sqlalchemy

from sqlalchemy.orm import relationship

from app.db.base_class import Base


from app.models.contact_person import ContactPerson
from app.models.contract import Contract
from app.models.factory_model import FactoryModel
from app.models.organization import Organization
from app.models.division import Division
from app.models.company import Company
from app.models.universal_user import UniversalUser


class Object(Base):
    __tablename__ = "objects"
    id = Column(Integer, primary_key=True)
    # name = Column(String)
    organization_id = Column(Integer, ForeignKey('organizations.id', ondelete="SET NULL"))
    division_id = Column(Integer, ForeignKey('divisions.id', ondelete="SET NULL"))
    address = Column(String)
    # type_object_id = Column(Integer, ForeignKey("type_objects.id", ondelete="SET NULL"))  # (lift, lift_mr)

    factory_model_id = Column(Integer, ForeignKey("factories_models.id", ondelete="SET NULL"))
    factory_number = Column(String, unique=True)
    registration_number = Column(String, unique=True)

    number_of_stops = Column(Integer)
    lifting_heights = Column(Integer)
    load_capacity = Column(Integer)
    width = Column(Integer)

    # эта часть под вопросом
    cost_nds = Column(Integer)  # цены не особенно нужны потому что это цены объекта получаются
    cost_no_nds = Column(Integer)

    company_id = Column(Integer, ForeignKey("company.id", ondelete="SET NULL"))
    contact_person_id = Column(Integer, ForeignKey("contact_persons.id", ondelete="SET NULL"))
    contract_id = Column(Integer, ForeignKey("contracts.id", ondelete="SET NULL"))

    date_inspection = Column(Date)
    planned_inspection = Column(Date)
    period_inspection = Column(Date)

    foreman_id = Column(Integer, ForeignKey("universal_users.id", ondelete="SET NULL"))
    mechanic_id = Column(Integer, ForeignKey("universal_users.id", ondelete="SET NULL"))
    letter_of_appointment = Column(String)  # приказ о назначении

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
    __table_args__ = (UniqueConstraint('factory_number', 'registration_number', name='_factory_and_reg_number_uc'),
                      )

# class DefectiveActBase(Base):  # TEST
#     __tablename__ = "defective_acts_bases"
#     id = Column(Integer, primary_key=True)
#     model_id = Column(Integer, ForeignKey("factories_models.id", ondelete="SET NULL"))
#     # type_act_id = Column(Integer, ForeignKey)
#     step_list = Column(List)

#
# class DefectiveActFact(Base):
#     pass
#
#
# class ActBase(Base):
#     __tablename__ = "acts_bases"
#     id = Column(Integer, primary_key=True)
#     factory_model_id = Column(Integer, ForeignKey("factories_models.id", ondelete="SET NULL"))
#     type_act_id = Column(Integer, ForeignKey)
#     step_list = Column(List)
#
#
# class TypeObject(Base):
#     __tablename__ = "type_objects"
#     id = Column(Integer, primary_key=True)
#     name = Column(String, unique=True)
#
#
# class TypeAct(Base):
#     __tablename__ = "type_acts"
#     id = Column(Integer, primary_key=True)
#     name = Column(String, unique=True)  # (1,3,6,12, defective)
#
#
# class ActFact(Base):  # TEST
#     __tablename__ = "acts"
#     id = Column(Integer, primary_key=True)
#
#     act_base_id = Column(Integer, ForeignKey("acts_bases.id", ondelete="SET NULL"))
#
#     step_list_done = Column(List)
#     date_create = Column(Date)
#     date_start = Column(Date)
#     date_finish = Column(Date)
#     file = Column(String)
#
#     foreman_id = Column(Integer, ForeignKey)
#     mechanic_id = Column(Integer, ForeignKey)
#     status = Column(Boolean)
#
#
#