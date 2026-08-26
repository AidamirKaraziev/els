"""Сборка строк раздела «Графики» из того, что вернул `crud_schedules`.

Здесь ровно две вещи, которых нет в SQL: статус клетки и достройка года до
двенадцати месяцев. Запрос отдаёт только занятые месяцы, а ленте нужны все —
иначе двенадцать клеток превратились бы в три и колонки разъехались бы между
строками.

Статус считает `maintenance_status` из отчётов, а не своя копия: лента
графиков и отчёт за тот же год обязаны говорить одно и то же.
"""

import datetime
from typing import Dict, List

from src.getters.reports import maintenance_status
from src.schemas.reports import MaintenanceStatus
from src.schemas.schedules import ScheduleCell, ScheduleRow

_MONTHS = range(1, 13)


def _by_object(cells) -> Dict[int, Dict[int, object]]:
    """Клетки, разложенные на «объект → месяц»."""
    grouped: Dict[int, Dict[int, object]] = {}
    for cell in cells:
        grouped.setdefault(cell.object_id, {})[int(cell.month)] = cell
    return grouped


def get_schedule_rows(
    *,
    rows,
    cells,
    year: int,
    now: datetime.datetime,
) -> List[ScheduleRow]:
    """Строки ленты: объект и его двенадцать клеток."""
    cells_by_object = _by_object(cells)

    result: List[ScheduleRow] = []
    for row in rows:
        by_month = cells_by_object.get(row.object_id, {})

        result.append(
            ScheduleRow(
                object_id=row.object_id,
                name=row.object_name,
                year=year,
                cells=[_cell(month, by_month.get(month), now) for month in _MONTHS],
                factory_number=row.factory_number,
                address=row.address,
                division=row.division,
                foreman=row.foreman,
                type_name=row.type_name,
            )
        )

    return result


def _cell(month: int, cell, now: datetime.datetime) -> ScheduleCell:
    """Клетка месяца. Пустая — это «ТО не назначено», а не «не выполнено».

    У пустой клетки нет ни вида ТО, ни работы: открывать по клику нечего.
    """
    if cell is None:
        return ScheduleCell(month=month, status=MaintenanceStatus.NONE)

    return ScheduleCell(
        month=month,
        status=maintenance_status(cell.finished_at, cell.month_end, now),
        to_name=cell.to_name,
        act_id=cell.act_id,
    )
