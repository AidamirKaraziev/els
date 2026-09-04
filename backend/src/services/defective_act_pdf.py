"""
Генерация PDF «Дефектная ведомость» для дефектного акта (ReportLab).
Шрифт с кириллицей: static/fonts/NotoSans-Regular.ttf (или системные пути).

Шаблон один на оба вида акта — внутренний и клиентский. Служебного в нём нет:
лист уходит заказчику, и ни статус записи, ни «кто сформировал» на нём не
место. Реквизиты обеих сторон берутся из объекта, подписи — пустые места под
живую ручку.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
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

#: Чем заполняется пустое поле. Прочерк, а не пустота: в бумажном акте пустое
#: место читается как «не заполнили», а прочерк — как «нечего писать».
_DASH = "—"


@dataclass
class DefectiveActPdfData:
    """Данные для заполнения шаблона (без ORM)."""

    # Шапка акта
    act_number: str
    act_date: str

    # Исполнитель — организация, обслуживающая объект
    executor_name: str = ""
    executor_address: str = ""
    executor_phone: str = ""
    executor_director: str = ""

    # Заказчик — компания, которой объект принадлежит
    customer_name: str = ""
    customer_address: str = ""
    customer_director: str = ""

    # Объект
    #: Наименование лифта. Оно же печатается в колонке «Наименование
    #: оборудования»: объект акта и есть оборудование.
    object_name: str = ""
    object_address: str = ""
    factory_number: str = ""
    registration_number: str = ""
    contract_title: str = ""

    # Тело ведомости
    planned_year: str = ""
    month: int | None = None
    title: str = ""
    description: str = ""
    responsible_name: str = ""
    photo_paths: list[str] = field(default_factory=list)


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


def _rich(markup: str, style: ParagraphStyle) -> Paragraph:
    """Абзац с разметкой: `<b>` и `<br/>` внутри должны сработать.

    Отдельно от `_p`, потому что тот экранирует всё подряд — и раньше подпись
    печаталась вместе с литеральными `<br/>` вместо переносов. Текст, который
    подставляется в такую разметку, экранирует вызывающий.
    """
    return Paragraph(markup, style)


def _val(text: str | None) -> str:
    """Значение поля или прочерк."""
    return (text or "").strip() or _DASH


def _scaled_image(path: str, max_w: float, max_h: float) -> Image:
    from reportlab.lib.utils import ImageReader

    ir = ImageReader(path)
    iw, ih = ir.getSize()
    if iw <= 0 or ih <= 0:
        return Image(path, width=max_w * 0.5, height=max_h * 0.5)
    ratio = min(max_w / float(iw), max_h / float(ih))
    return Image(path, width=iw * ratio, height=ih * ratio)


def _party_block(
    caption: str, name: str, address: str, phone: str, director: str
) -> str:
    """Реквизиты одной стороны — одним абзацем с переносами."""
    lines = [f"<b>{escape(caption)}</b>", escape(_val(name))]
    if (address or "").strip():
        lines.append(escape(address.strip()))
    if (phone or "").strip():
        lines.append("тел. " + escape(phone.strip()))
    if (director or "").strip():
        lines.append("рук. " + escape(director.strip()))
    return "<br/>".join(lines)


def _signature_block(caption: str) -> str:
    """Место под живую подпись: должность, ФИО, линейка."""
    line = "_" * 26
    return (
        f"<b>{escape(caption)}</b><br/><br/>"
        f"Должность: {line}<br/><br/>"
        f"ФИО: {line}<br/><br/>"
        f"Подпись: {line}"
    )


#: Поля страницы. Вынесены, потому что по ним считается ширина содержимого,
#: а её нужно знать и при сборке story отдельно от документа.
_MARGIN_X = 18 * mm
_MARGIN_Y = 14 * mm


def _inner_width() -> float:
    w, _ = landscape(A4)
    return w - 2 * _MARGIN_X


def build_defective_act_story(
    data: DefectiveActPdfData, inner_w: float | None = None
) -> list:
    """
    Содержимое листа: шапка с реквизитами сторон, заголовок с номером и датой,
    строка объекта, таблица 4×(шапка+нумерация+данные), фото, подписи сторон.

    Отделено от записи файла, чтобы проверять, что напечатано, а не только то,
    что файл получился: после сборки в PDF текст лежит в подмножестве шрифта и
    обратно не читается.
    """
    font = _ensure_font()
    if inner_w is None:
        inner_w = _inner_width()

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
    party_style = ParagraphStyle(
        name="ActParty",
        parent=styles["Normal"],
        fontName=font,
        fontSize=8,
        leading=11,
        alignment=TA_LEFT,
    )

    story = []

    # Шапка: реквизиты сторон в две колонки, без рамки.
    parties = Table(
        [
            [
                _rich(
                    _party_block(
                        "Исполнитель:",
                        data.executor_name,
                        data.executor_address,
                        data.executor_phone,
                        data.executor_director,
                    ),
                    party_style,
                ),
                _rich(
                    _party_block(
                        "Заказчик:",
                        data.customer_name,
                        data.customer_address,
                        "",
                        data.customer_director,
                    ),
                    party_style,
                ),
            ]
        ],
        colWidths=[inner_w * 0.5, inner_w * 0.5],
    )
    parties.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    story.append(parties)

    story.append(
        _p(
            f"ДЕФЕКТНАЯ ВЕДОМОСТЬ № {_val(data.act_number)} от {_val(data.act_date)}",
            title_style,
        )
    )

    object_line = (
        f"Объект: {_val(data.object_name)}. "
        f"Адрес: {_val(data.object_address)}. "
        f"Заводской №: {_val(data.factory_number)}. "
        f"Регистрационный №: {_val(data.registration_number)}. "
        f"Договор: {_val(data.contract_title)}."
    )
    story.append(_p(object_line, sub_style))
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

    equipment = _val(data.object_name)
    defects_block = _val(data.title)
    works = _val(data.description)

    # Плановое ТО и месяц есть не у всякого акта: три точки входа из четырёх
    # заводят дефект вне планового ТО. Пишем только то, что известно.
    notes_parts = []
    if (data.planned_year or "").strip():
        planned = f"Плановое ТО: {data.planned_year.strip()}"
        if data.month:
            planned += f", месяц: {data.month}"
        notes_parts.append(planned + ".")
    notes_parts.append(f"Ответственный: {_val(data.responsible_name)}.")
    notes = " ".join(notes_parts)

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

    # Подписи: обе стороны, пустые места под живую ручку.
    sig_table = Table(
        [
            [
                _rich(_signature_block("От исполнителя:"), footer_style),
                _rich(_signature_block("От заказчика:"), footer_style),
            ]
        ],
        colWidths=[inner_w * 0.5, inner_w * 0.5],
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

    return story


def build_defective_act_pdf(output_path: str, data: DefectiveActPdfData) -> None:
    """Собирает PDF «Дефектная ведомость» по данным акта."""
    doc = SimpleDocTemplate(
        output_path,
        pagesize=landscape(A4),
        leftMargin=_MARGIN_X,
        rightMargin=_MARGIN_X,
        topMargin=_MARGIN_Y,
        bottomMargin=_MARGIN_Y,
    )
    doc.build(build_defective_act_story(data, _inner_width()))
