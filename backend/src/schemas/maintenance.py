"""Плановое ТО глазами механика.

Отдельная схема, а не `ActFactGet`: механику в телефоне нужен не сам акт, а
ответ на вопрос «что мне сделать и сколько осталось». Поэтому здесь плановый
месяц из графика, короткая карточка объекта и счётчик пунктов, а не сырая
строка `step_list_fact` на сотни килобайт.
"""

from typing import Optional

from pydantic import BaseModel, Field


class MaintenanceObject(BaseModel):
    """Объект в списке ТО. Ровно то, что нужно, чтобы доехать."""

    id: int = Field(..., title="ID объекта")
    name: Optional[str] = Field(None, title="Название")
    address: Optional[str] = Field(None, title="Адрес")


class MyMaintenanceItem(BaseModel):
    act_id: int = Field(..., title="ID фактического акта")
    object: Optional[MaintenanceObject] = Field(None, title="Объект")

    year: int = Field(..., title="Год графика")
    month: int = Field(..., ge=1, le=12, title="Плановый месяц")
    title: Optional[str] = Field(
        None,
        title="Название ТО из графика",
        description="Например «ТО-1». Берётся из чек-листа, может отсутствовать.",
    )

    steps_total: int = Field(..., ge=0, title="Всего пунктов регламента")
    steps_done: int = Field(..., ge=0, title="Из них отмечено выполненными")

    started_at: Optional[int] = Field(None, title="Когда механик начал")
    finished_at: Optional[int] = Field(
        None,
        title="Когда акт закрыт",
        description="Пусто — ТО ещё не сделано. Именно по этой дате считается выполнение графика.",
    )
    status_id: Optional[int] = Field(None, title="Статус акта")

    updated_at: Optional[int] = Field(
        None,
        title="Метка последней правки",
        description="Клиент запоминает наибольшую и присылает её в `changed_since`.",
    )
