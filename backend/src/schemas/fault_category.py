from pydantic import BaseModel, Field


class FaultCategoryCreate(BaseModel):
    name: str = Field(..., title="категория неисправности")


class FaultCategoryUpdate(BaseModel):
    name: str = Field(..., title="категория неисправности")


class FaultCategoryGet(BaseModel):
    id: int = Field(..., title="ID категории неисправности")
    name: str = Field(..., title="категория неисправности")
