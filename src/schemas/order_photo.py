from pydantic import BaseModel


class OrderPhotoGet(BaseModel):
    id: int
    order_id: int
    photo: str


class OrderPhotoCreate(BaseModel):
    order_id: int
    photo: str


class OrderPhotoUpdate(BaseModel):
    photo: str
