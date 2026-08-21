"""Состояние работы по ТО: пауза и комментарий ко всей работе

До сих пор ТО знало про себя две вещи: начато оно (`started_at`) и закрыто
(`finished_at`). Живая смена в эти две вещи не укладывается: механик взялся за
ТО, приехал аварийный вызов, он уехал — и работа так и висит «в работе», а
прораб не отличает брошенное от идущего прямо сейчас.

`paused_at` — момент, когда работа встала. Отдельная колонка, а не один только
статус: статус говорит «стоит», а прорабу нужно ещё и «с какого момента».
Пустая при возобновлении.

`commentary` — комментарий ко всей работе: причина проблемы или запись при
закрытии акта. Комментарий к отдельному пункту регламента уже есть, он живёт
внутри чек-листа и с этим полем не пересекается.

Обе колонки `nullable` и обе только добавляются: у накопленных актов состояние
работы задним числом не восстановить, а выдумывать его — врать прорабу.

Revision ID: a8d3f5b27c14
Revises: f4c1e6a29b73
Create Date: 2026-08-21 12:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

revision = "a8d3f5b27c14"
down_revision = "f4c1e6a29b73"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("acts_fact", sa.Column("paused_at", sa.DateTime(), nullable=True))
    op.add_column("acts_fact", sa.Column("commentary", sa.String(), nullable=True))


def downgrade():
    op.drop_column("acts_fact", "commentary")
    op.drop_column("acts_fact", "paused_at")
