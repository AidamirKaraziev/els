"""Выполнение графика ТО: что попадает в план, что в факт и что в просрочку.

Тесты бьют по живой БД: вся логика здесь — SQL с агрегатами через FILTER,
границами месяца и разложением месяца в колонку. Мок проверил бы сам себя.

Определения, которые тесты защищают:
- план — заполненная ячейка месяца в графике на нужный год;
- факт — у связанного акта заполнен `finished_at`, любой датой;
- просрочка — акт закрыт после конца планового месяца, но он всё равно
  выполнен и входит в `completed_count`.
"""

import datetime
import itertools
import uuid

import pytest

from src.core.access import AccessScope, ScopeKind
from src.core.roles import FOREMAN, MECHANIC
from src.crud.crud_statistics import crud_statistics, month_period
from src.models import (
    ActFact,
    Company,
    Division,
    Object,
    Organization,
    UniversalUser,
    UserDivision,
)
from tests.scopes import ALL_SCOPE

MAY = month_period(2026, 5)
JUNE = month_period(2026, 6)
DECEMBER = month_period(2026, 12)


@pytest.fixture
def make_division(db_session):
    def _make(title=None):
        division = Division(title=title or f"Участок {uuid.uuid4().hex[:6]}")
        db_session.add(division)
        db_session.flush()
        return division

    return _make


@pytest.fixture
def make_object(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(**kwargs):
        number = next(counter)
        obj = Object(
            name=kwargs.pop("name", f"Лифт {number}"),
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            **kwargs,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def plan_to(db_session):
    """Строка графика с одним заполненным месяцем.

    `finished_at=None` означает «акт заведён, но не закрыт» — именно так
    выглядит запланированное, но не выполненное ТО.
    """
    from src.crud.crud_statistics import _PLANNED_MONTH_COLUMN
    from src.models import PlannedTO

    def _make(obj, *, month, year=2026, finished_at=None, act=True):
        act_id = None
        if act:
            act_fact = ActFact(object_id=obj.id, finished_at=finished_at)
            db_session.add(act_fact)
            db_session.flush()
            act_id = act_fact.id

        column_name = _PLANNED_MONTH_COLUMN[month].key
        # Год строковый — это тип колонки в модели, а не описка теста.
        planned = PlannedTO(year=str(year), object_id=obj.id, **{column_name: act_id})
        db_session.add(planned)
        db_session.flush()
        return planned

    return _make


def _by_division(rows):
    return {row.division_id: row for row in rows}


class TestWhatCountsAsPlanned:
    @pytest.mark.integration
    def test_filled_month_cell_is_the_plan(
        self, db_session, make_division, make_object, plan_to
    ):
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=5)

        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )

        assert _by_division(rows)[division.id].planned_count == 1

    @pytest.mark.integration
    def test_empty_month_cell_is_not_planned(
        self, db_session, make_division, make_object, plan_to
    ):
        # Ячейка без акта — незаполненный график, а не проваленное ТО. Так
        # учитывается разная периодичность обслуживания.
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=5, act=False)

        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )

        assert division.id not in _by_division(rows)

    @pytest.mark.integration
    def test_other_month_is_not_counted(
        self, db_session, make_division, make_object, plan_to
    ):
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=6)

        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )

        assert division.id not in _by_division(rows)

    @pytest.mark.integration
    def test_other_year_is_not_counted(
        self, db_session, make_division, make_object, plan_to
    ):
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=5, year=2025)

        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )

        assert division.id not in _by_division(rows)

    @pytest.mark.integration
    def test_orphaned_schedule_row_is_skipped(self, db_session, plan_to, make_object):
        # `planned_to.object_id` уходит в NULL при удалении объекта: в базе
        # такие строки есть, и в статистику они попадать не должны.
        from src.models import PlannedTO

        act = ActFact(finished_at=datetime.datetime(2026, 5, 20))
        db_session.add(act)
        db_session.flush()
        db_session.add(PlannedTO(year="2026", object_id=None, may_to_id=act.id))
        db_session.flush()

        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )

        # Ни строкой без участка, ни строкой с нулевым планом: осиротевший
        # график не должен доходить до выдачи вообще.
        assert rows == []


class TestWhatCountsAsCompleted:
    @pytest.mark.integration
    def test_act_without_finished_at_is_not_completed(
        self, db_session, make_division, make_object, plan_to
    ):
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=5)

        row = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=MAY, scope=ALL_SCOPE
            )
        )[division.id]

        assert (row.planned_count, row.completed_count) == (1, 0)

    @pytest.mark.integration
    def test_finished_inside_month_is_completed_on_time(
        self, db_session, make_division, make_object, plan_to
    ):
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=5, finished_at=datetime.datetime(2026, 5, 20))

        row = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=MAY, scope=ALL_SCOPE
            )
        )[division.id]

        assert (row.completed_count, row.completed_late_count) == (1, 0)

    @pytest.mark.integration
    def test_finished_next_month_counts_to_planned_month_as_late(
        self, db_session, make_division, make_object, plan_to
    ):
        # ТО за май, закрытое второго июня: работа сделана, месяц — майский,
        # но видно, что с опозданием.
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=5, finished_at=datetime.datetime(2026, 6, 2))

        may = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=MAY, scope=ALL_SCOPE
            )
        )[division.id]
        june = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=JUNE, scope=ALL_SCOPE
            )
        )

        assert (may.completed_count, may.completed_late_count) == (1, 1)
        assert division.id not in june

    @pytest.mark.integration
    def test_last_second_of_month_is_not_late(
        self, db_session, make_division, make_object, plan_to
    ):
        # Граница периода — полуинтервал [start, end): 31 мая ещё май.
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=5, finished_at=datetime.datetime(2026, 5, 31, 23, 59, 59))

        row = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=MAY, scope=ALL_SCOPE
            )
        )[division.id]

        assert row.completed_late_count == 0

    @pytest.mark.integration
    def test_december_late_crosses_the_year(
        self, db_session, make_division, make_object, plan_to
    ):
        # Декабрь — единственный месяц, у которого конец периода уезжает в
        # другой год: тут ошибка в границе не видна на остальных одиннадцати.
        division = make_division()
        obj = make_object(division_id=division.id)
        plan_to(obj, month=12, finished_at=datetime.datetime(2027, 1, 3))

        row = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=DECEMBER, scope=ALL_SCOPE
            )
        )[division.id]

        assert (row.completed_count, row.completed_late_count) == (1, 1)


class TestAggregationAndOrder:
    @pytest.mark.integration
    def test_counts_add_up_per_division(
        self, db_session, make_division, make_object, plan_to
    ):
        division = make_division()
        done = make_object(division_id=division.id)
        late = make_object(division_id=division.id)
        make_object(division_id=division.id)
        plan_to(done, month=5, finished_at=datetime.datetime(2026, 5, 4))
        plan_to(late, month=5, finished_at=datetime.datetime(2026, 7, 1))
        plan_to(make_object(division_id=division.id), month=5)

        row = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=MAY, scope=ALL_SCOPE
            )
        )[division.id]

        assert (row.planned_count, row.completed_count, row.completed_late_count) == (
            3,
            2,
            1,
        )

    @pytest.mark.integration
    def test_worst_division_comes_first(
        self, db_session, make_division, make_object, plan_to
    ):
        good = make_division()
        bad = make_division()
        plan_to(
            make_object(division_id=good.id),
            month=5,
            finished_at=datetime.datetime(2026, 5, 2),
        )
        plan_to(make_object(division_id=bad.id), month=5)

        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=ALL_SCOPE
        )
        order = [
            row.division_id for row in rows if row.division_id in (good.id, bad.id)
        ]

        assert order == [bad.id, good.id]


class TestFiltersAndScope:
    @pytest.mark.integration
    def test_division_filter_narrows_output(
        self, db_session, make_division, make_object, plan_to
    ):
        mine = make_division()
        other = make_division()
        plan_to(make_object(division_id=mine.id), month=5)
        plan_to(make_object(division_id=other.id), month=5)

        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=ALL_SCOPE, division_id=mine.id
        )

        assert [row.division_id for row in rows] == [mine.id]

    @pytest.mark.integration
    def test_company_filter_narrows_output(
        self, db_session, make_division, make_object, plan_to
    ):
        company = Company(name=f"Компания {uuid.uuid4().hex[:6]}")
        db_session.add(company)
        db_session.flush()
        division = make_division()
        plan_to(make_object(division_id=division.id, company_id=company.id), month=5)
        plan_to(make_object(division_id=division.id), month=5)

        row = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session, period=MAY, scope=ALL_SCOPE, company_id=company.id
            )
        )[division.id]

        assert row.planned_count == 1

    @pytest.mark.integration
    def test_organization_filter_narrows_output(
        self, db_session, make_division, make_object, plan_to
    ):
        organization = Organization(title=f"Орг {uuid.uuid4().hex[:6]}")
        db_session.add(organization)
        db_session.flush()
        division = make_division()
        plan_to(
            make_object(division_id=division.id, organization_id=organization.id),
            month=5,
        )
        plan_to(make_object(division_id=division.id), month=5)

        row = _by_division(
            crud_statistics.schedule_execution_by_division(
                db=db_session,
                period=MAY,
                scope=ALL_SCOPE,
                organization_id=organization.id,
            )
        )[division.id]

        assert row.planned_count == 1

    @pytest.mark.integration
    def test_scope_hides_foreign_divisions(
        self, db_session, make_division, make_object, plan_to
    ):
        mine = make_division()
        foreign = make_division()
        plan_to(make_object(division_id=mine.id), month=5)
        plan_to(make_object(division_id=foreign.id), month=5)

        scope = AccessScope(
            kind=ScopeKind.DIVISIONS,
            user_id=-1,
            division_ids=frozenset({mine.id}),
            company_id=None,
        )
        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=scope
        )

        assert [row.division_id for row in rows] == [mine.id]

    @pytest.mark.integration
    def test_requested_filter_cannot_widen_scope(
        self, db_session, make_division, make_object, plan_to
    ):
        # Фильтр — это выбор человека, область — граница. Чужой участок,
        # запрошенный явно, выдачу не расширяет.
        mine = make_division()
        foreign = make_division()
        plan_to(make_object(division_id=mine.id), month=5)
        plan_to(make_object(division_id=foreign.id), month=5)

        scope = AccessScope(
            kind=ScopeKind.DIVISIONS,
            user_id=-1,
            division_ids=frozenset({mine.id}),
            company_id=None,
        )
        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=MAY, scope=scope, division_id=foreign.id
        )

        assert rows == []

    @pytest.mark.integration
    def test_empty_month_returns_nothing(self, db_session):
        rows = crud_statistics.schedule_execution_by_division(
            db=db_session, period=month_period(1990, 2), scope=ALL_SCOPE
        )

        assert rows == []


class TestForemen:
    @pytest.fixture
    def make_foreman(self, db_session):
        def _make(division, role_id=FOREMAN, is_active=True, name=None):
            user = UniversalUser(
                name=name or f"Прораб {uuid.uuid4().hex[:6]}",
                email=f"foreman-{uuid.uuid4().hex[:8]}@test",
                role_id=role_id,
                is_active=is_active,
                division_id=division.id,
            )
            db_session.add(user)
            db_session.flush()
            db_session.add(UserDivision(user_id=user.id, division_id=division.id))
            db_session.flush()
            return user

        return _make

    @pytest.mark.integration
    def test_all_foremen_of_division_are_returned(
        self, db_session, make_division, make_foreman
    ):
        division = make_division()
        first = make_foreman(division)
        second = make_foreman(division)

        result = crud_statistics.foremen_by_division(
            db=db_session, division_ids=[division.id]
        )

        assert result[division.id] == [first.name, second.name]

    @pytest.mark.integration
    def test_other_roles_and_fired_are_skipped(
        self, db_session, make_division, make_foreman
    ):
        division = make_division()
        make_foreman(division, role_id=MECHANIC)
        make_foreman(division, is_active=False)

        result = crud_statistics.foremen_by_division(
            db=db_session, division_ids=[division.id]
        )

        assert division.id not in result

    @pytest.mark.integration
    def test_no_query_without_divisions(self, db_session):
        assert crud_statistics.foremen_by_division(db=db_session, division_ids=[]) == {}
