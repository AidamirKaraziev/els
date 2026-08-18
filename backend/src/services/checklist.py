"""Разбор чек-листа фактического акта.

`acts_fact.step_list_fact` — колонка `String` без схемы, и за годы в ней
накопилось **три разных формы**. Разбирать их порознь в каждом потребителе
нельзя: разъедутся, и отчёт заказчику разойдётся с экраном механика.

1. **Что пишут оба фронта сегодня.** Словарь с названием ТО и списком шагов,
   причём список лежит внутри **ещё одной строкой**:

       {"numberTo": "ТО-1", "stepListTO": "[{\\"text\\": \\"...\\", \\"bool\\": true}]"}

   Мобильное приложение добавляет к шагу `comment` и `photo`.

2. **Форма шаблона** `src/steplist_tamplate.json` — список шагов с подшагами
   (`step_name`, `substeps`). В базе встречается там, где акт заводили не
   через экран графика.

3. **Питоновский repr** любой из первых двух: строка приходила в базу через
   `str(...)`, и одинарные кавычки делают её невалидным JSON. Подробности:
   [[чек-лист акта хранится питоновским repr, а не JSON]].

Пустой список означает **«чек-лист не заполнен»**, а не «работ не было», и
экран обязан говорить это разными словами.
"""

import ast
import json
from typing import Any, List, NamedTuple, Optional

#: Что считаем отметкой «сделано». Справочника статусов не существует: значения
#: пишет фронт, и встречаются и строки, и булевы.
_DONE_MARKS = frozenset(
    {"true", "1", "да", "выполнено", "готово", "done", "yes", "ок", "ok"}
)


class ChecklistStep(NamedTuple):
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


def _steps_from_template(items: list) -> List[ChecklistStep]:
    """Форма шаблона: шаги с подшагами.

    Подшаги разворачиваются в те же строки, что и шаги: в отчёте клиенту важен
    перечень сделанного, а не глубина вложенности бланка.
    """
    steps: List[ChecklistStep] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        name = item.get("step_name")
        if name:
            steps.append(
                ChecklistStep(title=str(name), done=is_done(item.get("step_status")))
            )
        for sub in item.get("substeps") or []:
            if not isinstance(sub, dict):
                continue
            sub_name = sub.get("substep_name")
            if sub_name:
                steps.append(
                    ChecklistStep(
                        title=str(sub_name), done=is_done(sub.get("substep_status"))
                    )
                )
    return steps


def _steps_from_front(items: list) -> List[ChecklistStep]:
    """Форма фронтов: плоский список `{text, bool, comment, photo}`."""
    steps: List[ChecklistStep] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        title = item.get("text")
        if not title:
            continue
        comment = item.get("comment")
        steps.append(
            ChecklistStep(
                title=str(title),
                done=is_done(item.get("bool")),
                comment=str(comment) if comment else None,
                has_photo=bool(item.get("photo")),
            )
        )
    return steps


def _steps(items: list) -> List[ChecklistStep]:
    """Форму выбираем по содержимому, а не по надежде на порядок в базе."""
    template = _steps_from_template(items)
    if template:
        return template
    return _steps_from_front(items)


def parse_checklist(step_list_fact: Optional[str]) -> Checklist:
    raw = _loads(step_list_fact)

    if isinstance(raw, dict):
        # Список шагов лежит внутри строкой — её надо разобрать ещё раз.
        inner = _loads(raw.get("stepListTO"))
        items = inner if isinstance(inner, list) else []
        number = raw.get("numberTo")
        return Checklist(
            title=str(number) if number else None,
            steps=_steps(items),
        )

    if isinstance(raw, list):
        return Checklist(title=None, steps=_steps(raw))

    return Checklist(title=None, steps=[])
