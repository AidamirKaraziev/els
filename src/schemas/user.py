from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.location import LocationGet


class UserBase(BaseModel):
    id: int
    tel: str
    first_name: Optional[str]
    last_name: Optional[str]
    birthday: Optional[Date]
    location: Optional[LocationGet]
    photo_main: Optional[str]
    photo_1: Optional[str]
    photo_2: Optional[str]
    basic_about_me: Optional[str]
    job_title: Optional[str]
    company: Optional[str]
    about_me: Optional[str]
    contact_phone: Optional[str]
    telegram: Optional[str]


class UserGet(BaseModel):
    id: int
    tel: str
    first_name: Optional[str]
    last_name: Optional[str]
    birthday: Optional[int]
    location: Optional[LocationGet]
    photo_main: Optional[str]
    photo_1: Optional[str]
    photo_2: Optional[str]
    basic_about_me: Optional[str]
    job_title: Optional[str]
    company: Optional[str]
    about_me: Optional[str]
    contact_phone: Optional[str]
    telegram: Optional[str]


class UserCreate(BaseModel):
    tel: str


class DataToCreateUser(BaseModel):
    tel: str


class UserBasicUpdate(BaseModel):
    first_name: Optional[str] = Field(None, title="Имя ")
    last_name: Optional[str] = Field(None, title="Фамилия ")
    birthday: Optional[int] = Field(None, title="Дата рождения")
    location_id: Optional[int] = Field(None, title="Город ")
    basic_about_me: Optional[str] = Field(None, title="Основная информация 'Обо мне'")
    job_title: Optional[str]
    company: Optional[str]
    about_me: Optional[str]
    contact_phone: Optional[str]
    telegram: Optional[str]


class PhotoUser(BaseModel):
    photo: str = Field(..., title="Фотография")


class UserUpdateTel(BaseModel):
    tel: str = Field(..., title="Телефон")


# Properties to receive via API on update
class UserUpdate(UserBase):
    password: Optional[str] = None


class UserInDBBase(UserBase):
    id: Optional[int] = None

    class Config:
        orm_mode = True


# Additional properties to return via API
class User(UserInDBBase):
    pass


# Additional properties stored in DB
class UserInDB(UserInDBBase):
    hashed_password: str
