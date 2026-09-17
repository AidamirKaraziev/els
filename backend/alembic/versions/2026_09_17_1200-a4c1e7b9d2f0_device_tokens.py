"""device_tokens: адреса телефонов для push

Телефон механика узнавал о новой задаче только опросом раз в две минуты,
пока приложение открыто. Чтобы будить закрытое приложение, серверу нужен
адрес устройства — токен FCM. Таблица отдельная от `refresh_sessions`: токен
живёт дольше входа и уникален на устройство, а не на сессию.

Revision ID: a4c1e7b9d2f0
Revises: e9b7d4a06c32
Create Date: 2026-09-17 12:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a4c1e7b9d2f0"
down_revision: Union[str, None] = "e9b7d4a06c32"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "device_tokens",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("token", sa.String(), nullable=False),
        sa.Column(
            "platform", sa.String(length=16), nullable=False, server_default="android"
        ),
        sa.Column(
            "created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()
        ),
        sa.Column(
            "updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()
        ),
        sa.ForeignKeyConstraint(
            ["user_id"], ["universal_users.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token"),
    )
    op.create_index(
        "ix_device_tokens_user_id", "device_tokens", ["user_id"], unique=False
    )


def downgrade() -> None:
    op.drop_index("ix_device_tokens_user_id", table_name="device_tokens")
    op.drop_table("device_tokens")
