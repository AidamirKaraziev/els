"""Балл сотрудника для виджета «Топ сотрудников».

Формула живёт здесь, а не в SQL, и намеренно: балл — это договорённость с
заказчиком, а не свойство базы. Правило, записанное чистыми функциями, можно
проверить тестами без Postgres, показать человеку и поменять в одном месте,
когда договорённость изменится.

Что считается идеальной работой
-------------------------------
Формулировка заказчика: сотрудник делает плановые ТО своих объектов вовремя,
его лифты редко ломаются, на аварию он реагирует быстро, после его починки
лифт повторно не встаёт, и он тянет сложную работу. Отсюда четыре метрики и
один штраф.

Шкала — по нормативам, а не относительно лучшего
------------------------------------------------
«87» должно означать «близко к норме» и быть сравнимым между месяцами. Если
месяц провальный у всех, это должно быть видно, а не спрятано нормировкой по
лучшему в выборке. Исключение одно — объём работ: нормы выработки («сколько
работ в месяц — это нормально») в компании нет, придумать её за заказчика
нельзя, поэтому объём пока меряется медианой по выборке. Как только норма
появится, `WORK_UNITS_NORM` перестаёт быть `None`, и метрика становится
абсолютной, как остальные.

Метрика без данных не считается
-------------------------------
Механик, у которого в этом месяце не было ни одного планового ТО, не получает
ноль за своевременность: метрика выпадает, а её вес распределяется между
остальными. Иначе балл наказывал бы за то, чего человеку не поручали.
"""

import datetime
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional, Sequence

# ---------------------------------------------------------------------------
# Договорённости в числах
# ---------------------------------------------------------------------------

#: Веса метрик. Сумма — 100, но на это никто не опирается: веса метрик,
#: которые не удалось посчитать, перераспределяются пропорционально.
WEIGHTS: Dict[str, float] = {
    "timeliness": 25.0,
    "reaction": 25.0,
    "workload": 30.0,
    "reliability": 20.0,
}

#: Штраф за переделки вычитается из собранного балла, а не входит в веса:
#: это наказание, а не пятая сторона работы.
REPEAT_PENALTY_MAX = 15.0
#: Доля переделок, начиная с которой штраф полный.
REPEAT_PENALTY_FULL_SHARE = 0.30
#: Сколько дней после закрытия заявки авария на том же лифте считается
#: переделкой. Совпадения причины не требуем: поле причины заполняют не всегда.
REPEAT_WINDOW_DAYS = 14

#: Меньше этого числа работ за месяц — строка помечается «мало данных»,
#: уезжает в конец списка и не попадает ни в лучших, ни в худших. Отпуск не
#: повод ни для премии, ни для разбора.
MIN_WORKS_FOR_RANKING = 3

#: Выезд на чужой лифт весит больше: человек ехал на незнакомый объект
#: выручать коллегу.
OTHER_OBJECT_BONUS = 1.25

#: Норма выработки в условных единицах за месяц. `None` — нормы нет, объём
#: меряется медианой по выборке. Заказчик назовёт число — поставить сюда.
WORK_UNITS_NORM: Optional[float] = None

#: Вес аварии по тяжести категории. Коды — из справочника `fault_category`,
#: порядок тяжести там задан id, см. заметку про ранг категории.
SEVERITY_WEIGHT: Dict[str, float] = {
    "AA": 3.0,  # застревание пассажира, опасность
    "А": 2.0,  # остановка лифта
    "В": 1.5,  # ухудшение характеристик, требуется наладка
}
DEFAULT_WORK_WEIGHT = 1.0

#: Категории, на которые едут немедленно. Норматив реакции у них свой.
URGENT_CATEGORY_CODES = frozenset({"AA", "А"})

#: Нормативы реакции в секундах: (100 баллов, 50 баллов, 0 баллов).
URGENT_REACTION_NORM = (30 * 60, 60 * 60, 120 * 60)
ROUTINE_REACTION_NORM = (24 * 3600, 48 * 3600, 72 * 3600)

#: Веса метрик прораба.
FOREMAN_WEIGHTS: Dict[str, float] = {
    "team": 50.0,
    "schedule": 30.0,
    "overdue": 20.0,
}
#: Доля лифтов участка с просроченным ТО, при которой метрика прораба
#: обнуляется. Каждый второй лифт в долгу — это уже не просчёт, а развал.
OVERDUE_ZERO_SCORE_SHARE = 0.5


# ---------------------------------------------------------------------------
# Результат
# ---------------------------------------------------------------------------


@dataclass
class EmployeeScore:
    """Строка рейтинга: балл и всё, чем он объясняется.

    Разбивка едет наружу целиком, хотя экрана «Подробнее» у виджета нет: без
    неё нельзя ответить сотруднику на вопрос «почему у меня 54».
    """

    user_id: int
    name: Optional[str]
    role_id: Optional[int]
    division: Optional[str]

    #: Итог 0–100. `None` — посчитать было не из чего.
    score: Optional[float] = None
    #: Меньше `MIN_WORKS_FOR_RANKING` работ: цифре верить рано.
    is_provisional: bool = True

    works_count: int = 0
    orders_closed: int = 0
    maintenance_total: int = 0
    maintenance_on_time: int = 0
    work_units: float = 0.0
    objects_count: int = 0
    breakdowns_on_objects: int = 0
    repeat_count: int = 0
    reacted_count: int = 0
    avg_reaction_seconds: Optional[float] = None
    repeat_penalty: float = 0.0

    metrics: Dict[str, Optional[float]] = field(default_factory=dict)


# ---------------------------------------------------------------------------
# Мелкая арифметика
# ---------------------------------------------------------------------------


def _clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def _norm_score(value: float, norm) -> float:
    """Балл по нормативу «(100, 50, 0)» с линейной серединой.

    Уложился в норматив — сто. Вдвое хуже — пятьдесят. За третьей границей —
    ноль. Ступеньки нет намеренно: человек, опоздавший на минуту, не должен
    терять половину балла.
    """
    good, fair, bad = norm
    if value <= good:
        return 100.0
    if value <= fair:
        return 100.0 - 50.0 * (value - good) / (fair - good)
    if value < bad:
        return 50.0 - 50.0 * (value - fair) / (bad - fair)
    return 0.0


def _median(values: Sequence[float]) -> Optional[float]:
    ordered = sorted(values)
    if not ordered:
        return None
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return float(ordered[middle])
    return (ordered[middle - 1] + ordered[middle]) / 2


def _weighted_total(metrics: Dict[str, Optional[float]], weights) -> Optional[float]:
    """Свод метрик с перераспределением веса непосчитанных."""
    usable = {
        name: value
        for name, value in metrics.items()
        if value is not None and name in weights
    }
    if not usable:
        return None

    total_weight = sum(weights[name] for name in usable)
    if total_weight <= 0:
        return None

    return sum(value * weights[name] for name, value in usable.items()) / total_weight


def _severity_weight(code: Optional[str]) -> float:
    """Вес аварии по коду категории.

    Незнакомый код и пустая категория весят единицу: недозаполненная заявка —
    это обычная работа, а не повод её обнулить.
    """
    if not code:
        return DEFAULT_WORK_WEIGHT
    return SEVERITY_WEIGHT.get(code.strip(), DEFAULT_WORK_WEIGHT)


def _reaction_norm(code: Optional[str]):
    if code and code.strip() in URGENT_CATEGORY_CODES:
        return URGENT_REACTION_NORM
    return ROUTINE_REACTION_NORM


# ---------------------------------------------------------------------------
# Сбор фактов по сотруднику
# ---------------------------------------------------------------------------


def _repeat_object_times(events: Iterable) -> Dict[int, List[datetime.datetime]]:
    """{object_id: [когда на нём случались поломки]} — отсортировано."""
    by_object: Dict[int, List[datetime.datetime]] = {}
    for event in events:
        if event.object_id is None or event.created_at is None:
            continue
        by_object.setdefault(event.object_id, []).append(event.created_at)
    for times in by_object.values():
        times.sort()
    return by_object


def _has_repeat(
    *,
    order,
    events_by_object: Dict[int, List[datetime.datetime]],
    window: datetime.timedelta,
) -> bool:
    """Случилась ли новая авария на том же лифте в окне после закрытия."""
    closed_at = order.closed_at
    if closed_at is None or order.object_id is None:
        return False

    deadline = closed_at + window
    for happened_at in events_by_object.get(order.object_id, ()):
        # Строго после закрытия: сама заявка в окно попадать не должна.
        if closed_at < happened_at <= deadline:
            return True
    return False


def score_employees(
    *,
    employees: Sequence,
    orders: Sequence,
    maintenance: Sequence,
    objects_per_mechanic: Dict[int, int],
    breakdowns_per_mechanic: Dict[int, int],
    breakdown_events: Sequence,
    median_steps: float,
    period_end: datetime.datetime,
    min_works: int = MIN_WORKS_FOR_RANKING,
) -> List[EmployeeScore]:
    """Балл каждого сотрудника из списка.

    На вход идут строки запросов как есть — ни одного обращения к базе здесь
    нет. Это позволяет проверить формулу на выдуманных данных и не таскать в
    тесты Postgres ради арифметики.
    """
    results: Dict[int, EmployeeScore] = {}
    for employee in employees:
        results[employee.user_id] = EmployeeScore(
            user_id=employee.user_id,
            name=employee.name,
            role_id=employee.role_id,
            division=employee.division,
        )

    events_by_object = _repeat_object_times(breakdown_events)
    window = datetime.timedelta(days=REPEAT_WINDOW_DAYS)

    # --- заявки ------------------------------------------------------------
    reaction_scores: Dict[int, List[float]] = {}
    reaction_seconds: Dict[int, List[float]] = {}
    repeat_candidates: Dict[int, int] = {}

    for order in orders:
        result = results.get(order.executor_id)
        if result is None:
            # Исполнитель не из оцениваемых ролей — например, заявку закрыл
            # прораб. В рейтинг механиков такая работа не попадает.
            continue

        result.orders_closed += 1
        weight = _severity_weight(order.category_code)
        if not order.is_own_object:
            weight *= OTHER_OBJECT_BONUS
        result.work_units += weight

        if not order.is_breakdown:
            continue

        if order.created_at is not None and order.reacted_at is not None:
            seconds = (order.reacted_at - order.created_at).total_seconds()
            # Отрицательная разница — битая запись: «приняли» раньше, чем
            # создали. Такие в среднее не пускаем.
            if seconds >= 0:
                reaction_seconds.setdefault(result.user_id, []).append(seconds)
                reaction_scores.setdefault(result.user_id, []).append(
                    _norm_score(seconds, _reaction_norm(order.category_code))
                )

        repeat_candidates[result.user_id] = repeat_candidates.get(result.user_id, 0) + 1
        if _has_repeat(order=order, events_by_object=events_by_object, window=window):
            result.repeat_count += 1

    # --- плановые ТО -------------------------------------------------------
    for act in maintenance:
        result = results.get(act.mechanic_id)
        if result is None:
            continue

        result.maintenance_total += 1
        # Вовремя — закрыто до конца планового месяца. То же определение, что
        # у виджета выполнения графика.
        if act.finished_at is not None and act.finished_at < period_end:
            result.maintenance_on_time += 1

        if act.finished_at is None:
            continue

        steps = float(act.steps_count or 0)
        if steps > 0 and median_steps:
            weight = steps / median_steps
        else:
            # Заготовка без пунктов не должна обнулять работу: акт всё равно
            # закрыт, значит человек на объект съездил.
            weight = DEFAULT_WORK_WEIGHT
        if not act.is_own_object:
            weight *= OTHER_OBJECT_BONUS
        result.work_units += weight

    # --- аварийность парка -------------------------------------------------
    total_objects = 0
    total_breakdowns = 0
    for result in results.values():
        result.objects_count = objects_per_mechanic.get(result.user_id, 0)
        result.breakdowns_on_objects = breakdowns_per_mechanic.get(result.user_id, 0)
        total_objects += result.objects_count
        total_breakdowns += result.breakdowns_on_objects

    average_rate = total_breakdowns / total_objects if total_objects else None

    # --- объём: медиана по тем, кто в этом месяце работал ------------------
    worked_units = [
        result.work_units for result in results.values() if result.work_units > 0
    ]
    median_units = _median(worked_units)

    # --- сборка ------------------------------------------------------------
    for result in results.values():
        result.works_count = result.orders_closed + result.maintenance_total
        result.is_provisional = result.works_count < min_works

        metrics: Dict[str, Optional[float]] = {
            "timeliness": None,
            "reaction": None,
            "workload": None,
            "reliability": None,
        }

        if result.maintenance_total:
            metrics["timeliness"] = (
                100.0 * result.maintenance_on_time / result.maintenance_total
            )

        scores = reaction_scores.get(result.user_id)
        if scores:
            metrics["reaction"] = sum(scores) / len(scores)
            seconds = reaction_seconds[result.user_id]
            result.reacted_count = len(seconds)
            result.avg_reaction_seconds = sum(seconds) / len(seconds)

        if result.work_units > 0:
            if WORK_UNITS_NORM:
                metrics["workload"] = _clamp(
                    100.0 * result.work_units / WORK_UNITS_NORM
                )
            elif median_units:
                # Медиана — половина шкалы, вдвое выше медианы — потолок.
                metrics["workload"] = _clamp(
                    100.0 * result.work_units / (2 * median_units)
                )

        if result.objects_count and average_rate is not None:
            own_rate = result.breakdowns_on_objects / result.objects_count
            if average_rate == 0:
                metrics["reliability"] = 100.0
            else:
                metrics["reliability"] = _clamp(
                    100.0 * (1 - own_rate / (2 * average_rate))
                )

        candidates = repeat_candidates.get(result.user_id, 0)
        if candidates and result.repeat_count:
            share = result.repeat_count / candidates
            result.repeat_penalty = min(
                REPEAT_PENALTY_MAX,
                REPEAT_PENALTY_MAX * share / REPEAT_PENALTY_FULL_SHARE,
            )

        result.metrics = metrics
        total = _weighted_total(metrics, WEIGHTS)
        if result.works_count == 0:
            # Ни одной работы за месяц — балла нет вовсе, даже когда парк
            # человека не ломался. Иначе первым в списке лучших встаёт тот,
            # кто не сделал ничего: надёжность считается по закреплению
            # лифтов, а не по работе, и в одиночку она означает только
            # отсутствие данных. Проверено на копии боевой базы, где так и
            # вышло.
            result.score = None
        elif total is None:
            result.score = None
        else:
            result.score = _clamp(total - result.repeat_penalty)
        # Строка без балла — тоже «мало данных», даже когда порог отключён:
        # иначе она попала бы в список наравне с посчитанными.
        result.is_provisional = result.is_provisional or result.score is None

    return list(results.values())


def score_foremen(
    *,
    foremen: Sequence,
    mechanics_by_division: Dict[int, List[int]],
    mechanic_scores: Sequence[EmployeeScore],
    schedule_by_division: Dict[int, float],
    overdue_by_division: Dict[int, int],
    objects_by_division: Dict[int, int],
    min_works: int = MIN_WORKS_FOR_RANKING,
) -> List[EmployeeScore]:
    """Балл прораба: как работают его люди и держит ли он график.

    Половина оценки — средний балл механиков его участков; вторая половина —
    то, за что прораб отвечает лично: выполнение графика ТО и отсутствие
    долгов по нему.
    """
    by_user = {score.user_id: score for score in mechanic_scores}
    results: List[EmployeeScore] = []

    for foreman in foremen:
        divisions = list(foreman.division_ids)
        result = EmployeeScore(
            user_id=foreman.user_id,
            name=foreman.name,
            role_id=foreman.role_id,
            division=foreman.division,
        )

        team_scores: List[float] = []
        for division_id in divisions:
            for user_id in mechanics_by_division.get(division_id, ()):
                score = by_user.get(user_id)
                # Малоактивных в среднее не берём по той же причине, по
                # которой их не показываем в вершине: цифре рано верить.
                if score and score.score is not None and not score.is_provisional:
                    team_scores.append(score.score)
                if score:
                    result.works_count += score.works_count
                    result.orders_closed += score.orders_closed
                    result.maintenance_total += score.maintenance_total
                    result.maintenance_on_time += score.maintenance_on_time

        planned = sum(
            objects_by_division.get(division_id, 0) for division_id in divisions
        )
        overdue = sum(
            overdue_by_division.get(division_id, 0) for division_id in divisions
        )
        result.objects_count = planned

        metrics: Dict[str, Optional[float]] = {
            "team": None,
            "schedule": None,
            "overdue": None,
        }

        if team_scores:
            metrics["team"] = sum(team_scores) / len(team_scores)

        execution = [
            schedule_by_division[division_id]
            for division_id in divisions
            if division_id in schedule_by_division
        ]
        if execution:
            metrics["schedule"] = _clamp(100.0 * sum(execution) / len(execution))

        if planned:
            share = overdue / planned
            metrics["overdue"] = _clamp(100.0 * (1 - share / OVERDUE_ZERO_SCORE_SHARE))

        result.metrics = metrics
        result.score = _weighted_total(metrics, FOREMAN_WEIGHTS)
        # У прораба «мало данных» означает не отпуск, а участок, на котором
        # ничего не происходило: балл собрать не из чего.
        result.is_provisional = result.score is None or result.works_count < min_works
        results.append(result)

    return results


def sort_scores(
    scores: Sequence[EmployeeScore], *, worst_first: bool
) -> List[EmployeeScore]:
    """Порядок выдачи: лучшие сверху или худшие сверху.

    Строки без балла и помеченные «мало данных» всегда в конце, в обоих
    режимах: человек в отпуске не должен возглавить ни один из списков.
    """

    def key(score: EmployeeScore):
        unranked = score.score is None or score.is_provisional
        value = score.score if score.score is not None else 0.0
        ordered = value if worst_first else -value
        return (unranked, ordered, score.name or "", score.user_id)

    return sorted(scores, key=key)
