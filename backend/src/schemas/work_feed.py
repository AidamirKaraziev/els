"""Единая лента работ глазами прораба: заявки и акты ТО одним списком.

Одна схема на все статусы, а не три ручки на три стадии жизни работы
(`/order/all`, `/work/in-progress`, `/work/submitted`): экран «Работы» показывает
одну ленту с пилюлей статуса, и собирать её из трёх ответов значило бы
повторять на каждом клиенте правило «что считать паузой, а что проблемой».

Статус — одно слово, даты стадий — по отдельности: по ним экран считает
таймер («ждёт 40 мин», «на паузе 2 ч»), и одной «последней перемены» ему
мало. Причина внимания тоже считается здесь, а не на клиенте: блок «требуют
внимания» стоит наверху ленты с курсором, и упорядочить его можно только в
базе.
"""

from enum import Enum
from typing import Dict, List, Optional

from pydantic import BaseModel, Field

from src.schemas.maintenance import MaintenanceObject
from src.schemas.reports import WorkKind


class WorkStatus(str, Enum):
    """Где работа сейчас — одно слово на пилюле.

    Один ряд на заявку и на ТО. У заявки это её статус из справочника, у акта
    состояние собирается из дат и статуса — см. `crud/crud_work_feed.py`.
    """

    #: Создана, никто не взял.
    FRESH = "fresh"
    #: Назначена или взята механиком, но не начата.
    ACCEPTED = "accepted"
    #: Ведётся прямо сейчас. Пауза — тот же статус с заполненным `paused_at`.
    RUNNING = "running"
    #: Сдана: ТО закрыто актом, заявка выполнена.
    SUBMITTED = "submitted"
    #: Механик выехал и сделать не смог.
    PROBLEM = "problem"


#: Закрытые статусы: работа стала историей, внимания она не требует.
CLOSED_STATUSES = (WorkStatus.SUBMITTED, WorkStatus.PROBLEM)


class AttentionReason(str, Enum):
    """Почему строка требует внимания прораба.

    Три причины, и только они. Всё остальное — «идёт как идёт». Пороги —
    в `crud/crud_work_feed.py`, те же, что в `WorkTiming` на экране: полоса
    сводки и красный таймер обязаны сходиться в одном числе.
    """

    #: Новая заявка, которую никто не взял.
    UNASSIGNED = "unassigned"
    #: Стадия дольше порога: ждёт, лежит у механика или идёт слишком долго.
    OVERDUE = "overdue"
    #: Стоит на паузе дольше часа.
    PAUSED_LONG = "paused_long"


class WorkSort(str, Enum):
    """Порядок ленты."""

    #: Сначала блок «требуют внимания» (дольше стоит — выше), потом остальные
    #: по последней перемене.
    ATTENTION = "attention"
    #: Просто по последней перемене, новое сверху.
    UPDATED = "updated"


class WorkSection(BaseModel):
    """Участок обслуживания — для выпадашки."""

    id: int = Field(..., title="ID участка")
    title: Optional[str] = Field(None, title="Название")


class WorkEmployee(BaseModel):
    """Сотрудник в списке «кого назначить»."""

    id: int = Field(..., title="ID сотрудника")
    name: Optional[str] = Field(None, title="Имя")
    specialty: Optional[str] = Field(
        None, title="Должность", description="Из справочника `working_specialty`."
    )
    section_id: Optional[int] = Field(None, title="Основной участок")
    section: Optional[str] = Field(None, title="Название участка")
    phone: Optional[str] = Field(None, title="Телефон")


class WorkFeedItem(BaseModel):
    kind: WorkKind = Field(
        ...,
        title="Вид работы",
        description=(
            "`maintenance` — плановое ТО. Остальные виды приходят из заявок и "
            "делятся тем же правилом, что и в отчётах: авария, обращение "
            "заказчика, прочее."
        ),
    )
    work_id: int = Field(
        ...,
        title="ID работы",
        description="ID акта у ТО и ID заявки у остальных видов.",
    )
    status: WorkStatus = Field(..., title="Где работа сейчас")
    act_title: Optional[str] = Field(
        None,
        title="Регламент",
        description="«ТО-1», «ТО-3» — из чек-листа акта. У заявок пусто.",
    )

    object: Optional[MaintenanceObject] = Field(None, title="Объект")
    object_type: Optional[str] = Field(
        None,
        title="Тип техники",
        description="Из справочника типов через модель: «Лифт с МП», «Эскалатор».",
    )
    task_text: Optional[str] = Field(
        None,
        title="Что просили сделать",
        description="Только у заявок: у ТО задание — это чек-лист акта.",
    )

    performer_id: Optional[int] = Field(None, title="ID исполнителя")
    performer: Optional[str] = Field(
        None,
        title="Кто ведёт или сдал",
        description="Механик акта у ТО, исполнитель у заявки. Пусто у новой.",
    )
    performer_phone: Optional[str] = Field(None, title="Телефон исполнителя")

    created_at: Optional[int] = Field(
        None, title="Создана", description="Секунды эпохи."
    )
    accepted_at: Optional[int] = Field(
        None,
        title="Принята",
        description="У заявки — момент перевода в «Принято». У ТО не хранится.",
    )
    started_at: Optional[int] = Field(None, title="Начата")
    paused_at: Optional[int] = Field(
        None,
        title="Приостановлена",
        description=(
            "Заполнено только у идущего ТО, которое механик поставил на паузу. "
            "У заявки паузы не бывает."
        ),
    )
    closed_at: Optional[int] = Field(
        None,
        title="Сдана или закрыта проблемой",
        description="Дата закрытия акта у ТО, дата выполнения у заявки.",
    )
    updated_at: Optional[int] = Field(
        None,
        title="Последняя перемена",
        description="По ней лента упорядочена при `sort=updated` и работает `updated_since`.",
    )

    has_defect: bool = Field(False, title="К работе привязан дефектный акт")
    comment: Optional[str] = Field(
        None,
        title="Комментарий механика",
        description="Причина паузы, проблемы или запись при закрытии.",
    )
    is_actual: bool = Field(
        True,
        title="Живая запись",
        description="`false` — в архиве. Приходит только с `updated_since` или `only_archived`.",
    )

    section_id: Optional[int] = Field(None, title="ID участка")
    section: Optional[str] = Field(
        None,
        title="Участок",
        description="Участок объекта; если у объекта его нет — участок исполнителя.",
    )

    reviewed: bool = Field(
        False,
        title="Прораб отметил «проверил»",
        description=(
            "Строка уходит из блока внимания до следующей перемены статуса: "
            "смена статуса сбрасывает отметку."
        ),
    )
    attention: Optional[AttentionReason] = Field(
        None,
        title="Почему требует внимания",
        description="Пусто — не требует. Считается на момент запроса.",
    )


class WorkCounts(BaseModel):
    """Числа на чипсах.

    Каждое считается по отбору **без** своего чипса: число на «В работе»
    говорит, сколько строк появится, если его нажать.
    """

    by_status: Dict[WorkStatus, int] = Field({}, title="По статусу")
    by_kind: Dict[WorkKind, int] = Field({}, title="По виду работы")
    by_attention: Dict[AttentionReason, int] = Field({}, title="По причине внимания")


class WorkFeed(BaseModel):
    items: List[WorkFeedItem] = Field([], title="Строки ленты")
    counts: WorkCounts = Field(WorkCounts(), title="Числа на чипсах")
    attention_count: int = Field(
        0,
        ge=0,
        title="Сколько строк требуют внимания",
        description=(
            "По всему отбору, не по странице. При `sort=attention` ровно "
            "столько первых строк ленты — блок внимания; при `sort=updated` — 0."
        ),
    )
    next_cursor: Optional[str] = Field(
        None,
        title="Курсор следующей страницы",
        description="Пусто — страница последняя. Передаётся как есть в `cursor`.",
    )
    sections: List[WorkSection] = Field([], title="Участки, что встречаются в ленте")
    employees: List[WorkEmployee] = Field([], title="Кого можно назначить")
    my_sections: List[int] = Field(
        [], title="Участки того, кто спрашивает", description="Под чипс «Мои участки»."
    )


class AssignBody(BaseModel):
    performer_id: int = Field(..., title="Кого назначить")


class NewWorkObject(BaseModel):
    """Объект в выборе формы «Новая работа»: всё, по чему его ищут, и всё,
    что показывает карточка после выбора."""

    id: int = Field(..., title="ID объекта")
    name: Optional[str] = Field(None, title="Название")
    address: Optional[str] = Field(None, title="Адрес")
    type: Optional[str] = Field(None, title="Тип техники")
    factory_number: Optional[str] = Field(None, title="Заводской номер")
    registration_number: Optional[str] = Field(None, title="Регистрационный номер")
    section_id: Optional[int] = Field(None, title="Участок")
    section: Optional[str] = Field(None, title="Название участка")
    mechanic_id: Optional[int] = Field(
        None,
        title="Закреплённый механик",
        description="Подставляется исполнителем, пока не выбрали другого.",
    )
    mechanic: Optional[str] = Field(None, title="Имя механика")
    foreman: Optional[str] = Field(None, title="Прораб объекта")
    contact_name: Optional[str] = Field(None, title="Контактное лицо")
    contact_phone: Optional[str] = Field(None, title="Телефон контакта")


class NewWorkCategory(BaseModel):
    """Категория заявки из справочника `fault_category`."""

    id: int = Field(..., title="ID категории")
    code: Optional[str] = Field(None, title="Код", description="«Р», «AA», «ТО».")
    name: Optional[str] = Field(
        None,
        title="Описание без кода",
        description="«Ремонт по заявке» — код в справочнике стоит в имени, здесь срезан.",
    )
    counts_as_breakdown: bool = Field(
        ..., title="Считается поломкой", description="Да — «Авария», нет — «Заявка»."
    )


class NewWorkOpenItem(BaseModel):
    """Открытая работа по объекту — чтобы не завести дубль."""

    kind: WorkKind = Field(..., title="Вид работы")
    status: WorkStatus = Field(..., title="Статус")
    title: Optional[str] = Field(None, title="Задание или регламент")
    performer: Optional[str] = Field(None, title="Исполнитель")


class NewWorkContext(BaseModel):
    """Всё, что нужно форме «Новая работа», одним ответом.

    Три справочника с разной пагинацией и клиенты, которых в `employees`
    ленты нет, — собирать это на клиенте значило бы повторять область
    видимости в четырёх запросах. Здесь она применяется один раз.
    """

    objects: List[NewWorkObject] = Field([], title="Объекты в области видимости")
    categories: List[NewWorkCategory] = Field([], title="Категории заявок")
    employees: List[WorkEmployee] = Field(
        [],
        title="Кого можно назначить",
        description="Сотрудники ленты плюс заказчики — со `specialty` «Заказчик».",
    )
    open_works: Dict[int, List[NewWorkOpenItem]] = Field(
        {}, title="Открытые работы по объекту", description="Ключ — id объекта."
    )
    my_sections: List[int] = Field([], title="Участки того, кто спрашивает")
    author: Optional[str] = Field(None, title="Кто заводит работу")
