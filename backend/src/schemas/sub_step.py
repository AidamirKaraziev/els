from pydantic import BaseModel, Field


class SubStepCreate(BaseModel):
    name: str = Field(..., title="Название Подэтапа")


class SubStepUpdate(BaseModel):
    name: str = Field(..., title="Название Подэтапа")


class SubStepGet(BaseModel):
    id: int = Field(..., title="ID Подэтапа")
    name: str = Field(..., title="Название Подэтапа")
