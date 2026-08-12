# Старые модели баз данных, которые можно удалить в будущем
# from .user import User
# from .verif_code import VerifCode
# from .device import Device

from .location import Location
from .role import Role
from .division import Division
from .user_division import UserDivision
from .universal_user import UniversalUser
from .refresh_session import RefreshSession
from .type_object import TypeObject
from .object import Object
from .company import Company
from .factory_model import FactoryModel
from .organization import Organization
from .contact_person import ContactPerson
from .type_contract import TypeContract
from .cost_type import CostType
from .type_act import TypeAct
from .act_base import ActBase
from .status import Status
from .act_fact import ActFact
from .step import Step
from .sub_step import SubStep

from .order import Order
from .fault_category import FaultCategory
from .reason_fault import ReasonFault
from .order_photo import OrderPhoto
from .planned_to import PlannedTO
from .contract import Contract
from .working_specialty import WorkingSpecialty
from .defective_acts import DefectiveAct
from .defective_act_photo import DefectiveActPhoto

# удалил модель базы данных, потому что не понимаю зачем она
# from .act_fact_of_mechanic import ActFactOfMechanic
