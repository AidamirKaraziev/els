"""Разбор чек-листа акта: три формы, накопившиеся в одной колонке.

Проверки быстрые и без базы — это чистая функция, а форм у неё столько, что
держать их только в интеграционных тестах отчёта дорого и непонятно.
"""

import json

import pytest

from src.services.checklist import parse_checklist

FRONT_STEPS = [
    {"text": "Выключить вводное устройство", "bool": True},
    {"text": "Осмотр станции управления", "bool": False},
]


def _front(steps, number="ТО-1"):
    """Форма, которую пишут оба фронта: список шагов строкой внутри словаря."""
    return json.dumps(
        {"numberTo": number, "stepListTO": json.dumps(steps, ensure_ascii=False)},
        ensure_ascii=False,
    )


class TestFrontShape:
    def test_steps_are_found_inside_the_nested_string(self):
        result = parse_checklist(_front(FRONT_STEPS))

        assert [step.title for step in result.steps] == [
            "Выключить вводное устройство",
            "Осмотр станции управления",
        ]
        assert result.total == 2
        assert result.done == 1

    def test_title_of_the_maintenance_is_kept(self):
        assert parse_checklist(_front(FRONT_STEPS)).title == "ТО-1"

    def test_comment_and_photo_of_a_step_survive(self):
        steps = [{"text": "Проверить тормоз", "bool": False, "comment": "нет колодок"}]
        step = parse_checklist(_front(steps)).steps[0]

        assert step.comment == "нет колодок"
        assert step.has_photo is False

    def test_photo_marks_the_step(self):
        steps = [{"text": "Проверить тормоз", "bool": False, "photo": [1, 2, 3]}]

        assert parse_checklist(_front(steps)).steps[0].has_photo is True

    def test_python_repr_of_the_same_shape(self):
        """Строка попадала в базу через `str(...)` — с одинарными кавычками."""
        raw = str({"numberTo": "ТО-2", "stepListTO": str(FRONT_STEPS)})

        result = parse_checklist(raw)

        assert result.title == "ТО-2"
        assert result.total == 2


class TestTemplateShape:
    def test_steps_with_substeps_are_flattened(self):
        raw = json.dumps(
            [
                {
                    "step_name": "Осмотр канатов",
                    "step_status": "true",
                    "substeps": [
                        {"substep_name": "Проверить натяжение", "substep_status": "0"}
                    ],
                }
            ]
        )

        result = parse_checklist(raw)

        assert [step.title for step in result.steps] == [
            "Осмотр канатов",
            "Проверить натяжение",
        ]
        assert [step.done for step in result.steps] == [True, False]


class TestGarbage:
    @pytest.mark.parametrize(
        "raw", [None, "", "   ", "совсем не список", "{битый json", "42"]
    )
    def test_unreadable_gives_empty_checklist(self, raw):
        """Пустой список — это «не заполнено», а не падение ручки."""
        result = parse_checklist(raw)

        assert result.steps == []
        assert result.total == 0
        assert result.done == 0

    def test_step_without_text_is_skipped(self):
        raw = _front([{"bool": True}, {"text": "Настоящий шаг", "bool": True}])

        assert parse_checklist(raw).total == 1
