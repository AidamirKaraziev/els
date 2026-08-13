"""Сборка отчётов главной из строк, которые вернул `crud_statistics`."""

from typing import Dict, List, Optional

from src.crud.crud_statistics import MonthPeriod
from src.schemas.statistics import (
    BreakdownObjectItem,
    BreakdownPeriod,
    BreakdownsReport,
    OverdueMaintenanceItem,
    OverdueMaintenanceReport,
    ScheduleExecutionDivision,
    ScheduleExecutionReport,
    SeverityCount,
)

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


def _months_between(*, year: int, month: int, reference: MonthPeriod) -> int:
    """Сколько месяцев прошло с планового месяца до текущего.

    В выдачу попадает только то, что строго раньше текущего месяца, поэтому
    результат всегда не меньше единицы — но в отчёт он идёт как данные, а не
    как утверждение о запросе, так что нижнюю границу держим здесь.
    """
    distance = (reference.year - year) * 12 + (reference.month - month)
    return max(distance, 1)
