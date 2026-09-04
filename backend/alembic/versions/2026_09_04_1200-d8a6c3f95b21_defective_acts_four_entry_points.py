"""Дефектный акт заводится из четырёх мест, а не только из планового ТО

До сих пор `defective_acts` был жёстко привязан к паре `planned_to_id` +
`month`: акт существовал только внутри планового ТО за конкретный месяц. Но
дефект замечают из работы по ТО, с отдельного пункта чек-листа, по аварийной
заявке и просто так, обходом — три входа из четырёх в эту пару не ложатся.

Обязательной привязкой становится `object_id`: объект известен всегда, по нему
окно графика спрашивает список и счётчик за год. `planned_to_id` и `month`
остаются, но необязательными — старые записи и старый контракт продолжают
жить, а новые точки входа их просто не заполняют.

`kind` и `state` — строки с `CheckConstraint`, а не PG-`ENUM`: тип enum'а
пришлось бы отдельно создавать и сносить при откате, а список состояний по
ходу работы над дефектными актами ещё может подрасти.

`defective_act_client_photo` — связь «снимок ушёл в клиентский акт». Байты не
копируются: один снимок может уйти в несколько клиентских актов, внутренний
акт остаётся первоисточником.

**Бэкфилл необратим.** `object_id` берётся из `planned_to.object_id`. Акты, у
которых объект так и не вычислился (нет планового ТО или у ТО пустой объект),
удаляются — держать их без объекта нельзя, а выдумать объект неоткуда. Их `id`
печатаются в лог миграции. Перед прогоном на боевой базе нужен дамп
`defective_acts` и `defective_act_photo`.

Revision ID: d8a6c3f95b21
Revises: c7f5b2e84a19
Create Date: 2026-09-04 12:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

revision = "d8a6c3f95b21"
down_revision = "c7f5b2e84a19"
branch_labels = None
depends_on = None


#: Вынесено из `upgrade()` отдельно, чтобы бэкфилл можно было прогнать в тесте:
#: тесты работают на уже накаченной базе, домиграционных строк в ней нет.
BACKFILL_OBJECT_ID = sa.text(
    """
    UPDATE defective_acts
       SET object_id = planned_to.object_id
      FROM planned_to
     WHERE defective_acts.planned_to_id = planned_to.id
       AND defective_acts.object_id IS NULL
       AND planned_to.object_id IS NOT NULL
    """
)


def backfill_object_id(bind) -> int:
    """Проставляет объект по плановому ТО. Возвращает число закрытых строк."""
    return bind.execute(BACKFILL_OBJECT_ID).rowcount


def upgrade():
    op.add_column("defective_acts", sa.Column("object_id", sa.Integer(), nullable=True))
    op.add_column(
        "defective_acts", sa.Column("act_fact_id", sa.Integer(), nullable=True)
    )
    op.add_column(
        "defective_acts", sa.Column("checklist_step_id", sa.Integer(), nullable=True)
    )
    op.add_column("defective_acts", sa.Column("order_id", sa.Integer(), nullable=True))
    op.add_column("defective_acts", sa.Column("parent_id", sa.Integer(), nullable=True))
    op.add_column(
        "defective_acts", sa.Column("client_title", sa.String(), nullable=True)
    )
    op.add_column(
        "defective_acts", sa.Column("client_description", sa.Text(), nullable=True)
    )
    op.add_column(
        "defective_acts",
        sa.Column("kind", sa.String(), nullable=False, server_default="internal"),
    )
    op.add_column(
        "defective_acts",
        sa.Column("state", sa.String(), nullable=False, server_default="created"),
    )

    bind = op.get_bind()
    backfill_object_id(bind)

    orphans = [
        row[0]
        for row in bind.execute(
            sa.text("SELECT id FROM defective_acts WHERE object_id IS NULL ORDER BY id")
        )
    ]
    if orphans:
        print(
            "Дефектные акты без объекта удаляются "
            f"({len(orphans)} шт.): {', '.join(str(i) for i in orphans)}"
        )
        bind.execute(sa.text("DELETE FROM defective_acts WHERE object_id IS NULL"))

    op.alter_column("defective_acts", "object_id", nullable=False)
    op.alter_column(
        "defective_acts", "month", existing_type=sa.Integer(), nullable=True
    )

    op.create_foreign_key(
        "fk_defective_acts_object_id",
        "defective_acts",
        "objects",
        ["object_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_defective_acts_act_fact_id",
        "defective_acts",
        "acts_fact",
        ["act_fact_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_defective_acts_order_id",
        "defective_acts",
        "order",
        ["order_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_defective_acts_parent_id",
        "defective_acts",
        "defective_acts",
        ["parent_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.create_check_constraint(
        "_defective_act_kind", "defective_acts", "kind IN ('internal', 'client')"
    )
    op.create_check_constraint(
        "_defective_act_state",
        "defective_acts",
        "state IN ('created', 'reviewed', 'issued', 'fixed')",
    )
    op.create_check_constraint(
        "_defective_act_client_has_parent",
        "defective_acts",
        "kind <> 'client' OR parent_id IS NOT NULL",
    )

    # Список и счётчик за год спрашиваются по объекту на каждом открытии окна
    # графика.
    op.create_index("ix_defective_acts_object_id", "defective_acts", ["object_id"])

    op.create_table(
        "defective_act_client_photo",
        sa.Column("client_act_id", sa.Integer(), nullable=False),
        sa.Column("photo_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(
            ["client_act_id"], ["defective_acts.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["photo_id"], ["defective_act_photo.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("client_act_id", "photo_id"),
    )


def downgrade():
    op.drop_table("defective_act_client_photo")

    op.drop_index("ix_defective_acts_object_id", table_name="defective_acts")

    op.drop_constraint(
        "_defective_act_client_has_parent", "defective_acts", type_="check"
    )
    op.drop_constraint("_defective_act_state", "defective_acts", type_="check")
    op.drop_constraint("_defective_act_kind", "defective_acts", type_="check")

    op.drop_constraint(
        "fk_defective_acts_parent_id", "defective_acts", type_="foreignkey"
    )
    op.drop_constraint(
        "fk_defective_acts_order_id", "defective_acts", type_="foreignkey"
    )
    op.drop_constraint(
        "fk_defective_acts_act_fact_id", "defective_acts", type_="foreignkey"
    )
    op.drop_constraint(
        "fk_defective_acts_object_id", "defective_acts", type_="foreignkey"
    )

    # Записи новых точек входа месяца не знают, а старая схема требует его
    # заполненным. Январь здесь — не догадка о том, когда нашли дефект, а
    # заглушка ради `NOT NULL`: восстановить месяц неоткуда.
    op.execute(sa.text("UPDATE defective_acts SET month = 1 WHERE month IS NULL"))
    op.alter_column(
        "defective_acts", "month", existing_type=sa.Integer(), nullable=False
    )

    for column in (
        "state",
        "kind",
        "client_description",
        "client_title",
        "parent_id",
        "order_id",
        "checklist_step_id",
        "act_fact_id",
        "object_id",
    ):
        op.drop_column("defective_acts", column)
