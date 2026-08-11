import os
import shutil
import uuid
from datetime import datetime
from typing import Optional

from fastapi import UploadFile
from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.crud.crud_defective_act import crud_defective_act
from src.models import DefectiveActPhoto
from src.schemas.defective_act_photo import (
    DefectiveActPhotoCreate,
    DefectiveActPhotoUpdate,
)


class CrudDefectiveActPhoto(
    CRUDBase[DefectiveActPhoto, DefectiveActPhotoCreate, DefectiveActPhotoUpdate]
):
    not_found = -1341
    file_is_none = -1342

    def get_photo_by_id(self, *, db: Session, defective_act_photo_id: int):
        obj = (
            db.query(DefectiveActPhoto)
            .filter(DefectiveActPhoto.id == defective_act_photo_id)
            .first()
        )
        if obj is None:
            return None, self.not_found, None
        return obj, 0, None

    def get_photos_by_defective_act_id(self, *, db: Session, defective_act_id: int):
        act, code, _ = crud_defective_act.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id
        )
        if code != 0:
            return None, code, None
        q = db.query(DefectiveActPhoto).filter(
            DefectiveActPhoto.defective_act_id == act.id
        )
        return q, 0, None

    def add_photo(
        self,
        *,
        db: Session,
        file: Optional[UploadFile],
        defective_act_id: int,
        created_by_user_id: int,
    ):
        if file is None:
            return None, self.file_is_none, None

        act, code, _ = crud_defective_act.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id
        )
        if code != 0:
            return None, code, None

        base_path = "./static/"
        folder = os.path.join(base_path, "defective_act", str(act.id), "photo")
        os.makedirs(folder, exist_ok=True)

        filename = uuid.uuid4().hex + os.path.splitext(file.filename)[1]
        abs_path = os.path.join(folder, filename)
        rel_path = "/".join(["defective_act", str(act.id), "photo", filename])

        with open(abs_path, "wb") as wf:
            shutil.copyfileobj(file.file, wf)
            file.file.close()

        new = DefectiveActPhoto(
            defective_act_id=act.id,
            photo=rel_path,
            created_at=datetime.utcnow(),
            created_by_user_id=created_by_user_id,
        )
        db.add(new)
        db.commit()
        db.refresh(new)
        return new, 0, None

    def delete_photo_by_id(self, *, db: Session, defective_act_photo_id: int):
        """
        Удаление записи о фото из БД (файл на диске не удаляем — как в order_photo).
        """
        obj, code, _ = self.get_photo_by_id(
            db=db, defective_act_photo_id=defective_act_photo_id
        )
        if code != 0:
            return None, code, None
        super().remove(db=db, id=obj.id)
        return "Фотография дефектного акта успешно удалена из БД", 0, None


crud_defective_act_photo = CrudDefectiveActPhoto(DefectiveActPhoto)
