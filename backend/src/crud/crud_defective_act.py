import os
import uuid
from datetime import datetime

from sqlalchemy import extract, func
from sqlalchemy.orm import Session, joinedload

from src.core.access import (
    AccessScope,
    apply_defective_act_scope,
    can_access_defective_act,
)
from src.crud.base import CRUDBase
from src.crud.crud_act_fact import crud_acts_fact
from src.crud.crud_object import crud_objects
from src.crud.crud_order import crud_orders
from src.crud.crud_planned_to import crud_planned_to
from src.crud.crud_status import crud_status
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import (
    DEFECTIVE_ACT_STATES,
    DefectiveAct,
    DefectiveActClientPhoto,
    Object,
    UniversalUser,
)
from src.schemas.defective_act import (
    DefectiveActCreate,
    DefectiveActIssueToClient,
    DefectiveActStateUpdate,
    DefectiveActStatusUpdate,
    DefectiveActUpdate,
)
from src.services.defective_act_pdf import DefectiveActPdfData, build_defective_act_pdf
from src.utils import pagination


def _attr(obj, name: str) -> str:
    """Строковое поле связанной записи или пустая строка.

    Связей у объекта четыре, и любая может быть не заполнена: `ondelete` у
    всех — `SET NULL`. Прочерк вместо пустоты ставит уже шаблон.
    """
    if obj is None:
        return ""
    return (getattr(obj, name, None) or "").strip()


class CrudDefectiveAct(CRUDBase[DefectiveAct, DefectiveActCreate, DefectiveActUpdate]):
    not_found = -1340
    photo_not_found = -1341
    invalid_month = -1343
    no_link = -1344
    links_conflict = -1345
    invalid_state = -1346
    photo_foreign = -1347
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

    def _resolve_object(
        self, *, db: Session, new_data: DefectiveActCreate, scope: AccessScope
    ):
        """Единственное место, где из привязок акта выводится его объект.

        Акт заводится из четырёх мест, и объект в каждом достаётся по-своему:
        напрямую, через работу по ТО, через аварийную заявку или через плановое
        ТО. Каждая присланная ссылка проверяется своим CRUD с областью
        видимости — чужая даёт 403 до того, как что-то запишется.

        Если ссылок прислали несколько и объекты у них разные — это не выбор
        «какая главнее», а ошибка вызывающего: 422.
        """
        found = []

        if new_data.object_id is not None:
            obj, code, _ = crud_objects.get_object_by_id(
                db=db, object_id=new_data.object_id, scope=scope
            )
            if code != 0:
                return None, code, None
            found.append(obj.id)

        if new_data.act_fact_id is not None:
            act_fact, code, _ = crud_acts_fact.get_act_fact_by_id(
                db, new_data.act_fact_id, scope
            )
            if code != 0:
                return None, code, None
            found.append(act_fact.object_id)

        if new_data.order_id is not None:
            order, code, _ = crud_orders.get_order_by_id(
                db=db, order_id=new_data.order_id, scope=scope
            )
            if code != 0:
                return None, code, None
            found.append(order.object_id)

        if new_data.planned_to_id is not None:
            planned, code, _ = crud_planned_to.get_planed_to_by_id(
                db=db, planned_to_id=new_data.planned_to_id, scope=scope
            )
            if code != 0:
                return None, code, None
            # Плана без объекта быть не должно — такой акт вешать не на что.
            if planned.object_id is None:
                return None, self.not_found, None
            found.append(planned.object_id)

        if not found:
            return None, self.no_link, None
        if len(set(found)) > 1:
            return None, self.links_conflict, None
        return found[0], 0, None

    def create_defective_act(
        self,
        *,
        db: Session,
        new_data: DefectiveActCreate,
        current_user: UniversalUser,
        scope: AccessScope,
    ):
        object_id, code, _ = self._resolve_object(db=db, new_data=new_data, scope=scope)
        if code != 0:
            return None, code, None

        # Месяц проверяем, только когда он прислан: три точки входа из четырёх
        # его не знают.
        if new_data.month is not None:
            code = self._validate_month(new_data.month)
            if code != 0:
                return None, code, None

        responsible_id = None
        if new_data.responsible_user_id is not None:
            user, code, _ = crud_universal_users.get_user_by_reference(
                db=db, user_id=new_data.responsible_user_id
            )
            if code != 0:
                return None, code, None
            responsible_id = user.id

        db_obj = DefectiveAct(
            object_id=object_id,
            planned_to_id=new_data.planned_to_id,
            month=new_data.month,
            act_fact_id=new_data.act_fact_id,
            checklist_step_id=new_data.checklist_step_id,
            order_id=new_data.order_id,
            kind="internal",
            state="created",
            title=new_data.title,
            description=new_data.description,
            responsible_user_id=responsible_id,
            created_by_user_id=current_user.id,
            # Устаревшая колонка: заполняется ради старого контракта, цикл
            # акта живёт в `state`.
            status_id=1,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj, 0, None

    def get_by_object_and_year(
        self, *, db: Session, object_id: int, year: int, scope: AccessScope
    ):
        """Лента актов одного объекта за год.

        Год — год создания акта: у трёх точек входа из четырёх другого года
        просто нет. Клиентские акты в ленту не попадают — это порождённые
        записи, они видны из своего первоисточника.
        """
        obj, code, _ = crud_objects.get_object_by_id(
            db=db, object_id=object_id, scope=scope
        )
        if code != 0:
            return None, code, None

        q = (
            self.scoped_query(db, scope)
            .filter(DefectiveAct.object_id == obj.id)
            .filter(DefectiveAct.kind == "internal")
            .filter(extract("year", DefectiveAct.created_at) == year)
            .order_by(DefectiveAct.created_at.desc(), DefectiveAct.id.desc())
        )
        return q, 0, None

    def count_by_object_and_year(
        self, *, db: Session, object_id: int, year: int, scope: AccessScope
    ):
        """Счётчик той же ленты — одним запросом, без выгрузки записей."""
        q, code, _ = self.get_by_object_and_year(
            db=db, object_id=object_id, year=year, scope=scope
        )
        if code != 0:
            return None, code, None
        total = q.with_entities(func.count(DefectiveAct.id)).order_by(None).scalar()
        return int(total or 0), 0, None

    def update_state(
        self,
        *,
        db: Session,
        defective_act_id: int,
        new_data: DefectiveActStateUpdate,
        scope: AccessScope,
    ):
        """Движение по циклу акта. Порядок состояний не навязываем: акт
        возвращают на шаг назад чаще, чем хотелось бы."""
        obj, code, _ = self.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id, scope=scope
        )
        if code != 0:
            return None, code, None

        if new_data.state not in DEFECTIVE_ACT_STATES:
            return None, self.invalid_state, None

        obj.state = new_data.state
        obj.updated_at = datetime.utcnow()
        db.add(obj)
        db.commit()
        db.refresh(obj)
        return obj, 0, None

    def issue_to_client(
        self,
        *,
        db: Session,
        defective_act_id: int,
        new_data: DefectiveActIssueToClient,
        current_user: UniversalUser,
        scope: AccessScope,
    ):
        """Оформление акта клиенту: отдельная запись, а не правка исходной.

        Наружу уходит не то же самое, что механик писал для себя, поэтому у
        клиентского акта свои тексты и свой отобранный набор снимков. Снимки
        не копируются — связываются (`DefectiveActClientPhoto`), первоисточник
        остаётся нетронутым.

        Повторный вызов заводит ещё одну клиентскую запись: акт мог уйти
        клиенту дважды, с разным набором фото.
        """
        parent, code, _ = self.get_defective_act_by_id(
            db=db, defective_act_id=defective_act_id, scope=scope
        )
        if code != 0:
            return None, code, None

        photo_ids = list(dict.fromkeys(new_data.photo_ids or []))
        own_photo_ids = {photo.id for photo in (parent.photos or [])}
        for photo_id in photo_ids:
            if photo_id not in own_photo_ids:
                return None, self.photo_foreign, None

        client_act = DefectiveAct(
            object_id=parent.object_id,
            planned_to_id=parent.planned_to_id,
            month=parent.month,
            act_fact_id=parent.act_fact_id,
            checklist_step_id=parent.checklist_step_id,
            order_id=parent.order_id,
            kind="client",
            parent_id=parent.id,
            state="issued",
            title=parent.title,
            description=parent.description,
            client_title=new_data.client_title or parent.title,
            client_description=new_data.client_description or parent.description,
            responsible_user_id=parent.responsible_user_id,
            created_by_user_id=current_user.id,
            status_id=1,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(client_act)
        db.flush()

        for photo_id in photo_ids:
            db.add(
                DefectiveActClientPhoto(client_act_id=client_act.id, photo_id=photo_id)
            )

        parent.state = "issued"
        parent.updated_at = datetime.utcnow()
        db.add(parent)

        db.commit()
        db.refresh(client_act)
        return client_act, 0, None

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
                # Реквизиты берутся через объект, а не через плановое ТО: три
                # точки входа из четырёх заводят акт без `planned_to`, и у
                # клиентского его чаще всего нет вовсе.
                joinedload(DefectiveAct.object).joinedload(Object.organization),
                joinedload(DefectiveAct.object).joinedload(Object.company_obj),
                joinedload(DefectiveAct.object).joinedload(Object.contract),
                joinedload(DefectiveAct.planned_to),
                joinedload(DefectiveAct.photos),
                joinedload(DefectiveAct.client_photos).joinedload(
                    DefectiveActClientPhoto.photo
                ),
                joinedload(DefectiveAct.responsible_user),
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

        lift = obj.object
        organization = lift.organization if lift is not None else None
        customer = lift.company_obj if lift is not None else None
        contract = lift.contract if lift is not None else None

        planned = obj.planned_to
        year_str = str(planned.year) if planned is not None and planned.year else ""

        responsible = (
            obj.responsible_user.name
            if obj.responsible_user and obj.responsible_user.name
            else ""
        )

        # Наружу уходит не то же самое, что механик писал для себя: у
        # клиентского акта свои тексты и свой отбор снимков. Пустое поле
        # откатывается на исходное — акт, оформленный без правки текста,
        # не должен уйти пустым.
        is_client = obj.kind == "client"
        title = (obj.client_title if is_client else None) or obj.title or ""
        description = (
            (obj.client_description if is_client else None) or obj.description or ""
        )

        if is_client:
            photos = [link.photo for link in obj.client_photos or [] if link.photo]
        else:
            photos = list(obj.photos or [])

        static_root = os.path.abspath(base_path)
        photo_paths = []
        for ph in sorted(photos, key=lambda p: p.id or 0):
            if not ph.photo:
                continue
            rel = ph.photo.replace("\\", "/")
            fp = os.path.join(static_root, rel)
            if os.path.isfile(fp):
                photo_paths.append(fp)

        pdf_data = DefectiveActPdfData(
            act_number=str(obj.id),
            act_date=obj.created_at.strftime("%d.%m.%Y") if obj.created_at else "",
            executor_name=_attr(organization, "title"),
            executor_address=_attr(organization, "address"),
            executor_phone=_attr(organization, "phone_office"),
            executor_director=_attr(getattr(organization, "director", None), "name"),
            customer_name=_attr(customer, "name"),
            customer_address=_attr(customer, "cont_address"),
            customer_director=_attr(customer, "director_name"),
            object_name=_attr(lift, "name"),
            object_address=_attr(lift, "address"),
            factory_number=_attr(lift, "factory_number"),
            registration_number=_attr(lift, "registration_number"),
            contract_title=_attr(contract, "title"),
            planned_year=year_str,
            month=obj.month,
            title=title,
            description=description,
            responsible_name=responsible,
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
