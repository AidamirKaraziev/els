"""Разбор чек-листа акта: три формы, накопившиеся в одной колонке.

Проверки быстрые и без базы — это чистая функция, а форм у неё столько, что
держать их только в интеграционных тестах отчёта дорого и непонятно.
"""

import base64
import json

import pytest

from src.services.checklist import (
    dump_checklist,
    dump_legacy,
    extract_step_photos,
    parse_checklist,
    to_canonical,
)

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


class TestStepIds:
    """Номер шага — то, на что ссылается фотография, и он обязан быть стойким."""

    def test_steps_are_numbered_from_one_by_position(self):
        result = parse_checklist(_front(FRONT_STEPS))

        assert [step.id for step in result.steps] == [1, 2]

    def test_own_number_is_kept(self):
        raw = _front([{"id": 7, "text": "Проверить тормоз", "bool": True}])

        assert parse_checklist(raw).steps[0].id == 7

    def test_free_numbers_go_around_the_taken_one(self):
        """Шагу без номера нельзя выдать чужой — фото уехало бы к соседу."""
        raw = _front(
            [
                {"text": "Первый", "bool": False},
                {"id": 1, "text": "Со своим номером", "bool": False},
                {"text": "Третий", "bool": False},
            ]
        )

        assert [step.id for step in parse_checklist(raw).steps] == [2, 1, 3]

    def test_repeated_number_is_given_out_only_once(self):
        raw = _front(
            [
                {"id": 3, "text": "Первый", "bool": False},
                {"id": 3, "text": "Второй", "bool": False},
            ]
        )

        assert [step.id for step in parse_checklist(raw).steps] == [3, 1]

    @pytest.mark.parametrize("value", [0, -4, "нет", None, True, 1.5])
    def test_unusable_number_is_replaced_by_position(self, value):
        raw = _front([{"id": value, "text": "Шаг", "bool": False}])

        assert parse_checklist(raw).steps[0].id == 1


class TestCanonicalShape:
    """Форма, к которой всё сводит миграция, и единственная, которую пишем."""

    def test_canonical_is_read_back(self):
        raw = dump_checklist(parse_checklist(_front(FRONT_STEPS)))

        result = parse_checklist(raw)

        assert result.title == "ТО-1"
        assert [step.title for step in result.steps] == [
            "Выключить вводное устройство",
            "Осмотр станции управления",
        ]
        assert [step.done for step in result.steps] == [True, False]
        assert [step.id for step in result.steps] == [1, 2]

    def test_dump_is_valid_json_in_readable_russian(self):
        raw = dump_checklist(parse_checklist(_front(FRONT_STEPS)))

        assert "Выключить" in raw  # ensure_ascii=False, а не вы
        assert json.loads(raw)["steps"][0]["id"] == 1

    def test_comment_survives_the_round_trip(self):
        steps = [{"text": "Проверить тормоз", "bool": False, "comment": "нет колодок"}]

        result = parse_checklist(to_canonical(_front(steps)))

        assert result.steps[0].comment == "нет колодок"

    def test_second_conversion_changes_nothing(self):
        once = to_canonical(_front(FRONT_STEPS))

        assert to_canonical(once) == once

    def test_nothing_stays_nothing(self):
        assert to_canonical(None) is None

    def test_garbage_becomes_an_empty_checklist_and_not_a_crash(self):
        assert json.loads(to_canonical("совсем не список")) == {
            "title": None,
            "steps": [],
        }


class TestLegacyProjection:
    """Экран графика у прораба в проде читает форму фронтов. Её и отдаём."""

    def test_shape_is_the_one_the_web_reads(self):
        legacy = json.loads(dump_legacy(parse_checklist(_front(FRONT_STEPS))))

        assert legacy["numberTo"] == "ТО-1"
        steps = json.loads(legacy["stepListTO"])
        assert [step["text"] for step in steps] == [
            "Выключить вводное устройство",
            "Осмотр станции управления",
        ]
        assert [step["bool"] for step in steps] == [True, False]

    def test_step_number_goes_out_too_so_that_photos_survive_the_old_screen(self):
        """Старый экран пересохраняет пункт целиком — номер вернётся с ним."""
        legacy = json.loads(dump_legacy(parse_checklist(_front(FRONT_STEPS))))

        assert [step["id"] for step in json.loads(legacy["stepListTO"])] == [1, 2]

    def test_round_trip_through_the_old_screen_keeps_numbers(self):
        canonical = to_canonical(_front(FRONT_STEPS))
        # Ровно то, что делает экран графика: прочитал, ничего не понял про
        # номера, сохранил обратно.
        back = dump_legacy(parse_checklist(canonical))

        assert [step.id for step in parse_checklist(back).steps] == [1, 2]

    def test_missing_title_does_not_become_the_word_null(self):
        legacy = json.loads(dump_legacy(parse_checklist('[{"text": "Шаг"}]')))

        assert legacy["numberTo"] == ""


class TestEmbeddedPhotos:
    """Мобильное приложение клало снимок байтами прямо в шаг чек-листа."""

    PNG = b"\x89PNG\r\n\x1a\n" + b"\x00\x10"
    JPEG = b"\xff\xd8\xff\xe0" + b"\x00\x10"

    def test_bytes_of_a_step_are_found_with_its_number(self):
        raw = _front(
            [
                {"text": "Первый", "bool": True},
                {"text": "Со снимком", "bool": True, "photo": list(self.PNG)},
            ]
        )

        photos, unreadable = extract_step_photos(raw)

        assert photos == [(2, self.PNG, ".png")]
        assert unreadable is False

    def test_jpeg_is_recognised_too(self):
        raw = _front([{"text": "Шаг", "bool": True, "photo": list(self.JPEG)}])

        photos, _ = extract_step_photos(raw)

        assert photos[0][2] == ".jpg"

    def test_base64_string_is_read(self):
        raw = _front(
            [
                {
                    "text": "Шаг",
                    "bool": True,
                    "photo": base64.b64encode(self.PNG).decode(),
                }
            ]
        )

        photos, unreadable = extract_step_photos(raw)

        assert photos == [(1, self.PNG, ".png")]
        assert unreadable is False

    def test_unrecognisable_content_is_reported_and_not_guessed(self):
        """Миграция по этому признаку оставляет акт в покое, а не теряет фото."""
        raw = _front([{"text": "Шаг", "bool": True, "photo": [1, 2, 3]}])

        photos, unreadable = extract_step_photos(raw)

        assert photos == []
        assert unreadable is True

    def test_checklist_without_photos_reports_nothing(self):
        photos, unreadable = extract_step_photos(_front(FRONT_STEPS))

        assert photos == []
        assert unreadable is False

    def test_numbers_match_the_ones_the_checklist_gets(self):
        """Разбор и выемка снимков обязаны нумеровать шаги одинаково."""
        raw = _front(
            [
                {"id": 5, "text": "Со своим номером", "bool": True},
                {"text": "Со снимком", "bool": True, "photo": list(self.PNG)},
            ]
        )

        photos, _ = extract_step_photos(raw)
        steps = parse_checklist(raw).steps

        assert photos[0][0] == steps[1].id
