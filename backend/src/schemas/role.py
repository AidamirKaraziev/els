from pydantic import BaseModel, Field


class RoleCreate(BaseModel):
    name: str = Field(..., title="Должность")


class RoleUpdate(BaseModel):
    name: str = Field(..., title="Должность")


class RoleGet(BaseModel):
    id: int = Field(..., title="ID Должности")
    name: str = Field(..., title="Должность")
