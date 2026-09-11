"""Ссылка на файл, которую можно открыть в новой вкладке.

Существует ради одной проблемы: `/api/v1/static/...` требует токена, а
браузер не может послать заголовок `Authorization` ни в `<img src>`, ни при
переходе по ссылке на скачивание. Фронт просит здесь ссылку и открывает её.

Почему не боевой токен в адресе: nginx пишет строку запроса в журнал доступа,
туда же попал бы и он. Токен отсюда привязан к одному файлу и живёт минуту —
см. `core.security.create_file_token`.
"""

from fastapi import APIRouter, Depends, Request

from src.api import deps
from src.config import settings
from src.core.files import parse_owner, resolve_static_path
from src.core.permissions import Permission
from src.core.response import SingleEntityResponse
from src.core.security import create_file_token
from src.exceptions import InaccessibleEntity, UnfoundEntity
from src.getters.static_url import static_base_url
from src.schemas.files import ExportLinkRequest, FileLinkGet, FileLinkRequest
from src.services.file_access import can_download

#: Что вообще можно открыть по короткоживущей ссылке. Ключ приходит от фронта,
#: путь берётся отсюда — подставить свой адрес клиент не может.
EXPORTS = {
    "breakdowns": "/statistics/breakdowns/export",
    "works": "/reports/works/export",
}

router = APIRouter()


@router.post(
    "/files/link",
    response_model=SingleEntityResponse[FileLinkGet],
    name="file_download_link",
    summary="Короткоживущая ссылка на файл",
    description=(
        "Отдаёт адрес файла с одноразовым по смыслу токеном в строке запроса: "
        "его можно открыть в новой вкладке или подставить в `<img src>`, где "
        "заголовок `Authorization` отправить нельзя.\n\n"
        "Токен привязан к этому конкретному файлу и живёт минуту. Доступ "
        "проверяется здесь же — на чужой файл ссылка не выдаётся."
    ),
    tags=["Инструменты"],
)
def create_download_link(
    body: FileLinkRequest,
    request: Request,
    session=Depends(deps.get_db),
    current_user=Depends(deps.require(Permission.FILE_READ)),
    scope=Depends(deps.get_read_scope),
):
    # Путь в базе хранится без ведущего слэша и без префикса `static/` —
    # ровно в том виде, который принимает ручка отдачи файла. Приводим к нему,
    # чтобы токен совпал с тем, что придёт в запросе.
    resolved = resolve_static_path(body.path.lstrip("/"))
    if resolved is None:
        raise UnfoundEntity(
            message="Такого файла нет",
            num=2,
            description="Путь ведёт за пределы каталога загрузок",
            path="$.body",
        )

    # Дальше работаем с раскрытым путём: и токен, и проверка доступа должны
    # относиться к тому файлу, который в итоге будет прочитан.
    path = resolved.relative

    if not can_download(
        db=session, owner=parse_owner(path), user=current_user, scope=scope
    ):
        raise InaccessibleEntity(
            message="Нет доступа к этому файлу",
            num=136,
            description="Файл относится к записи, которая вам не видна",
            path="$.body",
        )

    # Токен привязывается к полному пути запроса — ровно к тому, который
    # придёт в ручку отдачи файла. Сверять по имени файла было бы мало: одна
    # ссылка открывала бы любой адрес.
    token = create_file_token(
        user_id=current_user.id, path=f"{settings.API_V1_STR}/static/{path}"
    )
    return SingleEntityResponse(
        data=FileLinkGet(
            url=f"{static_base_url(request)}{path}?token={token}",
            expires_in=settings.FILE_TOKEN_EXPIRE_SECONDS,
        )
    )


@router.post(
    "/files/export-link",
    response_model=SingleEntityResponse[FileLinkGet],
    name="export_download_link",
    summary="Короткоживущая ссылка на выгрузку отчёта",
    description=(
        "То же, что `/files/link`, но для отчётов, которых нет на диске: "
        "сервер собирает их на лету. Ссылку можно открыть в новой вкладке — "
        "именно этого не хватало кнопке выгрузки топа поломок.\n\n"
        "Разрешён только перечисленный набор адресов, произвольный путь "
        "подписать нельзя."
    ),
    tags=["Инструменты"],
)
def create_export_link(
    body: ExportLinkRequest,
    request: Request,
    current_user=Depends(deps.require(Permission.STATISTICS_READ)),
):
    # Список закрытый: подписывать произвольный путь нельзя, иначе ссылка на
    # минуту превращается в токен доступа ко всему API.
    if body.export not in EXPORTS:
        raise UnfoundEntity(
            message="Неизвестная выгрузка",
            num=2,
            description="Доступные выгрузки: " + ", ".join(sorted(EXPORTS)),
            path="$.body",
        )

    path = f"{settings.API_V1_STR}{EXPORTS[body.export]}"
    token = create_file_token(user_id=current_user.id, path=path)
    # Список — повторяющийся параметр: так FastAPI читает `List[int] = Query`.
    query = "&".join(
        f"{key}={item}"
        for key, value in body.params.items()
        for item in (value if isinstance(value, list) else [value])
    )
    separator = "&" if query else ""

    return SingleEntityResponse(
        data=FileLinkGet(
            url=f"{request.url.netloc}{path}?{query}{separator}token={token}",
            expires_in=settings.FILE_TOKEN_EXPIRE_SECONDS,
        )
    )
