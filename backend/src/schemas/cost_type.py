from pydantic import BaseModel, Field


class CostTypeCreate(BaseModel):
    name: str = Field(..., title="тип цены")


class CostTypeUpdate(BaseModel):
    name: str = Field(..., title="тип цены")


class CostTypeGet(BaseModel):
    id: int = Field(..., title="ID тип цены")
    name: str = Field(..., title="тип цены")
