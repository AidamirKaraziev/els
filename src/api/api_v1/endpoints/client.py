import logging

from fastapi import APIRouter, Depends, Request

from src.api import deps
from src.core.response import SingleEntityResponse
from src.crud.users.crud_client import crud_client
from src.exceptions import InaccessibleEntity, UnfoundEntity
from src.getters.client import get_client
from src.schemas.client import ClientGet, ClientUpdateSelf

router = APIRouter()


# GET
@router.get(
    "/cp/client/me/",
    response_model=SingleEntityResponse[ClientGet],
    name="Получить данные клиента ",
    description="Получение всех данных профиля клиента по токену",
    tags=["Админ панель / Клиент"],
)
def get_data(
    request: Request,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
):
    return SingleEntityResponse(data=get_client(current_user, request=request))


# UPDATE SELF
@router.put(
    "/cp/client/me/",
    response_model=SingleEntityResponse[ClientGet],
    name="Изменить данные клиента",
    description="Изменить данные текущего клиента",
    tags=["Админ панель / Клиент"],
)
def update_client_self(
    request: Request,
    new_data: ClientUpdateSelf,
    current_user=Depends(deps.get_current_universal_user_by_bearer),
    session=Depends(deps.get_db),
):

    db_obj, code, index = crud_client.updating_client_self(
        db=session, current_user=current_user, obj_in=new_data
    )
    if code == -1:
        raise UnfoundEntity(
            message="Клиента с таким id не существует!",
            num=1,
            description="Клиента с таким id не существует!",
            path="$.body",
        )
    if code == -2:
        raise InaccessibleEntity(
            message="Вы не обладаете правами клиента",
            num=4,
            description="Вы не обладаете правами клиента!",
            path="$.body",
        )
    if code == -3:
        raise UnfoundEntity(
            message="Такого города не существует!",
            num=1,
            description="Нет выбранного вами города",
            path="$.body",
        )

    return SingleEntityResponse(data=get_client(db_obj, request=request))


if __name__ == "__main__":
    logging.info("Running...")
