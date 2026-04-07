from sqlalchemy.orm import Session

from cafemap.repositories import store_repository


# ?? ???? ?? ????.


def get_nearby_stores(db: Session):
    # ??/??? ??? ?? ??? ????.
    return store_repository.fetch_nearby_stores(db)


def get_store_detail(db: Session, store_id: str):
    # ?? ?? ??? ????.
    return store_repository.fetch_store_detail(db, store_id)


def get_store_breakdown(db: Session, store_id: str):
    # ?? ?? ?? ??? ????.
    return store_repository.fetch_store_breakdown(db, store_id)


def get_store_reviews(db: Session, store_id: str):
    # ?? ?? ??? ????.
    return store_repository.fetch_store_reviews(db, store_id)
