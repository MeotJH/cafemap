from sqlalchemy import select
from sqlalchemy.orm import Session

from cafemap.models.entities import Brand, Menu, Review, Store, StoreAggregate, User

# ?? ?? ??? ?? ????.


def fetch_nearby_stores(db: Session):

    # ??/??? ??? ?? ?? ?? ???.

    stmt = (
        select(Store, StoreAggregate, Brand.name, Brand.logo_url)
        .join(StoreAggregate, StoreAggregate.store_id == Store.id)
        .join(Brand, Brand.id == Store.brand_id)
        .order_by(StoreAggregate.rating.desc())
    )

    return db.execute(stmt).all()


def fetch_store_rankings(db: Session):
    stmt = (
        select(Store, StoreAggregate, Brand.name, Brand.logo_url)
        .join(StoreAggregate, StoreAggregate.store_id == Store.id)
        .join(Brand, Brand.id == Store.brand_id)
        .order_by(StoreAggregate.rating.desc(), StoreAggregate.review_count.desc())
    )
    return db.execute(stmt).all()


def fetch_store_similarity_rows(db: Session):
    stmt = (
        select(Store, StoreAggregate, Brand.name, Brand.logo_url)
        .join(StoreAggregate, StoreAggregate.store_id == Store.id)
        .join(Brand, Brand.id == Store.brand_id)
    )
    return db.execute(stmt).all()


def fetch_store_detail(db: Session, store_id: str):

    # 가게 상세 정보를 조회합니다.

    stmt = (
        select(Store, StoreAggregate, Brand.name, Brand.logo_url)
        .join(StoreAggregate, StoreAggregate.store_id == Store.id)
        .join(Brand, Brand.id == Store.brand_id)
        .where(Store.id == store_id)
    )

    return db.execute(stmt).first()


def fetch_store_review_media_preview(db: Session, store_id: str):

    # Store detail preview media rows ordered by latest review first.

    stmt = (
        select(
            Review.id,
            Review.media_items_json,
            Review.image_urls_json,
            Review.created_at,
        )
        .where(Review.store_id == store_id)
        .order_by(Review.created_at.desc())
    )

    return db.execute(stmt).all()


def fetch_store_breakdown(db: Session, store_id: str):

    # 가게별 상세 정보를 조회합니다.

    return db.get(StoreAggregate, store_id)


def fetch_store_reviews(db: Session, store_id: str):

    # 가게 리뷰를 가져온다.

    stmt = (
        select(
            Review,
            Store.name,
            Store.link,
            Brand.name,
            Menu.name,
            Menu.category,
            User.email,
        )
        .join(Store, Store.id == Review.store_id)
        .join(Brand, Brand.id == Review.brand_id)
        .join(Menu, Menu.id == Review.menu_id)
        .join(User, User.id == Review.user_id)
        .where(Review.store_id == store_id)
        .order_by(Review.created_at.desc())
    )

    return db.execute(stmt).all()


def fetch_all_store_review_rows(db: Session):
    stmt = (
        select(
            Review,
            Store,
            Brand.name,
            Brand.logo_url,
            Menu.name,
            Menu.category,
            User.email,
        )
        .join(Store, Store.id == Review.store_id)
        .join(Brand, Brand.id == Review.brand_id)
        .join(Menu, Menu.id == Review.menu_id)
        .join(User, User.id == Review.user_id)
        .order_by(Review.created_at.desc())
    )
    return db.execute(stmt).all()
