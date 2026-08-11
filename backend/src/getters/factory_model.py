from src.getters.type_object import get_type_objects
from src.models import FactoryModel
from src.schemas.factory_model import FactoryModelGet


def get_factory_model(db_obj: FactoryModel) -> FactoryModelGet:
    return FactoryModelGet(
        id=db_obj.id,
        type_object_id=get_type_objects(db_obj=db_obj.type_object)
        if db_obj.type_object is not None
        else None,
        factory=db_obj.factory,
        model=db_obj.model,
    )
