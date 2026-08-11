from pydantic import BaseModel, Field


class StepCreate(BaseModel):
    name: str = Field(..., title="Название Шага")


class StepUpdate(BaseModel):
    name: str = Field(..., title="Название Шага")


class StepGet(BaseModel):
    id: int = Field(..., title="ID Шага")
    name: str = Field(..., title="Название Шага")
