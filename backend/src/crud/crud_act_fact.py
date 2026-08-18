import datetime
from typing import List, Optional, Tuple

from sqlalchemy import literal, select, union_all
from sqlalchemy.orm import Session
from starlette import status

from src.core.access import AccessScope, apply_act_fact_scope, can_access_act_fact
from src.core.roles import ADMIN, FOREMAN, MECHANIC
from src.crud.base import CRUDBase
from src.crud.crud_act_base import crud_acts_bases
from src.crud.crud_object import crud_objects
from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
from src.crud.crud_status import crud_status
from src.models import (
    ActFact,
    Object,
    PlannedTO,
    UniversalUser,
)
from src.schemas.act_fact import ActFactCreate, ActFactUpdate
from src.utils import pagination
from src.utils.time_stamp import datetime_from_timestamp

ROLE_RIGHTS = [ADMIN, FOREMAN]
ROLE_MECHANIC = [MECHANIC]
ROLE_FOREMAN = [FOREMAN]


class CrudActFact(CRUDBase[ActFact, ActFactCreate, ActFactUpdate]):
    obj_name = "Фактические акты"
    not_found_id = {
        "status_code": status.HTTP_404_NOT_FOUND,
        "detail": f"{obj_name}: не найден с таким id",
    }
    not_found_foreman = {
        "status_code": status.HTTP_403_FORBIDDEN,
        "detail": "Не найден прораб с таким id",
    }
    not_found_mechanic = {
        "status_code": status.HTTP_403_FORBIDDEN,
        "detail": "Не найден механик с таким id",
    }

    # Запись вне области видимости — 403, см. `templates_raise.out_of_scope`.
    out_of_scope = -136

    def scoped_query(self, db: Session, scope: AccessScope):
        """Единственное место, где список фактических актов режется."""
        return apply_act_fact_scope(db.query(self.model), scope)

    def get_multi(self, db: Session, *, scope: AccessScope, page: Optional[int] = None):
        """Перекрывает `CRUDBase.get_multi` ради обязательной области."""
        return pagination.get_page(self.scoped_query(db, scope), page)

    def _planned_cells(self):
        """Ячейки графика, развёрнутые из колонок в строки.

        Плановый месяц в `planned_to` — это колонка, а не значение, поэтому
        «когда это ТО по плану» одним `WHERE` не спросить: нужен `UNION ALL`
        из двенадцати выборок. Карта «номер месяца → колонка» берётся из
        статистики — двенадцать имён колонок, продублированных по модулям,
        разъедутся при первой же правке графика.

        Год в модели строковый и таким и остаётся: в колонке лежат данные,
        набитые руками, и `CAST` уронил бы запрос на первой же строке вроде
        «2025 г.». Приводим уже в Python, на разобранной строке.
        """
        branches = [
            select(
                PlannedTO.year.label("year"),
                literal(month).label("month"),
                _PLANNED_MONTH_COLUMN[month].label("act_id"),
            ).where(_PLANNED_MONTH_COLUMN[month].isnot(None))
            for month in sorted(_PLANNED_MONTH_COLUMN)
        ]
        return union_all(*branches).subquery("my_to_cells")

    def get_my_maintenance(
        self,
        *,
        db: Session,
        mechanic_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
        year: Optional[int] = None,
        month: Optional[int] = None,
        only_open: bool = False,
        changed_since: Optional[datetime.datetime] = None,
    ) -> Tuple[List, Optional[object]]:
        """Плановые ТО, назначенные на механика.

        Механик привязан к акту через `main_mechanic_id`, а тот проставляется
        из механика объекта при создании графика. Отдельного назначения на
        конкретное ТО в системе нет, и выдумывать его здесь не нужно.
        """
        cells = self._planned_cells()

        query = (
            self.scoped_query(db, scope)
            .add_columns(cells.c.year, cells.c.month)
            .join(cells, cells.c.act_id == ActFact.id)
            .outerjoin(Object, ActFact.object_id == Object.id)
            .filter(ActFact.main_mechanic_id == mechanic_id)
        )

        if year is not None and month is not None:
            query = query.filter(cells.c.year == str(year), cells.c.month == month)

        if only_open:
            # Незакрытое ТО — то, у которого нет даты окончания. Статус здесь
            # не спрашиваем: выполнение графика считается именно по
            # `finished_at`, и второй признак разошёлся бы с ним.
            query = query.filter(ActFact.finished_at.is_(None))

        if changed_since is not None:
            query = query.filter(ActFact.updated_at > changed_since)

        # Сначала ближайшее по плану: механику нужен текущий месяц, а не
        # январь позапрошлого года.
        query = query.order_by(cells.c.year.desc(), cells.c.month.desc())

        return pagination.get_page(query, page)

    def get_act_fact_by_id(self, db: Session, id: int, scope: AccessScope):
        act_fact = super().get(db=db, id=id)
        if not act_fact:
            return None, self.not_found_id, None
        if not can_access_act_fact(scope, act_fact):
            return None, self.out_of_scope, None
        return act_fact, 0, None

    def create_act_fact(
        self, db: Session, *, new_data: ActFactCreate, scope: AccessScope
    ):
        # проверка объекта
        obj, code, indexes = crud_objects.get_object_by_id(
            db=db, object_id=new_data.object_id, scope=scope
        )
        if code != 0:
            return None, code, None
        # проверка базовый акт
        act_base, code, indexes = crud_acts_bases.getting_act_base(
            db=db, act_base_id=new_data.act_base_id
        )
        if code != 0:
            return None, code, None
        # проверка на ответственный прораб
        foreman = (
            db.query(UniversalUser)
            .filter(
                UniversalUser.id == new_data.foreman_id,
                UniversalUser.role_id == FOREMAN,
            )
            .first()
        )
        if foreman is None:
            return None, self.not_found_foreman, None
        # проверка на ответственный механик
        mechanic = (
            db.query(UniversalUser)
            .filter(
                UniversalUser.id == new_data.main_mechanic_id,
                UniversalUser.role_id == MECHANIC,
            )
            .first()
        )
        if mechanic is None:
            return None, self.not_found_mechanic, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_act_fact(
        self,
        db: Session,
        *,
        update_data: Optional[ActFactUpdate],
        act_fact_id: int,
        scope: AccessScope,
    ):
        # проверить есть ли объект с таким id
        this_act_fact, code, indexes = self.get_act_fact_by_id(
            db=db, id=act_fact_id, scope=scope
        )
        if code != 0:
            return None, code, None
        # обновление выполненных шагов
        if update_data.step_list_fact:
            update_data.step_list_fact = update_data.step_list_fact
        # Перевод дат в нужный формат. `datetime`, а не `date`: обе колонки
        # объявлены DateTime, и прежний перевод в дату молча ронял время
        # закрытия акта на полночь.
        if update_data.started_at is not None:
            update_data.started_at = datetime_from_timestamp(update_data.started_at)
        if update_data.finished_at is not None:
            update_data.finished_at = datetime_from_timestamp(update_data.finished_at)
        # проверка на ответственный прораб
        if update_data.foreman_id:
            foreman = (
                db.query(UniversalUser)
                .filter(
                    UniversalUser.id == update_data.foreman_id,
                    UniversalUser.role_id == FOREMAN,
                )
                .first()
            )
            if foreman is None:
                return None, self.not_found_foreman, None
        # проверка на ответственный механик
        if update_data.main_mechanic_id:
            mechanic = (
                db.query(UniversalUser)
                .filter(
                    UniversalUser.id == update_data.main_mechanic_id,
                    UniversalUser.role_id == MECHANIC,
                )
                .first()
            )
            if mechanic is None:
                return None, self.not_found_mechanic, None
        # проверка статуса
        # `is not None`, а не проверка на истинность: ноль — существующий id в
        # чужих справочниках, и раньше такой запрос молча не менял ничего.
        if update_data.status_id is not None:
            status, code, indexes = crud_status.getting_status(
                db=db, status_id=update_data.status_id
            )
            if code != 0:
                return None, code, None
        # обновление данных
        db_obj = super().update(db=db, db_obj=this_act_fact, obj_in=update_data)
        return db_obj, 0, None

    def get_act_fact_by_object_id(
        self, *, db: Session, object_id: int, scope: AccessScope
    ):
        act_bases = (
            self.scoped_query(db, scope)
            .join(Object)
            .filter(Object.id == object_id)
            .all()
        )
        return act_bases, 0, None


crud_acts_fact = CrudActFact(ActFact)
