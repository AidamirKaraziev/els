"""Ссылки на загруженные файлы должны вести туда, откуда пришёл клиент.

Регрессия: тринадцать геттеров собирали адрес как
`request.url.hostname + ":" + APP_PORT`, то есть подставляли порт 8000 из
настроек вместо реального. Браузер ходит через nginx на 80 или 8080, порт
8000 наружу не публикуется — каждая аватарка отваливалась с
`ERR_EMPTY_RESPONSE`.
"""

import pytest
from starlette.requests import Request

from src.getters.static_url import static_base_url


def _request(host_header: str) -> Request:
    """Минимальный ASGI-scope: важен только заголовок Host."""
    return Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/api/v1/divisions/",
            "headers": [(b"host", host_header.encode())],
            "scheme": "http",
            "server": ("backend", 8000),
            "query_string": b"",
        }
    )


@pytest.mark.parametrize(
    "host_header",
    [
        "localhost:8080",
        "213.171.3.254:8080",
        "els.example.ru",
        "localhost",
    ],
)
def test_url_keeps_the_host_client_used(host_header: str):
    assert static_base_url(_request(host_header)) == f"{host_header}/api/v1/static/"


def test_internal_port_never_leaks_into_the_url():
    """Порт бэкенда внутри сети (8000) наружу попадать не должен."""
    url = static_base_url(_request("localhost:8080"))

    assert ":8000" not in url


def test_no_scheme_is_added():
    """Фронт в десятках мест сам дописывает `http://` — иначе выйдет http://http://."""
    url = static_base_url(_request("localhost:8080"))

    assert not url.startswith("http")


def test_without_request_there_is_no_url():
    """Часть геттеров зовут из генерации PDF, где Request взять неоткуда."""
    assert static_base_url(None) is None
