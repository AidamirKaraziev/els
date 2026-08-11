from src.models.fault_category import FaultCategory
from src.schemas.fault_category import FaultCategoryGet


def getting_fault_category(obj: FaultCategory) -> FaultCategoryGet:
    return FaultCategoryGet(
        id=obj.id,
        name=obj.name,
        code=obj.code,
        # Строки, созданные до миграции, флага не имеют — считаем их поломкой,
        # как и любую новую категорию без явной пометки.
        counts_as_breakdown=(
            True if obj.counts_as_breakdown is None else obj.counts_as_breakdown
        ),
    )
