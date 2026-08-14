"""Выгрузка отчёта о работах в Excel.

Четыре листа: «Сводка» с цифрами и помесячной полосой, дальше «ТО», «Заявки»
и «Дефекты» построчно. Разбито именно так, потому что файл не читают — с ним
работают: руководитель отправляет его клиенту, а клиент ставит автофильтр по
адресу и смотрит свой дом.

Цифры сводки приходят готовым `WorksReport` — тем же, который получает экран.
Собирать их здесь заново значило бы завести вторую реализацию, которая
однажды разойдётся с первой, и объяснить расхождение между экраном и
отправленным файлом было бы нечем.

Построчные листы приходят строками запроса, а не через `WorksReport`: в
матрице лежат счётчики по месяцам, а в файл нужны сами работы.
"""

import datetime
from io import BytesIO
from typing import List

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

from src.getters.reports import maintenance_status, work_steps
from src.schemas.reports import MaintenanceStatus, WorksReport

MONTHS = (
    "Январь",
    "Февраль",
    "Март",
    "Апрель",
    "Май",
    "Июнь",
    "Июль",
    "Август",
    "Сентябрь",
    "Октябрь",
    "Ноябрь",
    "Декабрь",
)

_STATUS_LABELS = {
    MaintenanceStatus.DONE: "Выполнено",
    MaintenanceStatus.LATE: "Выполнено с опозданием",
    MaintenanceStatus.OVERDUE: "Просрочено",
    MaintenanceStatus.PENDING: "Не выполнено, месяц идёт",
    MaintenanceStatus.NONE: "Не планировалось",
}

_HEADER_FILL = PatternFill("solid", fgColor="E8F0DC")
_HEADER_FONT = Font(bold=True)
_TITLE_FONT = Font(bold=True, size=14)
_THIN = Side(style="thin", color="C8C8C8")
_BORDER = Border(left=_THIN, right=_THIN, top=_THIN, bottom=_THIN)
_DATE_FORMAT = "DD.MM.YYYY"
_DATETIME_FORMAT = "DD.MM.YYYY HH:MM"


def _write_header(sheet, titles: List[str], row: int = 1) -> None:
    for column, title in enumerate(titles, start=1):
        cell = sheet.cell(row=row, column=column, value=title)
        cell.font = _HEADER_FONT
        cell.fill = _HEADER_FILL
        cell.border = _BORDER
        cell.alignment = Alignment(vertical="center", wrap_text=True)
    sheet.freeze_panes = sheet.cell(row=row + 1, column=1)


def _fit_columns(sheet, widths: List[int]) -> None:
    for index, width in enumerate(widths, start=1):
        sheet.column_dimensions[get_column_letter(index)].width = width


def _autofilter(sheet, columns: int, rows: int) -> None:
    """Автофильтр по шапке. На пустом листе не ставится — Excel ругается."""
    if rows:
        sheet.auto_filter.ref = f"A1:{get_column_letter(columns)}{rows + 1}"


def _period_title(report: WorksReport) -> str:
    period = report.period
    return (
        f"Период: {period.date_from.strftime('%d.%m.%Y')} — "
        f"{period.date_to.strftime('%d.%m.%Y')}"
    )


def _summary_sheet(book: Workbook, report: WorksReport) -> None:
    sheet = book.active
    sheet.title = "Сводка"
    summary = report.summary

    sheet["A1"] = "Отчёт о работах на объектах"
    sheet["A1"].font = _TITLE_FONT
    sheet["A2"] = _period_title(report)

    # Про расхождение границ сказано прямо в файле: клиент, который сложит
    # выгрузку с собственным учётом по дням, иначе решит, что мы ошиблись.
    month_from, month_to = report.period.month_from, report.period.month_to
    sheet["A3"] = (
        "Заявки учтены по датам. Плановые ТО — по плановому месяцу целиком: "
        f"{MONTHS[month_from.month - 1]} {month_from.year} — "
        f"{MONTHS[month_to.month - 1]} {month_to.year}."
    )

    rows = [
        ("Объектов в отчёте", summary.objects_total),
        ("Из них без единой аварии", summary.objects_without_breakdowns),
        ("ТО запланировано", summary.maintenance_planned),
        ("ТО выполнено", summary.maintenance_completed),
        ("Из них с опозданием", summary.maintenance_late),
        ("ТО просрочено", summary.maintenance_overdue),
        ("Выполнение графика, %", summary.completion_percent),
        ("Аварийных выездов", summary.counts.breakdowns),
        ("Среднее время реакции, ч", summary.avg_reaction_hours),
        ("Заявок от заказчика", summary.counts.client_requests),
        ("Прочих работ", summary.counts.other_requests),
        ("Дефектных ведомостей", summary.counts.defects),
    ]
    for index, (label, value) in enumerate(rows, start=5):
        sheet.cell(row=index, column=1, value=label).font = _HEADER_FONT
        sheet.cell(row=index, column=2, value=value)

    start = 5 + len(rows) + 2
    sheet.cell(row=start - 1, column=1, value="По месяцам").font = _TITLE_FONT
    _write_header(
        sheet,
        [
            "Месяц",
            "ТО план",
            "ТО факт",
            "Аварии",
            "Заявки заказчика",
            "Прочие работы",
            "Дефектные ведомости",
        ],
        row=start,
    )
    # `freeze_panes` выставляется в `_write_header` по строке шапки, но на
    # этом листе шапка не первая — закрепление уводило бы вид вниз.
    sheet.freeze_panes = None

    for offset, month in enumerate(report.months, start=1):
        row = start + offset
        values = [
            f"{MONTHS[month.month - 1]} {month.year}",
            month.maintenance_planned,
            month.maintenance_completed,
            month.counts.breakdowns,
            month.counts.client_requests,
            month.counts.other_requests,
            month.counts.defects,
        ]
        for column, value in enumerate(values, start=1):
            cell = sheet.cell(row=row, column=column, value=value)
            cell.border = _BORDER

    _fit_columns(sheet, [32, 22, 14, 14, 20, 16, 22])


def _maintenance_sheet(book: Workbook, rows, now: datetime.datetime) -> None:
    sheet = book.create_sheet("ТО")
    titles = [
        "Адрес",
        "Объект",
        "Год",
        "Месяц",
        "Статус",
        "Начато",
        "Закрыто",
        "Опоздание, дней",
        "Прораб",
        "Механик",
        "Пунктов выполнено",
        "Пунктов всего",
    ]
    _write_header(sheet, titles)

    for index, row in enumerate(rows, start=2):
        status = maintenance_status(row.finished_at, row.month_end, now)
        steps = work_steps(row.step_list_fact)
        late = None
        if status is MaintenanceStatus.LATE:
            late = max((row.finished_at - row.month_end).days, 0)

        values = [
            row.address,
            row.object_name,
            int(row.year),
            MONTHS[int(row.month) - 1],
            _STATUS_LABELS[status],
            row.started_at,
            row.finished_at,
            late,
            row.foreman,
            row.mechanic,
            sum(1 for step in steps if step.done),
            len(steps),
        ]
        for column, value in enumerate(values, start=1):
            cell = sheet.cell(row=index, column=column, value=value)
            cell.border = _BORDER
            if column in (6, 7):
                cell.number_format = _DATETIME_FORMAT

    _fit_columns(sheet, [34, 18, 8, 12, 24, 18, 18, 16, 22, 22, 18, 14])
    _autofilter(sheet, len(titles), len(rows))


def _order_sheet(book: Workbook, rows) -> None:
    sheet = book.create_sheet("Заявки")
    titles = [
        "Адрес",
        "Объект",
        "Вид",
        "Создана",
        "Принята",
        "Устранена",
        "Реакция, ч",
        "Категория",
        "Причина",
        "Статус",
        "Автор",
        "Исполнитель",
        "Текст заявки",
    ]
    _write_header(sheet, titles)

    for index, row in enumerate(rows, start=2):
        if row.is_breakdown:
            kind = "Авария"
        elif row.is_client:
            kind = "Заявка заказчика"
        else:
            kind = "Прочая работа"

        reaction = None
        if row.created_at is not None and row.accepted_at is not None:
            seconds = (row.accepted_at - row.created_at).total_seconds()
            # Отрицательная разница — битые данные: заявку взяли раньше, чем
            # создали. Пусто честнее минуса.
            reaction = round(seconds / 3600, 1) if seconds >= 0 else None

        values = [
            row.address,
            row.object_name,
            kind,
            row.created_at,
            row.accepted_at,
            row.done_at,
            reaction,
            row.category,
            row.reason,
            row.status,
            row.creator,
            row.executor,
            row.task_text,
        ]
        for column, value in enumerate(values, start=1):
            cell = sheet.cell(row=index, column=column, value=value)
            cell.border = _BORDER
            if column in (4, 5, 6):
                cell.number_format = _DATETIME_FORMAT

    _fit_columns(sheet, [34, 18, 18, 18, 18, 18, 12, 26, 26, 16, 22, 22, 50])
    _autofilter(sheet, len(titles), len(rows))


def _defect_sheet(book: Workbook, rows) -> None:
    sheet = book.create_sheet("Дефекты")
    titles = [
        "Адрес",
        "Объект",
        "Год",
        "Месяц",
        "Заголовок",
        "Описание",
        "Статус",
        "Ответственный",
        "Составлена",
        "Фотографий",
    ]
    _write_header(sheet, titles)

    for index, row in enumerate(rows, start=2):
        values = [
            row.address,
            row.object_name,
            int(row.year),
            MONTHS[int(row.month) - 1],
            row.title,
            row.description,
            row.status,
            row.responsible,
            row.created_at,
            int(row.photo_count or 0),
        ]
        for column, value in enumerate(values, start=1):
            cell = sheet.cell(row=index, column=column, value=value)
            cell.border = _BORDER
            if column == 9:
                cell.number_format = _DATE_FORMAT

    _fit_columns(sheet, [34, 18, 8, 12, 30, 50, 16, 22, 18, 14])
    _autofilter(sheet, len(titles), len(rows))


def build_works_xlsx(
    report: WorksReport,
    *,
    maintenance_rows,
    order_rows,
    defect_rows,
    now: datetime.datetime,
) -> bytes:
    """Собирает книгу Excel и отдаёт её байтами.

    `now` — момент, относительно которого месяц считается прошедшим. Тот же,
    что считал отчёт для экрана: иначе строка «Просрочено» в файле могла бы
    разойтись с красной ячейкой на экране, открытом секундой раньше.
    """
    book = Workbook()
    _summary_sheet(book, report)
    _maintenance_sheet(book, maintenance_rows, now)
    _order_sheet(book, order_rows)
    _defect_sheet(book, defect_rows)

    buffer = BytesIO()
    book.save(buffer)
    return buffer.getvalue()


def works_filename(report: WorksReport) -> str:
    """Имя файла из периода: «работы-2026-01-01-2026-12-31.xlsx»."""
    return (
        f"works-{report.period.date_from.isoformat()}-"
        f"{report.period.date_to.isoformat()}.xlsx"
    )
