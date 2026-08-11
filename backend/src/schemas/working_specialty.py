from pydantic import BaseModel, Field


class WorkingSpecialtyCreate(BaseModel):
    name: str = Field(..., title="Специальность")


class WorkingSpecialtyUpdate(BaseModel):
    name: str = Field(..., title="Специальность")


class WorkingSpecialtyGet(BaseModel):
    id: int = Field(..., title="ID специальности")
    name: str = Field(..., title="Специальность")
