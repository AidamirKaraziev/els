"""Сессии: выдача, ротация и отзыв refresh-токенов."""

from datetime import datetime, timedelta
from typing import List, Optional, Tuple

from sqlalchemy.orm import Session

from src.config import settings
from src.core.security import (
    generate_refresh_token,
    hash_refresh_token,
)
from src.models import RefreshSession

# Ротация гасит старый токен и выдаёт новый. Приложение при старте легко
# отправляет два запроса на обновление разом — оба с одним токеном. Второй
# придёт на уже погашенную сессию, и без этой поблажки человека выкинуло бы
# из системы на ровном месте.
#
# Поэтому: повторное использование сразу после ротации считаем гонкой и просто
# отказываем; позже — считаем кражей и гасим все сессии человека.
REUSE_GRACE_SECONDS = 30


class RefreshTokenInvalid(Exception):
    """Токен не найден, просрочен или уже погашен."""


class RefreshTokenReused(Exception):
    """Погашенный токен предъявлен снова — похоже на кражу.

    Все сессии пользователя к этому моменту уже отозваны.
    """


class CRUDRefreshSession:
    def create(
        self,
        db: Session,
        *,
        user_id: int,
        user_agent: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> Tuple[str, RefreshSession]:
        """Заводит сессию и возвращает `(токен, строку)`.

        Сам токен возвращается **только здесь и только сейчас** — в базе от
        него остаётся SHA-256, восстановить исходное значение нельзя.
        """
        token = generate_refresh_token()
        session = RefreshSession(
            user_id=user_id,
            token_hash=hash_refresh_token(token),
            created_at=datetime.utcnow(),
            expires_at=datetime.utcnow()
            + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            user_agent=(user_agent or "")[:512] or None,
            ip_address=ip_address,
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        return token, session

    def get_by_token(self, db: Session, *, token: str) -> Optional[RefreshSession]:
        return (
            db.query(RefreshSession)
            .filter(RefreshSession.token_hash == hash_refresh_token(token))
            .first()
        )

    def rotate(
        self,
        db: Session,
        *,
        token: str,
        user_agent: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> Tuple[str, RefreshSession]:
        """Гасит предъявленную сессию и заводит новую взамен."""
        session = self.get_by_token(db, token=token)
        if session is None:
            raise RefreshTokenInvalid("Сессия не найдена")

        if session.revoked_at is not None:
            revoked_long_ago = (
                datetime.utcnow() - session.revoked_at
            ).total_seconds() > REUSE_GRACE_SECONDS
            if revoked_long_ago:
                # Токен, погашенный при ротации, всплыл снова: либо его увели,
                # либо у кого-то осталась копия. Дешевле выгнать всех и
                # заставить войти заново, чем гадать.
                self.revoke_all_for_user(db, user_id=session.user_id)
                raise RefreshTokenReused("Повторное использование refresh-токена")
            raise RefreshTokenInvalid("Сессия уже обновлена")

        if session.expires_at <= datetime.utcnow():
            raise RefreshTokenInvalid("Срок сессии истёк")

        session.revoked_at = datetime.utcnow()
        db.add(session)
        db.commit()

        return self.create(
            db,
            user_id=session.user_id,
            # Устройство то же самое: подписи берём из нового запроса, чтобы в
            # списке сессий не оставалось устаревших данных.
            user_agent=user_agent or session.user_agent,
            ip_address=ip_address or session.ip_address,
        )

    def revoke(self, db: Session, *, token: str) -> bool:
        """Гасит одну сессию. Возвращает, было ли что гасить."""
        session = self.get_by_token(db, token=token)
        if session is None or session.revoked_at is not None:
            return False
        session.revoked_at = datetime.utcnow()
        db.add(session)
        db.commit()
        return True

    def revoke_all_for_user(self, db: Session, *, user_id: int) -> int:
        """Гасит все живые сессии пользователя. Возвращает их число."""
        count = (
            db.query(RefreshSession)
            .filter(
                RefreshSession.user_id == user_id,
                RefreshSession.revoked_at.is_(None),
            )
            .update({"revoked_at": datetime.utcnow()}, synchronize_session=False)
        )
        db.commit()
        return count

    def active_for_user(self, db: Session, *, user_id: int) -> List[RefreshSession]:
        return (
            db.query(RefreshSession)
            .filter(
                RefreshSession.user_id == user_id,
                RefreshSession.revoked_at.is_(None),
                RefreshSession.expires_at > datetime.utcnow(),
            )
            .order_by(RefreshSession.created_at.desc())
            .all()
        )

    def delete_expired(self, db: Session) -> int:
        """Убирает протухшие и погашенные строки.

        Таблица растёт при каждом входе и каждом обновлении токена, а
        пользы от старых строк нет.
        """
        count = (
            db.query(RefreshSession)
            .filter(RefreshSession.expires_at <= datetime.utcnow())
            .delete(synchronize_session=False)
        )
        db.commit()
        return count


crud_refresh_sessions = CRUDRefreshSession()
