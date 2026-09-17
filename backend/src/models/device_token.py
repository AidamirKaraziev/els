from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import relationship

from src.session import Base


class DeviceToken(Base):
    """Адрес телефона для push — одна строка на устройство.

    Не поле в `refresh_sessions`, а своя таблица: токен FCM живёт дольше
    входа. Человек выходит и входит снова — устройство то же, и токен тот же;
    сессий за это время может смениться несколько, а слать нужно ровно в один
    телефон. Токен уникален сам по себе: если он пришёл под другим
    пользователем, телефон сменил хозяина, и строка перевешивается, а не
    дублируется.
    """

    __tablename__ = "device_tokens"

    id = Column(Integer, primary_key=True)
    user_id = Column(
        Integer,
        ForeignKey("universal_users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    token = Column(String, nullable=False, unique=True)

    # Пока только `android`; поле есть, чтобы iOS не потребовал миграции.
    platform = Column(String(16), nullable=False, server_default="android")

    created_at = Column(DateTime, nullable=False, server_default=func.now())
    # Обновляется при каждой регистрации: по нему видно, какие телефоны давно
    # не выходили на связь.
    updated_at = Column(
        DateTime, nullable=False, server_default=func.now(), onupdate=func.now()
    )

    user = relationship("UniversalUser")
