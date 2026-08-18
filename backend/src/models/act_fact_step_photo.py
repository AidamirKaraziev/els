from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import relationship

from src.session import Base


class ActFactStepPhoto(Base):
    """Снимок к одному пункту чек-листа фактического акта.

    Отдельная таблица, потому что раньше мобильное приложение клало байты
    снимка прямо в текстовое поле `acts_fact.step_list_fact` — строка акта
    разрасталась до сотен килобайт, и список ТО невозможно было открыть с
    телефона. Устройство то же, что у фотографий заявок: на диске файл, в базе
    относительный путь, наружу — через `static_base_url`.
    """

    __tablename__ = "acts_fact_step_photos"

    id = Column(Integer, primary_key=True, autoincrement=True)
    act_fact_id = Column(
        Integer, ForeignKey("acts_fact.id", ondelete="CASCADE"), nullable=False
    )
    #: Номер шага внутри акта — тот же `id`, что в канонической форме
    #: чек-листа. Шаги нельзя переставлять после начала работ: снимок ссылается
    #: на номер, а не на текст пункта.
    step_id = Column(Integer, nullable=False)
    photo = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    act_fact = relationship("ActFact")

    __table_args__ = (
        # Основной запрос — «снимки этого акта», и почти всегда следом «этого
        # шага». Один составной индекс закрывает оба.
        Index("ix_acts_fact_step_photos_act_step", "act_fact_id", "step_id"),
    )
