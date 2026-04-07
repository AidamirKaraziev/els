from typing import List, Optional

from pydantic import BaseModel

from src.schemas.defective_act_photo import DefectiveActPhotoGet
from src.schemas.planned_to import PlannedTOGet
from src.schemas.status import StatusGet
from src.schemas.universal_user import UniversalUserGet


class DefectiveActCreate(BaseModel):
    planned_to_id: int
    month: int
    title: str
    description: Optional[str]
    responsible_user_id: int


class DefectiveActUpdate(BaseModel):
    planned_to_id: Optional[int]
    month: Optional[int]
    title: Optional[str]
    description: Optional[str]
    responsible_user_id: Optional[int]


class DefectiveActStatusUpdate(BaseModel):
    status_id: int


class DefectiveActGet(BaseModel):
    id: int
    planned_to_id: Optional[PlannedTOGet]
    month: int

    title: str
    description: Optional[str]

    responsible_user_id: Optional[UniversalUserGet]
    created_by_user_id: Optional[UniversalUserGet]

    status_id: Optional[StatusGet]
    pdf_file: Optional[str]

    created_at: Optional[int]
    updated_at: Optional[int]

    photos: List[DefectiveActPhotoGet] = []
