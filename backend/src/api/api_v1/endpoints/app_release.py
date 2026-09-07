"""Раздача мобильного приложения механикам.

Механик работает в лифтовом помещении, где связи нет, поэтому веб-версии ему
мало — нужен установленный APK. Взять его неоткуда: в магазины приложение не
выложено, а ссылка на файл в открытом доступе означала бы, что сборку со
всеми внутренними адресами скачивает кто угодно.

Отсюда устройство: файл лежит в том же томе, что и остальные загрузки, а
наружу смотрит только через проверку доступа.

* **Скачивание требует входа.** Права отдельного нет — приложение положено
  всем, кто вообще работает в системе; проверяется сам факт входа.
* **Ссылка короткоживущая.** Заголовок `Authorization` браузер не пошлёт при
  переходе по ссылке на скачивание, поэтому фронт просит ссылку с токеном в
  адресе — тот же приём, что и у `files.py`, и по той же причине.
* **Байты отдаёт nginx.** `X-Accel-Redirect` во внутренний `location`: APK
  весит десятки мегабайт, и тянуть их через uvicorn на машине с одним ядром
  значит занять единственный рабочий процесс на всё время скачивания.
"""

from urllib.parse import quote

from fastapi import APIRouter, Depends, Request, Response

from src.api import deps
from src.config import settings
from src.core.app_release import read_release
from src.core.response import SingleEntityResponse
from src.core.security import create_file_token
from src.exceptions import UnfoundEntity
from src.schemas.app_release import AppReleaseGet
from src.schemas.files import FileLinkGet

router = APIRouter()

#: Путь ручки скачивания. Один на всех: имя файла в него не входит, поэтому
#: токен нельзя переиспользовать для другого файла, а адрес не меняется от
#: версии к версии — приложение может помнить его между обновлениями.
DOWNLOAD_PATH = f"{settings.API_V1_STR}/app/download"


def _release_or_404():
    release = read_release()
    if release is None:
        raise UnfoundEntity(
            message="Приложение ещё не выложено",
            num=2,
            description="На сервере нет сборки для скачивания",
            path="$.path",
        )
    return release


@router.get(
    "/app/release",
    response_model=SingleEntityResponse[AppReleaseGet],
    name="Какая версия приложения выложена",
    summary="Что за сборка лежит на сервере",
    description=(
        "Версия, размер и «что нового» — то, что показывает страница "
        "скачивания.\n\n"
        "Той же ручкой приложение узнаёт, что вышло обновление: `version_code` "
        "больше своего — значит пора обновиться.\n\n"
        "`404`, пока APK на сервер не положили."
    ),
    tags=["Мобильное приложение"],
)
def get_app_release(current_user=Depends(deps.get_current_user)):
    release = _release_or_404()
    return SingleEntityResponse(
        data=AppReleaseGet(
            version_name=release.version_name,
            version_code=release.version_code,
            size=release.size,
            sha256=release.sha256,
            published_at=release.published_at,
            notes=release.notes,
        )
    )


@router.post(
    "/app/link",
    response_model=SingleEntityResponse[FileLinkGet],
    name="Ссылка на скачивание приложения",
    summary="Короткоживущая ссылка на APK",
    description=(
        "Адрес, который можно открыть переходом по ссылке: заголовок "
        "`Authorization` браузер при скачивании не отправляет.\n\n"
        "Токен привязан к этому одному адресу и живёт минуту."
    ),
    tags=["Мобильное приложение"],
)
def create_app_link(request: Request, current_user=Depends(deps.get_current_user)):
    # Проверяем до выдачи ссылки: подписывать адрес файла, которого нет,
    # значит отдать человеку ссылку, ведущую в 404 через минуту молчания.
    _release_or_404()

    token = create_file_token(user_id=current_user.id, path=DOWNLOAD_PATH)
    return SingleEntityResponse(
        data=FileLinkGet(
            url=f"{request.url.netloc}{DOWNLOAD_PATH}?token={token}",
            expires_in=settings.FILE_TOKEN_EXPIRE_SECONDS,
        )
    )


@router.get(
    "/app/download",
    name="Скачать приложение",
    summary="Сам файл APK",
    description=(
        "Отдаёт установочный файл. Требует токена: либо заголовок "
        "`Authorization`, либо короткоживущий `?token=` из `POST "
        "/api/v1/app/link`."
    ),
    tags=["Мобильное приложение"],
)
def download_app(current_user=Depends(deps.get_link_requester)):
    release = _release_or_404()

    # Тип именно такой: с ним Android предлагает установку, а не открытие в
    # неизвестно чём.
    content_type = "application/vnd.android.package-archive"
    headers = {
        # Без этого файл сохраняется под именем ручки — «download» без
        # расширения, который телефон поставить не предложит.
        "Content-Disposition": f'attachment; filename="{release.file_name}"',
    }

    if settings.X_ACCEL_REDIRECT:
        headers["X-Accel-Redirect"] = (
            f"{settings.X_ACCEL_LOCATION}/{quote(release.relative)}"
        )
        return Response(b"", media_type=content_type, headers=headers)

    # Путь без nginx — `make dev` и тесты. Файл читается целиком в память:
    # на боевом стенде эта ветка не работает, а десятки мегабайт локально
    # никому не мешают.
    with open(release.path, "rb") as f:
        content = f.read()

    return Response(content, media_type=content_type, headers=headers)
