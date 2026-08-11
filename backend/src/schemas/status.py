from pydantic import BaseModel, Field


class StatusCreate(BaseModel):
    name: str = Field(..., title="Статус")


class StatusUpdate(BaseModel):
    name: str = Field(..., title="Статус")


class StatusGet(BaseModel):
    id: int = Field(..., title="ID Статуса")
    name: str = Field(..., title="Статус")
