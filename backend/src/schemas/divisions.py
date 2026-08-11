from typing import Optional

from pydantic import BaseModel, Field


class DivisionBase(BaseModel):
    id: int = Field(..., title="ID Компании")
    title: str = Field(..., title="Название Участка")
    photo: Optional[str]
    is_actual: bool


class DivisionCreate(BaseModel):
    # id: int = Field(..., title="ID Компании")
    title: str = Field(..., title="Название Участка")
    # photo: Optional[str]
    # is_actual: bool


class DivisionUpdate(BaseModel):
    # id: int = Field(..., title="ID Компании")
    title: str = Field(..., title="Название Участка")
    # photo: Optional[str]
    # is_actual: bool


class DivisionGet(BaseModel):
    id: int = Field(..., title="ID Компании")
    title: str = Field(..., title="Название Участка")
    photo: Optional[str]
    is_actual: bool


class DivisionPhoto(BaseModel):
    photo: Optional[str]


# class DivisionGetById(BaseModel):
#     id: Optional[int]


# class DivisionRemove(BaseModel):
#     is_actual
