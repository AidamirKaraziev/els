from sqlalchemy import Column, ForeignKey, Integer
from sqlalchemy.orm import relationship

from src.session import Base


class DefectiveActClientPhoto(Base):
    """Снимок, отобранный в клиентский акт.

    Связь, а не копия файла: один и тот же снимок может уйти в несколько
    клиентских актов, а внутренний акт остаётся первоисточником и не правится.
    Байты лежат там, где их положил механик — в `defective_act_photo`.
    """

    __tablename__ = "defective_act_client_photo"

    client_act_id = Column(
        Integer,
        ForeignKey("defective_acts.id", ondelete="CASCADE"),
        primary_key=True,
    )
    photo_id = Column(
        Integer,
        ForeignKey("defective_act_photo.id", ondelete="CASCADE"),
        primary_key=True,
    )

    client_act = relationship("DefectiveAct", back_populates="client_photos")
    photo = relationship("DefectiveActPhoto")
