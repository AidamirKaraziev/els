from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from src.models import FactoryModel, TypeAct
from src.session import Base


class ActBase(Base):
    __tablename__ = "acts_bases"
    id = Column(Integer, primary_key=True)
    factory_model_id = Column(
        Integer, ForeignKey("factories_models.id", ondelete="SET NULL")
    )
    type_act_id = Column(Integer, ForeignKey("types_acts.id", ondelete="SET NULL"))
    #: Чек-лист шаблона — каноническая форма `services.checklist`; в старых
    #: строках встречаются и прежние формы, читать только через `parse_checklist`.
    step_list = Column(String)

    #: Мягкое удаление вида ТО у модели. Настоящий `DELETE` обнулил бы
    #: `acts_fact.act_base_id` (FK `SET NULL`) у уже созданных актов, а по нему
    #: график узнаёт вид ТО акта. Удалённую пару мастер графика не предлагает.
    deleted_at = Column(DateTime)

    factory_model = relationship(FactoryModel)
    type_act = relationship(TypeAct)

    __table_args__ = (
        UniqueConstraint(
            "factory_model_id", "type_act_id", name="_type_act_factory_model_uc"
        ),
    )
