from typing import Optional

from pydantic import BaseModel


class DefectiveActPhotoGet(BaseModel):
    id: int
    defective_act_id: int
    photo: Optional[str]
    created_at: Optional[int]
    created_by_user_id: Optional[int]


class DefectiveActPhotoCreate(BaseModel):
    defective_act_id: int
    photo: str


class DefectiveActPhotoUpdate(BaseModel):
    photo: Optional[str]
