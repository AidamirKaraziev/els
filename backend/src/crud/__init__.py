# from .crud_item import item
# from .crud_user import crud_user as user
# from .crud_verif_code import verif_codes_service
# For a new basic set of CRUD operations you could just do
#
# from .base import CRUDBase
# from src.models.item import Item
# from src.schemas.item import ItemCreate, ItemUpdate
#
# item = CRUDBase[Item, ItemCreate, ItemUpdate](Item)
#
# Добавить
# from .crud_user_my import user_my
# from .crud_verif_code import verif_code
from src.crud.users.crud_universal_user import crud_universal_users
