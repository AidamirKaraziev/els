from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.location import LocationGet


class CompanyCreate(BaseModel):
    name: str = Field(..., title="Название Компании")
    director_name: Optional[str] = Field(..., title="Директор")
    cont_phone: Optional[str]
    cont_address: Optional[str]
    email: Optional[str]
    site: Optional[str]
    location_id: Optional[int]


class CompanyUpdate(BaseModel):
    name: Optional[str]
    director_name: Optional[str]  # = Field(..., title="Директор")
    cont_phone: Optional[str]
    cont_address: Optional[str]
    email: Optional[str]
    site: Optional[str]
    location_id: Optional[int]


class CompanyGet(BaseModel):
    id: int = Field(..., title="ID Компании")
    name: str = Field(..., title="Название Компании")
    director_name: Optional[str] = Field(..., title="Директор")
    cont_phone: Optional[str]
    cont_address: Optional[str]
    photo: Optional[str]
    email: Optional[str]
    site: Optional[str]
    location_id: Optional[LocationGet]
    is_actual: bool


class CompanyPhoto(BaseModel):
    photo: Optional[str]


class CompanyGetById(BaseModel):
    id: Optional[int]


# class CompanyRemove(BaseModel):
#     is_actual
