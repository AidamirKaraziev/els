from typing import Any, Generic, List, Optional, TypeVar

from pydantic import BaseModel, Field
from pydantic.generics import GenericModel


class Paginator(BaseModel):
    page: int = Field(1, ge=1)
    total: int = Field(1, ge=0)
    has_prev: bool
    has_next: bool


class Error(BaseModel):
    code: int = Field(0, ge=0, title="Code of reason")
    message: str = Field(0, title="Human readable description")
    path: str = Field(None, title="location")
    additional: Any


class Meta(BaseModel):
    paginator: Optional[Paginator]


class BaseResponse(BaseModel):
    message: str = Field(default="Ok")
    meta: Meta = Field(None)
    errors: List[Error] = Field([])
    description: str = Field(default="Выполнено")


Entity = TypeVar("Entity")


class OkResponse(BaseResponse):
    data: bool = None


class SingleEntityResponse(GenericModel, Generic[Entity], BaseResponse):
    data: Optional[Entity] = Field(None)


class ListOfEntityResponse(GenericModel, Generic[Entity], BaseResponse):
    data: Optional[List[Entity]] = Field([])


class TokenResponse(BaseResponse):
    token: str = Field(..., title="Сгенерированный токен!")
