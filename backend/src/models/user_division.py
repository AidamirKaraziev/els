from sqlalchemy import Column, ForeignKey, Integer

from src.session import Base


class UserDivision(Base):
    """Участки сотрудника.

    Один человек может вести несколько участков — это касается всех ролей, а не
    только прорабов. Держать это списком у пользователя, а не полем
    `division_id`, пришлось потому, что иначе каждая проверка доступа получала
    бы две ветки: «у прораба список, у остальных одно поле».

    `universal_users.division_id` остался как основной участок и продолжает
    отдаваться в ответах API — экраны фронта читают именно его.
    """

    __tablename__ = "user_divisions"

    user_id = Column(
        Integer,
        ForeignKey("universal_users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    division_id = Column(
        Integer,
        ForeignKey("divisions.id", ondelete="CASCADE"),
        primary_key=True,
    )
