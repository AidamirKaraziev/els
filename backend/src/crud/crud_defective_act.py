import os
import uuid
from datetime import datetime

from sqlalchemy.orm import Session, joinedload

from src.core.access import (
    AccessScope,
    apply_defective_act_scope,
    can_access_defective_act,
)
from src.crud.base import CRUDBase
from src.crud.crud_planned_to import crud_planned_to
from src.crud.crud_status import crud_status
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import DefectiveAct, PlannedTO, UniversalUser
from src.schemas.defective_act import (
    DefectiveActCreate,
    DefectiveActStatusUpdate,
    DefectiveActUpdate,
)
from src.services.defective_act_pdf import DefectiveActPdfData, build_defective_act_pdf
from src.utils import pagination


class CrudDefectiveAct(CRUDBase[DefectiveAct, DefectiveActCreate, DefectiveActUpdate]):
    not_found = -1340
    invalid_month = -1343
    # Запись вне области видимости — 403, см. `templates_raise.out_of_scope`.
    out_of_scope = -136

    def scoped_query(self, db: Session, scope: AccessScope):
        """Единственное место, где список дефектных ведомостей режется."""
        return apply_defective_act_scope(db.query(self.model), scope)

    def get_multi(self, db: Session, *, scope: AccessScope, page=None):
        """Перекрывает `CRUDBase.get_multi` ради обязательной области."""
        return pagination.get_page(self.scoped_query(db, scope), page)

    def get_defective_act_by_id(
        self, *, db: Session, defective_act_id: int, scope: AccessScope
    ):
        obj = db.query(DefectiveAct).filter(DefectiveAct.id == defective_act_id).first()
        if obj is None:
            return None, self.not_found, None
        if not can_access_defective_act(scope, obj):
            return None, self.out_of_scope, None
        return obj, 0, None

    def get_by_planned_to_id(
        self, *, db: Session, planned_to_id: int, scope: AccessScope, month: int = 0
    ):
        planned, code, _ = crud_planned_to.get_planed_to_by_id(
            db=db, planned_to_id=planned_to_id, scope=scope
        )
        if code != 0:
            return None, code, None

        q = self.scoped_query(db, scope).filter(
            DefectiveAct.planned_to_id == planned.id
        )
        if month:
            code = self._validate_month(month)
            if code != 0:
                return None, code, None
            q = q.filter(DefectiveAct.month == month)
        return q, 0, None

    def _validate_month(self, month: int) -> int:
        return 0 if 1 <= int(month) <= 12 else self.invalid_month

    def create_defective_act(
        self,
        *,
        db: Session,
        new_data: DefectiveActCreate,
        current_user: UniversalUser,
        scope: AccessScope,
    ):
        planned, code, _ = crud_planned_to.get_planed_to_by_id(
            db=db, planned_to_id=new_data.planned_to_id, scope=scope
        )
        if code != 0:
            return None, code, None

        code = self._validate_month(new_data.month)
        if code != 0:
            return None, code, None

        user, code, _ = crud_universal_users.get_user_by_reference(
            db=db, user_id=new_data.responsible_user_id
        )
        if code != 0:
            return None, code, None

        # Объект теперь обязателен у любого акта, а старая ручка его не
        # присылает: берём у планового ТО. Плана без объекта быть не должно —
        # если он такой, акт вешать не на что.
        if planned.object_id is None:
            return None, self.not_found, None

        db_obj = DefectiveAct(
            object_id=planned.object_id,
            planned_to_id=planned.id,
            month=new_data.month,
            title=new_data.title,
            description=new_data.description,
            responsible_user_id=user.id,
            created_by_user_id=current_user.id,
            status_id=1,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj, 0, None

    def update_defective_act(
        self,
        *,
        db: Session,
        defective_act_id: int,
        update_data: DefectiveActUpdate,
        scope: AccessScope,
    ):
        obj, code, _ = self.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id, scope=scope
        )
        if code != 0:
            return None, code, None

        if update_data.planned_to_id is not None:
            planned, code, _ = crud_planned_to.get_planed_to_by_id(
                db=db, planned_to_id=update_data.planned_to_id, scope=scope
            )
            if code != 0:
                return None, code, None
            if planned.object_id is None:
                return None, self.not_found, None
            obj.planned_to_id = planned.id
            # Переезд на другое плановое ТО — переезд на его объект.
            obj.object_id = planned.object_id

        if update_data.month is not None:
            code = self._validate_month(update_data.month)
            if code != 0:
                return None, code, None
            obj.month = update_data.month

        if update_data.responsible_user_id is not None:
            user, code, _ = crud_universal_users.get_user_by_reference(
                db=db, user_id=update_data.responsible_user_id
            )
            if code != 0:
                return None, code, None
            obj.responsible_user_id = user.id

        if update_data.title is not None:
            obj.title = update_data.title
        if update_data.description is not None:
            obj.description = update_data.description

        obj.updated_at = datetime.utcnow()
        db.add(obj)
        db.commit()
        db.refresh(obj)
        return obj, 0, None

    def update_status(
        self,
        *,
        db: Session,
        defective_act_id: int,
        new_data: DefectiveActStatusUpdate,
        scope: AccessScope,
    ):
        obj, code, _ = self.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id, scope=scope
        )
        if code != 0:
            return None, code, None

        st, code, _ = crud_status.getting_status(db=db, status_id=new_data.status_id)
        if code != 0:
            return None, code, None

        obj.status_id = st.id
        obj.updated_at = datetime.utcnow()
        db.add(obj)
        db.commit()
        db.refresh(obj)
        return obj, 0, None

    def generate_pdf(
        self, *, db: Session, defective_act_id: int, scope: AccessScope
    ) -> tuple:
        obj = (
            self.scoped_query(db, scope)
            .options(
                joinedload(DefectiveAct.planned_to).joinedload(PlannedTO.object),
                joinedload(DefectiveAct.photos),
                joinedload(DefectiveAct.status),
                joinedload(DefectiveAct.responsible_user),
                joinedload(DefectiveAct.created_by_user),
            )
            .filter(DefectiveAct.id == defective_act_id)
            .first()
        )
        if obj is None:
            return None, self.not_found, None

        base_path = "./static/"
        folder = os.path.join(base_path, "defective_act", str(obj.id), "pdf")
        os.makedirs(folder, exist_ok=True)

        filename = f"{uuid.uuid4().hex}.pdf"
        abs_path = os.path.join(folder, filename)
        rel_path = "/".join(["defective_act", str(obj.id), "pdf", filename])

        planned = obj.planned_to
        equipment = "—"
        year_str = "—"
        if planned is not None:
            year_str = str(planned.year) if planned.year else "—"
            if planned.object is not None and planned.object.name:
                equipment = planned.object.name.strip()

        status_name = obj.status.name if obj.status and obj.status.name else "—"
        responsible = (
            obj.responsible_user.name
            if obj.responsible_user and obj.responsible_user.name
            else "—"
        )
        creator = (
            obj.created_by_user.name
            if obj.created_by_user and obj.created_by_user.name
            else "—"
        )

        static_root = os.path.abspath(base_path)
        photo_paths = []
        for ph in sorted(obj.photos or [], key=lambda p: p.id or 0):
            if not ph.photo:
                continue
            rel = ph.photo.replace("\\", "/")
            fp = os.path.join(static_root, rel)
            if os.path.isfile(fp):
                photo_paths.append(fp)

        pdf_data = DefectiveActPdfData(
            equipment_name=equipment,
            planned_year=year_str,
            month=obj.month,
            title=obj.title or "",
            description=obj.description or "",
            status_name=status_name,
            responsible_name=responsible,
            creator_name=creator,
            photo_paths=photo_paths,
        )
        build_defective_act_pdf(abs_path, pdf_data)

        obj.pdf_file = rel_path
        obj.updated_at = datetime.utcnow()
        db.add(obj)
        db.commit()
        db.refresh(obj)
        return obj, 0, None


crud_defective_act = CrudDefectiveAct(DefectiveAct)
