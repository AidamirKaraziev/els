# from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
# from sqlalchemy.orm import relationship
#
# from .act_fact import ActFact
# from .universal_user import UniversalUser
# from src.db.base_class import Base
#
#
# class ActFactOfMechanic(Base):
#     __tablename__ = 'acts_fact_of_mechanic'
#     id = Column(Integer, primary_key=True)
#     act_fact_id = Column(Integer, ForeignKey(ActFact.id, ondelete="CASCADE"),  nullable=False)
#     mechanic_id = Column(Integer, ForeignKey(UniversalUser.id, ondelete="CASCADE"),  nullable=False)
#
#     act_fact = relationship('ActFact', back_populates='acts_fact_of_mechanic')
#
#     mechanic = relationship('UniversalUser', back_populates='acts_fact_of_mechanic')
#
#     __table_args__ = (UniqueConstraint('act_fact_id', 'mechanic_id'),)

"""Мне не нравится эта модель базы данных, я не понимаю что это!)"""
