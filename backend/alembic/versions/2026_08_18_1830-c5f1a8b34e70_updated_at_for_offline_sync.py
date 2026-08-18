"""Метка последней правки в таблицах, которые синхронизируются с телефоном

Механику нужен офлайн: связь на объектах рвётся, и приложение должно
спрашивать «что изменилось с момента T», а не тянуть весь список заново.
Спросить нечем — `updated_at` не было ни в одной таблице, кроме дефектных
ведомостей.

Колонка добавляется в четыре таблицы, которые уезжают на телефон: заявки,
объекты, фактические акты и план ТО.

Существующие строки получают осмысленное значение, а не `now()`: если у
записи есть дата создания, берём её. Иначе телефон при первой же синхронизации
увидел бы всю базу как «только что изменённую» — что верно по форме и
бесполезно по сути.

Индекс по колонке нужен потому, что запрос «изменилось после T» — основной
запрос синхронизации, и он пойдёт по каждой из этих таблиц.

Revision ID: c5f1a8b34e70
Revises: b4e2a7c19f30
Create Date: 2026-08-18 18:30:00.000000

"""

import sqlalchemy as sa
from alembic import op

revision = "c5f1a8b34e70"
down_revision = "b4e2a7c19f30"
branch_labels = None
depends_on = None


#: Таблица и колонка, из которой берём дату для уже накопленных строк.
#: У объектов и плана ТО даты создания нет вовсе — там остаётся `now()`.
_TABLES = {
    "order": "created_at",
    "acts_fact": "created_at",
    "objects": None,
    "planned_to": None,
}


def upgrade():
    for table, source in _TABLES.items():
        op.add_column(
            table, sa.Column("updated_at", sa.DateTime(), nullable=True)
        )
        fallback = "now()"
        value = f'COALESCE("{source}", {fallback})' if source else fallback
        op.execute(f'UPDATE "{table}" SET updated_at = {value}')
        op.create_index(
            f"ix_{table}_updated_at", table, ["updated_at"], unique=False
        )


def downgrade():
    for table in _TABLES:
        op.drop_index(f"ix_{table}_updated_at", table_name=table)
        op.drop_column(table, "updated_at")
