from src.models import Location
from src.schemas.location import LocationGet


def get_location(db_obj: Location) -> LocationGet:
    return LocationGet(id=db_obj.id, name=db_obj.name)
