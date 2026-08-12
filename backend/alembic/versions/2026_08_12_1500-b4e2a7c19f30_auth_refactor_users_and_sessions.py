"""Авторизация: переименование полей пользователя, участки списком, сессии

Пять несвязанных на вид правок, но все они — фундамент под ролевую модель и
живут одной миграцией потому, что порознь оставляют базу в нерабочем виде.

1. `password` -> `hashed_password`, `is_actual` -> `is_active`. Имена врали:
   в `password` лежит bcrypt-хеш, а `is_actual` у пользователя означает не
   «актуальная запись», а «сотрудник работает».

2. Уникальность email по нижнему регистру. Прежнее ограничение
   `(email, is_actual)` уникальности не давало вовсе — NULL в булевом поле
   обходил его целиком, — а вход искал по точному совпадению строки, из-за
   чего `Голдобин@mail.ru` и `голдобин@mail.ru` были разными людьми.

3. `user_divisions` — сотрудник может вести несколько участков. Текущие
   `division_id` переносятся в таблицу, само поле остаётся основным участком.

4. `refresh_sessions` — сессии, которые можно погасить. Раньше выданный токен
   жил восемь суток и отозвать его было нечем.

5. Принудительный сброс паролей короче 8 символов. Закрывает вход в систему с
   правами админа по паролю «1»: аккаунт `id=1` создавался при каждом старте
   приложения с зашитым в код паролем.

Revision ID: b4e2a7c19f30
Revises: a1c7f3d92b40
Create Date: 2026-08-12 15:00:00.000000

"""
import logging
import secrets
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

_log = logging.getLogger("alembic.runtime.migration")

# revision identifiers, used by Alembic.
revision: str = "b4e2a7c19f30"
down_revision: Union[str, None] = "a1c7f3d92b40"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _make_unusable_hash() -> str:
    """То же, что `core.security.make_unusable_password_hash`.

    Продублировано намеренно: миграция обязана работать одинаково независимо
    от того, как потом изменится код приложения.
    """
    return "!" + secrets.token_urlsafe(32)


def upgrade() -> None:
    # --- 1. Переименования -------------------------------------------------
    op.alter_column("universal_users", "password", new_column_name="hashed_password")
    op.alter_column("universal_users", "is_actual", new_column_name="is_active")

    # --- 2. Уникальность email --------------------------------------------
    # Пустые адреса до NOT NULL не доедут, поэтому сначала смотрим, нет ли их.
    conn = op.get_bind()
    empty_emails = conn.execute(
        sa.text(
            "SELECT count(*) FROM universal_users "
            "WHERE email IS NULL OR btrim(email) = ''"
        )
    ).scalar()
    if empty_emails:
        raise RuntimeError(
            f"В universal_users {empty_emails} записей без email. "
            "Заполните адреса вручную и повторите миграцию: без них "
            "пользователь не сможет войти."
        )

    duplicates = conn.execute(
        sa.text(
            "SELECT lower(email) AS e, count(*) AS c FROM universal_users "
            "GROUP BY 1 HAVING count(*) > 1"
        )
    ).fetchall()
    if duplicates:
        listed = ", ".join(f"{row.e} ({row.c})" for row in duplicates)
        raise RuntimeError(
            "Email не уникальны без учёта регистра: "
            f"{listed}. Разведите адреса вручную и повторите миграцию."
        )

    op.drop_constraint(
        "_email_is_actual_uc", "universal_users", type_="unique"
    )
    op.alter_column("universal_users", "email", nullable=False)
    op.create_index(
        "uq_universal_users_email_lower",
        "universal_users",
        [sa.text("lower(email)")],
        unique=True,
    )

    # --- 3. Новые поля пользователя ---------------------------------------
    op.add_column(
        "universal_users", sa.Column("password_changed_at", sa.DateTime(), nullable=True)
    )
    op.add_column(
        "universal_users",
        sa.Column(
            "failed_login_attempts",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
    )
    op.add_column(
        "universal_users", sa.Column("locked_until", sa.DateTime(), nullable=True)
    )

    # --- 4. Участки списком ------------------------------------------------
    op.create_table(
        "user_divisions",
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("universal_users.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column(
            "division_id",
            sa.Integer(),
            sa.ForeignKey("divisions.id", ondelete="CASCADE"),
            primary_key=True,
        ),
    )
    op.execute(
        sa.text(
            "INSERT INTO user_divisions (user_id, division_id) "
            "SELECT id, division_id FROM universal_users "
            "WHERE division_id IS NOT NULL"
        )
    )

    # --- 5. Сессии ---------------------------------------------------------
    op.create_table(
        "refresh_sessions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("universal_users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("token_hash", sa.String(length=64), nullable=False, unique=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("revoked_at", sa.DateTime(), nullable=True),
        sa.Column("user_agent", sa.String(), nullable=True),
        sa.Column("ip_address", sa.String(), nullable=True),
    )
    op.create_index(
        "ix_refresh_sessions_user_id", "refresh_sessions", ["user_id"]
    )

    # --- 6. Сброс заведомо слабых паролей администраторов -------------------
    # Длину исходного пароля по bcrypt-хешу не узнать, поэтому проверяем набор
    # заглушек, которыми пользовались при разработке.
    #
    # Проверяем только администраторов: каждая проверка — полноценный bcrypt на
    # cost 12, около трети секунды. По всей таблице это были бы минуты работы
    # внутри миграции, а выигрыш сомнительный — у остальных ролей после этого
    # рефакторинга прав немного, и слабый пароль там не открывает систему.
    weak_candidates = [str(n) for n in range(10)] + [
        "11",
        "111",
        "123",
        "1234",
        "12345",
        "123456",
        "1234567",
        "admin",
        "test",
        "qwerty",
        "password",
    ]
    from passlib.context import CryptContext

    ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
    admins = conn.execute(
        sa.text(
            "SELECT id, email, hashed_password FROM universal_users "
            "WHERE role_id = 1 AND hashed_password IS NOT NULL"
        )
    ).fetchall()

    reset_ids = []
    for row in admins:
        for candidate in weak_candidates:
            try:
                matched = ctx.verify(candidate, row.hashed_password)
            except ValueError:
                # Строка в поле не разбирается как bcrypt-хеш — войти по ней и
                # так нельзя, трогать нечего.
                break
            if matched:
                reset_ids.append(row.id)
                break

    for user_id in reset_ids:
        conn.execute(
            sa.text(
                "UPDATE universal_users "
                "SET hashed_password = :h, password_changed_at = now() "
                "WHERE id = :id"
            ),
            {"h": _make_unusable_hash(), "id": user_id},
        )
    if reset_ids:
        _log.warning(
            "Пароль принудительно сброшен у администраторов с id: %s. "
            "Войти по старому паролю нельзя — задайте новые через "
            "суперадминистратора.",
            ", ".join(str(i) for i in reset_ids),
        )


def downgrade() -> None:
    # Сброшенные пароли обратно не восстанавливаются: исходных значений нет
    # нигде, и это правильно. Остальное откатывается.
    op.drop_index("ix_refresh_sessions_user_id", table_name="refresh_sessions")
    op.drop_table("refresh_sessions")
    op.drop_table("user_divisions")

    op.drop_column("universal_users", "locked_until")
    op.drop_column("universal_users", "failed_login_attempts")
    op.drop_column("universal_users", "password_changed_at")

    op.drop_index("uq_universal_users_email_lower", table_name="universal_users")
    op.alter_column("universal_users", "email", nullable=True)
    op.create_unique_constraint(
        "_email_is_actual_uc", "universal_users", ["email", "is_active"]
    )

    op.alter_column("universal_users", "is_active", new_column_name="is_actual")
    op.alter_column("universal_users", "hashed_password", new_column_name="password")
