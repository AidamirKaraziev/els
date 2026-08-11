from pydantic import BaseModel, Field


class StageOfImplementationCreate(BaseModel):
    name: str = Field(..., title="Название стадии")


class StageOfImplementationUpdate(BaseModel):
    name: str = Field(..., title="Название стадии")


class StageOfImplementationGet(BaseModel):
    id: int = Field(..., title="Идентификатор стадии")
    name: str = Field(..., title="Название стадии")
