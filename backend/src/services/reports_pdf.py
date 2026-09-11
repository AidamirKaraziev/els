"""Отчёт о работах на объектах в PDF.

Этот файл руководитель отправляет компании-клиенту, поэтому он устроен как
документ, а не как выгрузка данных: шапка с исполнителем и заказчиком,
сводка, матрица месяцев, подробности по объектам и место для подписи.

Собирается тем же ReportLab и тем же шрифтом, что дефектная ведомость и топ
поломок: регистрация кириллицы переиспользуется из `defective_act_pdf`, чтобы
не иметь двух списков путей к шрифтам, которые однажды разойдутся.

Цвет ячейки месяца взят из макета
--------------------------------
В кадре «Окно с графиками» строка объекта — это двенадцать квадратов в
зелёном, жёлтом и красном. Отчёт говорит на том же языке: свой набор цветов
означал бы, что один и тот же факт выглядит в системе по-разному.

Фотографии
----------
По умолчанию выключены. Три снимка по четыре мегабайта на акт превращают
годовой отчёт по сотне лифтов в файл на сотни мегабайт, который не уйдёт ни
по одной почте. Включённые — ужимаются до ширины колонки.
"""

import datetime
import os
from io import BytesIO
from typing import Dict, List, Optional
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from src.getters.reports import maintenance_status, work_steps
from src.schemas.reports import MaintenanceStatus, WorksReport
from src.services.defective_act_pdf import _ensure_font

#: Файлы лежат под `./static/`, а в базе хранится путь без этого префикса.
_STATIC_ROOT = "./static/"

_MONTH_SHORT = (
    "Я",
    "Ф",
    "М",
    "А",
    "М",
    "И",
    "И",
    "А",
    "С",
    "О",
    "Н",
    "Д",
)

_MONTH_FULL = (
    "январь",
    "февраль",
    "март",
    "апрель",
    "май",
    "июнь",
    "июль",
    "август",
    "сентябрь",
    "октябрь",
    "ноябрь",
    "декабрь",
)

# Те же три цвета, что в макете на экране графиков.
_GREEN = colors.HexColor("#97C459")
_AMBER = colors.HexColor("#EF9F27")
_RED = colors.HexColor("#E24B4A")
_GREY = colors.HexColor("#F1EFE8")
_LINE = colors.HexColor("#C8C8C8")

_CELL_COLORS = {
    MaintenanceStatus.DONE: _GREEN,
    MaintenanceStatus.LATE: _AMBER,
    MaintenanceStatus.OVERDUE: _RED,
    MaintenanceStatus.PENDING: _GREY,
    MaintenanceStatus.NONE: colors.white,
}

_STATUS_LABELS = {
    MaintenanceStatus.DONE: "выполнено",
    MaintenanceStatus.LATE: "выполнено с опозданием",
    MaintenanceStatus.OVERDUE: "просрочено",
    MaintenanceStatus.PENDING: "месяц ещё идёт",
    MaintenanceStatus.NONE: "не планировалось",
}


def _styles(font: str) -> Dict[str, ParagraphStyle]:
    return {
        "title": ParagraphStyle(
            "title", fontName=font, fontSize=16, leading=20, spaceAfter=2
        ),
        "sub": ParagraphStyle(
            "sub",
            fontName=font,
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#5F5E5A"),
        ),
        "h2": ParagraphStyle(
            "h2", fontName=font, fontSize=12, leading=15, spaceBefore=8, spaceAfter=4
        ),
        "cell": ParagraphStyle("cell", fontName=font, fontSize=7.5, leading=9.5),
        "head": ParagraphStyle(
            "head", fontName=font, fontSize=7.5, leading=9.5, textColor=colors.white
        ),
        "body": ParagraphStyle("body", fontName=font, fontSize=9, leading=12),
    }


def _p(text, style: ParagraphStyle) -> Paragraph:
    return Paragraph(
        escape(str(text if text is not None else "")).replace("\n", "<br/>"), style
    )


def _dash(value) -> str:
    """Пустое значение — прочерк.

    Пустая ячейка читается как «забыли напечатать», прочерк — как «данных нет».
    """
    if value is None:
        return "—"
    text = str(value).strip()
    return text if text else "—"


def _date(value: Optional[datetime.datetime], with_time: bool = False) -> str:
    if value is None:
        return "—"
    return value.strftime("%d.%m.%Y %H:%M" if with_time else "%d.%m.%Y")


def _static_path(stored: Optional[str]) -> Optional[str]:
    """Путь на диске из того, что лежит в базе.

    В базе — `organization/12/photo/abc.png`, на диске то же самое под
    `./static/`. Несуществующий файл даёт `None`: отчёт обязан собраться и
    без картинки, а не упасть на середине.
    """
    if not stored:
        return None
    path = os.path.join(_STATIC_ROOT, str(stored).lstrip("/"))
    return path if os.path.isfile(path) else None


def _scaled_image(path: str, max_w: float, max_h: float) -> Optional[Image]:
    """Картинка, вписанная в рамку. Битый файл пропускается молча."""
    try:
        from reportlab.lib.utils import ImageReader

        reader = ImageReader(path)
        width, height = reader.getSize()
        if width <= 0 or height <= 0:
            return None
        ratio = min(max_w / float(width), max_h / float(height))
        return Image(path, width=width * ratio, height=height * ratio)
    except Exception:
        # Сюда попадают обрезанные загрузки и файлы не тех форматов. Отчёт
        # важнее одной картинки, поэтому глушим: иначе один битый снимок
        # лишает заказчика всего документа.
        return None


def _header(report: WorksReport, organization, clients, styles, width) -> List:
    period = report.period
    left = [
        _p("Отчёт о работах на объектах", styles["title"]),
        _p(
            f"за период с {period.date_from.strftime('%d.%m.%Y')} "
            f"по {period.date_to.strftime('%d.%m.%Y')}",
            styles["sub"],
        ),
    ]
    if organization is not None:
        left.append(_p(f"Исполнитель: {_dash(organization.title)}", styles["sub"]))
        contacts = ", ".join(
            part for part in (organization.phone, organization.site) if part
        )
        if contacts:
            left.append(_p(contacts, styles["sub"]))
    if clients:
        # Много клиентов в одном отборе — обычное дело для руководителя,
        # который смотрит участок целиком. Перечисляем первых трёх, дальше
        # счётчик: полный список занял бы полстраницы.
        shown = ", ".join(clients[:3])
        tail = f" и ещё {len(clients) - 3}" if len(clients) > 3 else ""
        left.append(_p(f"Заказчик: {shown}{tail}", styles["sub"]))
    left.append(
        _p(
            f"Сформирован {datetime.date.today().strftime('%d.%m.%Y')}",
            styles["sub"],
        )
    )

    logo = None
    if organization is not None:
        path = _static_path(organization.logo)
        if path:
            logo = _scaled_image(path, 38 * mm, 20 * mm)

    table = Table(
        [[left, logo or ""]],
        colWidths=[width * 0.75, width * 0.25],
        style=TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ALIGN", (1, 0), (1, 0), "RIGHT"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ]
        ),
    )
    return [table, Spacer(1, 6)]


def _summary_block(report: WorksReport, styles, width) -> List:
    summary = report.summary
    period = report.period
    reaction = (
        f"{summary.avg_reaction_hours} ч"
        if summary.avg_reaction_hours is not None
        else "—"
    )

    pairs = [
        ("Объектов в отчёте", summary.objects_total),
        ("Без единой аварии", summary.objects_without_breakdowns),
        ("ТО по графику", summary.maintenance_planned),
        (
            "ТО выполнено",
            f"{summary.maintenance_completed} ({summary.completion_percent}%)",
        ),
        ("Из них с опозданием", summary.maintenance_late),
        ("ТО просрочено", summary.maintenance_overdue),
        ("Аварийных выездов", summary.counts.breakdowns),
        ("Среднее время реакции", reaction),
        ("Заявок от заказчика", summary.counts.client_requests),
        ("Прочих работ", summary.counts.other_requests),
        ("Дефектных актов", summary.counts.defects),
    ]

    cells = [
        [_p(label, styles["cell"]), _p(value, styles["cell"])] for label, value in pairs
    ]
    # Три колонки пар: одиннадцать строк в столбик заняли бы полстраницы.
    columns = 3
    rows = []
    for index in range(0, len(cells), columns):
        row = []
        for pair in cells[index : index + columns]:
            row.extend(pair)
        while len(row) < columns * 2:
            row.append("")
        rows.append(row)

    column_width = width / (columns * 2)
    table = Table(
        rows,
        colWidths=[column_width * 1.35, column_width * 0.65] * columns,
        style=TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.4, _LINE),
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FAFAF7")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        ),
    )

    note = _p(
        "Заявки учтены по датам. Плановые ТО — по плановому месяцу целиком: "
        f"{_MONTH_FULL[period.month_from.month - 1]} {period.month_from.year} — "
        f"{_MONTH_FULL[period.month_to.month - 1]} {period.month_to.year}.",
        styles["sub"],
    )

    return [
        _p("Сводка за период", styles["h2"]),
        table,
        Spacer(1, 3),
        note,
        Spacer(1, 8),
    ]


def _legend(styles) -> Table:
    items = [
        (_GREEN, "ТО в срок"),
        (_AMBER, "с опозданием"),
        (_RED, "просрочено"),
        (_GREY, "месяц идёт"),
        (colors.white, "нет плана"),
    ]
    row = []
    style = [("VALIGN", (0, 0), (-1, -1), "MIDDLE")]
    for index, (color, label) in enumerate(items):
        row.extend(["", _p(label, styles["cell"])])
        column = index * 2
        style.append(("BACKGROUND", (column, 0), (column, 0), color))
        style.append(("BOX", (column, 0), (column, 0), 0.4, _LINE))
    # Подпись не должна переноситься: разорванное посреди слова «не планиров
    # алось» в отчёте заказчику выглядит как брак вёрстки.
    widths = [5 * mm, 26 * mm] * len(items)
    return Table([row], colWidths=widths, style=TableStyle(style))


def _matrix(report: WorksReport, styles, width) -> List:
    """Матрица «объект × месяц»: цвет — статус ТО, число — прочие работы."""
    months = report.months
    header = [_p("Объект", styles["head"]), _p("Адрес", styles["head"])]
    for month in months:
        header.append(_p(_MONTH_SHORT[month.month - 1], styles["head"]))
    header.append(_p("Работ", styles["head"]))

    rows = [header]
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#5F5E5A")),
        ("GRID", (0, 0), (-1, -1), 0.4, _LINE),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (2, 0), (-1, -1), "CENTER"),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
    ]

    for index, item in enumerate(report.items, start=1):
        row = [
            _p(_dash(item.object_name), styles["cell"]),
            _p(_dash(item.address), styles["cell"]),
        ]
        for column, cell in enumerate(item.months, start=2):
            extra = (
                cell.counts.breakdowns
                + cell.counts.client_requests
                + cell.counts.other_requests
                + cell.counts.defects
            )
            # В ячейке — число внеплановых работ, а цвет несёт статус ТО. Так
            # одним взглядом видно, что в месяце было не только плановое ТО.
            row.append(_p(str(extra) if extra else "", styles["cell"]))
            style.append(
                (
                    "BACKGROUND",
                    (column, index),
                    (column, index),
                    _CELL_COLORS[cell.maintenance],
                )
            )
        total = (
            item.maintenance_completed
            + item.counts.breakdowns
            + item.counts.client_requests
            + item.counts.other_requests
            + item.counts.defects
        )
        row.append(_p(str(total), styles["cell"]))
        rows.append(row)

    month_width = 7 * mm
    fixed = month_width * len(months) + 12 * mm
    free = width - fixed
    widths = [free * 0.35, free * 0.65] + [month_width] * len(months) + [12 * mm]

    return [
        _p("Работы по месяцам", styles["h2"]),
        _legend(styles),
        Spacer(1, 3),
        Table(rows, colWidths=widths, style=TableStyle(style), repeatRows=1),
        Spacer(1, 8),
    ]


def _object_details(
    report: WorksReport,
    maintenance_rows,
    order_rows,
    defect_rows,
    order_photos: Dict[int, List[str]],
    defect_photos: Dict[int, List[str]],
    now: datetime.datetime,
    styles,
    width,
    with_photos: bool,
) -> List:
    """Подробности по каждому объекту: что именно делали."""
    by_object: Dict[int, Dict[str, List]] = {}
    for row in maintenance_rows:
        by_object.setdefault(row.object_id, {}).setdefault("to", []).append(row)
    for row in order_rows:
        by_object.setdefault(row.object_id, {}).setdefault("orders", []).append(row)
    for row in defect_rows:
        by_object.setdefault(row.object_id, {}).setdefault("defects", []).append(row)

    story: List = []
    for item in report.items:
        works = by_object.get(item.object_id)
        if not works:
            continue

        story.append(PageBreak())
        story.append(
            _p(f"{_dash(item.object_name)} — {_dash(item.address)}", styles["h2"])
        )
        story.append(
            _p(
                f"Зав. № {_dash(item.factory_number)} · рег. № "
                f"{_dash(item.registration_number)} · участок {_dash(item.division)} · "
                f"прораб {_dash(item.responsible_foreman)} · механик "
                f"{_dash(item.responsible_mechanic)}",
                styles["sub"],
            )
        )
        story.append(Spacer(1, 4))

        for row in works.get("to", []):
            status = maintenance_status(row.finished_at, row.month_end, now)
            steps = work_steps(row.step_list_fact)
            done = sum(1 for step in steps if step.done)
            head = (
                f"Плановое ТО за {_MONTH_FULL[int(row.month) - 1]} {int(row.year)} — "
                f"{_STATUS_LABELS[status]}"
            )
            lines = [
                _p(head, styles["body"]),
                _p(
                    f"Закрыт: {_date(row.finished_at)} · прораб {_dash(row.foreman)} · "
                    f"механик {_dash(row.mechanic)}",
                    styles["sub"],
                ),
            ]
            if steps:
                lines.append(
                    _p(f"Выполнено пунктов: {done} из {len(steps)}", styles["sub"])
                )
                lines.append(
                    _p(
                        "; ".join(
                            f"{'✓' if step.done else '×'} {step.title}"
                            for step in steps[:12]
                        )
                        + (" …" if len(steps) > 12 else ""),
                        styles["cell"],
                    )
                )
            else:
                # Пустой чек-лист — это «механик не заполнял», а не «работ не
                # было». Разница существенная, и в отчёте заказчику её надо
                # называть словами.
                lines.append(_p("Чек-лист не заполнен", styles["sub"]))
            story.append(KeepTogether(lines))
            story.append(Spacer(1, 4))

        orders = works.get("orders", [])
        if orders:
            story.append(_p("Заявки", styles["h2"]))
            head = [
                _p(title, styles["head"])
                for title in (
                    "Дата",
                    "Вид",
                    "Что случилось",
                    "Причина",
                    "Исполнитель",
                    "Реакция",
                )
            ]
            rows = [head]
            for row in orders:
                if row.is_breakdown:
                    kind = "Авария"
                elif row.is_client:
                    kind = "Заявка заказчика"
                else:
                    kind = "Прочая работа"
                reaction = "—"
                if row.created_at is not None and row.accepted_at is not None:
                    seconds = (row.accepted_at - row.created_at).total_seconds()
                    if seconds >= 0:
                        reaction = f"{round(seconds / 3600, 1)} ч"
                rows.append(
                    [
                        _p(_date(row.created_at, with_time=True), styles["cell"]),
                        _p(kind, styles["cell"]),
                        _p(_dash(row.task_text or row.category), styles["cell"]),
                        _p(_dash(row.reason), styles["cell"]),
                        _p(_dash(row.executor), styles["cell"]),
                        _p(reaction, styles["cell"]),
                    ]
                )
            story.append(
                Table(
                    rows,
                    colWidths=[
                        width * 0.13,
                        width * 0.13,
                        width * 0.33,
                        width * 0.18,
                        width * 0.15,
                        width * 0.08,
                    ],
                    style=TableStyle(
                        [
                            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#5F5E5A")),
                            ("GRID", (0, 0), (-1, -1), 0.4, _LINE),
                            ("VALIGN", (0, 0), (-1, -1), "TOP"),
                        ]
                    ),
                    repeatRows=1,
                )
            )
            story.append(Spacer(1, 4))
            if with_photos:
                story.extend(
                    _photo_strip(
                        [
                            path
                            for row in orders
                            for path in order_photos.get(row.order_id, [])
                        ],
                        styles,
                        width,
                    )
                )

        defects = works.get("defects", [])
        if defects:
            story.append(_p("Дефектные акты", styles["h2"]))
            for row in defects:
                story.append(
                    _p(
                        f"{_MONTH_FULL[int(row.month) - 1]}: {_dash(row.title)} — "
                        f"{_dash(row.status)}, ответственный {_dash(row.responsible)}",
                        styles["body"],
                    )
                )
                if row.description:
                    story.append(_p(row.description, styles["sub"]))
            if with_photos:
                story.extend(
                    _photo_strip(
                        [
                            path
                            for row in defects
                            for path in defect_photos.get(row.defect_id, [])
                        ],
                        styles,
                        width,
                    )
                )

    return story


def _defects_section(defect_rows, styles, width) -> List:
    """Дефектные акты одним списком по всему отбору.

    Внутри объекта акты тоже печатаются, но там они разбросаны по
    приложениям; заказчику нужен сводный перечень — тот же, что список под
    плиткой на экране. Фото здесь не печатаются: они остаются в блоке
    объекта, иначе годовой отчёт с галочкой удвоился бы в размере.
    """
    rows_in = list(defect_rows)
    if not rows_in:
        return []

    header = [
        _p(label, styles["head"])
        for label in (
            "№",
            "Дата",
            "Объект",
            "Адрес",
            "Акт",
            "Статус",
            "Ответственный",
            "Фото",
        )
    ]
    rows = [header]
    for index, row in enumerate(rows_in, start=1):
        act = [_p(_dash(row.title), styles["cell"])]
        if row.description:
            act.append(_p(row.description, styles["sub"]))
        rows.append(
            [
                _p(str(index), styles["cell"]),
                _p(_date(row.created_at), styles["cell"]),
                _p(_dash(row.object_name), styles["cell"]),
                _p(_dash(row.address), styles["cell"]),
                act,
                _p(_dash(row.status), styles["cell"]),
                _p(_dash(row.responsible), styles["cell"]),
                _p(str(row.photo_count) if row.photo_count else "—", styles["cell"]),
            ]
        )

    fixed = 8 * mm + 22 * mm + 12 * mm
    free = width - fixed
    widths = [
        8 * mm,
        22 * mm,
        free * 0.17,
        free * 0.21,
        free * 0.34,
        free * 0.12,
        free * 0.16,
        12 * mm,
    ]
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#5F5E5A")),
        ("GRID", (0, 0), (-1, -1), 0.4, _LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("ALIGN", (0, 0), (0, -1), "CENTER"),
        ("ALIGN", (-1, 0), (-1, -1), "CENTER"),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
    ]

    return [
        PageBreak(),
        _p("Дефектные акты за период", styles["h2"]),
        _p(
            f"Всего: {len(rows_in)}. Акты учтены по дате создания; "
            "фотографии — в подробностях по объекту.",
            styles["sub"],
        ),
        Spacer(1, 4),
        Table(rows, colWidths=widths, style=TableStyle(style), repeatRows=1),
    ]


def _photo_strip(stored_paths: List[str], styles, width) -> List:
    """Ряд фотографий, по три в строке.

    Ужимаются до трети ширины полосы: снимок с телефона в оригинале — это
    четыре мегабайта, и десяток таких делает файл неотправляемым.
    """
    images = []
    for stored in stored_paths:
        path = _static_path(stored)
        if not path:
            continue
        image = _scaled_image(path, width / 3.4, 45 * mm)
        if image is not None:
            images.append(image)

    if not images:
        return []

    rows = [images[index : index + 3] for index in range(0, len(images), 3)]
    for row in rows:
        while len(row) < 3:
            row.append("")

    return [
        Table(
            rows,
            colWidths=[width / 3.2] * 3,
            style=TableStyle(
                [
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 0),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ]
            ),
        ),
        Spacer(1, 4),
    ]


def _signature(styles, width) -> List:
    """Место для подписи: отчёт печатают и подписывают."""
    rows = [
        [
            _p("Руководитель ______________________", styles["body"]),
            _p("_______________ / ______________________", styles["body"]),
        ],
        [_p("должность", styles["sub"]), _p("подпись / расшифровка", styles["sub"])],
    ]
    return [
        Spacer(1, 12),
        Table(
            rows,
            colWidths=[width * 0.45, width * 0.55],
            style=TableStyle(
                [
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ]
            ),
        ),
    ]


def build_works_pdf(
    report: WorksReport,
    *,
    organization=None,
    clients: Optional[List[str]] = None,
    maintenance_rows=(),
    order_rows=(),
    defect_rows=(),
    order_photos: Optional[Dict[int, List[str]]] = None,
    defect_photos: Optional[Dict[int, List[str]]] = None,
    now: Optional[datetime.datetime] = None,
    with_photos: bool = False,
) -> bytes:
    """Собирает документ и отдаёт его байтами."""
    font = _ensure_font()
    styles = _styles(font)
    page_size = landscape(A4)
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=page_size,
        leftMargin=14 * mm,
        rightMargin=14 * mm,
        topMargin=12 * mm,
        bottomMargin=12 * mm,
        title="Отчёт о работах на объектах",
    )
    width = page_size[0] - doc.leftMargin - doc.rightMargin

    story: List = []
    story.extend(_header(report, organization, clients or [], styles, width))
    story.extend(_summary_block(report, styles, width))
    story.extend(_matrix(report, styles, width))
    story.extend(_signature(styles, width))
    story.extend(_defects_section(defect_rows, styles, width))
    story.extend(
        _object_details(
            report,
            maintenance_rows,
            order_rows,
            defect_rows,
            order_photos or {},
            defect_photos or {},
            now or datetime.datetime.now(),
            styles,
            width,
            with_photos,
        )
    )

    doc.build(story)
    return buffer.getvalue()


def works_pdf_filename(report: WorksReport) -> str:
    return (
        f"works-{report.period.date_from.isoformat()}-"
        f"{report.period.date_to.isoformat()}.pdf"
    )
