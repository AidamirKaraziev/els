"""Сборка отчёта по поломкам из строк, которые вернул `crud_statistics`."""

from typing import Dict, List, Optional

from src.crud.crud_statistics import MonthPeriod
from src.schemas.statistics import (
    BreakdownObjectItem,
    BreakdownPeriod,
    BreakdownsReport,
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
