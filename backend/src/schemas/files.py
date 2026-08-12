from typing import Dict

from pydantic import BaseModel, Field


class FileLinkRequest(BaseModel):
    """Путь файла в том виде, в каком он лежит в ответах API.

    Именно путь, а не id записи: в ответе у объекта три разных файла, у заявки
    — фотографии, и просить их по id пришлось бы отдельной ручкой на каждый
    вид. Путь уже пришёл фронту в теле ответа, его и передаём обратно.
    """

    path: str = Field(
        ...,
        title="Путь к файлу",
        example="objects/12/act_pto/9f3c1b7e4a.pdf",
    )


class FileLinkGet(BaseModel):
    url: str = Field(..., title="Адрес с токеном, готовый к открытию")
    expires_in: int = Field(..., title="Сколько секунд ссылка живёт")


class ExportLinkRequest(BaseModel):
    """Какую выгрузку открыть и с какими параметрами.

    Ключ, а не путь: подписывать произвольный адрес нельзя — короткоживущая
    ссылка превратилась бы в токен доступа ко всему API.
    """

    export: str = Field(..., title="Ключ выгрузки", example="breakdowns")
    params: Dict[str, str] = Field(
        default_factory=dict,
        title="Параметры запроса",
        example={"year": "2026", "month": "5"},
    )
