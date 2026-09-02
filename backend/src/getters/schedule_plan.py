"""Раскладка программы обслуживания на календарный год.

Считается на лету и в базу не пишется — как предложение программы в
`getters/maintenance_program.py`. Пока человек не нажал «создать график»,
это заготовка, а не план.

Здесь нет обращений к базе намеренно: правило «какая позиция цикла в каком
месяце» проверяется тестами без сессии, а всё, что нужно из базы, приносит
ручка.
"""

from typing import Dict, Iterable, List, Optional

from src.schemas.maintenance_program import PROGRAM_LENGTH
from src.schemas.schedule_plan import SchedulePreview, SchedulePreviewCell


def position_of(month: int, anchor_month: int) -> int:
    """Позиция программы, приходящаяся на месяц календаря.

    На `anchor_month` приходится первая позиция, дальше цикл идёт по кругу.
    Цикл длиной двенадцать и год длиной двенадцать месяцев совпадают,
    поэтому через границу года раскладка повторяется: якорь следующего года
    равен якорю прошлого, и «продолжить цикл» — это взять тот же якорь.
    """
    return ((month - anchor_month) % PROGRAM_LENGTH) + 1


def detect_anchor(
    *,
    program_by_position: Dict[int, int],
    known_type_acts: Dict[int, Optional[int]],
) -> Optional[int]:
    """Восстановить якорь цикла по уже расставленному году.

    Позиция программы в базе не хранится — в `planned_to` лежат только акты.
    Поэтому якорь не читается, а подбирается: ищем сдвиг, при котором виды
    ТО всех заполненных месяцев года совпадают с программой.

    Год сюда приходит любой: и прошлый, из которого цикл продолжается, и сам
    расставляемый, если его уже трогали. Правило одно и то же, поэтому и
    аргумент называется по смыслу, а не по году.

    Ответ отдаётся, только если сдвиг **один**. Ни одного — год расставлен не
    по этой программе; несколько — по нему цикл не опознать (например,
    заполнен один месяц, а ТО1 в программе стоит на восьми позициях). В обоих
    случаях якорь обязан назвать человек: молча выбрать за него — значит
    сдвинуть весь год и не сказать об этом.
    """
    known = {
        month: type_act_id
        for month, type_act_id in known_type_acts.items()
        if type_act_id is not None
    }
    if not known:
        return None

    candidates = [
        anchor
        for anchor in range(1, PROGRAM_LENGTH + 1)
        if all(
            program_by_position.get(position_of(month, anchor)) == type_act_id
            for month, type_act_id in known.items()
        )
    ]
    return candidates[0] if len(candidates) == 1 else None


def build_preview(
    *,
    object_id: int,
    year: int,
    anchor_month: int,
    program_id: int,
    factory_model_id: int,
    program_by_position: Dict[int, int],
    type_act_names: Dict[int, str],
    available_type_act_ids: Iterable[int],
    occupied_months: Iterable[int],
) -> SchedulePreview:
    """Двенадцать клеток года: месяц, позиция цикла, вид ТО и две пометки.

    `occupied` — месяц уже занят актом, создание графика его не тронет.
    `template_missing` — у модели нет шаблона чек-листа на этот вид ТО;
    клетка всё равно показывается, но утвердить такой график нельзя.
    """
    available = set(available_type_act_ids)
    occupied = set(occupied_months)

    cells: List[SchedulePreviewCell] = []
    for month in range(1, PROGRAM_LENGTH + 1):
        position = position_of(month, anchor_month)
        type_act_id = program_by_position[position]
        cells.append(
            SchedulePreviewCell(
                month=month,
                position=position,
                type_act_id=type_act_id,
                type_act_name=type_act_names.get(type_act_id),
                occupied=month in occupied,
                template_missing=type_act_id not in available,
            )
        )

    return SchedulePreview(
        object_id=object_id,
        year=year,
        anchor_month=anchor_month,
        factory_model_id=factory_model_id,
        program_id=program_id,
        cells=cells,
    )
