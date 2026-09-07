from typing import Optional

from pydantic import BaseModel, Field


class AppReleaseGet(BaseModel):
    """Сборка приложения, которая сейчас раздаётся механикам."""

    version_name: str = Field(..., title="Версия для человека", example="1.0.0")
    version_code: int = Field(
        ...,
        title="Номер сборки",
        description=(
            "Android ставит обновление, только если этот номер вырос. "
            "По нему же приложение понимает, что на сервере лежит свежее."
        ),
        example=1,
    )
    size: int = Field(..., title="Размер файла в байтах", example=41234567)
    sha256: Optional[str] = Field(
        None,
        title="Контрольная сумма",
        description="Печатается в логе сборки — по ней сверяют, что легло на сервер.",
    )
    published_at: Optional[str] = Field(
        None, title="Когда выложили", example="2026-09-07"
    )
    notes: Optional[str] = Field(None, title="Что нового")
