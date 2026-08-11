"""fault_category: код категории и флаг «считать поломкой» + индексы на order

Статистика поломок на главной должна отделять реальные отказы от плановых
работ. Раньше такой признак пришлось бы зашивать в код списком id
(6, 7, 8, 10) — и первая же категория, заведённая админом через админку,
молча испортила бы цифры. Признак живёт в самой таблице.

`code` нужен интерфейсу: полное имя «AA (Застревание пассажира. Опасность)»
в чип свода не помещается, а вытаскивать код из имени регуляркой на каждый
запрос — способ однажды получить пустую строку после правки названия.

Индексы на `order` — под запрос статистики: выборка за диапазон дат
с группировкой по объекту.

Revision ID: a1c7f3d92b40
Revises: 27d5b62d2360
Create Date: 2026-08-11 12:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a1c7f3d92b40"
down_revision: Union[str, None] = "27d5b62d2360"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# id категорий из `create_initial_data` -> (код, считать ли поломкой).
# Плановые работы (ТО, ПТО), капремонт и ложные вызовы поломками не считаются.
_SEED_CATEGORIES = (
    (1, "AA", True),
    (2, "А", True),
    (3, "В", True),
    (4, "Н", True),
    (5, "Д", True),
    (6, "ТО", False),
    (7, "ПТО", False),
    (8, "КР", False),
    (9, "С", True),
    (10, "Л", False),
)

_fault_category = sa.table(
    "fault_category",
    sa.column("id", sa.Integer),
    sa.column("code", sa.String),
    sa.column("counts_as_breakdown", sa.Boolean),
)


def upgrade() -> None:
    op.add_column("fault_category", sa.Column("code", sa.String(), nullable=True))
    op.add_column(
        "fault_category",
        sa.Column(
            "counts_as_breakdown",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
    )

    # Проставляем значения засеянным категориям. Категории, заведённые вручную,
    # остаются с code = NULL и counts_as_breakdown = true: новая категория
    # считается поломкой, пока админ явно не скажет обратное.
    for category_id, code, counts_as_breakdown in _SEED_CATEGORIES:
        op.execute(
            _fault_category.update()
            .where(_fault_category.c.id == category_id)
            .values(code=code, counts_as_breakdown=counts_as_breakdown)
        )

    op.create_index("ix_order_created_at", "order", ["created_at"])
    op.create_index("ix_order_object_id", "order", ["object_id"])


def downgrade() -> None:
    op.drop_index("ix_order_object_id", table_name="order")
    op.drop_index("ix_order_created_at", table_name="order")
    op.drop_column("fault_category", "counts_as_breakdown")
    op.drop_column("fault_category", "code")
