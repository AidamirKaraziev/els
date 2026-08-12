from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import relationship

from src.session import Base


class RefreshSession(Base):
    """Живая сессия пользователя — одна строка на устройство.

    Хранится не сам refresh-токен, а его SHA-256: утечка дампа базы не даёт
    возможности войти. Наличие строки — единственный источник истины о том,
    жива сессия или нет, поэтому «выйти» и «выйти со всех устройств» работают
    сразу, а не «когда истечёт срок».
    """

    __tablename__ = "refresh_sessions"

    id = Column(Integer, primary_key=True)
    user_id = Column(
        Integer,
        ForeignKey("universal_users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    token_hash = Column(String(64), nullable=False, unique=True)

    created_at = Column(DateTime, nullable=False, server_default=func.now())
    expires_at = Column(DateTime, nullable=False)
    revoked_at = Column(DateTime)

    # Чтобы человек мог узнать свои устройства в списке сессий и понять, какое
    # из них лишнее.
    user_agent = Column(String)
    ip_address = Column(String)

    user = relationship("UniversalUser")
