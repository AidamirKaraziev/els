from typing import Optional

from pydantic import BaseModel, Field


class FaultCategoryCreate(BaseModel):
    name: str = Field(..., title="категория неисправности")
    code: Optional[str] = Field(
        None, title="короткий код категории", description="Например AA, А, ТО, КР"
    )
    counts_as_breakdown: bool = Field(
        True,
        title="считать заявки этой категории поломкой",
        description=(
            "False у плановых работ, капремонта и ложных вызовов — "
            "такие заявки не попадают в статистику поломок."
        ),
    )


class FaultCategoryUpdate(BaseModel):
    name: str = Field(..., title="категория неисправности")
    code: Optional[str] = Field(None, title="короткий код категории")
    counts_as_breakdown: Optional[bool] = Field(
        None, title="считать заявки этой категории поломкой"
    )


class FaultCategoryGet(BaseModel):
    id: int = Field(..., title="ID категории неисправности")
    name: str = Field(..., title="категория неисправности")
    code: Optional[str] = Field(None, title="короткий код категории")
    counts_as_breakdown: bool = Field(
        True, title="считать заявки этой категории поломкой"
    )
