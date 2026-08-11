import pytest

from src.crud.crud_location import crud_location
from src.models import Location
from src.schemas.location import LocationCreate

# Города, которые create_initial_data() кладёт в базу при старте
# (см. src/core/db/init_db.py:check_locations). Брать их как «новые» нельзя.
SEEDED_CITY = "Краснодар"


class TestCrudLocation:
    @pytest.mark.integration
    @pytest.mark.parametrize(
        "name",
        [
            "Армавир",
            "Сочи",
            "Майкоп",
        ],
    )
    def test_create_location(self, db_session, name: str):
        obj, code, _ = crud_location.create_location(
            db=db_session, new_data=LocationCreate(name=name)
        )

        assert code == 0
        assert obj is not None
        assert obj.id is not None
        assert obj.name == name

        from_db = db_session.query(Location).filter(Location.id == obj.id).first()
        assert from_db is not None
        assert from_db.name == name

    @pytest.mark.integration
    def test_create_location_duplicate_name_returns_error(self, db_session):
        obj1, code1, _ = crud_location.create_location(
            db=db_session, new_data=LocationCreate(name="Казань")
        )
        assert code1 == 0
        assert obj1 is not None

        obj2, code2, _ = crud_location.create_location(
            db=db_session, new_data=LocationCreate(name="Казань")
        )
        assert obj2 is None
        assert code2 != 0

    @pytest.mark.integration
    def test_create_location_conflicts_with_seeded_city(self, db_session):
        """Город из начальных данных повторно завести нельзя."""
        obj, code, _ = crud_location.create_location(
            db=db_session, new_data=LocationCreate(name=SEEDED_CITY)
        )

        assert obj is None
        assert code != 0


class TestDbSessionIsolation:
    """
    Проверка самой фикстуры, а не бизнес-логики.

    Оба теста заводят город с одним и тем же названием. Если откат в `db_session`
    сломается, второй тест упадёт на дубликате — и мы узнаем об этом сразу,
    а не через месяц по плавающим падениям в других тестах.
    """

    NAME = "Изолированск"

    @pytest.mark.integration
    def test_creates_city_first_time(self, db_session):
        obj, code, _ = crud_location.create_location(
            db=db_session, new_data=LocationCreate(name=self.NAME)
        )
        assert code == 0
        assert obj is not None

    @pytest.mark.integration
    def test_same_city_is_free_again_in_next_test(self, db_session):
        obj, code, _ = crud_location.create_location(
            db=db_session, new_data=LocationCreate(name=self.NAME)
        )
        assert code == 0, "Предыдущий тест не откатился — изоляция db_session сломана"
        assert obj is not None


# TODO добавить пользователя через параметризацию
