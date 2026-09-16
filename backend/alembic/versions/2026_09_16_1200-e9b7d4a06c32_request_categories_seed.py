"""fault_category: категории заявок, которые заводят руками

Справочник рождался под аварии: AA, А, В, Н, Д, С — тяжесть отказа. Работа,
которую прораб заводит с сайта сам — ремонт по заявке, замена запчастей,
предписание надзора, документы, — в нём никак не называлась, и форма «Новая
работа» не могла предложить ничего, кроме «ТО» и «Капремонт». Категория
с `counts_as_breakdown=false` даёт заявке вид «Заявка» в ленте
(`services/work_kind.py`), а её код становится бейджем строки.

Имена — по конвенции справочника «КОД (Описание)», как у засеянных
изначально. Вставка по `name` только если такой ещё нет: на боевой базе
админ мог завести часть категорий руками, и второй «Ремонт по заявке» с
`UNIQUE(name)` уронил бы миграцию. id — следующий за наибольшим, но не
меньше 11: на пустой базе миграция идёт раньше `init_db`, и автоинкремент
занял бы 1–10, на которые тот сеет аварийные категории с явными id.

Revision ID: e9b7d4a06c32
Revises: d8a6c3f95b21
Create Date: 2026-09-16 12:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "e9b7d4a06c32"
down_revision: Union[str, None] = "d8a6c3f95b21"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# (код, имя) — всё «Заявка», поломкой не считается.
REQUEST_CATEGORIES = (
    ("Р", "Р (Ремонт по заявке)"),
    ("НЛ", "НЛ (Наладка и регулировка)"),
    ("ЗЧ", "ЗЧ (Замена запчастей)"),
    ("О", "О (Осмотр по обращению)"),
    ("ПР", "ПР (Предписание надзора)"),
    ("М", "М (Модернизация)"),
    ("УБ", "УБ (Приямок и машинное помещение)"),
    ("ДОК", "ДОК (Документы и организационное)"),
    ("ДР", "ДР (Другое)"),
)

_fault_category = sa.table(
    "fault_category",
    sa.column("id", sa.Integer),
    sa.column("name", sa.String),
    sa.column("code", sa.String),
    sa.column("counts_as_breakdown", sa.Boolean),
)


def upgrade() -> None:
    conn = op.get_bind()
    existing = {
        row[0] for row in conn.execute(sa.select(_fault_category.c.name)).fetchall()
    }
    next_id = max(
        11,
        (conn.execute(sa.select(sa.func.max(_fault_category.c.id))).scalar() or 0) + 1,
    )
    for code, name in REQUEST_CATEGORIES:
        if name in existing:
            continue
        conn.execute(
            _fault_category.insert().values(
                id=next_id, name=name, code=code, counts_as_breakdown=False
            )
        )
        next_id += 1
    # После вставки с явными id последовательность отстаёт — подтягиваем,
    # чтобы следующая категория из админки не упала на дубле ключа.
    conn.execute(
        sa.text(
            "SELECT setval(pg_get_serial_sequence('fault_category', 'id'), "
            "(SELECT COALESCE(MAX(id), 1) FROM fault_category))"
        )
    )


def downgrade() -> None:
    names = [name for _, name in REQUEST_CATEGORIES]
    op.execute(_fault_category.delete().where(_fault_category.c.name.in_(names)))
