"""Отправка писем.

Почтового ящика у проекта пока нет, поэтому отправка закрыта заглушкой: без
`SMTP_HOST` в `.env` письмо не уходит, а пишется в лог. Механизм сброса
пароля при этом рабочий целиком — не хватает только транспорта.

Когда реквизиты появятся, включать ничего не надо: `EMAILS_ENABLED` считается
из наличия `SMTP_HOST`, `SMTP_PORT` и `EMAILS_FROM_EMAIL` (см. `config.py`).
"""

import logging
import smtplib
from email.message import EmailMessage

from src.config import settings

_log = logging.getLogger(__name__)


def send_email(*, to: str, subject: str, body: str) -> bool:
    """Отправляет письмо. Возвращает, ушло ли оно на самом деле.

    Исключения наружу не выпускает: недоступный почтовый сервер не должен
    ронять запрос, из-за которого письмо отправлялось.
    """
    if not settings.EMAILS_ENABLED:
        _log.warning(
            "Почта не настроена (нет SMTP_HOST в .env). Письмо для %s не отправлено. "
            "Тема: %s",
            to,
            subject,
        )
        # Тело в лог не пишем: в письме сброса пароля лежит ссылка, дающая
        # вход в систему, а логи читают и хранят дольше, чем письма.
        return False

    message = EmailMessage()
    message["From"] = f"{settings.EMAILS_FROM_NAME} <{settings.EMAILS_FROM_EMAIL}>"
    message["To"] = to
    message["Subject"] = subject
    message.set_content(body)

    try:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as smtp:
            if settings.SMTP_TLS:
                smtp.starttls()
            if settings.SMTP_USER and settings.SMTP_PASSWORD:
                smtp.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            smtp.send_message(message)
    except Exception as exc:  # noqa: BLE001 - причин отказа много, все внешние
        _log.error("Не удалось отправить письмо на %s: %s", to, exc)
        return False

    _log.info("Письмо отправлено на %s, тема: %s", to, subject)
    return True


def send_password_reset(*, to: str, name: str, reset_token: str) -> bool:
    link = f"{settings.SERVER_HOST}/reset-password?token={reset_token}"
    hours = settings.PASSWORD_RESET_TOKEN_EXPIRE_HOURS
    body = (
        f"{name or 'Здравствуйте'}!\n\n"
        "Кто-то запросил смену пароля для вашей учётной записи в ЕЛС.\n"
        f"Чтобы задать новый пароль, перейдите по ссылке:\n\n{link}\n\n"
        f"Ссылка действует {hours} ч. Если вы не запрашивали смену пароля, "
        "просто не открывайте её — текущий пароль продолжит работать.\n"
    )
    return send_email(to=to, subject="Смена пароля в ЕЛС", body=body)
