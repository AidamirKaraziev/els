"""Отчёт «Топ поломок» в PDF.

Собирается тем же ReportLab, что и дефектная ведомость, и тем же шрифтом:
регистрацию кириллицы переиспользуем из `defective_act_pdf`, чтобы не иметь
двух списков путей к шрифтам, которые однажды разойдутся.

Лист альбомный: у отчёта десять колонок, в книжную ориентацию они не влезают
даже мелким кеглем.
"""

from __future__ import annotations

from io import BytesIO
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from src.schemas.statistics import BreakdownsReport

# Приватное имя, но брать его отсюда правильнее, чем заводить второй список
# путей к шрифтам: на сервере кириллический шрифт один и тот же.
from src.services.defective_act_pdf import _ensure_font

_MONTHS = (
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

_COLUMNS = (
    "Объект",
    "Адрес",
    "Клиент",
    "Участок",
    "Модель",
    "Механик",
    "Поломок",
    "По тяжести",
    "Реакция",
    "К прошлому",
)

# Доли ширины страницы. Сумма — единица; текстовым колонкам отдаём больше,
# числовым хватает узких.
_WIDTHS = (0.13, 0.16, 0.14, 0.09, 0.11, 0.11, 0.05, 0.09, 0.06, 0.06)


def _dash(value) -> str:
    """Пустое значение в отчёте — прочерк, а не пустая ячейка.

    Пустая ячейка читается как «забыли напечатать», прочерк — как «данных нет».
    """
    if value is None:
        return "—"
    text = str(value).strip()
    return text if text else "—"


def _reaction(item) -> str:
    if item.avg_reaction_hours is None or item.reacted_count == 0:
        return "—"
    # Число заявок рядом обязательно: «2 ч» по одной заявке из сорока и «2 ч»
    # по сорока — разные утверждения, а выглядят одинаково.
    return f"{item.avg_reaction_hours} ч\n(по {item.reacted_count} из {item.breakdown_count})"


def _delta(item) -> str:
    if item.delta is None:
        return "—"
    if item.delta == 0:
        return "="
    # Рост числа поломок — это хуже, поэтому знак важен и его видно.
    return f"+{item.delta}" if item.delta > 0 else str(item.delta)


def _severity(item) -> str:
    if not item.severity:
        return "—"
    return ", ".join(
        f"{part.code or 'без категории'} · {part.count}" for part in item.severity
    )


def build_breakdowns_pdf(report: BreakdownsReport) -> bytes:
    """Собирает отчёт и возвращает готовые байты PDF."""
    font = _ensure_font()
    page_size = landscape(A4)

    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=page_size,
        leftMargin=12 * mm,
        rightMargin=12 * mm,
        topMargin=12 * mm,
        bottomMargin=12 * mm,
        title="Топ поломок",
    )
    inner_width = page_size[0] - doc.leftMargin - doc.rightMargin

    title_style = ParagraphStyle(
        "title", fontName=font, fontSize=15, leading=19, spaceAfter=2
    )
    subtitle_style = ParagraphStyle(
        "subtitle", fontName=font, fontSize=9.5, leading=13, textColor=colors.grey
    )
    head_style = ParagraphStyle("head", fontName=font, fontSize=8, leading=10)
    cell_style = ParagraphStyle("cell", fontName=font, fontSize=7.5, leading=9.5)

    month_name = _MONTHS[report.period.month - 1] if report.period.month else ""
    story: list = [
        Paragraph(
            escape(f"Топ поломок · {month_name} {report.period.year}"), title_style
        ),
        Paragraph(
            escape(
                f"Поломок {report.total_breakdowns} "
                f"на {report.objects_affected} объектах"
            ),
            subtitle_style,
        ),
    ]

    if report.severity_summary:
        story.append(
            Paragraph(
                escape(
                    "По тяжести: "
                    + ", ".join(
                        f"{row.code or 'без категории'} — {row.count} ({row.share}%)"
                        for row in report.severity_summary
                    )
                ),
                subtitle_style,
            )
        )

    story.append(Spacer(1, 6 * mm))

    if not report.items:
        story.append(Paragraph("За этот период поломок нет.", cell_style))
        doc.build(story)
        return buffer.getvalue()

    rows: list[list] = [
        [Paragraph(escape(name), head_style) for name in _COLUMNS],
    ]
    for item in report.items:
        number = item.object_name or item.registration_number or f"№{item.object_id}"
        rows.append(
            [
                Paragraph(escape(_dash(number)), cell_style),
                Paragraph(escape(_dash(item.address)), cell_style),
                Paragraph(escape(_dash(item.client)), cell_style),
                Paragraph(escape(_dash(item.division)), cell_style),
                Paragraph(escape(_dash(item.factory_model)), cell_style),
                Paragraph(escape(_dash(item.responsible_mechanic)), cell_style),
                Paragraph(str(item.breakdown_count), cell_style),
                Paragraph(escape(_severity(item)), cell_style),
                Paragraph(escape(_reaction(item)).replace("\n", "<br/>"), cell_style),
                Paragraph(escape(_delta(item)), cell_style),
            ]
        )

    table = Table(
        rows,
        colWidths=[inner_width * share for share in _WIDTHS],
        # Шапка повторяется на каждой странице: на сотне объектов отчёт
        # уезжает на несколько листов, и без этого второй лист нечитаем.
        repeatRows=1,
    )
    table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#D9D9D9")),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F2F4F5")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    story.append(table)

    doc.build(story)
    return buffer.getvalue()
