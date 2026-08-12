"""Схемы запросов и ответов.

Импорты здесь ничего не переэкспортируют для остального кода: все модули
ходят за схемами напрямую (`from src.schemas.object import ObjectGet`).
Список нужен только затем, чтобы `import src.schemas` подтягивал модули
целиком — на это опирались звёздочные импорты прежнего подрядчика.
"""

from .act_base import *
from .act_fact import *
from .admin import *
from .client import *
from .company import CompanyGet, CompanyCreate, CompanyUpdate
from .contact_person import *
from .contract import *
from .cost_type import *
from .divisions import *
from .factory_model import *
from .fault_category import *
from .foreman import *
from .location import LocationGet, LocationCreate, LocationUpdate
from .object import *
from .order import *
from .organization import *
from .planned_to import *
from .reason_fault import *
from .role import RoleGet, RoleCreate, RoleUpdate
from .status import *
from .step import *
from .sub_step import *
from .type_act import *
from .type_object import *
from .type_contract import *
from .universal_user import *
from .working_specialty import (
    WorkingSpecialtyGet,
    WorkingSpecialtyCreate,
    WorkingSpecialtyUpdate,
)
