"""Отметка «проверил» на сданных работах

Механик закрывает ТО сам, и работа засчитывается сразу — приёмки,
блокирующей зачёт, в системе нет и не задумано. Прорабу нужно другое: видеть
ленту свежих сданных работ и уметь сказать «эту я посмотрел», чтобы счётчик
непросмотренного на главной гас.

Отметка — два поля на каждой из двух сущностей ленты, а не отдельная таблица
отметок: отметка одна на запись и нужна ровно в том же запросе, что и сама
запись. Отдельная таблица означала бы соединение на каждый показ ленты и
ничего не давала бы взамен — второй отметки у записи не бывает.

Индекс по `reviewed_at` нужен для счётчика непросмотренного: это запрос
«сданные работы, где отметки нет», и он идёт на каждое открытие главной.

Накопленным строкам отметка не проставляется. Работы, сданные до появления
ленты, честно показываются непроверенными: обратное означало бы соврать
прорабу, что он их уже смотрел.

Revision ID: e3b9d47c58a2
Revises: d7a2e5c19b41
Create Date: 2026-08-18 21:30:00.000000

"""

import sqlalchemy as sa
from alembic import op

revision = "e3b9d47c58a2"
down_revision = "d7a2e5c19b41"
branch_labels = None
depends_on = None

#: Обе сущности ленты сданных работ: закрытое ТО и закрытая заявка.
_TABLES = ("acts_fact", "order")


def upgrade():
    for table in _TABLES:
        op.add_column(table, sa.Column("reviewed_at", sa.DateTime(), nullable=True))
        op.add_column(
            table, sa.Column("reviewed_by_id", sa.Integer(), nullable=True)
        )
        op.create_foreign_key(
            f"fk_{table}_reviewed_by_id_universal_users",
            table,
            "universal_users",
            ["reviewed_by_id"],
            ["id"],
            ondelete="SET NULL",
        )
        op.create_index(f"ix_{table}_reviewed_at", table, ["reviewed_at"])


def downgrade():
    for table in _TABLES:
        op.drop_index(f"ix_{table}_reviewed_at", table_name=table)
        op.drop_constraint(
            f"fk_{table}_reviewed_by_id_universal_users", table, type_="foreignkey"
        )
        op.drop_column(table, "reviewed_by_id")
        op.drop_column(table, "reviewed_at")
