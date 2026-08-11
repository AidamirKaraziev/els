from pydantic import BaseModel, Field


class ActFactOfMechanic(BaseModel):
    id: int = Field(None, title="id")
    act_fact_id: int = Field(None, title="id проекта")
    mechanic_id: int = Field(None, title="id сферы деятельности")


class ActFactOfMechanicCreate(BaseModel):
    act_fact_id: int = Field(None, title="id проекта")
    mechanic_id: int = Field(None, title="id сферы деятельности")


class ActFactOfMechanicUpdate(BaseModel):
    pass
