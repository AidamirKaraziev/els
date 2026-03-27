from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel

from src.schemas.location import LocationGet


class SuperUserBase(BaseModel):
    id: int
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[Date]
    photo: Optional[str]
    location_id: Optional[LocationGet]
    is_super_user: Optional[bool]


class SuperUserRequest(BaseModel):
    name: Optional[str]
    email: Optional[str]
    password: Optional[str]
    contact_phone: Optional[str]
    birthday: Optional[int]
    # photo: Optional[str]
    location_id: Optional[int]
    is_super_user: Optional[bool]


class SuperUserCreate(BaseModel):
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    # photo: Optional[str]
    location_id: Optional[int]
    is_super_user: Optional[bool]


class SuperUserUpdate(BaseModel):
    name: Optional[str]
    email: Optional[str]
    password: Optional[str]
    contact_phone: Optional[str]
    birthday: Optional[Date]
    photo: Optional[str]
    location_id: Optional[int]
    is_super_user: Optional[bool]


class SuperUserGet(BaseModel):
    id: int
    name: Optional[str]
    email: Optional[str]
    contact_phone: Optional[str]
    birthday: Optional[int]
    photo: Optional[str]
    location_id: Optional[LocationGet]
    is_super_user: Optional[bool]


class SuperUserEntrance(BaseModel):
    email: str
    password: str


class SuperUserGetDelete(BaseModel):
    id: int
    name: Optional[str]
    email: Optional[str]
    contact_phone: Optional[str]
    birthday: Optional[int]
    photo: Optional[str]
    location_id: Optional[int]
    is_super_user: Optional[bool]
