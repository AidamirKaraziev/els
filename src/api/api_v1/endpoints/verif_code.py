import logging

from fastapi import APIRouter, Depends

from src.api import deps
from src.core.greensms import verif_code
from src.core.response import SingleEntityResponse
from src.crud.crud_verif_code import verif_codes_service as service
from src.schemas.verif_code import VerifCodeCreate, VerifCodeGet, VerifCodeSaveOnBase

router = APIRouter()


@router.post(
    "/verification-codes/",
    response_model=SingleEntityResponse[VerifCodeGet],
    name="Получить код верификации",
    description="Получить код верификации, используя телефонный номер",
)
def create_verif_code(
    tel_for_greensms: VerifCodeCreate,
    # service: VerifCodesServices = Depends(),
    session=Depends(deps.get_db),
):
    code = verif_code(tel_for_greensms.tel)
    case_for_save = VerifCodeSaveOnBase(value=code, tel=tel_for_greensms.tel)
    service.create(db=session, obj_in=case_for_save)

    return SingleEntityResponse(data=VerifCodeGet(code=code))


if __name__ == "__main__":
    logging.info("Running...")
