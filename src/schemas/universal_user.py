from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.company import CompanyGet
from src.schemas.divisions import DivisionGet
from src.schemas.location import LocationGet
from src.schemas.role import RoleGet
from src.schemas.working_specialty import WorkingSpecialtyGet


class UniversalUserBase(BaseModel):
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
    company_id: Optional[CompanyGet]
    division_id: Optional[DivisionGet]
    qualification_file: Optional[str]
    date_of_employment: Optional[Date]
    is_actual: Optional[bool]


# хз надо посмотреть для чего это, и почему не подходит UniversalUserUpdate
class UniversalUserRequest(BaseModel):
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    # photo: Optional[str]
    location_id: Optional[int]
    role_id: Optional[int]
    working_specialty_id: Optional[int]
    company_id: Optional[int]
    date_of_employment: Optional[int]
    # identity_card: Optional[str]


# Создание юзера
class UniversalUserCreate(BaseModel):
    id: Optional[int]
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    # photo: Optional[str]
    location_id: Optional[int]
    role_id: int
    working_specialty_id: Optional[int]
    # identity_card: Optional[str]
    company_id: Optional[int]  # переделать в CompanyGet
    division_id: Optional[int]
    date_of_employment: Optional[int]
    # qualification_file: Optional[str]
    # is_actual: Optional[bool]


# Изменение юзера
class UniversalUserUpdate(BaseModel):
    # id: int
    name: Optional[str]
    # email: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    # photo: Optional[str]
    location_id: Optional[int]
    # role_id: Optional[RoleGet]
    # working_specialty_id: Optional[WorkingSpecialtyGet]
    # identity_card: Optional[str]
    # qualification_file: Optional[str]
    # company_id: Optional[CompanyGet]
    # division_id: Optional[int]
    date_of_employment: Optional[int]
    # is_actual: Optional[bool]


# вывод юзера
class UniversalUserGet(BaseModel):
    id: int
    name: str
    email: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    photo: Optional[str]
    location_id: Optional[LocationGet]
    role_id: Optional[RoleGet]
    working_specialty_id: Optional[WorkingSpecialtyGet]
    identity_card: Optional[str]
    qualification_file: Optional[str]
    company_id: Optional[CompanyGet]
    division_id: Optional[DivisionGet]
    date_of_employment: Optional[int]
    is_actual: Optional[bool]


# Загрузить фото
class UniversalUserPhoto(BaseModel):
    photo: Optional[str]


# загрузить удостоверение
class UniversalUserIdentyCard(BaseModel):
    identy_card: Optional[str]


# вход
class UniversalUserEntrance(BaseModel):
    email: str
    password: str


class EmployeeCreate(BaseModel):
    # id: int
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    # photo: Optional[str]
    location_id: Optional[int]
    role_id: int
    working_specialty_id: Optional[int]
    # identity_card: Optional[str]
    # company_id: Optional[int]  # переделать в CompanyGet
    division_id: Optional[int]
    date_of_employment: Optional[int]
    # qualification_file: Optional[str]
    # is_actual: Optional[bool]


class ClientCreate(BaseModel):
    # id: int
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    # photo: Optional[str]
    location_id: Optional[int]
    role_id: int
    working_specialty_id: Optional[int]
    # identity_card: Optional[str]
    company_id: int = Field(..., title="Компания")  # переделать в CompanyGet

    # division_id: Optional[int]
    # qualification_file: Optional[str]
    # is_actual: Optional[bool]


# изменить участок
class UniversalUserDivision(BaseModel):
    division_id: int


class UniversalUserCompany(BaseModel):
    company_id: int


class UniversalUserIsActual(BaseModel):
    is_actual: bool
