"""Годовой график объекта, разложенный по программе обслуживания модели.

Предпросмотр — это ответ на вопрос «что ляжет в двенадцать месяцев года,
если расставить график по программе», заданный **до** того, как в базе
появится хоть один акт. Поэтому здесь нет ни статусов выполнения, ни дат
закрытия: это не лента графиков (`schemas/schedules.py`), а заготовка,
которую человек ещё утверждает.

Позиция программы (`position`) и месяц календаря (`month`) — разные вещи.
Программа описывает цикл: первая позиция не обязана быть январём, с какого
месяца цикл начинается на объекте, задаёт якорь.
"""

from typing import List, Optional

from pydantic import BaseModel, Field


class SchedulePreviewCell(BaseModel):
    """Один месяц заготовки графика."""

    month: int = Field(..., ge=1, le=12, title="Месяц календаря, 1..12")
    position: int = Field(
        ...,
        ge=1,
        le=12,
        title="Позиция программы, 1..12",
        description=(
            "Месяц **цикла**, а не календаря. Считается от якоря: на "
            "`anchor_month` приходится первая позиция."
        ),
    )
    type_act_id: int = Field(..., title="Вид ТО из программы")
    type_act_name: Optional[str] = Field(None, title="Название вида ТО")
    occupied: bool = Field(
        ...,
        title="Месяц года уже занят",
        description=(
            "В графике объекта за этот год на месяц уже заведён акт. "
            "Создание графика такой месяц не трогает."
        ),
    )
    template_missing: bool = Field(
        ...,
        title="Нет шаблона чек-листа",
        description=(
            "У модели нет `acts_bases` на этот вид ТО: по нему нечего "
            "показать механику, и создать акт не выйдет."
        ),
    )


class SchedulePreview(BaseModel):
    """Двенадцать месяцев года по программе. В базу не пишется."""

    object_id: int = Field(..., title="ID объекта")
    year: int = Field(..., title="Год графика")
    anchor_month: int = Field(
        ...,
        ge=1,
        le=12,
        title="Месяц, на который приходится первая позиция программы",
        description=(
            "Тот, что применён: переданный параметром или подобранный по "
            "графику прошлого года."
        ),
    )
    factory_model_id: int = Field(..., title="Модель оборудования")
    program_id: int = Field(..., title="Программа обслуживания модели")
    cells: List[SchedulePreviewCell] = Field(
        ...,
        title="Двенадцать клеток, январь..декабрь",
        description="Приходит полной всегда, по одной клетке на месяц года.",
    )


class ScheduleGenerate(BaseModel):
    """Запрос на создание годового графика по программе модели."""

    object_id: int = Field(..., title="ID объекта")
    year: int = Field(..., ge=2000, le=2100, title="Год графика")
    anchor_month: Optional[int] = Field(
        None,
        ge=1,
        le=12,
        title="Месяц, с которого начинается цикл программы",
        description=(
            "Без параметра берётся из графика за прошлый год — тем же "
            "подбором, что и в предпросмотре. Переданный параметр прошлый "
            "год не смотрит вовсе."
        ),
    )


class ScheduleGeneratedCell(BaseModel):
    """Месяц, в котором график завёл акт."""

    month: int = Field(..., ge=1, le=12, title="Месяц календаря, 1..12")
    position: int = Field(..., ge=1, le=12, title="Позиция программы, 1..12")
    type_act_id: int = Field(..., title="Вид ТО из программы")
    type_act_name: Optional[str] = Field(None, title="Название вида ТО")
    act_fact_id: int = Field(..., title="Созданный акт")


class ScheduleGenerateResult(BaseModel):
    """Что легло в базу после создания графика."""

    object_id: int = Field(..., title="ID объекта")
    year: int = Field(..., title="Год графика")
    anchor_month: int = Field(
        ...,
        ge=1,
        le=12,
        title="Месяц, на который пришлась первая позиция программы",
    )
    factory_model_id: int = Field(..., title="Модель оборудования")
    program_id: int = Field(..., title="Программа обслуживания модели")
    planned_to_id: int = Field(
        ...,
        title="Годовой график объекта",
        description="Существовавший за этот год либо заведённый этим вызовом.",
    )
    created: List[ScheduleGeneratedCell] = Field(
        ...,
        title="Месяцы, в которых акт создан",
        description="Пустой список — все месяцы года были заняты.",
    )
    skipped: List[int] = Field(
        ...,
        title="Месяцы, которые не тронули",
        description=(
            "Месяц уже занят актом: график его не перезаписывает. Повторный "
            "вызов возвращает здесь все двенадцать."
        ),
    )
