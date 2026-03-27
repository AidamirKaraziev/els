import glob
import os
import shutil
import uuid
from typing import Optional

from fastapi import UploadFile
from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.models import Division, UniversalUser
from src.schemas.divisions import DivisionCreate, DivisionUpdate

FOLDER_DIVISIONS_PHOTO = "./static/divisions_photo/"


class CrudDivision(CRUDBase[Division, DivisionCreate, DivisionUpdate]):
    def create_new(
        self, db: Session, *, new_data: Optional[DivisionUpdate], user: UniversalUser
    ):
        if user.role_id != 1 and user.role_id != 2:
            return None, -1, None
        if (
            db.query(Division).filter(Division.title == new_data.title).first()
            is not None
        ):
            return None, -2, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update(
        self,
        db: Session,
        *,
        new_data: Optional[DivisionUpdate],
        obj_id: int,
        user: UniversalUser,
    ):
        if user.role_id != 1 and user.role_id != 2:
            return None, -1, None
        # проверить есть ли участок с таким id
        div = db.query(Division).filter(Division.id == obj_id).first()
        if div is None:
            return None, -2, None
        # Check title
        if div.title != new_data.title:
            if (
                db.query(Division).filter(Division.title == new_data.title).first()
                is not None
            ):
                return None, -3, None
        # Вот тут должно быть обновление базы данных
        db_obj = super().update(db=db, db_obj=div, obj_in=new_data)
        return db_obj, 0, None

    def adding_photo(
        self, db: Session, obj_id: int, file: Optional[UploadFile], user: UniversalUser
    ):
        if user.role_id != 1 and user.role_id != 2:
            return None, -1, None

        path_name = FOLDER_DIVISIONS_PHOTO + f"{obj_id}/"
        if file is None:
            # Удаляем все содержимое папки
            path_to_clear = path_name + "*"
            for file_to_clear in glob.glob(path_to_clear):
                os.remove(file_to_clear)
            db.query(UniversalUser).filter(UniversalUser.id == obj_id).update(
                {"photo": None}
            )
            db.commit()
            return {"photo": None}
        filename = uuid.uuid4().hex + os.path.splitext(file.filename)[1]
        # path_name = FOLDER_MODERATOR_PHOTO + f"{id_moderator}/"
        element = ["division_photo", str(obj_id), filename]

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

        db.query(Division).filter(Division.id == obj_id).update({"photo": path_for_db})
        db.commit()
        db_obj = super().get(db=db, id=obj_id)
        return db_obj, 0, None


crud_division = CrudDivision(Division)
