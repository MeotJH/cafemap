from sqlalchemy.orm import Session

from chickenmap.repositories import brand_menu_repository


# 브랜드-메뉴 랭킹 비즈니스 로직 계층이다.


def get_rankings(db: Session):
    # 랭킹 리스트를 서비스 단에서 반환한다.
    return brand_menu_repository.fetch_rankings(db)


def get_ranking_breakdown(db: Session, ranking_id: str):
    # 랭킹 상세 점수 분해를 서비스 단에서 반환한다.
    return brand_menu_repository.fetch_ranking_breakdown(db, ranking_id)


def get_ranking_reviews(db: Session, ranking_id: str):
    # 랭킹 상세 리뷰 리스트를 서비스 단에서 반환한다.
    return brand_menu_repository.fetch_ranking_reviews(db, ranking_id)


def get_menus_by_brand(db: Session, brand_id: str, query: str | None = None):
    # 브랜드별 메뉴 목록을 반환한다.
    return brand_menu_repository.fetch_menus_by_brand(db, brand_id, query)
