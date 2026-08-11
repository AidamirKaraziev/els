from pydantic import BaseModel, Field


class TypeObjectCreate(BaseModel):
    name: str = Field(..., title="название объекта")


class TypeObjectUpdate(BaseModel):
    name: str = Field(..., title="название объекта")


class TypeObjectGet(BaseModel):
    id: int = Field(..., title="ID объекта")
    name: str = Field(..., title="Название объекта")
