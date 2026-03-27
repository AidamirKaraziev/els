from typing import Optional

from pydantic import BaseModel


# Создание юзера
class AdminCreate(BaseModel):
    name: str
    email: str
    password: str
    contact_phone: Optional[str]
    birthday: Optional[int]
    location_id: Optional[int]
    role_id: int = 1
    working_specialty_id: Optional[int]
