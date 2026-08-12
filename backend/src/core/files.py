"""Пути к загруженным файлам: безопасная склейка и разбор владельца.

Здесь нет ни базы, ни HTTP — только работа со строкой пути. Кто имеет право
скачать файл, решает `src/services/file_access.py`.

## Как устроен путь

Файлы складывает `CRUDBase.adding_file`, и путь у всех одинаковый:

    <сущность>/<id записи>/<вид файла>/<случайное имя>.<расширение>

Например `objects/12/act_pto/9f3c…pdf` или `order_photo/5/photo/1a2b….jpg`.
Первые два сегмента — это и есть ответ на вопрос «чей файл», и по ним
проверяется доступ.

## Почему склейка была опасной

Раньше ручка делала `"static/" + filename`, где `filename` приходит как
`{filename:path}`, то есть вместе со слэшами. Строка `../.env` превращалась в
`static/../.env` — путь за пределы каталога с загруженными файлами. Ни один
тест на это не падал: ручка честно отдавала файл.
"""

import os
from pathlib import Path
from typing import NamedTuple, Optional

#: Куда `CRUDBase.adding_file` кладёт файлы. Путь относительный, потому что
#: рабочий каталог у приложения и в контейнере, и локально — корень бэкенда.
STATIC_ROOT = Path("static")


class FileOwner(NamedTuple):
    """Чей это файл: сущность и id записи."""

    entity: str
    record_id: int
    kind: str


class ResolvedFile(NamedTuple):
    """Файл внутри `static/`: где он лежит и каким путём называется.

    `relative` — это путь **после** раскрытия `..` и симлинков. Именно по нему
    определяется владелец: иначе строка `objects/1/act_pto/../../../.env`
    читалась бы как «файл объекта №1», хотя ведёт она на `static/.env`. Проверка
    доступа сказала бы «да» тому, кто видит объект №1, и отдала бы совсем
    другой файл.
    """

    path: Path
    relative: str


def resolve_static_path(filename: str) -> Optional[ResolvedFile]:
    """Файл внутри `static/` — или None, если путь ведёт наружу.

    Проверяется не строка, а результат: путь раскрывается целиком
    (`..`, симлинки, лишние слэши) и сверяется с корнем. Проверять подстроки
    вроде `".." in filename` бессмысленно — экранирований у пути слишком много,
    а `os.path.realpath` знает про все.
    """
    if not filename:
        return None

    root = STATIC_ROOT.resolve()
    candidate = Path(os.path.realpath(root / filename))

    if candidate == root or root not in candidate.parents:
        # Сам корень тоже не отдаём: это каталог, а не файл.
        return None
    return ResolvedFile(path=candidate, relative=candidate.relative_to(root).as_posix())


def parse_owner(filename: str) -> Optional[FileOwner]:
    """Разбирает путь на «чей файл». None, если путь не той формы.

    None означает отказ, а не «файл ничей»: неизвестная форма пути — это либо
    файл, положенный в обход `adding_file`, либо попытка подобрать адрес.
    Открывать такое по умолчанию нельзя, поэтому разбор строгий.
    """
    parts = [part for part in filename.split("/") if part]
    if len(parts) < 3:
        return None

    entity, record_id, kind = parts[0], parts[1], parts[2]
    if not record_id.isdigit():
        return None

    return FileOwner(entity=entity, record_id=int(record_id), kind=kind)
