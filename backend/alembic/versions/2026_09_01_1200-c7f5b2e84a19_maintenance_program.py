"""Программа обслуживания модели оборудования

Годовой план (`planned_to`) держит двенадцать колонок `<месяц>_to_id` и знает
только «в этом месяце ТО было». Какое именно — выясняется, лишь когда по
месяцу заведён факт. Программа отвечает на это заранее: одна на модель
оборудования, двенадцать позиций «месяц → вид ТО».

Позиции лежат отдельной таблицей, а не строкой из двенадцати имён: вид ТО
должен быть внешним ключом на `types_acts`, иначе шаблон чек-листа по нему не
найти. `types_acts` сидится с id, равным периодичности (1, 3, 6, 12), поэтому
на позиции стоит `RESTRICT` — удаление вида из-под живых программ портит план.

Бэкфилла нет: программы заводятся руками, `planned_to` не трогаем.

Revision ID: c7f5b2e84a19
Revises: b6e4a9d31c05
Create Date: 2026-09-01 12:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

revision = "c7f5b2e84a19"
down_revision = "b6e4a9d31c05"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "maintenance_program",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("factory_model_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["factory_model_id"], ["factories_models.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("factory_model_id"),
    )
    op.create_index(
        op.f("ix_maintenance_program_updated_at"),
        "maintenance_program",
        ["updated_at"],
    )

    op.create_table(
        "maintenance_program_item",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("program_id", sa.Integer(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("type_act_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(
            ["program_id"], ["maintenance_program.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["type_act_id"], ["types_acts.id"], ondelete="RESTRICT"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("program_id", "position", name="_program_position_uc"),
        sa.CheckConstraint("position BETWEEN 1 AND 12", name="_program_position_range"),
    )


def downgrade():
    op.drop_table("maintenance_program_item")
    op.drop_index(
        op.f("ix_maintenance_program_updated_at"), table_name="maintenance_program"
    )
    op.drop_table("maintenance_program")
