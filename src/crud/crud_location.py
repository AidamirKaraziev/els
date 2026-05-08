from distutils.command.check import check
from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import Location
from src.schemas.location import LocationCreate, LocationUpdate



class CrudLocation(CRUDBase[Location, LocationCreate, LocationUpdate]):
    def get_location_by_id(
        self,
        db: Session, *,
        id: int
    ):
        """ Получить город по id."""
        location = db.query(Location).filter(Location.id == id).first()
        if location is None:
            return None, -101, None
        return location, 0, None


    def check_name(
        self,
        db: Session, *,
        name: str
    ):
        """Проверка есть ли такое название города в БД."""
        res = db.query(Location).filter(Location.name == name).first()
        if res is not None:
            return None, -1011, None
        else:
            return True, 0, None

    def update_location(
        self,
        db: Session, *,
        location: Optional[LocationUpdate],
        location_id: int
    ):
        # проверить есть ли город с таким id
        exist_location, code, indexes = self.get_location_by_id(db=db, id=location_id)
        if exist_location is None:
            return exist_location, code, indexes

        this_location = db.query(Location).filter(Location.id == location_id).first()

        # Check_name
        if this_location.name != location.name:
            good_name, code, indexes = self.check_name(db=db, name=location.name)
            return good_name, code, indexes

        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=this_location, obj_in=location)
        return db_obj, 0, None

    def create_location(
        self,
        db: Session, *,
        new_data: Optional[LocationCreate]
    ):
        # проверить есть ли с таким названием
        if db.query(Location).filter(Location.name == new_data.name).first() is not None:
            return None, -1061, None

        good_name, code, indexes = self.check_name(db=db, name=new_data.name)
        if code != 0:
            return None, code, None

        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None


crud_location = CrudLocation(Location)
