"""Чек-лист фактического акта: одна каноническая форма и разбор всего старого.

`acts_fact.step_list_fact` — колонка `String` без схемы, и за годы в ней
накопилось **три разных формы**. Разбирать их порознь в каждом потребителе
нельзя: разъедутся, и отчёт заказчику разойдётся с экраном механика.

1. **Что писали оба фронта.** Словарь с названием ТО и списком шагов,
   причём список лежит внутри **ещё одной строкой**:

       {"numberTo": "ТО-1", "stepListTO": "[{\\"text\\": \\"...\\", \\"bool\\": true}]"}

   Мобильное приложение добавляло к шагу `comment` и `photo`, причём в `photo`
   клало **сами байты снимка** массивом чисел.

2. **Форма шаблона** `src/steplist_tamplate.json` — список шагов с подшагами
   (`step_name`, `substeps`). В базе встречается там, где акт заводили не
   через экран графика.

3. **Питоновский repr** любой из первых двух: строка приходила в базу через
   `str(...)`, и одинарные кавычки делают её невалидным JSON. Подробности:
   [[чек-лист акта хранится питоновским repr, а не JSON]].

**Каноническая форма**, к которой всё это сводит миграция `d7a2e5c19b41`, и
единственная, которую пишем дальше:

    {"title": "ТО-1",
     "steps": [{"id": 1, "title": "Выключить вводное устройство",
                "done": true, "comment": null}]}

`id` — номер шага внутри акта, и он **обязан быть стабильным**: именно на него
ссылается фотография в `acts_fact_step_photos`. Поэтому переставлять и удалять
шаги после начала работ нельзя, а новый шаг получает следующий свободный
номер, а не занимает освободившийся.

Наружу по старым адресам чек-лист по-прежнему уходит **в форме фронтов** —
`dump_legacy`. Экран графика у прораба работает в проде и читает именно её;
менять хранение можно, ломать ответ нельзя.

Пустой список означает **«чек-лист не заполнен»**, а не «работ не было», и
экран обязан говорить это разными словами.
"""

import ast
import base64
import json
from typing import Any, List, NamedTuple, Optional, Tuple

#: Что считаем отметкой «сделано». Справочника статусов не существует: значения
#: пишет фронт, и встречаются и строки, и булевы.
_DONE_MARKS = frozenset(
    {"true", "1", "да", "выполнено", "готово", "done", "yes", "ок", "ok"}
)

#: Сигнатуры картинок, которые узнаём в байтах встроенного фото. Расширение
#: угадываем по содержимому, а не по вере: имени файла в базе не было вовсе.
_IMAGE_MAGIC = (
    (b"\x89PNG\r\n\x1a\n", ".png"),
    (b"\xff\xd8\xff", ".jpg"),
    (b"GIF87a", ".gif"),
    (b"GIF89a", ".gif"),
)


class ChecklistStep(NamedTuple):
    #: Номер шага внутри акта. На него ссылается фотография шага.
    id: int
    title: str
    done: bool
    comment: Optional[str] = None
    has_photo: bool = False


class Checklist(NamedTuple):
    #: Название ТО из графика — «ТО-1», «ТО-3». Пустое, если формы не было.
    title: Optional[str]
    steps: List[ChecklistStep]

    @property
    def total(self) -> int:
        return len(self.steps)

    @property
    def done(self) -> int:
        return sum(1 for step in self.steps if step.done)


def is_done(status: Any) -> bool:
    if isinstance(status, bool):
        return status
    if status is None:
        return False
    return str(status).strip().lower() in _DONE_MARKS


def _loads(raw: Any) -> Any:
    """JSON, а если не вышло — питоновский repr. На мусоре отдаёт None."""
    if not isinstance(raw, str) or not raw.strip():
        return None
    for parse in (json.loads, ast.literal_eval):
        try:
            return parse(raw)
        except (ValueError, SyntaxError, TypeError):
            continue
    return None


def _step_id(value: Any) -> int:
    """Номер шага из данных. Ноль означает «своего номера нет»."""
    if isinstance(value, bool) or not isinstance(value, (int, str)):
        return 0
    try:
        number = int(value)
    except (TypeError, ValueError):
        return 0
    return number if number > 0 else 0


#: Шаг вместе с сырым содержимым поля `photo`. Разбор ведём парами, чтобы
#: миграция вынимала снимки ровно из тех шагов, чьи номера она же и присвоила:
#: разойдись эти два обхода — фотография привязалась бы к чужому пункту.
_Parsed = Tuple[ChecklistStep, Any]


def _steps_from_template(items: list) -> List[_Parsed]:
    """Форма шаблона: шаги с подшагами.

    Подшаги разворачиваются в те же строки, что и шаги: в отчёте клиенту важен
    перечень сделанного, а не глубина вложенности бланка.
    """
    steps: List[_Parsed] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        name = item.get("step_name")
        if name:
            steps.append(
                (
                    ChecklistStep(
                        id=0, title=str(name), done=is_done(item.get("step_status"))
                    ),
                    None,
                )
            )
        for sub in item.get("substeps") or []:
            if not isinstance(sub, dict):
                continue
            sub_name = sub.get("substep_name")
            if sub_name:
                steps.append(
                    (
                        ChecklistStep(
                            id=0,
                            title=str(sub_name),
                            done=is_done(sub.get("substep_status")),
                        ),
                        None,
                    )
                )
    return steps


def _steps_from_front(items: list) -> List[_Parsed]:
    """Форма фронтов: плоский список `{text, bool, comment, photo}`."""
    steps: List[_Parsed] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        title = item.get("text")
        if not title:
            continue
        comment = item.get("comment")
        photo = item.get("photo")
        steps.append(
            (
                ChecklistStep(
                    id=_step_id(item.get("id")),
                    title=str(title),
                    done=is_done(item.get("bool")),
                    comment=str(comment) if comment else None,
                    has_photo=bool(photo),
                ),
                photo,
            )
        )
    return steps


def _steps_from_canonical(items: list) -> List[_Parsed]:
    """Каноническая форма: `{id, title, done, comment}`."""
    steps: List[_Parsed] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        title = item.get("title")
        if not title:
            continue
        comment = item.get("comment")
        steps.append(
            (
                ChecklistStep(
                    id=_step_id(item.get("id")),
                    title=str(title),
                    done=is_done(item.get("done")),
                    comment=str(comment) if comment else None,
                ),
                None,
            )
        )
    return steps


def _steps(items: list) -> List[_Parsed]:
    """Форму выбираем по содержимому, а не по надежде на порядок в базе."""
    for build in (_steps_from_template, _steps_from_canonical, _steps_from_front):
        steps = build(items)
        if steps:
            return steps
    return []


def _assign_ids(parsed: List[_Parsed]) -> List[_Parsed]:
    """Проставляет номера шагам, у которых своего нет.

    Чужой номер не отбираем и повторный не оставляем: два шага с одним номером
    означали бы, что фотография принадлежит сразу двум пунктам.
    """
    # Чужие номера собираем первым проходом: иначе шаг без номера успел бы
    # занять тот, который дальше по списку уже кому-то принадлежит.
    taken = {step.id for step, _ in parsed if step.id}
    given = set()
    result: List[_Parsed] = []
    free = 1
    for step, photo in parsed:
        if step.id and step.id not in given:
            given.add(step.id)
            result.append((step, photo))
            continue
        while free in taken or free in given:
            free += 1
        given.add(free)
        result.append((step._replace(id=free), photo))
    return result


def _parse(step_list_fact: Optional[str]) -> Tuple[Optional[str], List[_Parsed]]:
    raw = _loads(step_list_fact)

    if isinstance(raw, dict):
        # Каноническая форма держит список шагов списком, форма фронтов —
        # ещё одной строкой внутри. Разбираем по тому, что нашли.
        canonical = raw.get("steps")
        if isinstance(canonical, list):
            title = raw.get("title")
            return (str(title) if title else None), _assign_ids(_steps(canonical))

        inner = _loads(raw.get("stepListTO"))
        items = inner if isinstance(inner, list) else []
        number = raw.get("numberTo")
        return (str(number) if number else None), _assign_ids(_steps(items))

    if isinstance(raw, list):
        return None, _assign_ids(_steps(raw))

    return None, []


def parse_checklist(step_list_fact: Optional[str]) -> Checklist:
    """Чек-лист из колонки, в какой бы из форм он там ни лежал."""
    title, parsed = _parse(step_list_fact)
    return Checklist(title=title, steps=[step for step, _ in parsed])


def dump_checklist(checklist: Checklist) -> str:
    """Каноническая форма строкой — то, что кладём в базу."""
    return json.dumps(
        {
            "title": checklist.title,
            "steps": [
                {
                    "id": step.id,
                    "title": step.title,
                    "done": step.done,
                    "comment": step.comment,
                }
                for step in checklist.steps
            ],
        },
        ensure_ascii=False,
    )


def dump_legacy(checklist: Checklist) -> str:
    """Форма фронтов строкой — то, что отдаём по старым адресам.

    Номер шага кладём и сюда, лишним ключом: экран графика читает только
    `text`, но пересохраняет пункт целиком — значит, номер переживёт правку
    чек-листа старым экраном, и фотографии не переедут на соседние пункты.
    """
    return json.dumps(
        {
            "numberTo": checklist.title or "",
            "stepListTO": json.dumps(
                [
                    {
                        "id": step.id,
                        "text": step.title,
                        "bool": step.done,
                        "comment": step.comment,
                    }
                    for step in checklist.steps
                ],
                ensure_ascii=False,
            ),
        },
        ensure_ascii=False,
    )


def canonical_from_items(title: Optional[str], items: List[Any]) -> str:
    """Каноническая форма из уже разобранных шагов — то, что шлёт телефон.

    Ждёт словари с ключами канонической формы. Шаг без номера получает
    следующий свободный: клиент, приславший пункт без `id`, завёл новый пункт,
    а не переименовал старый, и фотографии прежнего к нему не перейдут.
    """
    parsed = _assign_ids(_steps_from_canonical(list(items)))
    return dump_checklist(
        Checklist(title=title or None, steps=[step for step, _ in parsed])
    )


def to_canonical(step_list_fact: Optional[str]) -> Optional[str]:
    """Приводит любую накопившуюся форму к канонической. Пустое — пустым."""
    if step_list_fact is None:
        return None
    return dump_checklist(parse_checklist(step_list_fact))


def photo_bytes(payload: Any) -> Tuple[Optional[bytes], Optional[str]]:
    """Байты и расширение встроенного в шаг снимка.

    Мобильное приложение клало в поле `photo` `Uint8List` — то есть список
    чисел. Возвращаем `(None, None)`, если содержимое не похоже на картинку:
    миграция на таком не гадает, а оставляет акт в покое.
    """
    data: Optional[bytes] = None

    if isinstance(payload, (bytes, bytearray)):
        data = bytes(payload)
    elif isinstance(payload, list) and payload:
        if all(isinstance(b, int) and not isinstance(b, bool) for b in payload) and all(
            0 <= b <= 255 for b in payload
        ):
            data = bytes(payload)
    elif isinstance(payload, str) and payload.strip():
        # base64 — на случай, если снимок дошёл до базы через веб.
        text = payload.split(",", 1)[-1] if payload.startswith("data:") else payload
        try:
            data = base64.b64decode(text, validate=True)
        except (ValueError, TypeError):
            data = None

    if not data:
        return None, None

    for magic, suffix in _IMAGE_MAGIC:
        if data.startswith(magic):
            return data, suffix
    return None, None


def extract_step_photos(
    step_list_fact: Optional[str],
) -> Tuple[List[Tuple[int, bytes, str]], bool]:
    """Снимки, встроенные прямо в шаги, — для миграции.

    Отдаёт список `(номер шага, байты, расширение)` и признак «что-то в поле
    `photo` было, но картинкой не оказалось». По второму миграция понимает,
    что акт трогать нельзя: перезапиши она строку — снимок исчез бы навсегда.
    """
    _, parsed = _parse(step_list_fact)

    photos: List[Tuple[int, bytes, str]] = []
    unreadable = False
    for step, payload in parsed:
        if not payload:
            continue
        data, suffix = photo_bytes(payload)
        if data is None:
            unreadable = True
            continue
        photos.append((step.id, data, suffix))
    return photos, unreadable
