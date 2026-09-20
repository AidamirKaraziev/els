"""acts_bases.deleted_at: мягкое удаление вида ТО у модели

Экран «Шаблоны ТО» убирает вид ТО у модели и умеет его вернуть. Настоящий
`DELETE acts_bases` обнулил бы `acts_fact.act_base_id` у созданных актов —
по этой ссылке график узнаёт вид ТО акта, — поэтому строка остаётся, а
удаление отмечается датой.

Revision ID: c3f8a1d27b64
Revises: a4c1e7b9d2f0
Create Date: 2026-09-20 12:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c3f8a1d27b64"
down_revision: Union[str, None] = "a4c1e7b9d2f0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("acts_bases", sa.Column("deleted_at", sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column("acts_bases", "deleted_at")
