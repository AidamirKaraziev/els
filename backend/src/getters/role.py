from src.models import Role
from src.schemas.role import RoleGet


def get_roles(db_obj: Role) -> RoleGet:
    return RoleGet(id=db_obj.id, name=db_obj.name)
