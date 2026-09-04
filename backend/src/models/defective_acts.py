from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import relationship

from src.models import PlannedTO, Status
from src.session import Base

#: Жизненный цикл акта: Создан → Просмотрен прорабом → Оформлен клиенту →
#: Устранён. К общему справочнику `statuses` отношения не имеет, как и к пяти
#: состояниям ТО (`MaintenanceStatus` в `src/schemas/reports.py`) — это третий,
#: свой цикл.
DEFECTIVE_ACT_STATES = ("created", "reviewed", "issued", "fixed")

#: Внутренний акт заводит механик, клиентский порождается из него и уходит
#: наружу только в виде PDF.
DEFECTIVE_ACT_KINDS = ("internal", "client")


class DefectiveAct(Base):
    """Дефектный акт.

    Заводится из четырёх мест: из работы по ТО (`act_fact_id`), с отдельного
    пункта чек-листа (`act_fact_id` + `checklist_step_id`), по аварийной заявке
    (`order_id`) и просто пунктом меню — тогда известен только объект. Поэтому
    единственная обязательная привязка здесь `object_id`, а не пара
    `planned_to_id` + `month`, как было раньше: три входа из четырёх в неё не
    ложатся.
    """

    __tablename__ = "defective_acts"
    id = Column(Integer, primary_key=True, autoincrement=True)

    #: Ось, по которой акт находится всегда: список и счётчик за год окно
    #: графика спрашивает по объекту.
    object_id = Column(
        Integer, ForeignKey("objects.id", ondelete="CASCADE"), nullable=False
    )

    #: Плановое ТО и месяц больше не обязательны: вычисляются, когда известны.
    #: Записи, заведённые старой ручкой, продолжают их заполнять.
    planned_to_id = Column(Integer, ForeignKey("planned_to.id", ondelete="SET NULL"))
    month = Column(Integer)

    #: Работа по ТО, на которой дефект замечен.
    act_fact_id = Column(Integer, ForeignKey("acts_fact.id", ondelete="SET NULL"))

    #: Номер пункта чек-листа внутри `act_fact_id` — не внешний ключ, а тот же
    #: номер, что у `ActFactStepPhoto.step_id`: шаги живут внутри акта.
    checklist_step_id = Column(Integer)

    #: Аварийная заявка, по которой дефект замечен.
    order_id = Column(Integer, ForeignKey("order.id", ondelete="SET NULL"))

    kind = Column(String, nullable=False, server_default="internal", default="internal")

    #: Клиентский акт — отдельная запись, порождённая механиковской. Фото не
    #: копируются (см. `DefectiveActClientPhoto`), первоисточник не правится.
    parent_id = Column(Integer, ForeignKey("defective_acts.id", ondelete="SET NULL"))

    title = Column(String, nullable=False)
    description = Column(Text)

    #: Тексты клиентского акта: наружу уходит не то же самое, что механик
    #: писал для себя.
    client_title = Column(String)
    client_description = Column(Text)

    state = Column(String, nullable=False, server_default="created", default="created")

    responsible_user_id = Column(
        Integer, ForeignKey("universal_users.id", ondelete="SET NULL")
    )
    created_by_user_id = Column(
        Integer, ForeignKey("universal_users.id", ondelete="SET NULL")
    )

    #: Устарел: цикл акта живёт в `state`. Колонка оставлена ради старого
    #: контракта и накопленных записей, новый код на неё не смотрит.
    status_id = Column(
        Integer, ForeignKey("statuses.id", ondelete="CASCADE"), default=1
    )

    pdf_file = Column(String)

    created_at = Column(DateTime, default=datetime.now, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.now, onupdate=datetime.now, nullable=False
    )

    planned_to = relationship(PlannedTO)
    object = relationship("Object")
    act_fact = relationship("ActFact")
    order = relationship("Order")
    parent = relationship("DefectiveAct", remote_side=[id])
    responsible_user = relationship("UniversalUser", foreign_keys=[responsible_user_id])
    created_by_user = relationship("UniversalUser", foreign_keys=[created_by_user_id])
    status = relationship(Status)

    photos = relationship(
        "DefectiveActPhoto",
        back_populates="defective_act",
        cascade="all, delete-orphan",
    )

    #: Снимки, отобранные в этот клиентский акт. Пусто у внутреннего.
    client_photos = relationship(
        "DefectiveActClientPhoto",
        back_populates="client_act",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        CheckConstraint("kind IN ('internal', 'client')", name="_defective_act_kind"),
        CheckConstraint(
            "state IN ('created', 'reviewed', 'issued', 'fixed')",
            name="_defective_act_state",
        ),
        # Клиентский акт без первоисточника — акт, взявшийся из ниоткуда:
        # наружу ушёл бы текст, за которым не стоит осмотра механика.
        CheckConstraint(
            "kind <> 'client' OR parent_id IS NOT NULL",
            name="_defective_act_client_has_parent",
        ),
        Index("ix_defective_acts_object_id", "object_id"),
    )
