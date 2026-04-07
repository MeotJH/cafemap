from sqlalchemy import select
from sqlalchemy.orm import Session

from chickenmap.models.entities import Brand


# 브랜드 데이터 접근 계층이다.


def fetch_brands(db: Session):
    # 브랜드 전체 목록을 조회한다.
    stmt = select(Brand).order_by(Brand.name.asc())
    return db.execute(stmt).scalars().all()
