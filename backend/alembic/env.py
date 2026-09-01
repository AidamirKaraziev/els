from src.config import settings
from alembic import context
from sqlalchemy import engine_from_config, pool
from logging.config import fileConfig

from src.session import Base


config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

fileConfig(config.config_file_name)

from src.models.location import Location
from src.models.role import Role
from src.models.division import Division
from src.models.user_division import UserDivision
from src.models.universal_user import UniversalUser
from src.models.refresh_session import RefreshSession
from src.models.type_object import TypeObject
from src.models.object import Object
from src.models.company import Company
from src.models.factory_model import FactoryModel
from src.models.organization import Organization
from src.models.contact_person import ContactPerson
from src.models.type_contract import TypeContract
from src.models.cost_type import CostType
from src.models.type_act import TypeAct
from src.models.act_base import ActBase
from src.models.status import Status
from src.models.act_fact import ActFact
from src.models.step import Step
from src.models.sub_step import SubStep
from src.models.order import Order
from src.models.fault_category import FaultCategory
from src.models.reason_fault import ReasonFault
from src.models.order_photo import OrderPhoto
from src.models.planned_to import PlannedTO
from src.models.contract import Contract
from src.models.working_specialty import WorkingSpecialty
from src.models.area_of_responsibility import AreaOfResponsibility
from src.models.defective_acts import DefectiveAct
from src.models.defective_act_photo import DefectiveActPhoto
from src.models.maintenance_program import MaintenanceProgram, MaintenanceProgramItem


target_metadata = Base.metadata


def run_migrations_offline():
    context.configure(
        url=settings.DB_URL, target_metadata=target_metadata, literal_binds=True, compare_type=True
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = settings.DB_URL
    connectable = engine_from_config(
        configuration, prefix="sqlalchemy.", poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata, compare_type=True
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
