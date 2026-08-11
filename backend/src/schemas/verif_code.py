from datetime import date
from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel, Field


class GettingVerifCode(BaseModel):
    id: Optional[int]
    value: Optional[str]
    tel: Optional[str]
    created_at: Optional[Date]
    actual: Optional[bool]


class VerifBase(BaseModel):
    value: str
    tel: str
    created_at: date


class VerifCode(VerifBase):
    id: int

    class Config:
        orm_mode = True


class VerifCodeSaveOnBase(BaseModel):
    value: str
    tel: str


class CheckCode(BaseModel):
    tel: str
    value: str


# Field(...,title='Код телефона без +',regex=r'\d{11,12}')


# для создания
class VerifCodeCreate(BaseModel):
    tel: str = Field(..., title="Код телефона без +", regex=r"^\d{11,12}$")


class VerifCodesUpdate(BaseModel):
    pass


class VerifCodeGet(BaseModel):
    code: str = Field(..., title="Сгенерированный код подтверждения")


class UsedVerifCode(BaseModel):
    actual: bool = (...,)
