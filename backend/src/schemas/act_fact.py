from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from src.schemas.status import StatusGet


class ChecklistStepGet(BaseModel):
    """Пункт регламента в фактическом акте."""

    id: int = Field(
        ...,
        title="Номер шага внутри акта",
        description=(
            "На него ссылается фотография шага. Номер стабилен: переставлять "
            "и удалять шаги после начала работ нельзя, новый шаг получает "
            "следующий свободный номер."
        ),
    )
    title: str = Field(..., title="Что нужно сделать")
    done: bool = Field(..., title="Отмечен выполненным")
    comment: Optional[str] = Field(None, title="Комментарий механика")


class ChecklistGet(BaseModel):
    """Чек-лист акта в канонической форме.

    Разобранный `step_list_fact`. Пустой `steps` означает «чек-лист не
    заполнен», а не «работ не было».
    """

    title: Optional[str] = Field(None, title="Название ТО из графика, например «ТО-1»")
    steps: List[ChecklistStepGet] = Field([], title="Пункты регламента")


class ChecklistStepSet(BaseModel):
    id: Optional[int] = Field(
        None,
        title="Номер шага",
        description=(
            "Присылать тот, что пришёл в ответе. Без номера шаг считается "
            "новым и получает следующий свободный — фотографии старого к нему "
            "не перейдут."
        ),
    )
    title: str = Field(..., title="Что нужно сделать")
    done: bool = Field(False, title="Отмечен выполненным")
    comment: Optional[str] = Field(None, title="Комментарий механика")


class ChecklistSet(BaseModel):
    title: Optional[str] = Field(None, title="Название ТО из графика")
    steps: List[ChecklistStepSet] = Field([], title="Пункты регламента")


class ActFactBase(BaseModel):
    id: int
    object_id: Optional[int]
    act_base_id: Optional[int]
    step_list_fact: Optional[str]

    date_create: Optional[int]
    date_start: Optional[int]
    date_finish: Optional[int]

    foreman_id: Optional[int]
    main_mechanic_id: Optional[int]

    file: Optional[str]
    status_id: Optional[int]


class ActFactCreate(BaseModel):
    object_id: int
    act_base_id: int
    foreman_id: int
    main_mechanic_id: int


class ActFactUpdate(BaseModel):
    step_list_fact: Optional[str] = Field(
        None,
        deprecated=True,
        title="Устарело: чек-лист строкой в форме старых экранов",
        description=(
            "Принимается по-прежнему — экран графика у прораба пишет именно "
            "сюда, — но в базе хранится приведённым к канонической форме. "
            "Новым клиентам слать `checklist`: строка не даёт сослаться на "
            "конкретный пункт, а фотография шага ссылается на его номер."
        ),
    )
    checklist: Optional[ChecklistSet] = Field(
        None,
        title="Чек-лист целиком",
        description=(
            "Присылается целиком, а не по одному пункту: отметка шага и "
            "правка списка — одно и то же действие. Пункт со своим `id` "
            "считается тем же самым, без `id` — новым."
        ),
    )
    started_at: Optional[int]
    finished_at: Optional[int]
    foreman_id: Optional[int]
    main_mechanic_id: Optional[int]
    status_id: Optional[int]


class ActFactGet(BaseModel):
    id: int
    object_id: Optional[int]
    act_base_id: Optional[int]
    step_list_fact: Optional[str] = Field(
        None,
        deprecated=True,
        title="Устарело: чек-лист строкой в форме старых экранов",
        description=(
            '`{"numberTo": ..., "stepListTO": ...}` строкой. Хранится '
            "акт в канонической форме, а это поле — проекция для экрана "
            "графика, который работает в проде. Новым клиентам — `checklist`."
        ),
    )
    checklist: Optional[ChecklistGet] = Field(None, title="Чек-лист акта")

    created_at: Optional[datetime]
    started_at: Optional[datetime]
    finished_at: Optional[datetime]

    foreman_id: Optional[int]
    main_mechanic_id: Optional[int]

    file: Optional[str]
    status_id: Optional[StatusGet]
