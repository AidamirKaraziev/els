"""Выгрузка отчёта «Топ поломок» в PDF.

Проверяем не вёрстку — её проверяют глазами, — а то, что файл действительно
собирается, отдаётся как PDF и не разъезжается с тем, что показано на экране.
"""

import datetime
import itertools
import uuid

import pytest

from src.config import settings
from src.core.roles import ADMIN, CLIENT_ID
from src.models import Object, Order

URL = f"{settings.API_V1_STR}/statistics/breakdowns/export"
REPORT_URL = f"{settings.API_V1_STR}/statistics/breakdowns"

CAT_AA = 1
CAT_A = 2
CAT_TO = 6


@pytest.fixture
def make_object(db_session):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(**kwargs):
        number = next(counter)
        obj = Object(
            name=kwargs.pop("name", f"Лифт {number}"),
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            **kwargs,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def make_order(db_session):
    def _make(obj, created_at, fault_category_id=CAT_A):
        order = Order(
            object_id=obj.id,
            creator_id=1,
            created_at=created_at,
            fault_category_id=fault_category_id,
        )
        db_session.add(order)
        db_session.flush()
        return order

    return _make


def _get(client, **params):
    params.setdefault("year", 2026)
    params.setdefault("month", 5)
    return client.get(URL, params=params)


class TestAccess:
    @pytest.mark.integration
    def test_requires_authentication(self, client_with_db):
        # 401, а не 403: отсутствие токена и нехватка прав — разные
        # ситуации, и перехватчик на фронте обновляет токен именно по 401.
        assert _get(client_with_db).status_code == 401

    @pytest.mark.integration
    def test_client_role_is_rejected(self, client_with_db, as_role):
        as_role(CLIENT_ID)
        assert _get(client_with_db).status_code != 200


class TestFile:
    @pytest.mark.integration
    def test_returns_a_real_pdf(self, client_with_db, as_role, make_object, make_order):
        as_role(ADMIN)
        obj = make_object(name="Лифт 12", address="ул. Красная, 1")
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=CAT_AA)

        response = _get(client_with_db)

        assert response.status_code == 200
        assert response.headers["content-type"] == "application/pdf"
        # Сигнатура формата: если вместо файла придёт HTML с ошибкой,
        # заголовки могут соврать, а первые байты — нет.
        assert response.content.startswith(b"%PDF-")
        assert len(response.content) > 1000

    @pytest.mark.integration
    def test_empty_month_still_produces_a_file(self, client_with_db, as_role):
        """Тихий месяц — это отчёт «поломок нет», а не ошибка."""
        as_role(ADMIN)

        response = _get(client_with_db)

        assert response.status_code == 200
        assert response.content.startswith(b"%PDF-")

    @pytest.mark.integration
    def test_filename_is_offered_for_download(self, client_with_db, as_role):
        as_role(ADMIN)

        disposition = _get(client_with_db).headers["content-disposition"]

        assert disposition.startswith("attachment;")
        assert "breakdowns-2026-05.pdf" in disposition
        # Кириллическое имя уходит по RFC 5987: заголовок ходит в latin-1,
        # и положить его в обычный filename нельзя.
        assert "filename*=UTF-8''" in disposition


class TestConsistencyWithScreen:
    @pytest.mark.integration
    def test_export_covers_every_object_not_just_the_first_page(
        self, client_with_db, as_role, make_object, make_order
    ):
        """Файл печатают и отправляют заказчику — он должен быть полным."""
        as_role(ADMIN)
        for index in range(7):
            obj = make_object()
            make_order(obj, datetime.datetime(2026, 5, 2 + index))

        # Экран по умолчанию просит пять строк, а выгрузка — все.
        on_screen = client_with_db.get(
            REPORT_URL, params={"year": 2026, "month": 5}
        ).json()["data"]
        assert len(on_screen["items"]) == 5
        assert on_screen["objects_affected"] == 7

        assert _get(client_with_db).status_code == 200

    @pytest.mark.integration
    def test_planned_works_are_excluded_here_too(
        self, client_with_db, as_role, make_object, make_order
    ):
        """Цифры в файле и на экране считаются одним и тем же кодом."""
        as_role(ADMIN)
        obj = make_object()
        make_order(obj, datetime.datetime(2026, 5, 2), fault_category_id=CAT_A)
        make_order(obj, datetime.datetime(2026, 5, 3), fault_category_id=CAT_TO)

        report = client_with_db.get(
            REPORT_URL, params={"year": 2026, "month": 5}
        ).json()["data"]

        assert report["total_breakdowns"] == 1
        assert _get(client_with_db).status_code == 200
