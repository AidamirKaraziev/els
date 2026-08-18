import datetime
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from src.core.access import AccessScope, apply_order_scope, can_access_order
from src.crud.base import CRUDBase
from src.crud.crud_fault_category import crud_fault_category
from src.crud.crud_object import crud_objects
from src.crud.crud_reason_fault import crud_reason_fault
from src.crud.crud_statistics import month_period
from src.crud.crud_status import crud_status
from src.crud.users.crud_universal_user import crud_universal_users
from src.models import (
    Company,
    FaultCategory,
    Object,
    Order,
    Organization,
    UniversalUser,
)
from src.schemas.order import OrderCreate, OrderUpdate
from src.utils import pagination

#: Статусы заявки из справочника `statuses`, см. `core/db/init_db.py:check_statuses`.
STATUS_DONE = 4
STATUS_PROBLEM = 5
#: Заявка отработана: либо сделана, либо упёрлась в проблему. Для механика обе
#: одинаково уходят из списка «что мне делать сейчас».
CLOSED_STATUSES = (STATUS_DONE, STATUS_PROBLEM)


def _object_display_label(name: Optional[str], object_id: int) -> str:
    if name and str(name).strip():
        return str(name).strip()
    return f"Объект №{object_id}"


class CrudOrder(CRUDBase[Order, OrderCreate, OrderUpdate]):
    not_found = -129
    is_exist = -1291
    # Запись вне области видимости — 403, см. `templates_raise.out_of_scope`.
    out_of_scope = -136

    def scoped_query(self, db: Session, scope: AccessScope):
        """Единственное место, где список заявок режется по области."""
        return apply_order_scope(db.query(self.model), scope)

    def get_order_by_id(self, *, db: Session, order_id: int, scope: AccessScope):
        obj = db.query(Order).filter(Order.id == order_id).first()
        if obj is None:
            return None, self.not_found, None
        if not can_access_order(scope, obj):
            return None, self.out_of_scope, None
        return obj, 0, None

    def create_order(
        self,
        db: Session,
        *,
        new_data: OrderCreate,
        current_user: UniversalUser,
        scope: AccessScope,
    ):
        # Заявку заводят по объекту, к которому есть доступ. Для клиента это
        # единственное, что он вообще создаёт, и завести её по чужому лифту он
        # не должен.
        obj, code, indexes = crud_objects.get_object_by_id(
            db=db, object_id=new_data.object_id, scope=scope
        )
        if code != 0:
            return None, code, None
        # проверка creator_id
        new_data.creator_id = current_user.id
        # проверка fault_category_id
        obj, code, indexes = crud_fault_category.get_fault_by_id(
            db=db, fault_id=new_data.fault_category_id
        )
        if code != 0:
            return None, code, None
        # проверка executor_id
        executor = db.query(UniversalUser).filter(
            UniversalUser.id == new_data.executor_id
        )
        if executor is None:
            return None, -130, None
        new_data.created_at = datetime.datetime.utcnow()
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_order(
        self, db: Session, *, new_data: OrderUpdate, order_id: int, scope: AccessScope
    ):
        # проверка order_id
        order, code, indexes = self.get_order_by_id(
            db=db, order_id=order_id, scope=scope
        )
        if code != 0:
            return None, code, None
        # Объект тоже проверяется по области: иначе заявку можно было бы
        # перевесить на чужой лифт и получить к нему доступ через неё.
        obj, code, indexes = crud_objects.get_object_by_id(
            db=db, object_id=new_data.object_id, scope=scope
        )
        if code != 0:
            return None, code, None
        if new_data.fault_category_id is not None:
            obj, code, indexes = crud_fault_category.get_fault_by_id(
                db=db, fault_id=new_data.fault_category_id
            )
            if code != 0:
                return None, code, None
        # проверка executor_id
        if new_data.executor_id == 0:
            new_data.executor_id = None
        if new_data.executor_id is not None:
            fact_executor, code, indexes = crud_universal_users.get_user_by_reference(
                db=db, user_id=new_data.executor_id
            )
            if code != 0:
                return None, code, None
        if new_data.reason_fault_id is not None:
            obj, code, indexes = crud_reason_fault.get_fault_by_id(
                db=db, fault_id=new_data.reason_fault_id
            )
            if code != 0:
                return None, code, None
        if new_data.status_id is not None:
            obj, code, indexes = crud_status.getting_status(
                db=db, status_id=new_data.status_id
            )
            if code != 0:
                return None, code, None
        if new_data.status_id == 2:
            new_data.accepted_at = datetime.datetime.utcnow()
        if new_data.status_id == 3:
            new_data.in_progress_at = datetime.datetime.utcnow()
        if new_data.status_id == 4:
            # Именно `done_at`: раньше здесь стоял `dane_at`, и заявка
            # закрывалась без отметки о времени закрытия. Ошибки при этом не
            # возникало — `CRUDBase.update` молча пропускает поля, которых нет
            # среди колонок модели.
            new_data.done_at = datetime.datetime.utcnow()

        # обновление данных
        db_obj = super().update(db=db, db_obj=order, obj_in=new_data)
        return db_obj, 0, None

    def get_orders_filtered(
        self,
        *,
        db: Session,
        scope: AccessScope,
        page: Optional[int],
        object_id: Optional[int] = None,
        year: Optional[int] = None,
        month: Optional[int] = None,
        only_breakdowns: bool = False,
        executor_id: Optional[int] = None,
        status_id: Optional[int] = None,
        only_open: bool = False,
        changed_since: Optional[datetime.datetime] = None,
    ):
        """Список заявок с необязательными фильтрами.

        Все параметры кроме `scope` необязательные: без них запрос совпадает с
        прежним `get_multi`, поэтому старые клиенты ничего не замечают.

        Нужно для перехода из виджета «Топ поломок»: человек видит у объекта
        число за месяц и хочет посмотреть, какие именно это были заявки.
        Отсюда же выбирается список для механика — там важен `executor_id`
        вместе с `only_open`.
        """
        query = self.scoped_query(db, scope)

        if object_id is not None:
            query = query.filter(self.model.object_id == object_id)

        if executor_id is not None:
            query = query.filter(self.model.executor_id == executor_id)

        if status_id is not None:
            query = query.filter(self.model.status_id == status_id)

        if changed_since is not None:
            # Синхронизация телефона: отдаём только то, что изменилось. Строка
            # без метки в выдачу не попадёт — сравнение с NULL даёт NULL, — но
            # таких строк нет: миграция проставила метку всем накопленным
            # записям, а новым её ставит сама модель.
            query = query.filter(self.model.updated_at > changed_since)

        if only_open:
            # `status_id` в базе обнуляемый, а заявка без статуса — это заявка,
            # которую никто не закрывал. NOT IN на NULL даёт NULL, то есть
            # молча выкинул бы такие строки из списка механика.
            query = query.filter(
                (self.model.status_id.is_(None))
                | (self.model.status_id.notin_(CLOSED_STATUSES))
            )

        if year is not None and month is not None:
            period = month_period(year, month)
            query = query.filter(
                self.model.created_at.isnot(None),
                self.model.created_at >= period.start,
                self.model.created_at < period.end,
            )

        if only_breakdowns:
            # Тот же отбор, что и в статистике: без него человек, кликнув по
            # «6 поломок», увидел бы девять заявок вместе с плановыми ТО и
            # решил бы, что виджет врёт.
            query = query.outerjoin(
                FaultCategory, self.model.fault_category_id == FaultCategory.id
            ).filter(
                (self.model.fault_category_id.is_(None))
                | (FaultCategory.counts_as_breakdown.is_(True))
            )

        # Порядок задаём только здесь, в отфильтрованной выдаче. У `get_multi`
        # сортировки нет вовсе, и менять её сейчас — значит трогать экран,
        # который и так работает.
        query = query.order_by(self.model.created_at.desc().nullslast())

        return pagination.get_page(query, page)

    def get_my_orders(self, *, db: Session, creator_id: int, scope: AccessScope):
        # Свои заявки и так внутри области — фильтр здесь не сужает выдачу, а
        # держит правило одним для всех выборок заявок.
        my_orders = self.scoped_query(db, scope).filter(
            self.model.creator_id == creator_id
        )
        return my_orders, 0, None

    def get_orders_for_me(
        self,
        *,
        db: Session,
        executor_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
        status_id: Optional[int] = None,
        only_open: bool = False,
        year: Optional[int] = None,
        month: Optional[int] = None,
        changed_since: Optional[datetime.datetime] = None,
    ):
        """Задачи, назначенные на человека.

        Раньше отдавала всё за всё время без сортировки и без страниц, а
        мобильное приложение опрашивало ручку раз в три секунды — у механика
        за год это сотни записей в каждом ответе. Фильтры и страницы
        необязательные: без `page` выдача остаётся полной, как была.
        """
        return self.get_orders_filtered(
            db=db,
            scope=scope,
            page=page,
            year=year,
            month=month,
            executor_id=executor_id,
            status_id=status_id,
            only_open=only_open,
            changed_since=changed_since,
        )

    def get_top_breakdowns_by_month(
        self, *, db: Session, scope: AccessScope, year: int, month: int
    ) -> list:
        """
        Задачи (поломки) с object_id за календарный месяц [year-month],
        сгруппированные по объекту, по убыванию числа заявок.
        """
        start = datetime.datetime(year, month, 1)
        if month == 12:
            end = datetime.datetime(year + 1, 1, 1)
        else:
            end = datetime.datetime(year, month + 1, 1)

        query = (
            db.query(
                Object.id,
                Object.name,
                func.coalesce(Organization.title, Company.name).label("client_name"),
                UniversalUser.name.label("mechanic_name"),
                func.count(Order.id).label("breakdown_count"),
            )
            .select_from(Order)
            .join(Object, Order.object_id == Object.id)
            .outerjoin(Organization, Object.organization_id == Organization.id)
            .outerjoin(Company, Object.company_id == Company.id)
            .outerjoin(UniversalUser, Object.mechanic_id == UniversalUser.id)
            .filter(
                Order.object_id.isnot(None),
                Order.created_at.isnot(None),
                Order.created_at >= start,
                Order.created_at < end,
            )
        )
        # Тем же фильтром, что и список заявок: цифра в сводке и длина списка
        # за тот же месяц должны сходиться, иначе виджет выглядит враньём.
        query = apply_order_scope(query, scope)

        return (
            query.group_by(
                Object.id,
                Object.name,
                Organization.id,
                Organization.title,
                Company.id,
                Company.name,
                UniversalUser.id,
                UniversalUser.name,
            )
            .order_by(func.count(Order.id).desc())
            .all()
        )


crud_orders = CrudOrder(Order)
