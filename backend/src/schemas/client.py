from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel, Field

from src.core.roles import CLIENT_ID
from src.schemas.company import CompanyGet
from src.schemas.location import LocationGet
from src.schemas.role import RoleGet
from src.schemas.working_specialty import WorkingSpecialtyGet


class ClientBase(BaseModel):
    id: int
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[Date]
    photo: Optional[str]
    location_id: Optional[LocationGet]
    role_id: Optional[RoleGet]
    working_specialty_id: Optional[WorkingSpecialtyGet]
    identity_card: Optional[str]
    company_id: Optional[int]
    is_actual: Optional[bool]


class ClientCreate(BaseModel):
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    location_id: Optional[int]
    role_id: int = CLIENT_ID
    company_id: int = Field(..., title="Компания")


class ClientUpdateSelf(BaseModel):
    name: Optional[str]
    contact_phone: Optional[str]
    birthday: Optional[int]
    location_id: Optional[int]


class ClientGet(BaseModel):
    id: int
    name: str
    email: str
    contact_phone: Optional[str]
    birthday: Optional[Date]
    photo: Optional[str]
    location_id: Optional[LocationGet]
    role_id: Optional[RoleGet]
    working_specialty_id: Optional[WorkingSpecialtyGet]
    identity_card: Optional[str]
    company_id: Optional[CompanyGet]
    is_actual: Optional[bool]
