"""Push в приложение механика через Firebase Cloud Messaging (HTTP v1).

Телефон узнаёт о новой задаче опросом раз в две минуты — пока приложение
открыто. Закрытое приложение будит только push, и слать его умеет один
сервер. Здесь всё, что для этого нужно: ключ сервисного аккаунта, токен
доступа Google, сама отправка и выбор получателей по заявке.

## Как устроено

* **Без SDK.** `firebase-admin` тянет за собой google-auth, grpc и cachetools
  ради одного HTTP-запроса. Токен доступа получается по протоколу OAuth2
  «JWT bearer»: подписываем утверждение ключом сервисного аккаунта
  (`python-jose` уже в зависимостях) и меняем его на `access_token` — тот
  живёт час, кэшируем в памяти процесса.
* **Отправка после ответа.** Ручка кладёт задачу в `BackgroundTasks`: заявка
  создана, и ответ ушёл, даже если Google не отвечает. Ошибка отправки —
  строка в журнале, не 500.
* **Токены выбираются в запросе, шлются в фоне.** Сессия запроса закрывается
  вместе с ответом, поэтому фоновой задаче достаются готовые строки токенов;
  для удаления мёртвых она открывает свою сессию.
* **Мёртвые токены удаляются.** `UNREGISTERED` — приложение снесли или
  токен сменился; такому адресу слать больше нечего.
* **Ключа нет — push выключен.** `FIREBASE_SERVICE_ACCOUNT` пуст или файла
  нет: одна строка в журнале при первом обращении, дальше тишина. `make dev`
  и тесты живут без Firebase.

## Кому и когда

Заявку видят двое — исполнитель и механик объекта (`get_orders_filtered`),
им и уведомление. Автор действия себя не получает: он только что нажал
кнопку. Шлём по трём событиям — создана, переназначена, снята; смену статуса
телефон и так видит опросом, а после S04 — и по тихому push.
"""

import json
import logging
import threading
import time
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Optional, Sequence

import httpx
from fastapi import BackgroundTasks
from jose import jwt
from sqlalchemy.orm import Session

from src.config import _BACKEND_DIR, settings
from src.crud import crud_device_token
from src.models import Order
from src.session import SessionLocal

_log = logging.getLogger(__name__)

FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
FCM_SEND_URL = "https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

#: Канал уведомлений на телефоне. Заводит фронт (S04) с тем же именем:
#: максимальный приоритет, звук, вибрация — это аварийная заявка.
ANDROID_CHANNEL = "emergency"

#: Ответы FCM, после которых токен можно удалять: устройства с таким адресом
#: больше нет. `INVALID_ARGUMENT` на токен — строка не похожа на токен вовсе.
DEAD_TOKEN_ERRORS = ("UNREGISTERED", "INVALID_ARGUMENT")

# Кто вызывает `send`, чтобы дойти до FCM. Подменяется в тестах.
Transport = Callable[[str, str, dict], "FcmResult"]


class FcmResult:
    """Что FCM ответил на одно сообщение."""

    __slots__ = ("ok", "error")

    def __init__(self, ok: bool, error: Optional[str] = None):
        self.ok = ok
        self.error = error

    @property
    def token_is_dead(self) -> bool:
        return self.error in DEAD_TOKEN_ERRORS


class ServiceAccount:
    """Ключ из консоли Firebase и токен доступа, выписанный по нему."""

    def __init__(self, data: dict):
        self.project_id: str = data["project_id"]
        self.client_email: str = data["client_email"]
        self.private_key: str = data["private_key"]
        self.token_uri: str = data["token_uri"]
        self._access_token: Optional[str] = None
        self._expires_at: float = 0
        self._lock = threading.Lock()

    def access_token(self, client: httpx.Client) -> str:
        """Токен Google на час; за минуту до конца выписывается заново."""
        with self._lock:
            if self._access_token and time.time() < self._expires_at - 60:
                return self._access_token
            now = int(time.time())
            assertion = jwt.encode(
                {
                    "iss": self.client_email,
                    "scope": FCM_SCOPE,
                    "aud": self.token_uri,
                    "iat": now,
                    "exp": now + 3600,
                },
                self.private_key,
                algorithm="RS256",
            )
            response = client.post(
                self.token_uri,
                data={
                    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                    "assertion": assertion,
                },
                timeout=10,
            )
            response.raise_for_status()
            payload = response.json()
            self._access_token = payload["access_token"]
            self._expires_at = time.time() + int(payload.get("expires_in", 3600))
            return self._access_token


_account: Optional[ServiceAccount] = None
_account_loaded = False


def service_account() -> Optional[ServiceAccount]:
    """Ключ из `FIREBASE_SERVICE_ACCOUNT`; `None` — push выключен."""
    global _account, _account_loaded
    if _account_loaded:
        return _account
    _account_loaded = True
    raw = settings.FIREBASE_SERVICE_ACCOUNT
    if not raw:
        _log.info("Push выключен: FIREBASE_SERVICE_ACCOUNT не задан")
        return None
    path = Path(raw)
    if not path.is_absolute():
        path = _BACKEND_DIR / path
    # Docker монтирует отсутствующий файл как пустой каталог — это тот же
    # случай «ключа нет», а не ошибка.
    if not path.is_file():
        _log.warning("Push выключен: ключ Firebase не найден — %s", path)
        return None
    try:
        _account = ServiceAccount(json.loads(path.read_text()))
    except (ValueError, KeyError) as exc:
        _log.error("Push выключен: ключ Firebase не читается (%s): %s", path, exc)
        return None
    _log.info("Push включён: проект Firebase %s", _account.project_id)
    return _account


def enabled() -> bool:
    return service_account() is not None


def build_message(
    *, title: str, body: str, data: Optional[Dict[str, str]] = None
) -> dict:
    """Тело сообщения FCM без адресата — `token` подставляет `send`.

    `notification` показывает система, когда приложение закрыто; `data`
    читает само приложение, когда открыто. Значения `data` — только строки,
    так требует FCM.
    """
    return {
        "notification": {"title": title, "body": body},
        "data": {key: str(value) for key, value in (data or {}).items()},
        "android": {
            "priority": "high",
            "notification": {
                "channel_id": ANDROID_CHANNEL,
                "sound": "default",
                "default_vibrate_timings": True,
            },
        },
    }


def _fcm_post(token: str, access_token: str, message: dict, *, client: httpx.Client):
    """Один запрос к FCM. Возвращает `FcmResult`, наружу не бросает."""
    account = service_account()
    url = FCM_SEND_URL.format(project_id=account.project_id)
    try:
        response = client.post(
            url,
            json={"message": {**message, "token": token}},
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=10,
        )
    except httpx.HTTPError as exc:
        return FcmResult(False, f"network: {exc}")
    if response.is_success:
        return FcmResult(True)
    error = ""
    try:
        body = response.json().get("error", {})
        error = body.get("status", "")
        for detail in body.get("details", []):
            if detail.get("errorCode"):
                error = detail["errorCode"]
    except ValueError:
        pass
    return FcmResult(False, error or f"http {response.status_code}")


#: Подмена доставки для тестов: `None` — живой FCM. Фоновая задача зовёт
#: `send` без аргументов, поэтому подмена живёт на модуле, а не в параметре.
_transport: Optional[Transport] = None
_db_factory: Callable[[], Session] = SessionLocal


def send(tokens: Sequence[str], message: dict) -> int:
    """Отправить сообщение на каждый токен; вернуть, сколько дошло.

    Мёртвые токены удаляются своей сессией — вызов идёт из фоновой задачи,
    когда сессия запроса уже закрыта.
    """
    if not tokens:
        return 0
    account = service_account()
    if account is None:
        return 0
    delivered = 0
    dead: List[str] = []
    transport = _transport
    try:
        with httpx.Client() as client:
            if transport is None:
                access_token = account.access_token(client)

                def transport(token, access, message):
                    return _fcm_post(token, access, message, client=client)

            else:
                access_token = ""
            for token in tokens:
                result = transport(token, access_token, message)
                if result.ok:
                    delivered += 1
                elif result.token_is_dead:
                    dead.append(token)
                else:
                    _log.warning(
                        "Push не ушёл (%s): %s",
                        result.error,
                        message.get("notification"),
                    )
    except Exception:  # noqa: BLE001 — фоновая задача, ронять некого
        _log.exception("Push: отправка сорвалась")
        return delivered
    if dead:
        try:
            db = _db_factory()
            try:
                crud_device_token.drop_tokens(db, dead)
                _log.info("Push: удалено мёртвых токенов — %d", len(dead))
            finally:
                db.close()
        except Exception:  # noqa: BLE001 — не удалили сейчас, удалим в следующий раз
            _log.exception("Push: мёртвые токены не удалены")
    return delivered


# --- получатели по заявке ---------------------------------------------------

KIND_ASSIGNED = "order_assigned"
KIND_REASSIGNED = "order_reassigned"
KIND_REMOVED = "order_removed"


def order_recipients(order: Order) -> List[int]:
    """Исполнитель и механик объекта — те, у кого заявка на телефоне."""
    ids: List[int] = []
    if order.executor_id is not None:
        ids.append(order.executor_id)
    mechanic_id = getattr(order.object, "mechanic_id", None) if order.object else None
    if mechanic_id is not None and mechanic_id not in ids:
        ids.append(mechanic_id)
    return ids


def _order_label(order: Order) -> str:
    name = getattr(order.object, "name", None) if order.object else None
    if name and str(name).strip():
        return str(name).strip()
    return f"Объект №{order.object_id}" if order.object_id else "без объекта"


def notify_order(
    db: Session,
    background: BackgroundTasks,
    *,
    order: Order,
    kind: str,
    actor_id: Optional[int],
    user_ids: Optional[Iterable[int]] = None,
) -> List[int]:
    """Поставить push по заявке в фон. Возвращает, кому он адресован.

    `user_ids` — получатели, если они не совпадают с текущими по заявке
    (прежний исполнитель при переназначении). Автор действия исключается.
    """
    if not enabled():
        return []
    recipients = [
        uid
        for uid in (user_ids if user_ids is not None else order_recipients(order))
        if uid is not None and uid != actor_id
    ]
    if not recipients:
        return []
    tokens = crud_device_token.tokens_for_users(db, recipients)
    if not tokens:
        return recipients

    label = _order_label(order)
    if kind == KIND_ASSIGNED:
        title, body = f"Новая задача №{order.id}", label
    elif kind == KIND_REASSIGNED:
        title, body = f"Задача №{order.id} передана другому", label
    elif kind == KIND_REMOVED:
        title, body = f"Задача №{order.id} снята", label
    else:
        raise ValueError(f"неизвестный вид push: {kind}")
    if order.task_text and kind == KIND_ASSIGNED:
        body = f"{label} — {str(order.task_text).strip()}"[:200]

    message = build_message(
        title=title, body=body, data={"kind": kind, "order_id": order.id}
    )
    background.add_task(send, tokens, message)
    return recipients


if __name__ == "__main__":  # pragma: no cover — ручная проверка ключа
    import argparse

    parser = argparse.ArgumentParser(description="Проверка ключа Firebase и отправки")
    parser.add_argument(
        "--token", help="токен FCM устройства; без него — только токен Google"
    )
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    acc = service_account()
    if acc is None:
        raise SystemExit("ключ не загружен — см. журнал выше")
    with httpx.Client() as c:
        print("access_token получен:", acc.access_token(c)[:24] + "…")
    if args.token:
        n = send(
            [args.token],
            build_message(title="ЕЛС", body="Проверка push", data={"kind": "test"}),
        )
        print("доставлено:", n)
