"""Просроченные ТО: что попадает в долг, а что нет.

Тесты бьют по живой БД: вся логика здесь — развёртка двенадцати колонок
месяца через `UNION ALL`, сравнение планового месяца с текущим и строковый
год. Мок проверил бы сам себя.

Определения, которые тесты защищают:
- просрочка — ячейка месяца заполнена, плановый месяц уже закончился, а
  `finished_at` у связанного акта пуст;
- текущий месяц не просрочен: он ещё идёт;
- горизонт — текущий и предыдущий год, глубже не смотрим.

Текущий месяц во всех тестах задан явно (`reference`), а не берётся из
`datetime.now()`: иначе набор проходящих тестов зависел бы от дня прогона.
"""

import datetime
import itertools
import uuid

import pytest

from src.core.access import AccessScope, ScopeKind
from src.crud.crud_statistics import (
    _PLANNED_MONTH_COLUMN,
    crud_statistics,
    month_period,
)
from src.models import (
    ActFact,
    Company,
    Division,
    Object,
    Organization,
    PlannedTO,
    UniversalUser,
)
from tests.scopes import ALL_SCOPE

#: Сейчас — август 2026. Значит просрочены январь–июль 2026 и весь 2025.
AUGUST = month_period(2026, 8)


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
    """Строка графика на год с несколькими заполненными месяцами.

    Месяцы задаются словарём `{номер: finished_at}`, где `None` означает
    «акт заведён, но не закрыт» — именно так выглядит долг. Пустые ячейки
    (месяц, на который ТО не заводили) перечисляются в `empty`.

    Одной строкой на год, а не вызовом на каждый месяц: в `planned_to` висит
    `UniqueConstraint("year", "object_id")`, и второй вызов упал бы.
    """

    def _make(obj, *, months=None, empty=(), year=2026):
        columns = {}
        for month, finished_at in (months or {}).items():
            act = ActFact(object_id=obj.id, finished_at=finished_at)
            db_session.add(act)
            db_session.flush()
            columns[_PLANNED_MONTH_COLUMN[month].key] = act.id
        for month in empty:
            columns[_PLANNED_MONTH_COLUMN[month].key] = None

        planned = PlannedTO(year=str(year), object_id=obj.id, **columns)
        db_session.add(planned)
        db_session.flush()
        return planned

    return _make


def _months(rows):
    """(год, месяц) каждой строки выдачи — в порядке, в котором пришли."""
    return [(int(row.year), int(row.month)) for row in rows]


class TestWhatCountsAsOverdue:
    @pytest.mark.integration
    def test_past_month_without_finished_at_is_overdue(
        self, db_session, make_object, plan_to
    ):
        obj = make_object()
        plan_to(obj, months={3: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert _months(rows) == [(2026, 3)]

    @pytest.mark.integration
    def test_finished_act_is_not_overdue(self, db_session, make_object, plan_to):
        # Закрыто с опозданием — но закрыто. Опоздание считает виджет
        # «Выполнение графика», а долг — это то, что до сих пор не сделано.
        obj = make_object()
        plan_to(obj, months={3: datetime.datetime(2026, 7, 20)})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert rows == []

    @pytest.mark.integration
    def test_current_month_is_not_overdue(self, db_session, make_object, plan_to):
        # Август ещё идёт: ТО на август не сделано, но и не просрочено.
        obj = make_object()
        plan_to(obj, months={8: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert rows == []

    @pytest.mark.integration
    def test_future_month_is_not_overdue(self, db_session, make_object, plan_to):
        obj = make_object()
        plan_to(obj, months={12: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert rows == []

    @pytest.mark.integration
    def test_empty_cell_is_not_overdue(self, db_session, make_object, plan_to):
        # Ячейка без акта — незаполненный график, а не пропущенное ТО. То же
        # определение плана, что и у выполнения графика.
        obj = make_object()
        plan_to(obj, empty=(3,))

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert rows == []

    @pytest.mark.integration
    def test_orphaned_schedule_row_is_skipped(self, db_session):
        # `planned_to.object_id` уходит в NULL при удалении объекта: такие
        # строки в базе есть, и долгом они не являются — предъявлять некому.
        act = ActFact(finished_at=None)
        db_session.add(act)
        db_session.flush()
        db_session.add(PlannedTO(year="2026", object_id=None, march_to_id=act.id))
        db_session.flush()

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert rows == []


class TestHorizon:
    @pytest.mark.integration
    def test_previous_year_is_overdue_whole(self, db_session, make_object, plan_to):
        obj = make_object()
        plan_to(obj, months={12: None}, year=2025)

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert _months(rows) == [(2025, 12)]

    @pytest.mark.integration
    def test_older_years_are_out_of_horizon(self, db_session, make_object, plan_to):
        obj = make_object()
        plan_to(obj, months={3: None}, year=2024)

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert rows == []

    @pytest.mark.integration
    def test_january_looks_at_previous_year_only(
        self, db_session, make_object, plan_to
    ):
        # В январе у текущего года прошедших месяцев нет вообще — ветка
        # «этот год, месяц меньше текущего» не должна ничего вернуть, а
        # прошлогодний долг обязан остаться виден.
        obj = make_object()
        plan_to(obj, months={1: None}, year=2026)
        plan_to(obj, months={11: None}, year=2025)

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=month_period(2026, 1), scope=ALL_SCOPE
        )

        assert _months(rows) == [(2025, 11)]

    @pytest.mark.integration
    def test_non_numeric_year_does_not_break_the_query(
        self, db_session, make_object, plan_to
    ):
        # В колонку `year` пишут руками, и строка вроде «2025 г.» там
        # завестись может. Приведение типа уронило бы весь запрос; сравнение
        # перечислением просто её не находит.
        obj = make_object()
        plan_to(obj, months={3: None}, year="2025 г.")

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert rows == []


class TestRowsAndOrder:
    @pytest.mark.integration
    def test_object_with_three_gaps_gives_three_rows(
        self, db_session, make_object, plan_to
    ):
        obj = make_object()
        plan_to(obj, months={2: None, 4: None, 6: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert _months(rows) == [(2026, 2), (2026, 4), (2026, 6)]

    @pytest.mark.integration
    def test_oldest_comes_first_across_years(self, db_session, make_object, plan_to):
        obj = make_object()
        plan_to(obj, months={5: None}, year=2026)
        plan_to(obj, months={9: None}, year=2025)

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert _months(rows) == [(2025, 9), (2026, 5)]

    @pytest.mark.integration
    def test_row_carries_object_client_and_mechanic(
        self, db_session, make_object, make_division, plan_to
    ):
        division = make_division()
        organization = Organization(title=f"Орг {uuid.uuid4().hex[:6]}")
        mechanic = UniversalUser(
            name="И.И. Механиков",
            email=f"mech-{uuid.uuid4().hex[:8]}@test",
            role_id=4,
        )
        db_session.add_all([organization, mechanic])
        db_session.flush()
        obj = make_object(
            division_id=division.id,
            organization_id=organization.id,
            mechanic_id=mechanic.id,
        )
        plan_to(obj, months={3: None})

        row = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )[0]

        assert (row.object_id, row.client, row.division, row.responsible_mechanic) == (
            obj.id,
            organization.title,
            division.title,
            "И.И. Механиков",
        )

    @pytest.mark.integration
    def test_company_is_the_client_when_organization_is_empty(
        self, db_session, make_object, plan_to
    ):
        company = Company(name=f"Компания {uuid.uuid4().hex[:6]}")
        db_session.add(company)
        db_session.flush()
        obj = make_object(company_id=company.id)
        plan_to(obj, months={3: None})

        row = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )[0]

        assert row.client == company.name


class TestLimitAndCount:
    @pytest.mark.integration
    def test_limit_cuts_the_list_but_not_the_total(
        self, db_session, make_object, plan_to
    ):
        obj = make_object()
        plan_to(obj, months={1: None, 2: None, 3: None, 4: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE, limit=2
        )
        total, objects = crud_statistics.count_overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )

        assert (len(rows), total, objects) == (2, 4, 1)

    @pytest.mark.integration
    def test_offset_continues_the_same_order(self, db_session, make_object, plan_to):
        obj = make_object()
        plan_to(obj, months={1: None, 2: None, 3: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE, limit=2, offset=1
        )

        assert _months(rows) == [(2026, 2), (2026, 3)]

    @pytest.mark.integration
    def test_count_distinguishes_objects_from_maintenances(
        self, db_session, make_object, plan_to
    ):
        # Два объекта, четыре долга: счётчик в шапке карточки обязан считать
        # ТО, а не объекты, иначе «просрочено 2» при четырёх пропусках.
        first = make_object()
        second = make_object()
        plan_to(first, months={1: None, 2: None, 3: None})
        plan_to(second, months={4: None})

        assert crud_statistics.count_overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        ) == (4, 2)

    @pytest.mark.integration
    def test_nothing_overdue_returns_zeroes(self, db_session):
        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        )
        assert rows == []
        assert crud_statistics.count_overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE
        ) == (0, 0)


class TestFiltersAndScope:
    @pytest.mark.integration
    def test_division_filter_narrows_output(
        self, db_session, make_division, make_object, plan_to
    ):
        mine = make_division()
        other = make_division()
        plan_to(make_object(division_id=mine.id), months={3: None})
        plan_to(make_object(division_id=other.id), months={3: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE, division_id=mine.id
        )

        assert [row.division for row in rows] == [mine.title]

    @pytest.mark.integration
    def test_company_filter_narrows_output(self, db_session, make_object, plan_to):
        company = Company(name=f"Компания {uuid.uuid4().hex[:6]}")
        db_session.add(company)
        db_session.flush()
        mine = make_object(company_id=company.id)
        plan_to(mine, months={3: None})
        plan_to(make_object(), months={3: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=ALL_SCOPE, company_id=company.id
        )

        assert [row.object_id for row in rows] == [mine.id]

    @pytest.mark.integration
    def test_organization_filter_narrows_output(self, db_session, make_object, plan_to):
        organization = Organization(title=f"Орг {uuid.uuid4().hex[:6]}")
        db_session.add(organization)
        db_session.flush()
        mine = make_object(organization_id=organization.id)
        plan_to(mine, months={3: None})
        plan_to(make_object(), months={3: None})

        rows = crud_statistics.overdue_maintenance(
            db=db_session,
            reference=AUGUST,
            scope=ALL_SCOPE,
            organization_id=organization.id,
        )

        assert [row.object_id for row in rows] == [mine.id]

    @pytest.mark.integration
    def test_scope_hides_foreign_divisions(
        self, db_session, make_division, make_object, plan_to
    ):
        mine = make_division()
        foreign = make_division()
        visible = make_object(division_id=mine.id)
        plan_to(visible, months={3: None})
        plan_to(make_object(division_id=foreign.id), months={3: None})

        scope = AccessScope(
            kind=ScopeKind.DIVISIONS,
            user_id=-1,
            division_ids=frozenset({mine.id}),
            company_id=None,
        )
        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=scope
        )

        assert [row.object_id for row in rows] == [visible.id]

    @pytest.mark.integration
    def test_requested_filter_cannot_widen_scope(
        self, db_session, make_division, make_object, plan_to
    ):
        # Фильтр — выбор человека, область — граница. Чужой участок,
        # запрошенный явно, выдачу не расширяет.
        mine = make_division()
        foreign = make_division()
        plan_to(make_object(division_id=mine.id), months={3: None})
        plan_to(make_object(division_id=foreign.id), months={3: None})

        scope = AccessScope(
            kind=ScopeKind.DIVISIONS,
            user_id=-1,
            division_ids=frozenset({mine.id}),
            company_id=None,
        )
        rows = crud_statistics.overdue_maintenance(
            db=db_session, reference=AUGUST, scope=scope, division_id=foreign.id
        )

        assert rows == []

    @pytest.mark.integration
    def test_scope_applies_to_the_counter_too(
        self, db_session, make_division, make_object, plan_to
    ):
        # Счётчик и список считаются двумя запросами: разойтись им нельзя,
        # иначе в шапке «просрочено 4», а в списке две строки.
        mine = make_division()
        foreign = make_division()
        plan_to(make_object(division_id=mine.id), months={3: None})
        plan_to(make_object(division_id=foreign.id), months={3: None, 4: None})

        scope = AccessScope(
            kind=ScopeKind.DIVISIONS,
            user_id=-1,
            division_ids=frozenset({mine.id}),
            company_id=None,
        )

        assert crud_statistics.count_overdue_maintenance(
            db=db_session, reference=AUGUST, scope=scope
        ) == (1, 1)
