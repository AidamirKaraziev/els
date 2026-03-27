from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.area_of_responsibility import AreaOfResponsibilityGet
from src.schemas.location import LocationGet


class ModeratorBase(BaseModel):
    id: int
    login: str
    password: str
    tel: Optional[str]
    first_name: Optional[str]
    last_name: Optional[str]
    birthday: Optional[Date]
    location: Optional[LocationGet]
    closed_appeals: Optional[int]
    open_appeals: Optional[int]
    photo: Optional[str]
    area_of_responsibility: Optional[AreaOfResponsibilityGet]  # C
    average_first_response_time: Optional[int]  # или формат должен быть временной
    is_superuser: Optional[bool]


class ModeratorRequest(BaseModel):
    login: Optional[str]
    password: Optional[str]
    tel: Optional[str]
    first_name: Optional[str]
    last_name: Optional[str]
    birthday: Optional[int]
    location_id: Optional[int]
    # photo: Optional[str]
    area_of_responsibility_id: Optional[int]  # C
    average_first_response_time: Optional[int]  # или формат должен быть временной
    is_superuser: Optional[bool] = Field(False, title="Этот юзер супер?")


# class ModeratorRequest(BaseModel):
#     login: str
#     password: str
#     tel: Optional[str]
#     first_name: Optional[str]
#     last_name: Optional[str]
#     birthday: Optional[Date]
#     location_id: Optional[int]
#     photo: Optional[str]
#     # area_of_responsibility_id: Optional[int]  # C
#     average_first_response_time: Optional[int]  # или формат должен быть временной
#     # is_superuser: Optional[bool] = Field(False, title="Этот юзер супер?")


class ModeratorCreate(BaseModel):
    login: str
    password: str
    tel: Optional[str]
    first_name: Optional[str]
    last_name: Optional[str]
    birthday: Optional[Date]
    location_id: Optional[int]
    photo: Optional[str]
    area_of_responsibility_id: Optional[int]  # C
    average_first_response_time: Optional[int]  # или формат должен быть временной
    is_superuser: Optional[bool] = Field(False, title="Этот юзер супер?")


class ModeratorPhoto(BaseModel):
    photo: str = Field(..., title="Фотография")


class ModeratorUpdate(BaseModel):
    pass


class ModeratorGet(BaseModel):
    id: int
    login: str
    tel: Optional[str]
    first_name: Optional[str]
    last_name: Optional[str]
    birthday: Optional[int]
    location: Optional[LocationGet]
    photo: Optional[str]
    area_of_responsibility: Optional[AreaOfResponsibilityGet]  # C
    average_first_response_time: Optional[int]  # или формат должен быть временной
    is_superuser: Optional[bool]


class ModeratorEntrance(BaseModel):
    login: str
    password: str


class ModeratorGetDelete(BaseModel):
    id: int
    login: str
    tel: Optional[str]
    first_name: Optional[str]
    last_name: Optional[str]
    birthday: Optional[int]
    location: Optional[int]
    photo: Optional[str]
    area_of_responsibility: Optional[int]  # C
    average_first_response_time: Optional[int]  # или формат должен быть временной
    is_superuser: Optional[bool]
