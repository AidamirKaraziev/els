from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.universal_user import UniversalUserGet


class OrganizationBase(BaseModel):
    id: int = Field(..., title="ID организации")
    title: str = Field(..., title="Название организации")
    director_id: Optional[int]
    phone_office: Optional[str]
    phone_dispatcher: Optional[str]
    phone_accountant: Optional[str]
    photo: Optional[str]
    email: Optional[str]
    site: Optional[str]
    address: Optional[str]
    is_actual: bool


class OrganizationCreate(BaseModel):
    # id: int = Field(..., title="ID организации")
    title: str = Field(..., title="Название организации")
    director_id: Optional[int]
    phone_office: Optional[str]
    phone_dispatcher: Optional[str]
    phone_accountant: Optional[str]
    # photo: Optional[str]
    email: Optional[str]
    site: Optional[str]
    address: Optional[str]
    # is_actual: bool


class OrganizationUpdate(BaseModel):
    # id: int = Field(..., title="ID организации")
    title: str = Field(..., title="Название организации")
    director_id: Optional[int]
    phone_office: Optional[str]
    phone_dispatcher: Optional[str]
    phone_accountant: Optional[str]
    # photo: Optional[str]
    email: Optional[str]
    site: Optional[str]
    address: Optional[str]
    # is_actual: bool


class OrganizationGet(BaseModel):
    id: int = Field(..., title="ID организации")
    title: str = Field(..., title="Название организации")
    director_id: Optional[UniversalUserGet]
    phone_office: Optional[str]
    phone_dispatcher: Optional[str]
    phone_accountant: Optional[str]
    photo: Optional[str]
    email: Optional[str]
    site: Optional[str]
    address: Optional[str]
    is_actual: bool


class OrganizationPhoto(BaseModel):
    photo: Optional[str]


class OrganizationGetById(BaseModel):
    id: Optional[int]


# class CompanyRemove(BaseModel):
#     is_actual
