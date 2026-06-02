from sqlalchemy.orm import Session

from cafemap.repositories import brand_menu_repository

# 랭킹과 메뉴 조회에 대한 서비스 계층입니다.


def get_rankings(db: Session):
    # 랭킹 목록을 조회합니다.
    return brand_menu_repository.fetch_rankings(db)


def get_ranking_breakdown(db: Session, ranking_id: str):
    # 랭킹별 상세 정보를 조회합니다.
    return brand_menu_repository.fetch_ranking_breakdown(db, ranking_id)


def get_ranking_reviews(db: Session, ranking_id: str):
    # 랭킹별 리뷰를 조회합니다.
    return brand_menu_repository.fetch_ranking_reviews(db, ranking_id)


def get_menus_by_brand(db: Session, brand_id: str, query: str | None = None):
    # 브랜드별 메뉴를 조회합니다.
    return brand_menu_repository.fetch_menus_by_brand(db, brand_id, query)
