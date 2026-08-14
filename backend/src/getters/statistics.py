"""Сборка отчётов главной из строк, которые вернул `crud_statistics`."""

from typing import Dict, List, Optional

from src.crud.crud_statistics import MonthPeriod
from src.schemas.statistics import (
    BreakdownObjectItem,
    BreakdownPeriod,
    BreakdownsReport,
    EmployeeMetrics,
    EmployeeScoreItem,
    ForemanMetrics,
    OverdueMaintenanceItem,
    OverdueMaintenanceReport,
    ScheduleExecutionDivision,
    ScheduleExecutionReport,
    SeverityCount,
    TopEmployeesReport,
)
from src.services.employee_score import sort_scores

_SECONDS_IN_HOUR = 3600


def _hours(seconds: Optional[float]) -> Optional[float]:
    """Секунды в часы с одним знаком. None остаётся None, а не превращается в 0."""
    if seconds is None:
        return None
    return round(float(seconds) / _SECONDS_IN_HOUR, 1)


def _share(count: int, total: int) -> float:
    if not total:
        return 0.0
    return round(count * 100 / total, 1)


def _severity_counts(rows, total: int) -> List[SeverityCount]:
    return [
        SeverityCount(
            category_id=row.category_id,
            code=row.code,
            name=row.name,
            count=int(row.count),
            share=_share(int(row.count), total),
        )
        for row in rows
    ]


def _factory_model(factory: Optional[str], model: Optional[str]) -> Optional[str]:
    """«Завод Модель» одной строкой; пустые части не превращаются в пробелы."""
    parts = [part.strip() for part in (factory, model) if part and part.strip()]
    return " ".join(parts) if parts else None


def get_breakdowns_report(
    *,
    period: MonthPeriod,
    rows,
    total_breakdowns: int,
    objects_affected: int,
    summary_rows,
    severity_by_object: Dict[int, List],
    previous_counts: Optional[Dict[int, int]] = None,
) -> BreakdownsReport:
    items = []
    for row in rows:
        object_breakdowns = int(row.breakdown_count)

        previous_count = None
        delta = None
        if previous_counts is not None:
            # Объекта нет в словаре — значит в прошлом месяце поломок не было,
            # это честный ноль, а не отсутствие данных: период запрашивался
            # тем же запросом и по тем же фильтрам.
            previous_count = previous_counts.get(row.object_id, 0)
            delta = object_breakdowns - previous_count

        items.append(
            BreakdownObjectItem(
                object_id=row.object_id,
                object_name=row.object_name,
                registration_number=row.registration_number,
                factory_number=row.factory_number,
                address=row.address,
                client=row.client,
                division=row.division,
                factory_model=_factory_model(row.factory, row.model),
                responsible_mechanic=row.responsible_mechanic,
                breakdown_count=object_breakdowns,
                severity=_severity_counts(
                    severity_by_object.get(row.object_id, []), object_breakdowns
                ),
                avg_reaction_hours=_hours(row.avg_reaction_seconds),
                reacted_count=int(row.reacted_count or 0),
                avg_resolution_hours=_hours(row.avg_resolution_seconds),
                resolved_count=int(row.resolved_count or 0),
                previous_count=previous_count,
                delta=delta,
            )
        )

    return BreakdownsReport(
        period=BreakdownPeriod(year=period.year, month=period.month),
        total_breakdowns=total_breakdowns,
        objects_affected=objects_affected,
        severity_summary=_severity_counts(summary_rows, total_breakdowns),
        items=items,
    )


def _responsible(names: List[str]) -> Optional[str]:
    """Имена прорабов в одну ячейку таблицы.

    Второе и последующие имена сворачиваются в «+N»: в строку карточки на
    телефоне не помещается и одно полное ФИО, а обрезать список молча — значит
    показать участок так, будто за него отвечает один человек.
    """
    if not names:
        return None
    if len(names) == 1:
        return names[0]
    return f"{names[0]} +{len(names) - 1}"


def get_schedule_execution_report(
    *,
    period: MonthPeriod,
    rows,
    foremen: Dict[int, List[str]],
) -> ScheduleExecutionReport:
    items: List[ScheduleExecutionDivision] = []
    total_planned = 0
    total_completed = 0
    total_late = 0

    for row in rows:
        planned = int(row.planned_count or 0)
        completed = int(row.completed_count or 0)
        late = int(row.completed_late_count or 0)

        total_planned += planned
        total_completed += completed
        total_late += late

        names = foremen.get(row.division_id, [])
        items.append(
            ScheduleExecutionDivision(
                division_id=row.division_id,
                division=row.division,
                responsible=_responsible(names),
                responsible_count=len(names),
                planned_count=planned,
                completed_count=completed,
                completed_late_count=late,
                completion_percent=_share(completed, planned),
            )
        )

    return ScheduleExecutionReport(
        period=BreakdownPeriod(year=period.year, month=period.month),
        planned_count=total_planned,
        completed_count=total_completed,
        completed_late_count=total_late,
        completion_percent=_share(total_completed, total_planned),
        items=items,
    )


def get_overdue_maintenance_report(
    *,
    reference: MonthPeriod,
    rows,
    total_count: int,
    objects_affected: int,
) -> OverdueMaintenanceReport:
    items = [
        OverdueMaintenanceItem(
            act_id=row.act_id,
            object_id=row.object_id,
            object_name=row.object_name,
            registration_number=row.registration_number,
            factory_number=row.factory_number,
            address=row.address,
            client=row.client,
            division=row.division,
            responsible_mechanic=row.responsible_mechanic,
            # Год в базе строковый, наружу отдаём числом: фронту он нужен для
            # подписи «Март 2026», а не для сравнения строк.
            year=int(row.year),
            month=int(row.month),
            months_overdue=_months_between(
                year=int(row.year), month=int(row.month), reference=reference
            ),
        )
        for row in rows
    ]

    return OverdueMaintenanceReport(
        generated_for=BreakdownPeriod(year=reference.year, month=reference.month),
        total_count=total_count,
        objects_affected=objects_affected,
        items=items,
    )


def get_top_employees_report(
    *,
    period: MonthPeriod,
    scores,
    kind: str,
    worst_first: bool,
    min_works: int,
    limit: Optional[int],
    offset: int,
) -> TopEmployeesReport:
    """Рейтинг сотрудников: порядок, обрезка страницы и счётчики.

    Сортировка и обрезка живут здесь, а не в SQL: балл считается в Python,
    и отсортировать в базе то, чего в ней нет, всё равно нельзя.
    """
    ordered = sort_scores(scores, worst_first=worst_first)

    total_count = len(ordered)
    ranked_count = sum(
        1 for score in ordered if score.score is not None and not score.is_provisional
    )

    page = ordered[offset:] if offset else ordered
    if limit is not None:
        page = page[:limit]

    return TopEmployeesReport(
        period=BreakdownPeriod(year=period.year, month=period.month),
        kind=kind,
        order="worst" if worst_first else "best",
        min_works=min_works,
        total_count=total_count,
        ranked_count=ranked_count,
        items=[_employee_item(score, kind=kind) for score in page],
    )


def _employee_item(score, *, kind: str) -> EmployeeScoreItem:
    metrics = score.metrics or {}
    is_foreman = kind == "foreman"

    return EmployeeScoreItem(
        user_id=score.user_id,
        name=score.name,
        role_id=score.role_id,
        division=score.division,
        score=_rounded(score.score),
        is_provisional=score.is_provisional,
        works_count=score.works_count,
        orders_closed=score.orders_closed,
        maintenance_total=score.maintenance_total,
        maintenance_on_time=score.maintenance_on_time,
        work_units=round(float(score.work_units), 2),
        objects_count=score.objects_count,
        breakdowns_on_objects=score.breakdowns_on_objects,
        repeat_count=score.repeat_count,
        repeat_penalty=round(float(score.repeat_penalty), 1),
        reacted_count=score.reacted_count,
        avg_reaction_hours=_hours(score.avg_reaction_seconds),
        # У прораба и механика метрики разные, но строка одна: так карточка на
        # главной переключает режим, не меняя разбор ответа.
        metrics=EmployeeMetrics(
            timeliness=_rounded(metrics.get("timeliness")),
            reaction=_rounded(metrics.get("reaction")),
            workload=_rounded(metrics.get("workload")),
            reliability=_rounded(metrics.get("reliability")),
        )
        if not is_foreman
        else EmployeeMetrics(),
        foreman_metrics=ForemanMetrics(
            team=_rounded(metrics.get("team")),
            schedule=_rounded(metrics.get("schedule")),
            overdue=_rounded(metrics.get("overdue")),
        )
        if is_foreman
        else None,
    )


def _rounded(value: Optional[float]) -> Optional[float]:
    """Балл с одним знаком. None остаётся None: «нет данных» — не ноль."""
    if value is None:
        return None
    return round(float(value), 1)


def _months_between(*, year: int, month: int, reference: MonthPeriod) -> int:
    """Сколько месяцев прошло с планового месяца до текущего.

    В выдачу попадает только то, что строго раньше текущего месяца, поэтому
    результат всегда не меньше единицы — но в отчёт он идёт как данные, а не
    как утверждение о запросе, так что нижнюю границу держим здесь.
    """
    distance = (reference.year - year) * 12 + (reference.month - month)
    return max(distance, 1)
