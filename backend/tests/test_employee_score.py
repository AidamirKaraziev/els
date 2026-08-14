"""Формула балла сотрудника: нормативы, веса, штрафы, порядок выдачи.

Без базы: `score_employees` принимает строки как есть, поэтому арифметику
можно проверять на выдуманных данных. Запросы, которые эти строки достают,
проверяет `test_api_top_employees`.
"""

import datetime
from types import SimpleNamespace

import pytest

from src.services.employee_score import (
    MIN_WORKS_FOR_RANKING,
    OTHER_OBJECT_BONUS,
    REPEAT_PENALTY_MAX,
    score_employees,
    score_foremen,
    sort_scores,
)

PERIOD_START = datetime.datetime(2026, 8, 1)
PERIOD_END = datetime.datetime(2026, 9, 1)
MEDIAN_STEPS = 40.0


def employee(user_id, name="Механик"):
    return SimpleNamespace(user_id=user_id, name=name, role_id=3, division="Участок №1")


def order(
    *,
    executor_id,
    object_id=1,
    created_at=PERIOD_START,
    reaction=datetime.timedelta(minutes=10),
    category_code="AA",
    is_breakdown=True,
    is_own_object=True,
    closed_at=None,
):
    return SimpleNamespace(
        executor_id=executor_id,
        object_id=object_id,
        created_at=created_at,
        reacted_at=None if reaction is None else created_at + reaction,
        closed_at=closed_at or created_at + datetime.timedelta(hours=2),
        category_code=category_code,
        is_breakdown=is_breakdown,
        is_own_object=is_own_object,
    )


def act(*, mechanic_id, finished_at=None, steps_count=MEDIAN_STEPS, is_own_object=True):
    return SimpleNamespace(
        mechanic_id=mechanic_id,
        finished_at=finished_at,
        steps_count=steps_count,
        is_own_object=is_own_object,
    )


def run(
    *,
    employees,
    orders=(),
    maintenance=(),
    objects_per_mechanic=None,
    breakdowns_per_mechanic=None,
    breakdown_events=(),
    min_works=0,
):
    """Расчёт с порогом активности, выключенным по умолчанию.

    Порог проверяется отдельными тестами; в остальных он только мешал бы
    заводить по одной работе на человека.
    """
    return {
        score.user_id: score
        for score in score_employees(
            employees=employees,
            orders=orders,
            maintenance=maintenance,
            objects_per_mechanic=objects_per_mechanic or {},
            breakdowns_per_mechanic=breakdowns_per_mechanic or {},
            breakdown_events=breakdown_events,
            median_steps=MEDIAN_STEPS,
            period_end=PERIOD_END,
            min_works=min_works,
        )
    }


class TestTimeliness:
    def test_maintenance_closed_inside_planned_month_is_on_time(self):
        scores = run(
            employees=[employee(1)],
            maintenance=[act(mechanic_id=1, finished_at=datetime.datetime(2026, 8, 20))],
        )

        assert scores[1].metrics["timeliness"] == 100.0
        assert scores[1].maintenance_on_time == 1

    def test_maintenance_closed_next_month_is_late(self):
        scores = run(
            employees=[employee(1)],
            maintenance=[act(mechanic_id=1, finished_at=datetime.datetime(2026, 9, 2))],
        )

        assert scores[1].metrics["timeliness"] == 0.0
        assert scores[1].maintenance_total == 1

    def test_unfinished_maintenance_counts_against_him(self):
        scores = run(
            employees=[employee(1)],
            maintenance=[
                act(mechanic_id=1, finished_at=datetime.datetime(2026, 8, 5)),
                act(mechanic_id=1, finished_at=None),
            ],
        )

        assert scores[1].metrics["timeliness"] == 50.0

    def test_without_maintenance_metric_is_not_counted(self):
        """Не было ТО — не должно быть и нуля за своевременность."""
        scores = run(employees=[employee(1)], orders=[order(executor_id=1)])

        assert scores[1].metrics["timeliness"] is None
        # Балл при этом есть: вес выпавшей метрики ушёл к остальным.
        assert scores[1].score is not None


class TestReaction:
    @pytest.mark.parametrize(
        "minutes, expected",
        [(10, 100.0), (30, 100.0), (45, 75.0), (60, 50.0), (120, 0.0), (300, 0.0)],
    )
    def test_urgent_norm_is_half_an_hour(self, minutes, expected):
        scores = run(
            employees=[employee(1)],
            orders=[
                order(executor_id=1, reaction=datetime.timedelta(minutes=minutes))
            ],
        )

        assert scores[1].metrics["reaction"] == pytest.approx(expected)

    def test_routine_breakdown_has_a_day_to_react(self):
        """Час на «В» — это отлично, тот же час на застревание — норматив."""
        scores = run(
            employees=[employee(1)],
            orders=[
                order(
                    executor_id=1,
                    category_code="В",
                    reaction=datetime.timedelta(hours=1),
                )
            ],
        )

        assert scores[1].metrics["reaction"] == 100.0

    def test_untouched_order_falls_out_of_the_average(self):
        """Заявку никто не принял — она не улучшает и не портит среднее."""
        scores = run(
            employees=[employee(1)],
            orders=[
                order(executor_id=1, reaction=datetime.timedelta(minutes=10)),
                order(executor_id=1, reaction=None),
            ],
        )

        assert scores[1].metrics["reaction"] == 100.0
        assert scores[1].reacted_count == 1

    def test_negative_reaction_is_ignored(self):
        """«Приняли» раньше, чем создали, — битая запись, а не рекорд."""
        scores = run(
            employees=[employee(1)],
            orders=[order(executor_id=1, reaction=datetime.timedelta(minutes=-30))],
        )

        assert scores[1].metrics["reaction"] is None

    def test_planned_work_does_not_count_as_reaction(self):
        scores = run(
            employees=[employee(1)],
            orders=[
                order(
                    executor_id=1,
                    category_code="ТО",
                    is_breakdown=False,
                    reaction=datetime.timedelta(days=10),
                )
            ],
        )

        assert scores[1].metrics["reaction"] is None
        assert scores[1].orders_closed == 1


class TestWorkload:
    def test_severity_sets_the_weight_of_a_breakdown(self):
        scores = run(
            employees=[employee(1), employee(2)],
            orders=[
                order(executor_id=1, category_code="AA"),
                order(executor_id=2, category_code="Н"),
            ],
        )

        assert scores[1].work_units == 3.0
        assert scores[2].work_units == 1.0
        # Тяжёлая работа даёт больший балл за объём, а не только уважение.
        assert scores[1].metrics["workload"] > scores[2].metrics["workload"]

    def test_foreign_object_costs_a_quarter_more(self):
        scores = run(
            employees=[employee(1), employee(2)],
            orders=[
                order(executor_id=1, category_code="Н", is_own_object=True),
                order(executor_id=2, category_code="Н", is_own_object=False),
            ],
        )

        assert scores[2].work_units == pytest.approx(OTHER_OBJECT_BONUS)
        assert scores[2].work_units > scores[1].work_units

    def test_longer_checklist_weighs_more(self):
        """ТО-12 вчетверо длиннее ТО-3 — значит и весит вчетверо."""
        scores = run(
            employees=[employee(1)],
            maintenance=[
                act(
                    mechanic_id=1,
                    finished_at=datetime.datetime(2026, 8, 10),
                    steps_count=MEDIAN_STEPS * 4,
                )
            ],
        )

        assert scores[1].work_units == pytest.approx(4.0)

    def test_unfinished_maintenance_adds_no_units(self):
        scores = run(
            employees=[employee(1)],
            maintenance=[act(mechanic_id=1, finished_at=None)],
        )

        assert scores[1].work_units == 0

    def test_median_is_half_the_scale(self):
        """Медианный по объёму получает 50, вдвое выше медианы — 100."""
        scores = run(
            employees=[employee(1), employee(2), employee(3)],
            orders=[
                order(executor_id=1, category_code="Н"),
                order(executor_id=2, category_code="Н"),
                order(executor_id=3, category_code="Н"),
                order(executor_id=3, category_code="Н"),
            ],
        )

        assert scores[1].metrics["workload"] == pytest.approx(50.0)
        assert scores[3].metrics["workload"] == pytest.approx(100.0)


class TestReliability:
    def test_no_breakdowns_on_his_lifts_is_a_hundred(self):
        scores = run(
            employees=[employee(1), employee(2)],
            objects_per_mechanic={1: 10, 2: 10},
            breakdowns_per_mechanic={2: 4},
        )

        assert scores[1].metrics["reliability"] == 100.0

    def test_average_is_half_the_scale(self):
        scores = run(
            employees=[employee(1), employee(2)],
            objects_per_mechanic={1: 10, 2: 10},
            breakdowns_per_mechanic={1: 2, 2: 2},
        )

        assert scores[1].metrics["reliability"] == pytest.approx(50.0)

    def test_twice_the_average_is_zero(self):
        scores = run(
            employees=[employee(1), employee(2), employee(3)],
            objects_per_mechanic={1: 10, 2: 10, 3: 10},
            breakdowns_per_mechanic={1: 4, 2: 1, 3: 1},
        )

        # Средняя аварийность 0,2 на лифт, у первого — 0,4.
        assert scores[1].metrics["reliability"] == pytest.approx(0.0)

    def test_mechanic_without_objects_is_not_judged_by_the_fleet(self):
        scores = run(
            employees=[employee(1)],
            objects_per_mechanic={},
            breakdowns_per_mechanic={},
        )

        assert scores[1].metrics["reliability"] is None

    def test_old_fleet_is_compared_with_the_average_not_with_zero(self):
        """Механик со старым парком не должен падать в ноль, если он не хуже
        остальных."""
        scores = run(
            employees=[employee(1), employee(2)],
            objects_per_mechanic={1: 5, 2: 5},
            breakdowns_per_mechanic={1: 5, 2: 5},
        )

        assert scores[1].metrics["reliability"] == pytest.approx(50.0)


class TestRepeatCalls:
    def _events(self, days):
        closed_at = PERIOD_START + datetime.timedelta(hours=2)
        return [
            SimpleNamespace(
                object_id=1, created_at=closed_at + datetime.timedelta(days=days)
            )
        ]

    def test_breakdown_within_two_weeks_is_a_redo(self):
        scores = run(
            employees=[employee(1)],
            orders=[order(executor_id=1, object_id=1)],
            breakdown_events=self._events(5),
        )

        assert scores[1].repeat_count == 1
        assert scores[1].repeat_penalty == REPEAT_PENALTY_MAX

    def test_after_the_window_it_is_not_his_fault(self):
        scores = run(
            employees=[employee(1)],
            orders=[order(executor_id=1, object_id=1)],
            breakdown_events=self._events(15),
        )

        assert scores[1].repeat_count == 0
        assert scores[1].repeat_penalty == 0

    def test_breakdown_on_another_lift_is_not_a_redo(self):
        closed_at = PERIOD_START + datetime.timedelta(hours=2)
        scores = run(
            employees=[employee(1)],
            orders=[order(executor_id=1, object_id=1)],
            breakdown_events=[
                SimpleNamespace(
                    object_id=2, created_at=closed_at + datetime.timedelta(days=1)
                )
            ],
        )

        assert scores[1].repeat_count == 0

    def test_penalty_is_proportional_to_the_share(self):
        """Одна переделка из десяти — десятая доля полного штрафа."""
        closed_at = PERIOD_START + datetime.timedelta(hours=2)
        orders = [order(executor_id=1, object_id=number) for number in range(1, 11)]
        events = [
            SimpleNamespace(
                object_id=1, created_at=closed_at + datetime.timedelta(days=1)
            )
        ]

        scores = run(employees=[employee(1)], orders=orders, breakdown_events=events)

        assert scores[1].repeat_penalty == pytest.approx(REPEAT_PENALTY_MAX / 3)

    def test_penalty_lowers_the_total(self):
        clean = run(
            employees=[employee(1)],
            orders=[order(executor_id=1, object_id=1)],
        )
        with_redo = run(
            employees=[employee(1)],
            orders=[order(executor_id=1, object_id=1)],
            breakdown_events=self._events(3),
        )

        assert with_redo[1].score < clean[1].score


class TestProvisional:
    def test_below_threshold_is_marked(self):
        scores = run(
            employees=[employee(1)],
            orders=[order(executor_id=1)],
            min_works=MIN_WORKS_FOR_RANKING,
        )

        assert scores[1].works_count == 1
        assert scores[1].is_provisional is True

    def test_threshold_counts_orders_and_maintenance_together(self):
        scores = run(
            employees=[employee(1)],
            orders=[order(executor_id=1), order(executor_id=1)],
            maintenance=[act(mechanic_id=1, finished_at=datetime.datetime(2026, 8, 3))],
            min_works=MIN_WORKS_FOR_RANKING,
        )

        assert scores[1].works_count == 3
        assert scores[1].is_provisional is False

    def test_employee_without_any_data_has_no_score(self):
        scores = run(employees=[employee(1)])

        assert scores[1].score is None
        assert scores[1].is_provisional is True

    def test_idle_mechanic_does_not_win_on_a_quiet_fleet(self):
        """Ноль работ — нет балла, даже если его лифты не ломались.

        На копии боевой базы без этого правила первым в списке лучших вставал
        механик, не сделавший ничего: надёжность парка считается по
        закреплению лифтов, а не по работе, и в одиночку означает только
        отсутствие данных.
        """
        scores = run(
            employees=[employee(1)],
            objects_per_mechanic={1: 5},
            breakdowns_per_mechanic={},
        )

        assert scores[1].metrics["reliability"] == 100.0
        assert scores[1].score is None
        assert scores[1].is_provisional is True


class TestSorting:
    def _three(self):
        return run(
            employees=[employee(1), employee(2), employee(3)],
            orders=[
                order(executor_id=1, reaction=datetime.timedelta(minutes=10)),
                order(executor_id=2, reaction=datetime.timedelta(hours=3)),
                order(executor_id=3, reaction=datetime.timedelta(minutes=20)),
            ],
            min_works=0,
        )

    def test_best_first(self):
        ordered = sort_scores(list(self._three().values()), worst_first=False)

        assert [score.user_id for score in ordered][0] in {1, 3}
        assert ordered[-1].user_id == 2

    def test_worst_first(self):
        ordered = sort_scores(list(self._three().values()), worst_first=True)

        assert ordered[0].user_id == 2

    def test_provisional_rows_never_lead_either_list(self):
        scores = run(
            employees=[employee(1), employee(2)],
            orders=[
                # Один идеальный выезд у первого и три обычных у второго.
                order(executor_id=1, reaction=datetime.timedelta(minutes=1)),
                order(executor_id=2, reaction=datetime.timedelta(hours=1)),
                order(executor_id=2, reaction=datetime.timedelta(hours=1)),
                order(executor_id=2, reaction=datetime.timedelta(hours=1)),
            ],
            min_works=MIN_WORKS_FOR_RANKING,
        )
        rows = list(scores.values())

        assert sort_scores(rows, worst_first=False)[0].user_id == 2
        assert sort_scores(rows, worst_first=True)[0].user_id == 2


class TestForemanScore:
    def _foreman(self, user_id=10, divisions=(1,)):
        return SimpleNamespace(
            user_id=user_id,
            name="Прораб",
            role_id=2,
            division="Участок №1",
            division_ids=list(divisions),
        )

    def test_team_average_drives_half_the_score(self):
        mechanics = list(
            run(
                employees=[employee(1), employee(2)],
                orders=[
                    order(executor_id=1, reaction=datetime.timedelta(minutes=10)),
                    order(executor_id=1, reaction=datetime.timedelta(minutes=10)),
                    order(executor_id=1, reaction=datetime.timedelta(minutes=10)),
                ],
            ).values()
        )

        scored = score_foremen(
            foremen=[self._foreman()],
            mechanics_by_division={1: [1, 2]},
            mechanic_scores=mechanics,
            schedule_by_division={1: 1.0},
            overdue_by_division={},
            objects_by_division={1: 10},
            min_works=0,
        )

        assert scored[0].metrics["team"] is not None
        assert scored[0].metrics["schedule"] == 100.0
        assert scored[0].metrics["overdue"] == 100.0
        assert scored[0].score == pytest.approx(
            0.5 * scored[0].metrics["team"] + 50.0, abs=0.1
        )

    def test_debts_pull_the_score_down(self):
        clean = score_foremen(
            foremen=[self._foreman()],
            mechanics_by_division={},
            mechanic_scores=[],
            schedule_by_division={1: 1.0},
            overdue_by_division={},
            objects_by_division={1: 10},
            min_works=0,
        )
        indebted = score_foremen(
            foremen=[self._foreman()],
            mechanics_by_division={},
            mechanic_scores=[],
            schedule_by_division={1: 1.0},
            # Каждый четвёртый лифт участка с долгом — половина шкалы.
            overdue_by_division={1: 5},
            objects_by_division={1: 20},
            min_works=0,
        )

        assert indebted[0].metrics["overdue"] == pytest.approx(50.0)
        assert indebted[0].score < clean[0].score

    def test_provisional_mechanics_stay_out_of_the_average(self):
        """Механик с одной работой не тянет прораба ни вверх, ни вниз."""
        mechanics = list(
            run(
                employees=[employee(1)],
                orders=[order(executor_id=1, reaction=datetime.timedelta(minutes=1))],
                min_works=MIN_WORKS_FOR_RANKING,
            ).values()
        )

        scored = score_foremen(
            foremen=[self._foreman()],
            mechanics_by_division={1: [1]},
            mechanic_scores=mechanics,
            schedule_by_division={1: 0.5},
            overdue_by_division={},
            objects_by_division={1: 10},
            min_works=0,
        )

        assert scored[0].metrics["team"] is None
