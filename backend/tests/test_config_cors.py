"""BACKEND_CORS_ORIGINS принимается в обеих формах.

Регрессия: форма через запятую была написана в README и в комментарии
`main.py`, но не работала никогда. pydantic 1.x разбирает значения полей
сложных типов как JSON ещё до валидаторов, поэтому `assemble_cors_origins`
с `pre=True` до переменной окружения не доходил. Прод падал на старте с
`SettingsError: error parsing env var "BACKEND_CORS_ORIGINS"`.
"""

import pytest

from src.config import Settings


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        # Форма из README и docs/server-deploy.md — та, на которой лёг прод.
        (
            "https://els23.ru,https://www.els23.ru",
            ["https://els23.ru", "https://www.els23.ru"],
        ),
        # Пробелы вокруг запятой человек поставит почти наверняка.
        ("https://a.ru, https://b.ru", ["https://a.ru", "https://b.ru"]),
        # Один домен без запятых.
        ("https://els23.ru", ["https://els23.ru"]),
        # JSON — в этой форме написаны шаблоны в backend/envs/.
        ('["https://els23.ru","https://www.els23.ru"]',
         ["https://els23.ru", "https://www.els23.ru"]),
        ("[]", []),
        # Пустое значение: API остаётся открытым для всех, но не падает.
        ("", []),
    ],
)
def test_cors_origins_accepts_both_forms(monkeypatch, raw, expected):
    monkeypatch.setenv("BACKEND_CORS_ORIGINS", raw)

    assert Settings().BACKEND_CORS_ORIGINS == expected


def test_other_settings_are_not_broken_by_the_override(monkeypatch):
    """parse_env_var вызывается только для сложных типов, строки не трогает."""
    monkeypatch.setenv("DB_USER", "postgres")
    monkeypatch.setenv("PROJECT_NAME", "ELS")

    settings = Settings()

    assert settings.DB_USER == "postgres"
    assert settings.PROJECT_NAME == "ELS"
