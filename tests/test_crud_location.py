import pytest

from src.crud.crud_location import crud_location
from src.models import Location
from src.schemas.location import LocationCreate


class TestCrudLocation:
    @pytest.mark.integration
    @pytest.mark.parametrize(
        "name",
        [
            "Армавир",
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

        # from_db = db_session.query(Location).filter(Location.id == obj.id).first()
        # assert from_db is not None
        # assert from_db.name == name

    # @pytest.mark.integration
    # def test_create_location_duplicate_name_returns_error(self, db_session):
    #     obj1, code1, _ = crud_location.create_location(
    #         db=db_session, new_data=LocationCreate(name="Казань")
    #     )
    #     assert code1 == 0
    #     assert obj1 is not None
    #
    #     obj2, code2, _ = crud_location.create_location(
    #         db=db_session, new_data=LocationCreate(name="Казань")
    #     )
    #     assert obj2 is None
    #     assert code2 != 0


# TODO добавить пользователя через параметризацию
# TODO использовать фикстуру чтобы эту работу проводить каждый раз при запуске бд
