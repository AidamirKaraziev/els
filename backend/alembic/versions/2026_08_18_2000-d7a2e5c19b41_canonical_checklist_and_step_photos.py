"""Один формат чек-листа и отдельная таблица под фотографии шагов

В `acts_fact.step_list_fact` за годы накопились три формы: то, что пишут
экраны, форма шаблона с подшагами и питоновский `repr` любой из них. Читать
это можно было только угадыванием, а сослаться на конкретный пункт — нечем:
номера у шага не существовало.

Миграция делает две вещи.

**Сводит колонку к канонической форме** — `{"title": ..., "steps": [{"id",
"title", "done", "comment"}]}`. Разбор берётся из `src/services/checklist.py`,
а не переписывается здесь: разъедься эти два разбора, миграция превратила бы
часть чек-листов в пустые. Плата за это — миграция зависит от кода приложения,
поэтому трогать разбор форм в сервисе после выката нельзя.

**Вынимает снимки, встроенные прямо в шаги.** Мобильное приложение клало в
поле `photo` байты картинки массивом чисел, и строка акта разрасталась до
сотен килобайт. Снимки уезжают файлами в `static/act_fact_step_photo/{id
акта}/photo/`, а в базе остаётся путь — ровно как у фотографий заявок.

**Порядок важен: строка акта переписывается только после того, как файл лёг на
диск.** Иначе неудачная запись файла стала бы тихой потерей фотографии. Акт, у
которого хоть один снимок не удалось ни разобрать, ни сохранить, не трогаем
вовсе — его id пишется в лог, и разбираться с ним нужно руками.

Откат возвращает колонку в форму экранов (`numberTo` / `stepListTO`) вместе с
номерами шагов, так что повторный накат ничего не перемешает. Вынутые файлы
откат в строку не возвращает: они остаются на диске, а таблица с путями
удаляется. Акты, которые накат пропустил, откат тоже не трогает — иначе он
выбросил бы из строки ровно те снимки, ради которых накат её и не переписал.

Revision ID: d7a2e5c19b41
Revises: c5f1a8b34e70
Create Date: 2026-08-18 20:00:00.000000

"""

import logging
import os
import uuid

import sqlalchemy as sa
from alembic import op

from src.services.checklist import (
    dump_legacy,
    extract_step_photos,
    parse_checklist,
    to_canonical,
)

revision = "d7a2e5c19b41"
down_revision = "c5f1a8b34e70"
branch_labels = None
depends_on = None

logger = logging.getLogger("alembic.runtime.migration")

#: Та же раскладка, что у остальных загруженных файлов:
#: `static/{сущность}/{id записи}/{вид}/{случайное имя}`.
_PATH_MODEL = "act_fact_step_photo"
_PATH_TYPE = "photo"
_STATIC_ROOT = "./static/"

_TABLE = "acts_fact_step_photos"


def _save(act_id: int, data: bytes, suffix: str) -> str:
    """Кладёт снимок на диск и отдаёт относительный путь для базы."""
    folder = os.path.join(_STATIC_ROOT, _PATH_MODEL, str(act_id), _PATH_TYPE)
    os.makedirs(folder, exist_ok=True)
    filename = uuid.uuid4().hex + suffix
    with open(os.path.join(folder, filename), "wb") as wf:
        wf.write(data)
    return "/".join([_PATH_MODEL, str(act_id), _PATH_TYPE, filename])


def _acts(connection):
    return connection.execute(
        sa.text(
            "SELECT id, step_list_fact FROM acts_fact "
            "WHERE step_list_fact IS NOT NULL"
        )
    ).fetchall()


def upgrade():
    op.create_table(
        _TABLE,
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "act_fact_id",
            sa.Integer(),
            sa.ForeignKey("acts_fact.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("step_id", sa.Integer(), nullable=False),
        sa.Column("photo", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index(
        "ix_acts_fact_step_photos_act_step", _TABLE, ["act_fact_id", "step_id"]
    )

    connection = op.get_bind()
    skipped = []
    saved = 0

    for act_id, raw in _acts(connection):
        photos, unreadable = extract_step_photos(raw)
        if unreadable:
            # В поле `photo` что-то лежало, но картинкой не оказалось.
            # Перезаписать акт — значит потерять это навсегда.
            skipped.append(act_id)
            continue

        try:
            paths = [
                (step_id, _save(act_id, data, suffix))
                for step_id, data, suffix in photos
            ]
        except OSError as error:
            logger.warning("Акт %s: снимок не записан на диск (%s)", act_id, error)
            skipped.append(act_id)
            continue

        for step_id, path in paths:
            connection.execute(
                sa.text(
                    f"INSERT INTO {_TABLE} "  # noqa: S608
                    "(act_fact_id, step_id, photo, created_at) "
                    "VALUES (:act_id, :step_id, :photo, now())"
                ),
                {"act_id": act_id, "step_id": step_id, "photo": path},
            )
        saved += len(paths)

        connection.execute(
            sa.text("UPDATE acts_fact SET step_list_fact = :value WHERE id = :id"),
            {"value": to_canonical(raw), "id": act_id},
        )

    logger.info("Чек-листы сведены к одной форме, снимков вынуто: %s", saved)
    if skipped:
        logger.warning(
            "Акты, оставленные как есть (снимок не разобрался): %s",
            ", ".join(str(act_id) for act_id in skipped),
        )


def downgrade():
    connection = op.get_bind()

    for act_id, raw in _acts(connection):
        # Акт, у которого снимок так и остался внутри строки, не трогаем: накат
        # его пропустил именно потому, что вынуть снимок не смог, а откат
        # переписал бы строку и выбросил бы его насовсем.
        photos, unreadable = extract_step_photos(raw)
        if photos or unreadable:
            continue
        connection.execute(
            sa.text("UPDATE acts_fact SET step_list_fact = :value WHERE id = :id"),
            {"value": dump_legacy(parse_checklist(raw)), "id": act_id},
        )

    op.drop_index("ix_acts_fact_step_photos_act_step", table_name=_TABLE)
    op.drop_table(_TABLE)
