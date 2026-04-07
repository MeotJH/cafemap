from sqlalchemy.orm import Session

from chickenmap.repositories import brand_repository


# 브랜드 비즈니스 로직 계층이다.


def get_brands(db: Session):
    # 브랜드 목록을 반환한다.
    return brand_repository.fetch_brands(db)
