"""Трёхграммные индексы под поиск по объектам

Лупа в разделе «Графики» ищет вхождение: `name ILIKE '%спорт%'`. Обычный
btree такой запрос не ускоряет вовсе — индекс упорядочен по началу строки, а
шаблон начинается с `%`, и планировщик честно идёт последовательным чтением
всей таблицы. На каждый набранный символ.

Поэтому GIN по трёхграммам (`pg_trgm`): он индексирует куски строки по три
символа и как раз отвечает на вопрос «где встречается подстрока».

Расширение ставится `IF NOT EXISTS` и в `downgrade` не снимается: его могли
поставить не мы, и снести его — значит уронить чужие индексы. Создание
расширения требует прав суперпользователя; если у прод-роли их нет, миграция
упадёт здесь, и расширение надо поставить руками до выката.

Revision ID: b6e4a9d31c05
Revises: a8d3f5b27c14
Create Date: 2026-08-26 12:00:00.000000

"""

from alembic import op

revision = "b6e4a9d31c05"
down_revision = "a8d3f5b27c14"
branch_labels = None
depends_on = None

# Колонки, по которым ищет `ilike_any` в `crud_schedules._search_condition`.
_COLUMNS = ("name", "factory_number", "address")


def upgrade():
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    for column in _COLUMNS:
        op.execute(
            f"CREATE INDEX IF NOT EXISTS ix_objects_{column}_trgm "
            f"ON objects USING gin ({column} gin_trgm_ops)"
        )


def downgrade():
    for column in _COLUMNS:
        op.execute(f"DROP INDEX IF EXISTS ix_objects_{column}_trgm")
