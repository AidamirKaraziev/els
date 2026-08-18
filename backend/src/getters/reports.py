"""Сборка отчёта из строк, которые вернул `crud_reports`.

Здесь живут три вещи, которых нет в SQL: статус ТО за месяц, разбор чек-листа
акта и достройка матрицы месяцами, в которых не было ничего. Последнее важно:
запрос возвращает только месяцы с работами, а матрице нужны все, иначе
двенадцать ячеек превратятся в три и колонки разъедутся между строками.
"""

import datetime
from typing import Dict, List, Optional, Tuple

from src.crud.crud_reports import ReportRange, days_late
from src.schemas.reports import (
    DefectItem,
    MaintenanceStatus,
    MaintenanceWork,
    MonthCell,
    MonthTotals,
    ObjectWorksReport,
    ReportMonth,
    ReportObjectRow,
    ReportPeriod,
    ReportSummary,
    RequestWork,
    WorkCounts,
    WorkKind,
    WorksReport,
    WorkStep,
)
from src.services.checklist import parse_checklist

_SECONDS_IN_HOUR = 3600


def _hours(seconds: Optional[float]) -> Optional[float]:
    """Секунды в часы с одним знаком. None остаётся None, а не становится 0."""
    if seconds is None:
        return None
    return round(float(seconds) / _SECONDS_IN_HOUR, 1)


def _percent(part: int, whole: int) -> float:
    if not whole:
        return 0.0
    return round(part * 100 / whole, 1)


def _factory_model(factory: Optional[str], model: Optional[str]) -> Optional[str]:
    """«Завод Модель» одной строкой; пустые части не дают лишних пробелов."""
    parts = [part.strip() for part in (factory, model) if part and part.strip()]
    return " ".join(parts) if parts else None


def _key(year, month) -> Tuple[int, int]:
    """(год, месяц) числами.

    Год приходит строкой из графика и `Decimal` из `extract` по дате заявки,
    месяц — то литералом, то `Decimal`. Ключ матрицы обязан быть один и тот же
    независимо от источника, иначе ячейки не сойдутся.
    """
    return int(year), int(month)


def maintenance_status(
    finished_at: Optional[datetime.datetime],
    month_end: datetime.datetime,
    now: datetime.datetime,
) -> MaintenanceStatus:
    """Состояние ТО за месяц.

    Незакрытый акт даёт разное в зависимости от того, кончился ли плановый
    месяц: за прошедший это долг, за текущий — работа впереди. Смешивать их
    нельзя, иначе первого числа каждого месяца отчёт показывал бы всплеск
    просрочки на ровном месте.
    """
    if finished_at is None:
        return (
            MaintenanceStatus.OVERDUE if month_end <= now else MaintenanceStatus.PENDING
        )
    return (
        MaintenanceStatus.LATE if finished_at >= month_end else MaintenanceStatus.DONE
    )


def work_steps(step_list_fact: Optional[str]) -> List[WorkStep]:
    """Чек-лист акта из `step_list_fact`.

    Разбор живёт в `services/checklist.py`: форм у поля три, и держать их
    разбор здесь означало бы, что отчёт заказчику и экран механика считают
    выполненные пункты по-разному.

    Пустой список означает «чек-лист не заполнен», а не «работ не было», и
    экран обязан показывать это разными словами.
    """
    return [
        WorkStep(title=step.title, done=step.done)
        for step in parse_checklist(step_list_fact).steps
    ]


def get_report_period(period: ReportRange) -> ReportPeriod:
    first_year, first_month = period.months[0]
    last_year, last_month = period.months[-1]
    return ReportPeriod(
        date_from=period.date_from,
        date_to=period.date_to,
        month_from=ReportMonth(year=first_year, month=first_month),
        month_to=ReportMonth(year=last_year, month=last_month),
        months_count=len(period.months),
    )


def _counts(row=None, defects: int = 0) -> WorkCounts:
    if row is None:
        return WorkCounts(defects=defects)
    return WorkCounts(
        breakdowns=int(row.breakdowns or 0),
        client_requests=int(row.client_requests or 0),
        other_requests=int(row.other_requests or 0),
        defects=defects,
    )


def get_works_report(
    *,
    period: ReportRange,
    objects,
    total_objects: int,
    maintenance_totals,
    order_totals,
    defect_total: int,
    maintenance_months,
    order_months,
    defect_months,
    maintenance_cells,
    order_counts,
    defect_counts,
) -> WorksReport:
    """Отчёт целиком: сводка, помесячная полоса и матрица объектов."""
    planned = int(maintenance_totals.planned or 0)
    completed = int(maintenance_totals.completed or 0)
    objects_with_breakdowns = int(order_totals.objects_with_breakdowns or 0)

    summary = ReportSummary(
        objects_total=total_objects,
        # Считается вычитанием, а не отдельным запросом: «объектов в отборе»
        # и «объектов с авариями» уже посчитаны по одному и тому же отбору, и
        # третий запрос мог бы разойтись с ними.
        objects_without_breakdowns=max(total_objects - objects_with_breakdowns, 0),
        maintenance_planned=planned,
        maintenance_completed=completed,
        maintenance_late=int(maintenance_totals.late or 0),
        maintenance_overdue=int(maintenance_totals.overdue or 0),
        completion_percent=_percent(completed, planned),
        counts=_counts(order_totals, defects=defect_total),
        avg_reaction_hours=_hours(order_totals.avg_reaction_seconds),
        reacted_count=int(order_totals.reacted_count or 0),
    )

    months = _month_totals(
        period=period,
        maintenance_months=maintenance_months,
        order_months=order_months,
        defect_months=defect_months,
    )

    items = _object_rows(
        period=period,
        objects=objects,
        maintenance_cells=maintenance_cells,
        order_counts=order_counts,
        defect_counts=defect_counts,
    )

    return WorksReport(
        period=get_report_period(period),
        summary=summary,
        months=months,
        total_objects=total_objects,
        items=items,
    )


def _month_totals(
    *, period: ReportRange, maintenance_months, order_months, defect_months
) -> List[MonthTotals]:
    """Полоса по месяцам. Месяцы без работ остаются в ней нулями."""
    maintenance = {_key(row.year, row.month): row for row in maintenance_months}
    orders = {_key(row.year, row.month): row for row in order_months}
    defects = {
        _key(row.year, row.month): int(row.defects or 0) for row in defect_months
    }

    totals = []
    for year, month in period.months:
        key = (year, month)
        plan_row = maintenance.get(key)
        totals.append(
            MonthTotals(
                year=year,
                month=month,
                maintenance_planned=int(plan_row.planned or 0) if plan_row else 0,
                maintenance_completed=int(plan_row.completed or 0) if plan_row else 0,
                counts=_counts(orders.get(key), defects=defects.get(key, 0)),
            )
        )
    return totals


def _object_rows(
    *, period: ReportRange, objects, maintenance_cells, order_counts, defect_counts
) -> List[ReportObjectRow]:
    cells_by_object: Dict[int, Dict[Tuple[int, int], object]] = {}
    for row in maintenance_cells:
        cells_by_object.setdefault(row.object_id, {})[_key(row.year, row.month)] = row

    orders_by_object: Dict[int, Dict[Tuple[int, int], object]] = {}
    for row in order_counts:
        orders_by_object.setdefault(row.object_id, {})[_key(row.year, row.month)] = row

    defects_by_object: Dict[int, Dict[Tuple[int, int], int]] = {}
    for row in defect_counts:
        defects_by_object.setdefault(row.object_id, {})[_key(row.year, row.month)] = (
            int(row.defects or 0)
        )

    rows = []
    for obj in objects:
        cells = cells_by_object.get(obj.object_id, {})
        orders = orders_by_object.get(obj.object_id, {})
        defects = defects_by_object.get(obj.object_id, {})

        months: List[MonthCell] = []
        planned = completed = late = overdue = 0
        total_counts = WorkCounts()

        for year, month in period.months:
            key = (year, month)
            cell = cells.get(key)
            status = MaintenanceStatus.NONE
            finished_at = None

            if cell is not None:
                planned += 1
                finished_at = cell.finished_at
                status = maintenance_status(finished_at, cell.month_end, period.now)
                if status is MaintenanceStatus.DONE:
                    completed += 1
                elif status is MaintenanceStatus.LATE:
                    completed += 1
                    late += 1
                elif status is MaintenanceStatus.OVERDUE:
                    overdue += 1

            month_counts = _counts(orders.get(key), defects=defects.get(key, 0))
            total_counts = _add(total_counts, month_counts)

            months.append(
                MonthCell(
                    year=year,
                    month=month,
                    maintenance=status,
                    maintenance_finished_at=finished_at
                    if status in (MaintenanceStatus.DONE, MaintenanceStatus.LATE)
                    else None,
                    counts=month_counts,
                    works_total=_total(month_counts)
                    + (1 if status is not MaintenanceStatus.NONE else 0),
                )
            )

        rows.append(
            ReportObjectRow(
                object_id=obj.object_id,
                object_name=obj.object_name,
                registration_number=obj.registration_number,
                factory_number=obj.factory_number,
                address=obj.address,
                client=obj.client,
                division=obj.division,
                factory_model=_factory_model(obj.factory, obj.model),
                responsible_mechanic=obj.responsible_mechanic,
                responsible_foreman=obj.responsible_foreman,
                maintenance_planned=planned,
                maintenance_completed=completed,
                maintenance_late=late,
                maintenance_overdue=overdue,
                counts=total_counts,
                months=months,
            )
        )
    return rows


def _add(left: WorkCounts, right: WorkCounts) -> WorkCounts:
    return WorkCounts(
        breakdowns=left.breakdowns + right.breakdowns,
        client_requests=left.client_requests + right.client_requests,
        other_requests=left.other_requests + right.other_requests,
        defects=left.defects + right.defects,
    )


def _total(counts: WorkCounts) -> int:
    return (
        counts.breakdowns
        + counts.client_requests
        + counts.other_requests
        + counts.defects
    )


def get_object_works_report(
    *, period: ReportRange, obj: ReportObjectRow, maintenance, orders, defects
) -> ObjectWorksReport:
    """Работы одного объекта — уровни 2 и 3 экрана."""
    defect_items = [
        DefectItem(
            defect_id=row.defect_id,
            title=row.title,
            description=row.description,
            month=int(row.month),
            status=row.status,
            responsible=row.responsible,
            created_at=row.created_at,
            photo_count=int(row.photo_count or 0),
        )
        for row in defects
    ]
    defects_by_month: Dict[int, List[DefectItem]] = {}
    for item in defect_items:
        defects_by_month.setdefault(item.month, []).append(item)

    maintenance_works = []
    for row in maintenance:
        year, month = _key(row.year, row.month)
        status = maintenance_status(row.finished_at, row.month_end, period.now)
        maintenance_works.append(
            MaintenanceWork(
                act_id=row.act_id,
                year=year,
                month=month,
                status=status,
                started_at=row.started_at,
                finished_at=row.finished_at,
                days_late=days_late(row.finished_at, year, month)
                if status is MaintenanceStatus.LATE
                else None,
                foreman=row.foreman,
                mechanic=row.mechanic,
                steps=work_steps(row.step_list_fact),
                defects=defects_by_month.get(month, []),
            )
        )

    request_works = [
        RequestWork(
            kind=_request_kind(row),
            order_id=row.order_id,
            created_at=row.created_at,
            accepted_at=row.accepted_at,
            done_at=row.done_at,
            reaction_hours=_reaction_hours(row),
            category=row.category,
            category_code=row.category_code,
            reason=row.reason,
            task_text=row.task_text,
            commentary=row.commentary,
            status=row.status,
            creator=row.creator,
            executor=row.executor,
        )
        for row in orders
    ]

    return ObjectWorksReport(
        object=obj,
        period=get_report_period(period),
        maintenance=maintenance_works,
        requests=request_works,
        defects=defect_items,
    )


def _request_kind(row) -> WorkKind:
    if row.is_breakdown:
        return WorkKind.BREAKDOWN
    return WorkKind.CLIENT_REQUEST if row.is_client else WorkKind.REQUEST


def _reaction_hours(row) -> Optional[float]:
    """Время реакции по одной заявке.

    Отрицательная разница означает битые данные — заявку взяли раньше, чем
    создали. Показываем пусто, а не минус: в отчёте клиенту такая строка
    выглядела бы как ошибка счёта, а не как ошибка ввода.
    """
    if row.created_at is None or row.accepted_at is None:
        return None
    seconds = (row.accepted_at - row.created_at).total_seconds()
    return _hours(seconds) if seconds >= 0 else None
