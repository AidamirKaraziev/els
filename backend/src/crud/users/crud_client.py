import glob
import os
import shutil
import uuid
from typing import Any, Dict, Optional, Union

from fastapi import UploadFile
from fastapi.encoders import jsonable_encoder
from sqlalchemy.orm import Session
from starlette import status

from src.core.roles import CLIENT_ID
from src.crud.base import CRUDBase
from src.crud.crud_location import crud_location
from src.crud.users.crud_universal_user import crud_universal_users
from src.exceptions import UnfoundEntity
from src.models import UniversalUser
from src.schemas.client import ClientUpdateSelf
from src.schemas.universal_user import UniversalUserCreate, UniversalUserUpdate
from src.utils.time_stamp import date_from_timestamp

FOLDER_UNIVERSAL_USER_PHOTO = "./static/universal_user_photo/"


class CrudClient(CRUDBase[UniversalUser, UniversalUserCreate, UniversalUserUpdate]):
    obj_name = "Клиенты"
    not_found_id = {
        "status_code": status.HTTP_404_NOT_FOUND,
        "detail": f"{obj_name}: не найден с таким id",
    }

    def get_client_by_id(self, *, db: Session, id: int):
        """
        Получение клиента по id.
        """
        client = (
            db.query(self.model)
            .filter(self.model.id == id, self.model.role_id == CLIENT_ID)
            .first()
        )
        if not client:
            return None, self.not_found_id, None
        return client, 0, None

    def updating_client_self(
        self,
        db: Session,
        *,
        current_user: UniversalUser,
        obj_in: Union[ClientUpdateSelf, Dict[str, Any]],
    ):
        db_obj = crud_universal_users.get(db=db, id=current_user.id)
        obj_data = jsonable_encoder(db_obj)
        new_obj = jsonable_encoder(obj_in)

        # Проверить есть ли такой user
        if db_obj is None:
            return None, -1, None
        # Проверить является ли он клиентом
        if current_user.role_id != 6:
            return None, -2, None
        # BIRTHDAY
        if new_obj["birthday"] is not None:
            obj_in.birthday = str(date_from_timestamp(new_obj["birthday"]))
        # ГОРОДА
        if new_obj["location_id"] is not None:
            if crud_location.get(db=db, id=new_obj["location_id"]) is None:
                return None, -3, None

        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.dict(exclude_unset=True)
        for field in obj_data:
            if field in update_data:
                setattr(db_obj, field, update_data[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj, 0, None

    def adding_photo(self, db: Session, id_user: int, file: Optional[UploadFile]):
        path_name = FOLDER_UNIVERSAL_USER_PHOTO + f"{id_user}/"
        if file is None:
            # Удаляем все содержимое папки
            path_to_clear = path_name + "*"
            for file_to_clear in glob.glob(path_to_clear):
                os.remove(file_to_clear)
            db.query(UniversalUser).filter(UniversalUser.id == id_user).update(
                {"photo": None}
            )
            db.commit()
            return {"photo": None}
        filename = uuid.uuid4().hex + os.path.splitext(file.filename)[1]
        # path_name = FOLDER_MODERATOR_PHOTO + f"{id_moderator}/"
        element = ["universal_user_photo", str(id_user), filename]

        path_for_db = "/".join(element)

        if not os.path.exists(path_name):
            os.makedirs(path_name)

        # Удаляем все содержимое папки
        path_to_clear = path_name + "*"
        for file_to_clear in glob.glob(path_to_clear):
            os.remove(file_to_clear)

        with open(path_name + filename, "wb") as wf:
            shutil.copyfileobj(file.file, wf)
            file.file.close()  # удаляет временный

        db.query(UniversalUser).filter(UniversalUser.id == id_user).update(
            {"photo": path_for_db}
        )
        db.commit()
        if not file:
            raise UnfoundEntity(
                message="Не отправлен загружаемый файл",
                num=2,
                description="Попробуйте загрузить файл еще раз",
                path="$.body",
            )
        else:
            return {"photo": path_for_db}


crud_client = CrudClient(UniversalUser)
