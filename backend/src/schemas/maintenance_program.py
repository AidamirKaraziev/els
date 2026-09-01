"""Программа обслуживания модели оборудования: двенадцать позиций «месяц → ТО».

Программа правится **целиком**. Частичной правки нет по смыслу: позиции — это
цикл, и «поменять март, не глядя на остальное» означает получить график, в
котором ТО12 встречается дважды или не встречается вовсе. Поэтому на входе
всегда полный набор из двенадцати позиций, а проверка «1..12 без пропусков и
повторов» проверяется не здесь, а в ручке: pydantic отдал бы её через общий
обработчик как 400, а неполная программа — это не поломанный формат тела, а
неверные данные, и фронт ждёт по ней 422 со списком проблем.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

#: Длина цикла программы. Один год, одно ТО в месяц — решение заказчика от
#: 27 августа, `planned_to` с двенадцатью колонками месяцев его же и держит.
PROGRAM_LENGTH = 12


class MaintenanceProgramItemIn(BaseModel):
    """Одна позиция программы на входе."""

    position: int = Field(
        ...,
        title="Месяц программы, 1..12",
        description=(
            "1 — первый месяц цикла, а не обязательно январь. Границы "
            "проверяет ручка, а не схема: тогда все нарушения цикла приходят "
            "одним ответом 422, а не вперемешку с 400 от разбора тела."
        ),
    )
    type_act_id: int = Field(..., title="Вид ТО")


class MaintenanceProgramItemOut(MaintenanceProgramItemIn):
    """Позиция программы в ответе — с названием вида ТО."""

    type_act_name: Optional[str] = Field(None, title="Название вида ТО")


class MaintenanceProgramUpsert(BaseModel):
    """Тело `PUT`: программа целиком."""

    name: Optional[str] = Field(None, title="Название программы")
    items: List[MaintenanceProgramItemIn] = Field(
        ...,
        title="Двенадцать позиций",
        description=(
            "Ровно двенадцать штук, `position` — в точности числа 1..12, "
            "каждое по одному разу."
        ),
    )


class MaintenanceProgramOut(BaseModel):
    """Сохранённая программа."""

    id: int = Field(..., title="ID программы")
    factory_model_id: int = Field(..., title="Модель оборудования")
    name: Optional[str] = Field(None, title="Название программы")
    updated_at: Optional[datetime] = Field(None, title="Когда правили")
    items: List[MaintenanceProgramItemOut] = Field(
        ..., title="Двенадцать позиций по порядку"
    )


class MaintenanceProgramSuggestionItem(BaseModel):
    """Позиция предложения. Вид ТО может отсутствовать."""

    position: int = Field(..., title="Месяц программы, 1..12")
    type_act_id: Optional[int] = Field(
        None,
        title="Предлагаемый вид ТО",
        description="Пусто, если у модели нет ни одного подходящего шаблона.",
    )
    type_act_name: Optional[str] = Field(None, title="Название вида ТО")


class MaintenanceProgramSuggestion(BaseModel):
    """Предложение по умолчанию. В базу не пишется, пока человек не сохранил."""

    factory_model_id: int = Field(..., title="Модель оборудования")
    items: List[MaintenanceProgramSuggestionItem] = Field(
        ..., title="Двенадцать предложенных позиций"
    )
    available_type_act_ids: List[int] = Field(
        ...,
        title="Виды ТО, на которые у модели есть шаблон чек-листа",
        description="Из `acts_bases` по этой модели.",
    )
    missing_type_act_ids: List[int] = Field(
        ...,
        title="Виды ТО, которых не хватает",
        description=(
            "Виды, которые предложило бы правило, но шаблона на них у модели "
            "нет. Утвердить график по такой программе нельзя — сначала "
            "заводится шаблон."
        ),
    )
