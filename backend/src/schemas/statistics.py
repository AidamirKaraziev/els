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
