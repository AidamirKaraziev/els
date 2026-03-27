from pydantic import BaseModel, Field


class LocationCreate(BaseModel):
    name: str = Field(..., title="Название города")


class LocationUpdate(BaseModel):
    name: str = Field(..., title="Название города")


class LocationGet(BaseModel):
    id: int = Field(..., title="Идентификатор города")
    name: str = Field(..., title="Название города")
