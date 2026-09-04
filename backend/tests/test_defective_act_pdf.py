"""Шаблон дефектной ведомости: что напечатано на листе.

Проверяем story, а не готовый файл: после сборки текст лежит в подмножестве
шрифта и обратно не читается, так что «нет слова "Статус"» по байтам PDF не
проверить. Отдельным тестом убеждаемся, что из той же story получается
настоящий PDF.
"""

import pytest
from reportlab.platypus import Paragraph, Table

from src.services.defective_act_pdf import (
    DefectiveActPdfData,
    build_defective_act_pdf,
    build_defective_act_story,
)


def _texts(story) -> str:
    """Весь текст листа одной строкой, включая содержимое таблиц."""
    chunks = []

    def walk(node):
        if isinstance(node, Paragraph):
            chunks.append(node.text)
        elif isinstance(node, Table):
            for row in node._cellvalues:
                for cell in row:
                    walk(cell)
        elif isinstance(node, (list, tuple)):
            for item in node:
                walk(item)

    walk(story)
    return "\n".join(chunks)


@pytest.fixture
def filled() -> DefectiveActPdfData:
    return DefectiveActPdfData(
        act_number="17",
        act_date="04.09.2026",
        executor_name="ООО «Подъёмник»",
        executor_address="Пермь, ул. Ленина, 1",
        executor_phone="+7 342 000-00-00",
        executor_director="Иванов И. И.",
        customer_name="УК «Престиж»",
        customer_address="Пермь, ул. Мира, 5",
        customer_director="Петров П. П.",
        object_name="Лифт пассажирский",
        object_address="Пермь, ул. Мира, 5, подъезд 2",
        factory_number="F-1234",
        registration_number="R-5678",
        contract_title="Договор № 42 от 01.02.2026",
        planned_year="2026",
        month=5,
        title="износ троса",
        description="заменить тяговый канат",
        responsible_name="Сидоров С. С.",
    )


def test_header_carries_both_parties(filled):
    text = _texts(build_defective_act_story(filled))

    assert "ООО «Подъёмник»" in text
    assert "Пермь, ул. Ленина, 1" in text
    assert "УК «Престиж»" in text
    assert "Петров П. П." in text


def test_title_carries_number_and_date(filled):
    text = _texts(build_defective_act_story(filled))

    assert "ДЕФЕКТНАЯ ВЕДОМОСТЬ № 17 от 04.09.2026" in text


def test_object_line_carries_numbers_and_contract(filled):
    text = _texts(build_defective_act_story(filled))

    assert "Лифт пассажирский" in text
    assert "F-1234" in text
    assert "R-5678" in text
    assert "Договор № 42 от 01.02.2026" in text


def test_both_sides_have_a_place_to_sign(filled):
    text = _texts(build_defective_act_story(filled))

    assert "От исполнителя:" in text
    assert "От заказчика:" in text
    assert text.count("Подпись:") == 2
    assert text.count("ФИО:") == 2


def test_service_lines_are_not_printed(filled):
    """Лист уходит заказчику: ни статуса записи, ни «кто сформировал»."""
    text = _texts(build_defective_act_story(filled))

    assert "Статус" not in text
    assert "Сформировал" not in text


def test_empty_fields_become_dashes():
    """Ни организации, ни компании, ни договора — лист всё равно собирается."""
    text = _texts(
        build_defective_act_story(
            DefectiveActPdfData(act_number="1", act_date="04.09.2026")
        )
    )

    assert "—" in text
    # Планового ТО нет — и строки про него тоже.
    assert "Плановое ТО" not in text


def test_month_is_printed_only_with_the_year(filled):
    filled.month = None
    text = _texts(build_defective_act_story(filled))

    assert "Плановое ТО: 2026." in text
    assert "месяц" not in text


def test_a_real_pdf_is_written_without_photos(filled, tmp_path):
    out = tmp_path / "act.pdf"

    build_defective_act_pdf(str(out), filled)

    assert out.stat().st_size > 0
    assert out.read_bytes().startswith(b"%PDF")
