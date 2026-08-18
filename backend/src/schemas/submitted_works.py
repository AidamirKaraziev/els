"""Лента сданных работ глазами прораба.

Отдельная схема, а не `OrderGet` с `ActFactGet` вперемешку: прорабу в ленте
нужен не сам акт и не сама заявка, а ответ на вопрос «что и где сдали, кто
сдал и смотрел ли я это». Поэтому здесь короткая карточка объекта, дата сдачи
и отметка — и ни чек-листа, ни истории статусов.
"""

from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.maintenance import MaintenanceObject
from src.schemas.reports import WorkKind


class SubmittedWork(BaseModel):
    kind: WorkKind = Field(
        ...,
        title="Вид работы",
        description=(
            "`maintenance` — закрытое плановое ТО. Остальные виды приходят из "
            "заявок и делятся тем же правилом, что и в отчётах: авария, "
            "обращение заказчика, прочее."
        ),
    )
    work_id: int = Field(
        ...,
        title="ID работы",
        description="ID акта у ТО и ID заявки у остальных видов.",
    )
    object: Optional[MaintenanceObject] = Field(None, title="Объект")

    task_text: Optional[str] = Field(
        None,
        title="Что просили сделать",
        description="Только у заявок: у ТО задание — это чек-лист акта.",
    )
    performer: Optional[str] = Field(
        None,
        title="Кто сдал работу",
        description="Механик акта у ТО, исполнитель у заявки.",
    )
    closed_at: Optional[int] = Field(
        None,
        title="Когда работа сдана",
        description=(
            "Дата закрытия акта у ТО, дата выполнения у заявки. Лента "
            "упорядочена по ней, свежие сверху."
        ),
    )

    reviewed_at: Optional[int] = Field(
        None,
        title="Когда прораб отметил, что проверил",
        description="Пусто — работа ещё не просмотрена, она и в счётчике.",
    )
    reviewer: Optional[str] = Field(None, title="Кто отметил")


class UnreviewedCount(BaseModel):
    """Счётчик для карточки на главной."""

    count: int = Field(..., ge=0, title="Сколько сданных работ ещё не смотрели")
