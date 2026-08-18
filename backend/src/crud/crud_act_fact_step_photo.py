import os
import shutil
import uuid
from datetime import datetime
from typing import Optional

from fastapi import UploadFile
from sqlalchemy.orm import Session

from src.core.access import AccessScope, apply_act_fact_step_photo_scope
from src.crud.base import CRUDBase
from src.crud.crud_act_fact import crud_acts_fact
from src.models import ActFactStepPhoto
from src.schemas.act_fact_step_photo import (
    ActFactStepPhotoCreate,
    ActFactStepPhotoUpdate,
)
from src.services.checklist import parse_checklist

#: Куда кладём файл: `./static/{модель}/{id акта}/{тип}/{uuid}.ext`. Раскладка
#: та же, что у фотографий заявок, чтобы отдача статики осталась одна на всех.
PATH_MODEL = "act_fact_step_photo"
PATH_TYPE = "photo"
BASE_PATH = "./static/"


class CrudActFactStepPhoto(
    CRUDBase[ActFactStepPhoto, ActFactStepPhotoCreate, ActFactStepPhotoUpdate]
):
    obj_name = "Фотографии шагов ТО"

    not_found = -1350
    file_is_none = -1351
    step_not_found = -1352

    def scoped_query(self, db: Session, scope: AccessScope):
        """Единственное место, где снимки шагов режутся по области."""
        return apply_act_fact_step_photo_scope(db.query(self.model), scope)

    def get_photo_by_id(self, *, db: Session, photo_id: int, scope: AccessScope):
        obj = (
            self.scoped_query(db, scope).filter(ActFactStepPhoto.id == photo_id).first()
        )
        if obj is None:
            # 404 и на чужой снимок: сам по себе он ничего не значит без акта,
            # а акт по прямому запросу уже отвечает 403.
            return None, self.not_found, None
        return obj, 0, None

    def get_photos_by_act_fact_id(
        self,
        *,
        db: Session,
        act_fact_id: int,
        scope: AccessScope,
        step_id: Optional[int] = None,
    ):
        act, code, _ = crud_acts_fact.get_act_fact_by_id(
            db=db, id=act_fact_id, scope=scope
        )
        if code != 0:
            return None, code, None

        query = self.scoped_query(db, scope).filter(
            ActFactStepPhoto.act_fact_id == act.id
        )
        if step_id is not None:
            query = query.filter(ActFactStepPhoto.step_id == step_id)
        # По порядку загрузки: механик снимает шаги подряд, и лента снизу вверх
        # читалась бы как чужая работа.
        return query.order_by(ActFactStepPhoto.id), 0, None

    def add_photo(
        self,
        *,
        db: Session,
        file: Optional[UploadFile],
        act_fact_id: int,
        step_id: int,
        scope: AccessScope,
    ):
        if file is None:
            return None, self.file_is_none, None

        act, code, _ = crud_acts_fact.get_act_fact_by_id(
            db=db, id=act_fact_id, scope=scope
        )
        if code != 0:
            return None, code, None

        # Снимок без пункта регламента бесполезен: показать его будет негде, а
        # найти — нечем. Проверяем по тому же разбору, что отдаёт чек-лист.
        checklist = parse_checklist(act.step_list_fact)
        if step_id not in {step.id for step in checklist.steps}:
            return None, self.step_not_found, None

        folder = os.path.join(BASE_PATH, PATH_MODEL, str(act.id), PATH_TYPE)
        os.makedirs(folder, exist_ok=True)

        filename = uuid.uuid4().hex + os.path.splitext(file.filename or "")[1]
        with open(os.path.join(folder, filename), "wb") as wf:
            shutil.copyfileobj(file.file, wf)
            file.file.close()  # удаляет временный

        new = ActFactStepPhoto(
            act_fact_id=act.id,
            step_id=step_id,
            # В базе относительный путь: адрес сервера меняется, а снимки нет.
            photo="/".join([PATH_MODEL, str(act.id), PATH_TYPE, filename]),
            created_at=datetime.utcnow(),
        )
        db.add(new)
        db.commit()
        db.refresh(new)
        return new, 0, None

    def delete_photo_by_id(self, *, db: Session, photo_id: int, scope: AccessScope):
        """Удаляет запись из БД. Файл на диске остаётся — как у заявок."""
        obj, code, _ = self.get_photo_by_id(db=db, photo_id=photo_id, scope=scope)
        if code != 0:
            return None, code, None
        super().remove(db=db, id=obj.id)
        return "Фотография шага ТО успешно удалена из БД", 0, None


crud_act_fact_step_photo = CrudActFactStepPhoto(ActFactStepPhoto)
