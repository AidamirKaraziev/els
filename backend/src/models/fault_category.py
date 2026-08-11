from sqlalchemy import Boolean, Column, Integer, String

from src.session import Base


class FaultCategory(Base):
    """Категория заявки по отраслевой классификации: AA, А, В, Н, Д, ТО, ПТО, КР, С, Л.

    Категория задаёт не «что сломалось», а тяжесть события: AA — застревание
    пассажира, Н — мелочь, ТО — вообще плановая работа. Статистика поломок
    опирается на два служебных поля ниже, а не на разбор `name` по скобкам.
    """

    __tablename__ = "fault_category"
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, unique=True)

    # Короткий код из классификации ("AA", "А", "ТО"). Нужен там, где полное
    # имя не помещается — например в чипах свода на главной.
    code = Column(String)

    # Считать ли заявки этой категории поломкой. False у плановых работ
    # (ТО, ПТО), капремонта и ложных вызовов: в топ поломок они не идут.
    # Флаг в БД, а не список id в коде, — чтобы новая категория,
    # заведённая админом, не ломала статистику молча.
    counts_as_breakdown = Column(
        Boolean, nullable=False, server_default="true", default=True
    )
