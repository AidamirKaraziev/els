"""Схемы раздела «Отчёты».

Отчёт отвечает на один вопрос: что делали на объектах за период. В отличие от
виджетов главной, здесь период задаётся произвольными датами, а не месяцем, и
в одну картину сведены все виды работ сразу.

Почему видов работ пять, а не два
---------------------------------
Руководитель отправляет отчёт клиенту, и «сделали ТО» — это половина правды:
за тот же месяц могли быть аварийные выезды, заявка от самого заказчика и
дефектная ведомость по итогам осмотра. Поэтому `WorkKind` перечисляет все
виды, а не делит работы на плановые и внеплановые.

Список закрытый и заведомо неполный: замены оборудования и ремонты по
допсоглашению в системе сегодня не заводятся вовсе. Когда они появятся, к
`WorkKind` добавится значение, а `MonthCell` получит ещё один счётчик —
формат ответа при этом не сломается, потому что фронт читает счётчики по
имени, а не по позиции.

Почему у ТО отдельный статус, а у остальных работ — счётчик
-----------------------------------------------------------
ТО за месяц либо положено, либо нет, и оно ровно одно: план в базе — это
заполненная ячейка месяца. Поэтому у ТО состояние, а не количество. Аварий и
заявок за месяц может быть сколько угодно, и осмысленно только их число.
"""

import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class WorkKind(str, Enum):
    """Вид работы на объекте.

    Значения приходят строками, а не числами: число пришлось бы держать
    синхронным между базой, бэком и фронтом, а строку видно в ответе глазами.
    """

    MAINTENANCE = "maintenance"
    BREAKDOWN = "breakdown"
    CLIENT_REQUEST = "client_request"
    REQUEST = "request"
    DEFECT = "defect"


class MaintenanceStatus(str, Enum):
    """Состояние планового ТО за конкретный месяц.

    `PENDING` и `OVERDUE` различаются только тем, кончился ли плановый месяц:
    незакрытое ТО за текущий месяц — это работа впереди, а за прошедший —
    долг. Смешивать их нельзя, иначе первого числа каждого месяца отчёт
    показывал бы всплеск просрочки на ровном месте.
    """

    NONE = "none"
    DONE = "done"
    LATE = "late"
    PENDING = "pending"
    OVERDUE = "overdue"


class ReportMonth(BaseModel):
    """Год и месяц — граница периода в терминах плана ТО."""

    year: int = Field(..., title="Год")
    month: int = Field(..., ge=1, le=12, title="Месяц")


class ReportPeriod(BaseModel):
    """Период отчёта: как его попросили и как он считался на самом деле.

    Даты и месяцы расходятся намеренно. Заявки лежат в базе с точным
    временем, и по ним период соблюдается день в день. План ТО хранится
    помесячно — у ячейки графика нет дня, — поэтому ТО попадает в отчёт, если
    его плановый месяц пересекается с периодом хотя бы одним днём.

    Из-за этого период «15.03 — 20.06» захватывает ТО за весь март и весь
    июнь. Это не ошибка округления, а единственный способ не потерять ТО,
    которое действительно относится к периоду. Оба набора границ отдаются
    наружу, чтобы экран мог сказать об этом человеку, а не оставлять его
    гадать, откуда взялось лишнее ТО.
    """

    date_from: datetime.date = Field(..., title="Начало периода, включительно")
    date_to: datetime.date = Field(..., title="Конец периода, включительно")
    month_from: ReportMonth = Field(
        ..., title="Первый месяц плана ТО, попавший в отчёт"
    )
    month_to: ReportMonth = Field(..., title="Последний месяц плана ТО")
    months_count: int = Field(
        ...,
        ge=1,
        title="Сколько месяцев в матрице",
        description="Длина months у объекта.",
    )


class WorkCounts(BaseModel):
    """Сколько работ каждого вида — общий кубик для месяца, объекта и свода.

    Плановое ТО сюда не входит: у него состояние, а не количество.
    """

    breakdowns: int = Field(0, ge=0, title="Аварийные выезды")
    client_requests: int = Field(
        0,
        ge=0,
        title="Заявки от заказчика",
        description="Заявки, заведённые пользователем с ролью клиента.",
    )
    other_requests: int = Field(
        0,
        ge=0,
        title="Прочие заявки",
        description=(
            "Заявки, чья категория не помечена counts_as_breakdown и которые "
            "завёл не клиент: замена лампы, осмотр по просьбе, уборка."
        ),
    )
    defects: int = Field(
        0, ge=0, title="Дефектные ведомости, составленные по итогам ТО"
    )


class MonthCell(BaseModel):
    """Один месяц одного объекта — ячейка матрицы отчёта."""

    year: int = Field(..., title="Год")
    month: int = Field(..., ge=1, le=12, title="Месяц")
    maintenance: MaintenanceStatus = Field(
        ..., title="Состояние планового ТО за этот месяц"
    )
    maintenance_finished_at: Optional[datetime.datetime] = Field(
        None,
        title="Когда закрыт акт ТО",
        description="Заполнено при статусах done и late.",
    )
    counts: WorkCounts = Field(..., title="Внеплановые работы за месяц")
    works_total: int = Field(
        ...,
        ge=0,
        title="Всего работ за месяц, включая ТО",
        description=(
            "Число для беглого взгляда: по нему видно, что в месяце было не "
            "только плановое ТО. ТО добавляет единицу, если оно планировалось."
        ),
    )


class ReportObjectRow(BaseModel):
    """Объект (лифт) в отчёте: карточка слева, двенадцать ячеек справа."""

    object_id: int = Field(..., title="ID объекта")
    object_name: Optional[str] = Field(None, title="Название объекта")
    registration_number: Optional[str] = Field(None, title="Регистрационный номер")
    factory_number: Optional[str] = Field(None, title="Заводской номер")
    address: Optional[str] = Field(None, title="Адрес объекта")
    client: Optional[str] = Field(
        None, title="Клиент: организация объекта, либо компания, если организации нет"
    )
    division: Optional[str] = Field(None, title="Участок")
    factory_model: Optional[str] = Field(None, title="Завод и модель оборудования")
    responsible_mechanic: Optional[str] = Field(
        None, title="Механик, закреплённый за объектом"
    )
    responsible_foreman: Optional[str] = Field(
        None, title="Прораб, закреплённый за объектом"
    )

    maintenance_planned: int = Field(..., ge=0, title="ТО запланировано за период")
    maintenance_completed: int = Field(..., ge=0, title="ТО выполнено")
    maintenance_late: int = Field(
        ...,
        ge=0,
        title="Из них закрыто после конца планового месяца",
        description="Входит в maintenance_completed, а не считается отдельно.",
    )
    maintenance_overdue: int = Field(
        ..., ge=0, title="ТО просрочено: плановый месяц прошёл, акт не закрыт"
    )
    counts: WorkCounts = Field(..., title="Внеплановые работы за период")
    months: List[MonthCell] = Field(
        [],
        title="Матрица месяцев, по возрастанию",
        description="Длина равна months_count из периода; месяцы без работ тоже есть.",
    )


class MonthTotals(BaseModel):
    """Столбик помесячной полосы: свод по всем объектам отбора."""

    year: int = Field(..., title="Год")
    month: int = Field(..., ge=1, le=12, title="Месяц")
    maintenance_planned: int = Field(..., ge=0, title="ТО запланировано")
    maintenance_completed: int = Field(..., ge=0, title="ТО выполнено")
    counts: WorkCounts = Field(..., title="Внеплановые работы за месяц")


class ReportSummary(BaseModel):
    """Краткая сводка за период — верх экрана и первая страница файла."""

    objects_total: int = Field(..., ge=0, title="Объектов в отчёте")
    objects_without_breakdowns: int = Field(
        ...,
        ge=0,
        title="Объектов без единого аварийного выезда",
        description="Считается по объектам отбора, а не только по видимым на странице.",
    )

    maintenance_planned: int = Field(..., ge=0, title="ТО запланировано за период")
    maintenance_completed: int = Field(..., ge=0, title="ТО выполнено")
    maintenance_late: int = Field(..., ge=0, title="Из них закрыто с опозданием")
    maintenance_overdue: int = Field(..., ge=0, title="ТО просрочено")
    completion_percent: float = Field(
        ...,
        ge=0,
        le=100,
        title="Доля выполненных ТО, проценты",
        description=(
            "Считается от общих чисел периода, а не средним из процентов "
            "объектов: объект с одним ТО не должен весить столько же, "
            "сколько объект с двенадцатью."
        ),
    )

    counts: WorkCounts = Field(..., title="Внеплановые работы за период")
    avg_reaction_hours: Optional[float] = Field(
        None,
        title="Среднее время реакции по аварийным выездам, часы",
        description=(
            "От создания заявки до момента, когда её взяли в работу. "
            "null, если за период не взяли ни одной."
        ),
    )
    reacted_count: int = Field(
        0,
        ge=0,
        title="По скольким заявкам посчитано время реакции",
        description="Без этого числа среднее по одной заявке неотличимо от среднего по сорока.",
    )


class WorksReport(BaseModel):
    """Отчёт о работах на объектах за период."""

    period: ReportPeriod = Field(..., title="Период отчёта")
    summary: ReportSummary = Field(..., title="Сводка за период")
    months: List[MonthTotals] = Field(
        [], title="Помесячная полоса по всему отбору, по возрастанию"
    )
    total_objects: int = Field(
        ...,
        ge=0,
        title="Всего объектов в отборе",
        description="По всей выдаче, а не по обрезанному limit списку.",
    )
    items: List[ReportObjectRow] = Field([], title="Объекты, по адресу и названию")


# ---------------------------------------------------------------------------
# Вложенность: что именно делали на объекте
# ---------------------------------------------------------------------------


class WorkStep(BaseModel):
    """Пункт чек-листа акта ТО."""

    title: str = Field(..., title="Что проверяли или делали")
    done: bool = Field(..., title="Отмечен ли пункт выполненным")


class DefectItem(BaseModel):
    """Дефектная ведомость, составленная по итогам ТО."""

    defect_id: int = Field(..., title="ID дефектной ведомости")
    title: str = Field(..., title="Заголовок")
    description: Optional[str] = Field(None, title="Описание дефекта")
    month: int = Field(..., ge=1, le=12, title="Месяц ТО, к которому относится")
    status: Optional[str] = Field(None, title="Статус")
    responsible: Optional[str] = Field(None, title="Ответственный")
    created_at: Optional[datetime.datetime] = Field(None, title="Когда составлена")
    photo_count: int = Field(0, ge=0, title="Сколько фотографий приложено")


class MaintenanceWork(BaseModel):
    """Плановое ТО за месяц — раскрытая работа со всем, что в неё вошло."""

    kind: WorkKind = Field(WorkKind.MAINTENANCE, title="Вид работы")
    act_id: int = Field(..., title="ID акта")
    year: int = Field(..., title="Год планового ТО")
    month: int = Field(..., ge=1, le=12, title="Плановый месяц")
    status: MaintenanceStatus = Field(..., title="Состояние ТО")
    started_at: Optional[datetime.datetime] = Field(None, title="Когда начали")
    finished_at: Optional[datetime.datetime] = Field(None, title="Когда закрыли акт")
    days_late: Optional[int] = Field(
        None,
        ge=0,
        title="На сколько дней позже конца планового месяца закрыт акт",
        description="Заполняется только при статусе late.",
    )
    foreman: Optional[str] = Field(None, title="Прораб")
    mechanic: Optional[str] = Field(None, title="Механик")
    steps: List[WorkStep] = Field(
        [],
        title="Чек-лист работ по акту",
        description=(
            "Разобранный step_list_fact. Пустой список означает, что механик "
            "чек-лист не заполнял, а не что работ не было."
        ),
    )
    defects: List[DefectItem] = Field(
        [], title="Дефектные ведомости, составленные по этому ТО"
    )


class RequestWork(BaseModel):
    """Заявка: аварийный выезд, задача от заказчика или прочая работа."""

    kind: WorkKind = Field(..., title="Вид работы")
    order_id: int = Field(..., title="ID заявки")
    created_at: Optional[datetime.datetime] = Field(None, title="Когда создана")
    accepted_at: Optional[datetime.datetime] = Field(None, title="Когда взяли в работу")
    done_at: Optional[datetime.datetime] = Field(None, title="Когда устранили")
    reaction_hours: Optional[float] = Field(
        None,
        ge=0,
        title="Время реакции, часы",
        description="От создания до момента, когда заявку взяли в работу.",
    )
    category: Optional[str] = Field(None, title="Категория неисправности")
    category_code: Optional[str] = Field(None, title="Код категории: AA, А, В, Н")
    reason: Optional[str] = Field(None, title="Причина неисправности")
    task_text: Optional[str] = Field(None, title="Текст заявки")
    commentary: Optional[str] = Field(None, title="Комментарий исполнителя")
    status: Optional[str] = Field(None, title="Статус заявки")
    creator: Optional[str] = Field(None, title="Кто завёл заявку")
    executor: Optional[str] = Field(None, title="Кто исполнял")
    photo_count: int = Field(0, ge=0, title="Сколько фотографий приложено")


class ObjectWorksReport(BaseModel):
    """Все работы на одном объекте за период — уровни 2 и 3 экрана.

    Три списка, а не один общий: у ТО и у заявки нет общего набора полей, и
    сведение их в одну плоскую запись означало бы половину полей пустыми в
    каждой строке. Ленту по датам собирает тот, кто показывает, — слиянием
    трёх списков по времени.
    """

    object: ReportObjectRow = Field(..., title="Объект со своими итогами за период")
    period: ReportPeriod = Field(..., title="Период отчёта")
    maintenance: List[MaintenanceWork] = Field(
        [], title="Плановые ТО, по возрастанию месяца"
    )
    requests: List[RequestWork] = Field([], title="Заявки, по возрастанию даты")
    defects: List[DefectItem] = Field(
        [],
        title="Дефектные ведомости периода",
        description=(
            "Те же ведомости, что вложены в ТО. Отдельным списком — чтобы "
            "показать их сплошным перечнем, не разворачивая каждое ТО."
        ),
    )
