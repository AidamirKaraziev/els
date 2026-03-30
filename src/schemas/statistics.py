from typing import Optional

from pydantic import BaseModel, Field


class TopBreakdownItem(BaseModel):
    object_id: int = Field(..., title="ID объекта (лифта)")
    object_number: str = Field(..., title="Номер или название объекта для отображения")
    client: Optional[str] = Field(
        None, title="Клиент: организация объекта или компания (если организации нет)"
    )
    responsible_mechanic: Optional[str] = Field(
        None, title="Механик, закреплённый за объектом"
    )
    breakdown_count: int = Field(..., ge=0, title="Количество поломок за период")

    class Config:
        orm_mode = True
