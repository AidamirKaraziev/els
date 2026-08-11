from pydantic import BaseModel, Field


class ReasonFaultCreate(BaseModel):
    name: str = Field(..., title="Причина неисправности")


class ReasonFaultUpdate(BaseModel):
    name: str = Field(..., title="Причина неисправности")


class ReasonFaultGet(BaseModel):
    id: int = Field(..., title="ID Причина неисправности")
    name: str = Field(..., title="Причина неисправности")
