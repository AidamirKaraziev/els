from pydantic import BaseModel, Field


class TypeActCreate(BaseModel):
    name: str = Field(..., title="название акта")


class TypeActUpdate(BaseModel):
    name: str = Field(..., title="название акта")


class TypeActGet(BaseModel):
    id: int = Field(..., title="ID акта")
    name: str = Field(..., title="Название акта")
