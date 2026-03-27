from typing import Optional

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import Location
from src.schemas.location import LocationCreate, LocationUpdate


class CrudLocation(CRUDBase[Location, LocationCreate, LocationUpdate]):
    def update_location(
        self, db: Session, *, location: Optional[LocationUpdate], location_id: int
    ):
        # проверить есть ли город с таким id
        if db.query(Location).filter(Location.id == location_id).first() is None:
            return None, -1, None
        this_location = db.query(Location).filter(Location.id == location_id).first()

        # Check_name
        if this_location.name != location.name:
            if (
                db.query(Location).filter(Location.name == location.name).first()
                is not None
            ):
                return None, -2, None

        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=this_location, obj_in=location)
        return db_obj, 0, None


crud_location = CrudLocation(Location)
