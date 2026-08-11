"""
Генерация PDF «Дефектная ведомость» для дефектного акта (ReportLab).
Шрифт с кириллицей: static/fonts/NotoSans-Regular.ttf (или системные пути).
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

# Корень репозитория: src/services -> два уровня вверх
_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

_FONT_REGISTERED = False
_FONT_NAME = "DefectActNoto"


@dataclass
class DefectiveActPdfData:
    """Данные для заполнения шаблона (без ORM)."""

    equipment_name: str
    planned_year: str
    month: int
    title: str
    description: str
    status_name: str
    responsible_name: str
    creator_name: str
    photo_paths: list[str]


def _resolve_font_path() -> str | None:
    candidates = [
        os.path.join(_REPO_ROOT, "static", "fonts", "NotoSans-Regular.ttf"),
        os.path.join(_REPO_ROOT, "static", "fonts", "DejaVuSans.ttf"),
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for p in candidates:
        if p and os.path.isfile(p):
            return os.path.abspath(p)
    return None


def _ensure_font() -> str:
    global _FONT_REGISTERED
    if _FONT_REGISTERED:
        return _FONT_NAME
    path = _resolve_font_path()
    if path:
        pdfmetrics.registerFont(TTFont(_FONT_NAME, path))
        _FONT_REGISTERED = True
        return _FONT_NAME
    return "Helvetica"


def _p(text: str, style: ParagraphStyle) -> Paragraph:
    safe = escape(str(text or "")).replace("\n", "<br/>")
    return Paragraph(safe, style)


def _scaled_image(path: str, max_w: float, max_h: float) -> Image:
    from reportlab.lib.utils import ImageReader

    ir = ImageReader(path)
    iw, ih = ir.getSize()
    if iw <= 0 or ih <= 0:
        return Image(path, width=max_w * 0.5, height=max_h * 0.5)
    ratio = min(max_w / float(iw), max_h / float(ih))
    return Image(path, width=iw * ratio, height=ih * ratio)


def build_defective_act_pdf(output_path: str, data: DefectiveActPdfData) -> None:
    """
    Собирает PDF в духе образца: заголовок, таблица 4×(шапка+нумерация+данные), фото, подписи.
    """
    font = _ensure_font()
    page_size = landscape(A4)
    doc = SimpleDocTemplate(
        output_path,
        pagesize=page_size,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=14 * mm,
        bottomMargin=14 * mm,
    )
    w, _ = page_size
    inner_w = w - doc.leftMargin - doc.rightMargin

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        name="ActTitle",
        parent=styles["Normal"],
        fontName=font,
        fontSize=14,
        leading=18,
        alignment=TA_CENTER,
        spaceAfter=6,
    )
    sub_style = ParagraphStyle(
        name="ActSub",
        parent=styles["Normal"],
        fontName=font,
        fontSize=9,
        leading=12,
        alignment=TA_CENTER,
        spaceAfter=10,
    )
    cell_style = ParagraphStyle(
        name="ActCell",
        parent=styles["Normal"],
        fontName=font,
        fontSize=8,
        leading=10,
        alignment=TA_LEFT,
    )
    num_style = ParagraphStyle(
        name="ActNum",
        parent=styles["Normal"],
        fontName=font,
        fontSize=8,
        leading=10,
        alignment=TA_CENTER,
    )
    footer_style = ParagraphStyle(
        name="ActFooter",
        parent=styles["Normal"],
        fontName=font,
        fontSize=9,
        leading=12,
        alignment=TA_LEFT,
    )

    story = []

    story.append(_p("ДЕФЕКТНАЯ ВЕДОМОСТЬ", title_style))
    story.append(
        _p(
            "В процессе эксплуатации перечисленного оборудования обнаружены следующие дефекты:",
            sub_style,
        )
    )

    # Таблица: шапка | нумерация | данные
    col_w = [inner_w * 0.22, inner_w * 0.26, inner_w * 0.30, inner_w * 0.22]
    header_texts = [
        "Наименование оборудования",
        "Обнаруженные дефекты",
        "Для устранения дефектов необходимо произвести работы",
        "Примечание",
    ]
    row_header = [_p(t, cell_style) for t in header_texts]
    row_nums = [
        _p("1", num_style),
        _p("2", num_style),
        _p("3", num_style),
        _p("4", num_style),
    ]

    equipment = data.equipment_name.strip() if data.equipment_name else "—"
    defects_block = (data.title or "").strip() or "—"
    works = (data.description or "").strip() or "—"
    notes = (
        f"Плановое ТО: {data.planned_year or '—'}, "
        f"месяц: {data.month}. "
        f"Статус: {data.status_name or '—'}. "
        f"Ответственный: {data.responsible_name or '—'}."
    )

    row_data = [
        _p(equipment, cell_style),
        _p(defects_block, cell_style),
        _p(works, cell_style),
        _p(notes, cell_style),
    ]

    tbl = Table(
        [row_header, row_nums, row_data],
        colWidths=col_w,
        repeatRows=1,
    )
    tbl.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.8, colors.black),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e8e8e8")),
                ("ROWBACKGROUNDS", (0, 1), (-1, 1), [colors.white]),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.append(tbl)
    story.append(Spacer(1, 8 * mm))

    # Фотографии: сетка по 3 в ряд
    valid_paths = [p for p in data.photo_paths if p and os.path.isfile(p)]
    if valid_paths:
        story.append(_p("Фотоматериалы:", footer_style))
        story.append(Spacer(1, 3 * mm))
        cols = 3
        max_w = (inner_w - (cols - 1) * 4 * mm) / cols
        max_h = 52 * mm
        row: list = []
        for _i, pth in enumerate(valid_paths):
            try:
                img = _scaled_image(pth, max_w, max_h)
                img.hAlign = "CENTER"
                row.append(img)
            except Exception:
                row.append(
                    _p(f"(файл недоступен: {os.path.basename(pth)})", cell_style)
                )
            if len(row) == cols:
                t = Table([row], colWidths=[max_w] * cols)
                t.setStyle(
                    TableStyle(
                        [
                            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                            ("TOPPADDING", (0, 0), (-1, -1), 4),
                            ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                        ]
                    )
                )
                story.append(t)
                row = []
        if row:
            while len(row) < cols:
                row.append("")
            t = Table([row], colWidths=[max_w] * cols)
            t.setStyle(
                TableStyle(
                    [
                        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ]
                )
            )
            story.append(t)

    story.append(Spacer(1, 12 * mm))

    sig_left = (
        "Представитель ООО «ПЛК»<br/>"
        "Начальник сервисного участка<br/><br/>"
        f"Сформировал: {data.creator_name or '—'}"
    )
    sig_right = "Подпись: " + "_" * 42
    sig_table = Table(
        [
            [
                _p(sig_left, footer_style),
                _p(sig_right, footer_style),
            ]
        ],
        colWidths=[inner_w * 0.55, inner_w * 0.45],
    )
    sig_table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ]
        )
    )
    story.append(sig_table)

    doc.build(story)
