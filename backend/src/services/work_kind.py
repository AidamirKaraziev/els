"""Вид работы по заявке: авария, обращение заказчика или прочее.

Одно правило на весь проект. Считают его отчёты, статистика главной и лента
сданных работ, и разъехаться им нельзя: аварийность объекта в отчёте клиенту
и та же аварийность на карточке прораба обязаны быть одним числом.

Порядок разбора важен:

1. **Авария** — по флагу `counts_as_breakdown` у категории неисправности.
   Заявка **без категории** тоже авария: недозаполненная заявка не повод
   потерять реальный выезд.
2. **Обращение заказчика** — из оставшихся те, что завёл пользователь с ролью
   клиента.
3. **Прочее** — всё остальное.

Настоящая поломка остаётся поломкой, даже если о ней сообщил сам клиент.
Иначе аварийность объекта зависела бы от того, кто первым нажал кнопку.

Выражения строятся на `Order` и `FaultCategory`, поэтому запрос обязан
присоединить обе таблицы, а автора — отдельным `aliased(UniversalUser)`:
у заявки два разных человека (автор и исполнитель), и без псевдонима
SQLAlchemy склеит их в одно соединение.
"""

from sqlalchemy import case

from src.core.roles import Role
from src.models import FaultCategory, Order
from src.schemas.reports import WorkKind


def order_kind_flags(creator):
    """Три взаимоисключающих условия «авария / клиент / прочее»."""
    is_breakdown = (Order.fault_category_id.is_(None)) | (
        FaultCategory.counts_as_breakdown.is_(True)
    )
    is_client = (~is_breakdown) & (creator.role_id == Role.CLIENT)
    is_other = (~is_breakdown) & (
        (creator.role_id.is_(None)) | (creator.role_id != Role.CLIENT)
    )
    return is_breakdown, is_client, is_other


def order_kind_case(creator):
    """Тот же разбор, но одним значением `WorkKind` в строке выдачи.

    Нужен там, где вид работы не считают, а показывают: в ленте сданных работ
    заявка приезжает строкой и обязана назвать себя сама.
    """
    is_breakdown, is_client, _ = order_kind_flags(creator)
    return case(
        (is_breakdown, WorkKind.BREAKDOWN.value),
        (is_client, WorkKind.CLIENT_REQUEST.value),
        else_=WorkKind.REQUEST.value,
    )
