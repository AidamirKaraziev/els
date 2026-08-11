from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.company import CompanyGet


class ContactPersonBase(BaseModel):
    id: int = Field(..., title="ID")
    name: str = Field(..., title="Имя")
    company_id: Optional[int]
    # company_id = Optional[CompanyGet]
    phone: Optional[str]
    email: Optional[str]
    address: Optional[str]
    photo: Optional[str]
    is_actual: bool


class ContactPersonCreate(BaseModel):
    name: Optional[str]
    company_id: Optional[int]
    phone: Optional[str]
    phone: str = Field(..., title="телефон")
    email: Optional[str]
    address: Optional[str]
    # photo: Optional[str]


class ContactPersonUpdate(BaseModel):
    name: Optional[str]
    company_id: Optional[int]
    phone: Optional[str]
    email: Optional[str]
    address: Optional[str]
    # photo: Optional[str]


class ContactPersonGet(BaseModel):
    id: int = Field(..., title="ID")
    name: str = Field(..., title="Имя")
    company_id: Optional[CompanyGet]
    phone: Optional[str]
    email: Optional[str]
    address: Optional[str]
    photo: Optional[str]
    is_actual: bool


class ContactPersonPhoto(BaseModel):
    photo: Optional[str]


class ContactPersonGetById(BaseModel):
    id: Optional[int]


# class ContactPersonRemove(BaseModel):
#     is_actual
