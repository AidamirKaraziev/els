from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel, Field

from src.schemas.company import CompanyGet
from src.schemas.cost_type import CostTypeGet
from src.schemas.type_contract import TypeContractGet


class ContractBase(BaseModel):
    id: int = Field(..., title="ID Компании")
    company_id: Optional[int]
    title: str
    validity_period: Optional[Date]
    type_contract_id: Optional[int]
    cost_type_id: Optional[int]
    file: Optional[str]
    is_actual: bool


class ContractCreate(BaseModel):
    # id: int = Field(..., title="ID Компании")
    company_id: int
    title: str
    validity_period: Optional[int]
    type_contract_id: Optional[int]
    cost_type_id: Optional[int]
    # file: str
    # is_actual: bool


class ContractUpdate(BaseModel):
    # id: int = Field(..., title="ID Компании")
    # company_id: int
    title: Optional[str]
    validity_period: Optional[int]
    type_contract_id: Optional[int]
    cost_type_id: Optional[int]
    # file: str
    # is_actual: bool


class ContractGet(BaseModel):
    id: int = Field(..., title="ID Компании")
    company_id: Optional[CompanyGet]
    title: str
    validity_period: Optional[Date]
    type_contract_id: Optional[TypeContractGet]
    cost_type_id: Optional[CostTypeGet]
    file: Optional[str]
    is_actual: bool


class ContractFile(BaseModel):
    file: Optional[str]


class ContractGetById(BaseModel):
    id: Optional[int]


# class ContractRemove(BaseModel):
#     is_actual
