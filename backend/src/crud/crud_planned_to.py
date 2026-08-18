from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy import and_, case, func
from sqlalchemy.orm import Session

from src.core.access import (
    AccessScope,
    apply_planned_to_scope,
    can_access_planned_to,
    object_scope_filter,
)
from src.core.archiving import ArchiveView, apply_archive_view
from src.core.response import Paginator
from src.core.roles import FOREMAN
from src.crud.base import CRUDBase
from src.crud.base_user import ModelType
from src.crud.crud_act_fact import crud_acts_fact
from src.models import ActFact, Division, Object, PlannedTO, UniversalUser
from src.schemas.planned_to import (
    PlannedTOCreate,
    PlannedTOUpdate,
    ScheduleExecutionDivisionStats,
    ScheduleExecutionStatsGet,
)
from src.utils import pagination

_MONTH_PLANNED_COLUMN = {
    1: PlannedTO.january_to_id,
    2: PlannedTO.february_to_id,
    3: PlannedTO.march_to_id,
    4: PlannedTO.april_to_id,
    5: PlannedTO.may_to_id,
    6: PlannedTO.june_to_id,
    7: PlannedTO.july_to_id,
    8: PlannedTO.august_to_id,
    9: PlannedTO.september_to_id,
    10: PlannedTO.october_to_id,
    11: PlannedTO.november_to_id,
    12: PlannedTO.december_to_id,
}


def _reporting_month_bounds(year: int, month: int) -> Tuple[datetime, datetime]:
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)
    return start, end


def _responsible_name_for_division(db: Session, division_id: int) -> Optional[str]:
    row = (
        db.query(UniversalUser.name)
        .filter(
            UniversalUser.division_id == division_id,
            UniversalUser.role_id == FOREMAN,
            UniversalUser.is_active.is_(True),
        )
        .order_by(UniversalUser.id)
        .first()
    )
    if row and row[0]:
        return row[0]
    row = (
        db.query(UniversalUser.name)
        .join(Object, Object.foreman_id == UniversalUser.id)
        .filter(Object.division_id == division_id)
        .order_by(UniversalUser.id)
        .first()
    )
    return row[0] if row and row[0] else None


class CrudPlannedTO(CRUDBase[PlannedTO, PlannedTOCreate, PlannedTOUpdate]):
    not_found = -133
    year_object_uc_is_exist = -1331
    # Запись вне области видимости — 403, см. `templates_raise.out_of_scope`.
    out_of_scope = -136

    def scoped_query(
        self,
        db: Session,
        scope: AccessScope,
        view: ArchiveView = ArchiveView.ACTUAL,
    ):
        """Единственное место, где список плановых ТО режется по области.

        Вместе с областью отсекается архив: заархивированный график удалён и в
        обычных списках не показывается.
        """
        query = apply_planned_to_scope(db.query(self.model), scope)
        return apply_archive_view(query, self.model, view)

    def get_multi(
        self,
        db: Session,
        *,
        scope: AccessScope,
        page: Optional[int] = None,
        only_archived: bool = False,
    ):
        """Перекрывает `CRUDBase.get_multi` ради обязательной области."""
        view = ArchiveView.choose(only_archived=only_archived)
        return pagination.get_page(self.scoped_query(db, scope, view), page)

    def get_planed_to_by_id(
        self, *, db: Session, planned_to_id: int, scope: AccessScope
    ):
        obj = db.query(PlannedTO).filter(PlannedTO.id == planned_to_id).first()
        if obj is None:
            return None, self.not_found, None
        if not can_access_planned_to(scope, obj):
            return None, self.out_of_scope, None
        return obj, 0, None

    def create_planned_to(
        self, db: Session, *, new_data: PlannedTOCreate, scope: AccessScope
    ):
        # проверка объекта
        if new_data.object_id is not None:
            obj = (
                db.query(Object)
                .filter(Object.id == new_data.object_id, object_scope_filter(scope))
                .first()
            )
            if obj is None:
                return None, -116, None  # нет объекта или он вне области
        # проверка плановых то
        if new_data.year is not None and new_data.object_id is not None:
            constrain = (
                db.query(PlannedTO)
                .filter(
                    PlannedTO.year == new_data.year,
                    PlannedTO.object_id == new_data.object_id,
                )
                .first()
            )
            if constrain is not None:
                return None, self.year_object_uc_is_exist, None
        if new_data.january_to_id:
            january_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.january_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " january_to"
                return None, code, None
        if new_data.february_to_id:
            february_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.february_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " february_to"
                return None, code, None
        if new_data.march_to_id:
            march_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.march_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " march_to"
                return None, code, None
        if new_data.april_to_id:
            april_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.april_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " april_to"
                return None, code, None
        if new_data.may_to_id:
            may_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.may_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " may_to"
                return None, code, None
        if new_data.june_to_id:
            june_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.june_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " june_to"
                return None, code, None
        if new_data.july_to_id:
            july_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.july_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " july_to"
                return None, code, None
        if new_data.august_to_id:
            august_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.august_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " august_to"
                return None, code, None
        if new_data.september_to_id:
            september_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.september_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " september_to"
                return None, code, None
        if new_data.october_to_id:
            october_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.october_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " october_to"
                return None, code, None
        if new_data.november_to_id:
            november_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.november_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " november_to"
                return None, code, None
        if new_data.december_to_id:
            december_to, code, indexes = crud_acts_fact.get_act_fact_by_id(
                db=db, id=new_data.december_to_id, scope=scope
            )
            if code != 0:
                code["detail"] = code["detail"] + " december_to"
                return None, code, None
        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_planned_to(
        self,
        *,
        db: Session,
        new_data: PlannedTOUpdate,
        planned_to_id: int,
        scope: AccessScope,
    ):
        # проверка наличия планового ТО
        this_planned_to, code, indexes = self.get_planed_to_by_id(
            db=db, planned_to_id=planned_to_id, scope=scope
        )
        if code != 0:
            return this_planned_to, code, indexes

        list_planned_to = [
            new_data.january_to_id,
            new_data.february_to_id,
            new_data.march_to_id,
            new_data.april_to_id,
            new_data.may_to_id,
            new_data.june_to_id,
            new_data.july_to_id,
            new_data.august_to_id,
            new_data.september_to_id,
            new_data.october_to_id,
            new_data.november_to_id,
            new_data.december_to_id,
        ]
        for to_id in list_planned_to:
            if to_id is not None:
                obj, code, indexes = crud_acts_fact.get_act_fact_by_id(
                    db=db, id=to_id, scope=scope
                )
                if code != 0:
                    code["detail"] = (
                        code["detail"] + f". Нет фактического акта с id {to_id}"
                    )
                    return obj, code, indexes
        # обновление данных
        db_obj = super().update(db=db, db_obj=this_planned_to, obj_in=new_data)
        return db_obj, 0, None

    def get_planed_to_by_object_id(
        self,
        *,
        db: Session,
        object_id: int,
        scope: AccessScope,
        page: Optional[int] = None,
    ) -> Tuple[List[ModelType], Paginator]:
        query = self.scoped_query(db, scope).filter(self.model.object_id == object_id)
        return pagination.get_page(query, page)

    def archive_planned_to(
        self, db: Session, *, planned_to_id: int, scope: AccessScope
    ):
        """Мягкое удаление годового графика ТО по объекту.

        Акты, на которые ссылаются ячейки, остаются как были: график — это
        план, а сделанная по нему работа никуда не девается.
        """
        planned, code, indexes = self.get_planed_to_by_id(
            db=db, planned_to_id=planned_to_id, scope=scope
        )
        if code != 0:
            return None, code, None
        return super().archiving(db=db, db_obj=planned)

    def restore_planned_to(
        self, db: Session, *, planned_to_id: int, scope: AccessScope
    ):
        """Вернуть график ТО из архива."""
        planned, code, indexes = self.get_planed_to_by_id(
            db=db, planned_to_id=planned_to_id, scope=scope
        )
        if code != 0:
            return None, code, None
        return super().unzipping(db=db, db_obj=planned)

    def get_schedule_execution_stats(
        self, *, db: Session, scope: AccessScope, year: int, month: int
    ) -> ScheduleExecutionStatsGet:
        month_col = _MONTH_PLANNED_COLUMN[month]
        period_start, period_end = _reporting_month_bounds(year, month)
        year_str = str(year)

        finished_in_period = and_(
            ActFact.finished_at.isnot(None),
            ActFact.finished_at >= period_start,
            ActFact.finished_at < period_end,
        )

        rows = (
            db.query(
                Object.division_id,
                Division.title,
                func.count(PlannedTO.id).label("planned"),
                func.coalesce(
                    func.sum(case((finished_in_period, 1), else_=0)),
                    0,
                ).label("completed"),
            )
            .select_from(PlannedTO)
            .join(Object, PlannedTO.object_id == Object.id)
            .join(Division, Division.id == Object.division_id)
            .join(ActFact, ActFact.id == month_col)
            # Тот же фильтр по объекту, что и у списков: у прораба и админа
            # проценты выполнения будут разными, и это ожидаемо.
            .filter(PlannedTO.year == year_str, object_scope_filter(scope))
            .group_by(Object.division_id, Division.title)
            .order_by(Object.division_id)
            .all()
        )

        divisions: List[ScheduleExecutionDivisionStats] = []
        for division_id, division_title, planned, completed in rows:
            completed_i = int(completed)
            planned_i = int(planned)
            pct = round(100.0 * completed_i / planned_i, 2) if planned_i > 0 else 0.0
            divisions.append(
                ScheduleExecutionDivisionStats(
                    division_id=division_id,
                    division_title=division_title,
                    responsible_name=_responsible_name_for_division(db, division_id),
                    completion_percent=pct,
                    planned_works_count=planned_i,
                    completed_works_count=completed_i,
                )
            )

        return ScheduleExecutionStatsGet(year=year, month=month, divisions=divisions)


crud_planned_to = CrudPlannedTO(PlannedTO)
