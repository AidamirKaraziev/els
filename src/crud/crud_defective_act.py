import os
import uuid
from datetime import datetime

from sqlalchemy.orm import Session

from src.crud.base import CRUDBase
from src.crud.crud_planned_to import crud_planned_to
from src.crud.crud_status import crud_status
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import DefectiveAct, UniversalUser
from src.schemas.defective_act import (
    DefectiveActCreate,
    DefectiveActStatusUpdate,
    DefectiveActUpdate,
)


class CrudDefectiveAct(CRUDBase[DefectiveAct, DefectiveActCreate, DefectiveActUpdate]):
    not_found = -1340
    invalid_month = -1343

    def get_defective_act_by_id(self, *, db: Session, defective_act_id: int):
        obj = db.query(DefectiveAct).filter(DefectiveAct.id == defective_act_id).first()
        if obj is None:
            return None, self.not_found, None
        return obj, 0, None

    def get_by_planned_to_id(self, *, db: Session, planned_to_id: int, month: int = 0):
        planned, code, _ = crud_planned_to.get_planed_to_by_id(
            db=db, planned_to_id=planned_to_id
        )
        if code != 0:
            return None, code, None

        q = db.query(DefectiveAct).filter(DefectiveAct.planned_to_id == planned.id)
        if month:
            code = self._validate_month(month)
            if code != 0:
                return None, code, None
            q = q.filter(DefectiveAct.month == month)
        return q, 0, None

    def _validate_month(self, month: int) -> int:
        return 0 if 1 <= int(month) <= 12 else self.invalid_month

    def create_defective_act(
        self, *, db: Session, new_data: DefectiveActCreate, current_user: UniversalUser
    ):
        planned, code, _ = crud_planned_to.get_planed_to_by_id(
            db=db, planned_to_id=new_data.planned_to_id
        )
        if code != 0:
            return None, code, None

        code = self._validate_month(new_data.month)
        if code != 0:
            return None, code, None

        user, code, _ = crud_universal_users.get_user_by_id(
            db=db, user_id=new_data.responsible_user_id
        )
        if code != 0:
            return None, code, None

        db_obj = DefectiveAct(
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
        self, *, db: Session, defective_act_id: int, update_data: DefectiveActUpdate
    ):
        obj, code, _ = self.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id
        )
        if code != 0:
            return None, code, None

        if update_data.planned_to_id is not None:
            planned, code, _ = crud_planned_to.get_planed_to_by_id(
                db=db, planned_to_id=update_data.planned_to_id
            )
            if code != 0:
                return None, code, None
            obj.planned_to_id = planned.id

        if update_data.month is not None:
            code = self._validate_month(update_data.month)
            if code != 0:
                return None, code, None
            obj.month = update_data.month

        if update_data.responsible_user_id is not None:
            user, code, _ = crud_universal_users.get_user_by_id(
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
    ):
        obj, code, _ = self.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id
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

    def generate_pdf(self, *, db: Session, defective_act_id: int) -> tuple:
        """
        Минимальная генерация PDF без внешних зависимостей.
        Дальше можно заменить на нормальный рендер (HTML->PDF, reportlab и т.п.).
        """
        obj, code, _ = self.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id
        )
        if code != 0:
            return None, code, None

        base_path = "./static/"
        folder = os.path.join(base_path, "defective_act", str(obj.id), "pdf")
        os.makedirs(folder, exist_ok=True)

        filename = f"{uuid.uuid4().hex}.pdf"
        abs_path = os.path.join(folder, filename)
        rel_path = "/".join(["defective_act", str(obj.id), "pdf", filename])

        pdf_bytes = _minimal_pdf_bytes(
            title=obj.title or f"Defective act #{obj.id}",
            body=obj.description or "",
        )
        with open(abs_path, "wb") as f:
            f.write(pdf_bytes)

        obj.pdf_file = rel_path
        obj.updated_at = datetime.utcnow()
        db.add(obj)
        db.commit()
        db.refresh(obj)
        return obj, 0, None


def _pdf_escape(text: str) -> str:
    return (
        (text or "")
        .replace("\\", "\\\\")
        .replace("(", "\\(")
        .replace(")", "\\)")
        .replace("\n", " ")
        .strip()
    )


def _minimal_pdf_bytes(*, title: str, body: str) -> bytes:
    """
    Очень простой PDF: 1 страница, Helvetica, 2 строки текста.
    """
    title = _pdf_escape(title)[:120]
    body = _pdf_escape(body)[:500]

    content = (
        "BT\n"
        "/F1 16 Tf\n"
        "50 780 Td\n"
        f"({title}) Tj\n"
        "/F1 12 Tf\n"
        "0 -24 Td\n"
        f"({body}) Tj\n"
        "ET\n"
    ).encode("latin-1", errors="replace")

    parts = []

    def add(b: bytes) -> int:
        parts.append(b)
        return sum(len(x) for x in parts) - len(b)

    add(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    xref = []

    xref.append(add(b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"))
    xref.append(add(b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"))
    xref.append(
        add(
            b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
            b"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n"
        )
    )
    xref.append(
        add(
            b"4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"
        )
    )
    xref.append(
        add(
            b"5 0 obj\n<< /Length "
            + str(len(content)).encode()
            + b" >>\nstream\n"
            + content
            + b"endstream\nendobj\n"
        )
    )

    xref_start = sum(len(x) for x in parts)
    out = b"".join(parts)

    # xref table
    xref_lines = [b"xref\n0 6\n", b"0000000000 65535 f \n"]
    # objects 1..5
    for off in xref:
        xref_lines.append(f"{off:010d} 00000 n \n".encode())
    trailer = (
        b"trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n"
        + str(xref_start).encode()
        + b"\n%%EOF\n"
    )
    return out + b"".join(xref_lines) + trailer


crud_defective_act = CrudDefectiveAct(DefectiveAct)
