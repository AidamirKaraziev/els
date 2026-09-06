from typing import List, Optional

from pydantic import BaseModel

from src.schemas.defective_act_photo import DefectiveActPhotoGet
from src.schemas.planned_to import PlannedTOGet
from src.schemas.status import StatusGet
from src.schemas.type_act import TypeActGet
from src.schemas.universal_user import UniversalUserGet


class DefectiveActCreate(BaseModel):
    """Тело создания акта: одна привязка обязательна, но любая из четырёх.

    Обязательных полей ровно столько же, сколько было, — `title`. Старый
    клиент шлёт `planned_to_id` + `month` и получает прежний результат, новый
    может прислать `act_fact_id`, `order_id` или один `object_id`. Что именно
    прислано и не спорят ли привязки между собой, проверяет
    `CrudDefectiveAct._resolve_object`: там же лежит доступ к самим ссылкам.
    """

    object_id: Optional[int]
    planned_to_id: Optional[int]
    month: Optional[int]
    act_fact_id: Optional[int]
    #: Номер пункта чек-листа внутри `act_fact_id`, не внешний ключ.
    checklist_step_id: Optional[int]
    order_id: Optional[int]

    title: str
    description: Optional[str]
    responsible_user_id: Optional[int]


class DefectiveActUpdate(BaseModel):
    planned_to_id: Optional[int]
    month: Optional[int]
    title: Optional[str]
    description: Optional[str]
    responsible_user_id: Optional[int]


class DefectiveActStatusUpdate(BaseModel):
    status_id: int


class DefectiveActStateUpdate(BaseModel):
    """Состояние акта: `created` / `reviewed` / `issued` / `fixed`."""

    state: str


class DefectiveActIssueToClient(BaseModel):
    """Оформление клиенту: свои тексты и отобранные снимки первоисточника.

    Тексты необязательны — пустые берутся из внутреннего акта. `photo_ids` —
    id снимков этого же акта; пустой список допустим, акт может уйти и без фото.
    """

    client_title: Optional[str]
    client_description: Optional[str]
    photo_ids: List[int] = []


class DefectiveActChildGet(BaseModel):
    """Клиентский акт в списке у своего первоисточника.

    Узкая нарочно: полная `DefectiveActGet` внутри себя утянула бы рекурсию,
    снимки и развёрнутое плановое ТО — в каждую строку ленты объекта. Здесь
    ровно то, чем прораб отличает один выпуск от другого: когда оформлен, под
    каким заголовком и есть ли готовый файл.
    """

    id: int
    client_title: Optional[str]
    state: Optional[str]
    pdf_file: Optional[str]
    created_at: Optional[int]


class DefectiveActGet(BaseModel):
    id: int

    #: Единственная привязка, которая есть у любого акта.
    object_id: Optional[int]

    planned_to_id: Optional[PlannedTOGet]
    #: Пуст у актов, заведённых не с планового ТО.
    month: Optional[int]

    act_fact_id: Optional[int]
    checklist_step_id: Optional[int]
    order_id: Optional[int]

    #: Вид ТО той работы, на которой дефект замечен: `act_fact` → `act_base`
    #: → `type_act`. Пуст у актов, заведённых по заявке или прямо с объекта —
    #: там работы по ТО нет вовсе. Разворачивается здесь, а не вычисляется
    #: клиентом: `act_fact_id` уходит наружу голым числом, и пройти цепочку
    #: с фронта нечем.
    type_act: Optional[TypeActGet]

    title: str
    description: Optional[str]

    #: `internal` — акт механика, `client` — порождённый из него для клиента.
    kind: Optional[str]
    state: Optional[str]
    parent_id: Optional[int]
    client_title: Optional[str]
    client_description: Optional[str]

    responsible_user_id: Optional[UniversalUserGet]
    created_by_user_id: Optional[UniversalUserGet]

    status_id: Optional[StatusGet]
    pdf_file: Optional[str]

    created_at: Optional[int]
    updated_at: Optional[int]

    photos: List[DefectiveActPhotoGet] = []
    #: Снимки, отобранные в клиентский акт. У внутреннего пусто.
    client_photos: List[DefectiveActPhotoGet] = []

    #: Что из этого акта уже ушло клиенту. У самого клиентского пусто.
    #: Выпусков может быть несколько: акт мог уйти дважды, с разным набором фото.
    client_acts: List[DefectiveActChildGet] = []
