from typing import Optional

from pydantic import BaseModel, Field


class ActFactStepPhotoGet(BaseModel):
    id: int = Field(..., title="ID фотографии")
    act_fact_id: int = Field(..., title="ID фактического акта")
    step_id: int = Field(
        ...,
        title="Номер шага чек-листа",
        description=(
            "Тот же `id`, что у пункта в `checklist`. Шаги нельзя переставлять "
            "после начала работ: снимок ссылается на номер, а не на текст."
        ),
    )
    photo: Optional[str] = Field(None, title="Ссылка на файл")
    created_at: Optional[int] = Field(None, title="Когда загружена")


class ActFactStepPhotoCreate(BaseModel):
    act_fact_id: int
    step_id: int
    photo: str


class ActFactStepPhotoUpdate(BaseModel):
    photo: Optional[str]
