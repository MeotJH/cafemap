from sqlalchemy.orm import Session

from cafemap.repositories import brand_menu_repository

# ??? ?? ?? ???? ?? ????.


def get_rankings(db: Session):
    # ?? ???? ????.
    return brand_menu_repository.fetch_rankings(db)


def get_ranking_breakdown(db: Session, ranking_id: str):
    # ?? ?? ?? ??? ????.
    return brand_menu_repository.fetch_ranking_breakdown(db, ranking_id)


def get_ranking_reviews(db: Session, ranking_id: str):
    # ?? ?? ?? ??? ????.
    return brand_menu_repository.fetch_ranking_reviews(db, ranking_id)


def get_menus_by_brand(db: Session, brand_id: str, query: str | None = None):
    # ???? ?? ??? ????.
    return brand_menu_repository.fetch_menus_by_brand(db, brand_id, query)
