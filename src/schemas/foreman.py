from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel

from src.schemas.divisions import DivisionGet
from src.schemas.location import LocationGet
from src.schemas.role import RoleGet
from src.schemas.working_specialty import WorkingSpecialtyGet


class ForemanBase(BaseModel):
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
    division_id: Optional[str]
    # company_id: Optional[int]  # переделать в CompanyGet
    qualification_file: Optional[str]
    is_actual: Optional[bool]


# # хз надо посмотреть для чего это, и почему не подходит ForemanUpdate
# class ForemanRequest(BaseModel):
#     name: str
#     email: str
#     password: str
#     contact_phone: Optional[str]
#     birthday: Optional[Date]
#     # photo: Optional[str]
#     location_id: Optional[int]
#     role_id: Optional[int]
#     working_specialty_id: Optional[int]
#     # company_id: Optional[int]
#     # identity_card: Optional[str]


# скорее всего это не нужно будет НАХЕР
# Создание юзера
class ForemanCreate(BaseModel):
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[Date]
    # photo: Optional[str]
    location_id: Optional[int]
    role_id: int = 2
    working_specialty_id: Optional[int]
    division_id: Optional[int]


# вывод юзера
class ForemanGet(BaseModel):
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
    division_id: Optional[DivisionGet]
    # company_id: Optional[int]  # переделать в CompanyGet
    qualification_file: Optional[str]
    is_actual: Optional[bool]


# Загрузить фото
class ForemanPhoto(BaseModel):
    photo: Optional[str]


# загрузить удостоверение
class ForemanIdentyCard(BaseModel):
    identy_card: Optional[str]


# Загрузить ЦОК
class ForemanQualificationFile(BaseModel):
    qualification_file: Optional[str]
