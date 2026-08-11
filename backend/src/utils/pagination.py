from typing import List, Optional, Tuple

from paginate_sqlalchemy import SqlalchemyOrmPage

from src.core.response import Paginator


def get_page(query, page: Optional[int]) -> Tuple[List, Optional[Paginator]]:
    if page is None:
        return query.all(), None

    page_obj = SqlalchemyOrmPage(query, page=page, items_per_page=30)

    total = page_obj.page_count

    paginator = Paginator(
        page=page, total=total, has_prev=page > 1, has_next=page < total
    )
    return page_obj.items, paginator
