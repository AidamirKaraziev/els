"""Ссылки на загруженные файлы: фото, сканы, PDF.

Раньше каждый из тринадцати геттеров собирал префикс сам, и все тринадцать
собирали его неправильно:

    request.url.hostname + ":" + str(settings.APP_PORT) + API_V1_STR + "/static/"

`hostname` — это только имя хоста, без порта, а порт дописывался из настроек
и всегда был 8000. Браузер же приходит через nginx на 80 или 8080, и порт
8000 наружу вообще не опубликован. Получалась ссылка на адрес, где никто не
отвечает: `ERR_EMPTY_RESPONSE` на каждой аватарке.

`request.url.netloc` — это заголовок `Host` целиком, вместе с портом, то есть
ровно тот адрес, по которому клиент к нам пришёл. Ссылка сама подстраивается
под localhost:8080, под IP сервера и под домен, без единой настройки.

Чтобы это работало через nginx, он должен передавать `Host` без потерь:
`proxy_set_header Host $http_host` (у `$host` порт отрезан).

Схему (`http://`) здесь не добавляем намеренно: фронт в десятках мест делает
`'http://${photo}'` сам, и добавить её значило бы получить `http://http://`.
Когда фронт переведут на HTTPS, чинить придётся обе стороны разом.
"""

from typing import Optional

from fastapi import Request

from src.config import Settings, settings


def static_base_url(
    request: Optional[Request], config: Settings = settings
) -> Optional[str]:
    """Префикс вида `host:port/api/v1/static/`.

    Возвращает None, если запроса нет: часть геттеров вызывают из фоновых
    задач и генерации PDF, где `Request` взять неоткуда.
    """
    if request is None:
        return None
    return f"{request.url.netloc}{config.API_V1_STR}/static/"
