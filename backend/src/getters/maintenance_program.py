"""Сборка ответов по программе обслуживания и предложение по умолчанию.

Предложение считается на лету и в базу не пишется: пока прораб его не
сохранил, это не программа, а подсказка. Отдельной ручкой, а не полем в
ответе по программе, — чтобы «сбросить к предложенному» работало и тогда,
когда программа уже есть.
"""

from typing import Dict, Iterable, List, Optional

from src.schemas.maintenance_program import (
    PROGRAM_LENGTH,
    MaintenanceProgramItemOut,
    MaintenanceProgramOut,
    MaintenanceProgramSuggestion,
    MaintenanceProgramSuggestionItem,
)

#: Периодичности по убыванию. `id` вида ТО в справочнике равен периодичности в
#: месяцах (`core/db/init_db.py`), поэтому период и есть `type_act_id`.
_PERIODS = (12, 6, 3, 1)


def get_maintenance_program(program) -> MaintenanceProgramOut:
    return MaintenanceProgramOut(
        id=program.id,
        factory_model_id=program.factory_model_id,
        name=program.name,
        updated_at=program.updated_at,
        items=[
            MaintenanceProgramItemOut(
                position=item.position,
                type_act_id=item.type_act_id,
                type_act_name=item.type_act.name if item.type_act else None,
            )
            for item in sorted(program.items, key=lambda item: item.position)
        ],
    )


def suggest_program(
    *,
    factory_model_id: int,
    available_type_act_ids: Iterable[int],
    type_act_names: Optional[Dict[int, str]] = None,
) -> MaintenanceProgramSuggestion:
    """Предложить программу по умолчанию.

    Правило: позиция `k` получает ТО12 при `k % 12 == 0`, иначе ТО6 при
    `k % 6 == 0`, иначе ТО3 при `k % 3 == 0`, иначе ТО1 — то есть наибольшую
    периодичность, на которую позиция делится.

    Предлагаются только те виды, на которые у модели есть шаблон чек-листа:
    у модели с шаблонами лишь на ТО1 и ТО12 двенадцатая позиция остаётся
    ТО12, а шестая опускается до ТО1. Если не подошёл ни один вид, позиция
    приходит пустой, а недостающие виды перечислены в `missing_type_act_ids`
    — мастер обязан назвать, чего не хватает, а не подставить чужое ТО.
    """
    available = set(available_type_act_ids)
    names = type_act_names or {}

    items: List[MaintenanceProgramSuggestionItem] = []
    missing = set()
    for position in range(1, PROGRAM_LENGTH + 1):
        divisors = [period for period in _PERIODS if position % period == 0]
        chosen = next((period for period in divisors if period in available), None)
        if divisors and divisors[0] not in available:
            # Недостающим называем то, что хотело правило, а не то, чем
            # пришлось обойтись: у модели с шаблонами только на ТО1 и ТО12
            # шестая позиция опустится до ТО1, но завести-то надо ТО6.
            missing.add(divisors[0])
        items.append(
            MaintenanceProgramSuggestionItem(
                position=position,
                type_act_id=chosen,
                type_act_name=names.get(chosen) if chosen else None,
            )
        )

    return MaintenanceProgramSuggestion(
        factory_model_id=factory_model_id,
        items=items,
        available_type_act_ids=sorted(available),
        missing_type_act_ids=sorted(missing),
    )
