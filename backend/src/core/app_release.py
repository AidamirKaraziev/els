"""Какая версия приложения лежит на сервере и как называется её файл.

Здесь нет ни HTTP, ни базы — только чтение манифеста с диска и проверка
имени файла. Кто имеет право скачать APK, решает сама ручка.

## Почему манифест, а не таблица

Запись ровно одна: «сейчас раздаётся вот эта сборка». Таблица ради одной
строки означала бы модель, миграцию и ручку администрирования — а кладёт файл
на сервер всё равно человек руками, вместе с выкатом. Пусть тем же движением
кладёт и манифест: тогда «что на диске» и «что обещает API» нельзя развести.

Рядом с APK лежит `static/app/release.json`:

    {
      "versionName": "1.0.0",
      "versionCode": 1,
      "file": "els-1.0.0.apk",
      "sha256": "9f3c…",
      "publishedAt": "2026-09-07",
      "notes": "Первая сборка для механиков"
    }

`sha256` печатает CI при сборке — по нему сверяется, что на сервер легло
именно то, что собралось, а не пересжатый по дороге файл.
"""

import json
from pathlib import Path
from typing import NamedTuple, Optional

from src.core.files import STATIC_ROOT

#: Куда человек кладёт APK при выкате. Отдельный подкаталог, а не корень
#: `static/`: там лежат загрузки пользователей, разобранные по сущностям, и
#: сборка приложения к ним не относится.
RELEASE_DIR = STATIC_ROOT / "app"

MANIFEST_NAME = "release.json"


class AppRelease(NamedTuple):
    """Сборка, которая сейчас раздаётся."""

    version_name: str
    version_code: int
    file_name: str
    size: int
    sha256: Optional[str]
    published_at: Optional[str]
    notes: Optional[str]

    @property
    def path(self) -> Path:
        return RELEASE_DIR / self.file_name

    @property
    def relative(self) -> str:
        """Путь внутри `static/` — в том виде, какой нужен `X-Accel-Redirect`."""
        return f"app/{self.file_name}"


def _is_plain_name(name: str) -> bool:
    """Имя файла, а не путь.

    Манифест кладёт на сервер человек, но проверять его всё равно надо:
    опечатка вида `../../.env` в поле `file` превратила бы ручку скачивания в
    чтение чего угодно с диска. Разрешаем ровно один сегмент имени.
    """
    return (
        bool(name) and "/" not in name and "\\" not in name and name not in (".", "..")
    )


def read_release() -> Optional[AppRelease]:
    """Что сейчас раздаётся — или None, если раздавать нечего.

    None означает «APK на сервер ещё не положили» и отвечает `404`, а не
    ошибкой: до первого выката это нормальное состояние, и падать пятисоткой
    из-за него нельзя.

    Битый манифест — тоже None. Разбирать «файла нет» и «в JSON опечатка»
    по разным ответам API незачем: и то и другое чинит человек на сервере
    одним и тем же движением, а наружу разница только помогла бы подбирать.
    """
    directory = RELEASE_DIR
    manifest = directory / MANIFEST_NAME

    try:
        raw = json.loads(manifest.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None

    if not isinstance(raw, dict):
        return None

    file_name = raw.get("file")
    version_name = raw.get("versionName")
    version_code = raw.get("versionCode")

    if not isinstance(file_name, str) or not _is_plain_name(file_name):
        return None
    if not isinstance(version_name, str) or not version_name:
        return None
    if not isinstance(version_code, int) or isinstance(version_code, bool):
        return None

    apk = directory / file_name
    try:
        size = apk.stat().st_size
    except OSError:
        # Манифест есть, файла нет: выкат оборвался на полпути. Раздавать
        # нечего, и ссылку выдавать не на что.
        return None

    return AppRelease(
        version_name=version_name,
        version_code=version_code,
        file_name=file_name,
        size=size,
        sha256=raw.get("sha256") if isinstance(raw.get("sha256"), str) else None,
        published_at=(
            raw.get("publishedAt") if isinstance(raw.get("publishedAt"), str) else None
        ),
        notes=raw.get("notes") if isinstance(raw.get("notes"), str) else None,
    )
