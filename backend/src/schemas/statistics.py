from typing import List, Optional

from pydantic import BaseModel, Field


class TopBreakdownItem(BaseModel):
    """Строка старого топа поломок.

    Оставлена ради `/order/statistics/top-breakdowns`, который помечен
    устаревшим. Новый формат — `BreakdownsReport` ниже.
    """

    object_id: int = Field(..., title="ID объекта (лифта)")
    object_number: str = Field(..., title="Номер или название объекта для отображения")
    client: Optional[str] = Field(
        None, title="Клиент: организация объекта или компания (если организации нет)"
    )
    responsible_mechanic: Optional[str] = Field(
        None, title="Механик, закреплённый за объектом"
    )
    breakdown_count: int = Field(..., ge=0, title="Количество поломок за период")

    class Config:
        orm_mode = True


class BreakdownPeriod(BaseModel):
    year: int = Field(..., title="Год отчёта")
    month: int = Field(..., ge=1, le=12, title="Месяц отчёта")


class SeverityCount(BaseModel):
    """Сколько заявок пришлось на одну категорию тяжести."""

    category_id: Optional[int] = Field(
        None, title="ID категории; null — заявки без категории"
    )
    code: Optional[str] = Field(None, title="Короткий код: AA, А, В, Н, Д, С")
    name: Optional[str] = Field(None, title="Полное название категории")
    count: int = Field(..., ge=0, title="Количество заявок")
    share: float = Field(
        ..., ge=0, le=100, title="Доля от всех поломок периода, проценты"
    )


class BreakdownObjectItem(BaseModel):
    """Объект (лифт) в топе поломок за месяц."""

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

    breakdown_count: int = Field(..., ge=0, title="Поломок за период")
    severity: List[SeverityCount] = Field(
        [], title="Разбивка поломок по тяжести, от самой тяжёлой категории"
    )

    avg_reaction_hours: Optional[float] = Field(
        None,
        title="Среднее время реакции, часы",
        description=(
            "От создания заявки до момента, когда её взяли в работу. "
            "null, если ни одну заявку объекта за период не взяли."
        ),
    )
    reacted_count: int = Field(
        0,
        ge=0,
        title="По скольким заявкам посчитано время реакции",
        description="Без этого числа среднее по одной заявке неотличимо от среднего по сорока.",
    )

    avg_resolution_hours: Optional[float] = Field(
        None,
        title="Среднее время устранения, часы",
        description=(
            "От создания заявки до закрытия. Заполняется только по заявкам, "
            "у которых проставлен done_at."
        ),
    )
    resolved_count: int = Field(
        0, ge=0, title="По скольким заявкам посчитано время устранения"
    )

    previous_count: Optional[int] = Field(
        None,
        ge=0,
        title="Поломок за предыдущий месяц",
        description="Приходит только при with_previous=true.",
    )
    delta: Optional[int] = Field(
        None,
        title="Разница с предыдущим месяцем",
        description="Положительное число — поломок стало больше.",
    )


class BreakdownsReport(BaseModel):
    """Отчёт по поломкам за месяц: свод сверху, топ объектов ниже."""

    period: BreakdownPeriod = Field(..., title="Период отчёта")
    total_breakdowns: int = Field(..., ge=0, title="Всего поломок за период")
    objects_affected: int = Field(..., ge=0, title="Объектов с поломками за период")
    severity_summary: List[SeverityCount] = Field(
        [], title="Свод по категориям за период, от самой тяжёлой"
    )
    items: List[BreakdownObjectItem] = Field([], title="Топ объектов по числу поломок")


class ScheduleExecutionDivision(BaseModel):
    """Участок в отчёте о выполнении графика ТО."""

    division_id: Optional[int] = Field(
        None, title="ID участка; null — объекты без участка"
    )
    division: Optional[str] = Field(None, title="Название участка")
    responsible: Optional[str] = Field(
        None,
        title="Ответственные прорабы участка",
        description=(
            "Одно имя, либо «Никифоров +2», если прорабов несколько. "
            "null, если активных прорабов у участка нет."
        ),
    )
    responsible_count: int = Field(0, ge=0, title="Сколько активных прорабов у участка")

    planned_count: int = Field(
        ...,
        ge=0,
        title="ТО запланировано на месяц",
        description=(
            "Заполненные ячейки месяца в графике на этот год. Объект, "
            "которому ТО на месяц не завели, сюда не попадает."
        ),
    )
    completed_count: int = Field(
        ..., ge=0, title="ТО выполнено", description="Акт закрыт: заполнен finished_at."
    )
    completed_late_count: int = Field(
        ...,
        ge=0,
        title="Из них закрыто после конца планового месяца",
        description="Входит в completed_count, а не считается отдельно от него.",
    )
    completion_percent: float = Field(
        ..., ge=0, le=100, title="Доля выполненных ТО, проценты"
    )


class ScheduleExecutionReport(BaseModel):
    """Выполнение графика ТО за месяц по участкам."""

    period: BreakdownPeriod = Field(..., title="Период отчёта")
    planned_count: int = Field(..., ge=0, title="Всего ТО запланировано за месяц")
    completed_count: int = Field(..., ge=0, title="Всего выполнено")
    completed_late_count: int = Field(..., ge=0, title="Всего закрыто с просрочкой")
    completion_percent: float = Field(
        ...,
        ge=0,
        le=100,
        title="Доля выполненных по всем участкам",
        description=(
            "Считается от общих чисел, а не средним из процентов участков: "
            "участок с одним ТО не должен весить столько же, сколько участок "
            "с сорока."
        ),
    )
    items: List[ScheduleExecutionDivision] = Field(
        [], title="Участки, от худшего процента к лучшему"
    )


class OverdueMaintenanceItem(BaseModel):
    """Одно просроченное ТО: объект и плановый месяц.

    Объект с тремя пропущенными месяцами придёт тремя строками — иначе не
    видно, за какие именно месяцы долг.
    """

    act_id: int = Field(..., title="ID акта, заведённого на этот месяц")
    object_id: int = Field(..., title="ID объекта")
    object_name: Optional[str] = Field(None, title="Название объекта")
    registration_number: Optional[str] = Field(None, title="Регистрационный номер")
    factory_number: Optional[str] = Field(None, title="Заводской номер")
    address: Optional[str] = Field(None, title="Адрес объекта")
    client: Optional[str] = Field(
        None, title="Клиент: организация объекта, либо компания, если организации нет"
    )
    division: Optional[str] = Field(None, title="Участок")
    responsible_mechanic: Optional[str] = Field(
        None, title="Механик, закреплённый за объектом"
    )

    year: int = Field(..., title="Год планового ТО")
    month: int = Field(..., ge=1, le=12, title="Месяц планового ТО")
    months_overdue: int = Field(
        ...,
        ge=1,
        title="На сколько месяцев просрочено",
        description=(
            "Считается от текущего месяца: ТО за март, если сейчас август, "
            "просрочено на 5 месяцев. Минимум 1 — текущий месяц не просрочен."
        ),
    )


class EmployeeMetrics(BaseModel):
    """Разбивка балла по сторонам работы, 0–100 каждая.

    `null` означает «не считалось»: у механика не было в этом месяце ни
    одного планового ТО, ни одной аварии, и так далее. Вес непосчитанной
    метрики распределяется между остальными, а не превращается в ноль.
    """

    timeliness: Optional[float] = Field(
        None, ge=0, le=100, title="Своевременность плановых ТО"
    )
    reaction: Optional[float] = Field(
        None, ge=0, le=100, title="Скорость реакции на аварии, против норматива"
    )
    workload: Optional[float] = Field(
        None, ge=0, le=100, title="Объём и сложность выполненных работ"
    )
    reliability: Optional[float] = Field(
        None, ge=0, le=100, title="Надёжность парка: поломки на его лифтах"
    )


class ForemanMetrics(BaseModel):
    """Разбивка балла прораба."""

    team: Optional[float] = Field(
        None, ge=0, le=100, title="Средний балл механиков его участков"
    )
    schedule: Optional[float] = Field(
        None, ge=0, le=100, title="Выполнение графика ТО по его участкам"
    )
    overdue: Optional[float] = Field(
        None, ge=0, le=100, title="Отсутствие просроченных ТО на его участках"
    )


class EmployeeScoreItem(BaseModel):
    """Строка рейтинга сотрудников."""

    user_id: int = Field(..., title="ID сотрудника")
    name: Optional[str] = Field(None, title="ФИО")
    role_id: Optional[int] = Field(None, title="Роль: 2 прораб, 3 механик, 4 инженер")
    division: Optional[str] = Field(None, title="Участок")

    score: Optional[float] = Field(
        None,
        ge=0,
        le=100,
        title="Итоговый балл",
        description=(
            "null — посчитать было не из чего: у человека нет ни работ, ни "
            "закреплённых объектов за период."
        ),
    )
    is_provisional: bool = Field(
        ...,
        title="Мало данных",
        description=(
            "Работ за месяц меньше порога. Строка показывается с пометкой, "
            "уезжает в конец списка и не попадает ни в лучших, ни в худших."
        ),
    )

    works_count: int = Field(0, ge=0, title="Работ за месяц: заявки плюс ТО")
    orders_closed: int = Field(0, ge=0, title="Закрытых заявок")
    maintenance_total: int = Field(0, ge=0, title="Плановых ТО за месяц")
    maintenance_on_time: int = Field(0, ge=0, title="Из них закрыто в свой месяц")
    work_units: float = Field(
        0,
        ge=0,
        title="Объём работ в условных единицах",
        description=(
            "Авария весит по тяжести категории, ТО — по числу пунктов "
            "чек-листа, работа на чужом объекте — с коэффициентом 1,25."
        ),
    )
    objects_count: int = Field(0, ge=0, title="Закреплённых лифтов")
    breakdowns_on_objects: int = Field(0, ge=0, title="Поломок за месяц на его лифтах")
    repeat_count: int = Field(
        0,
        ge=0,
        title="Повторных вызовов после его ремонта",
        description="Новая авария на том же лифте в течение 14 дней.",
    )
    repeat_penalty: float = Field(0, ge=0, title="Штраф за повторы, баллы")
    reacted_count: int = Field(
        0, ge=0, title="По скольким авариям посчитано время реакции"
    )
    avg_reaction_hours: Optional[float] = Field(
        None, ge=0, title="Среднее время реакции, часы"
    )

    metrics: EmployeeMetrics = Field(..., title="Разбивка балла")
    foreman_metrics: Optional[ForemanMetrics] = Field(
        None, title="Разбивка балла прораба; у механиков пусто"
    )


class TopEmployeesReport(BaseModel):
    """Рейтинг сотрудников за месяц."""

    period: BreakdownPeriod = Field(..., title="Период отчёта")
    kind: str = Field(
        ...,
        title="Кого ранжировали: mechanic или foreman",
        description="Прорабов может смотреть только админ.",
    )
    order: str = Field(..., title="Порядок: best — лучшие сверху, worst — худшие")
    min_works: int = Field(
        ..., ge=0, title="Порог активности, ниже которого строка помечена «мало данных»"
    )
    total_count: int = Field(
        ...,
        ge=0,
        title="Всего сотрудников в выдаче",
        description="По всей выборке, а не по обрезанному limit списку.",
    )
    ranked_count: int = Field(
        ..., ge=0, title="Из них с полноценным баллом, без пометки «мало данных»"
    )
    items: List[EmployeeScoreItem] = Field([], title="Строки рейтинга")


class OverdueMaintenanceReport(BaseModel):
    """Просроченные ТО на сегодня.

    Периода у отчёта нет намеренно: просрочка — это состояние, а не срез
    месяца. `generated_for` говорит, от какого месяца отсчитывалась
    просрочка, чтобы `months_overdue` можно было проверить.
    """

    generated_for: BreakdownPeriod = Field(
        ..., title="Текущий месяц, от которого считалась просрочка"
    )
    total_count: int = Field(
        ...,
        ge=0,
        title="Всего просроченных ТО",
        description="По всей выдаче, а не по обрезанному limit списку.",
    )
    objects_affected: int = Field(..., ge=0, title="Объектов с просрочкой")
    items: List[OverdueMaintenanceItem] = Field(
        [], title="Просроченные ТО, самые старые сверху"
    )
