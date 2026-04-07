from sqlalchemy import select
from sqlalchemy.orm import Session

from chickenmap.models.entities import Store, StoreAggregate, Brand, Review, Menu, User


# 지점 관련 데이터 접근 계층이다.


def fetch_nearby_stores(db: Session):
    # 지도/리스트 화면용 지점 요약 조회 쿼리다.
    stmt = (
        select(Store, StoreAggregate, Brand.name, Brand.logo_url)
        .join(StoreAggregate, StoreAggregate.store_id == Store.id)
        .join(Brand, Brand.id == Store.brand_id)
        .order_by(StoreAggregate.rating.desc())
    )
    return db.execute(stmt).all()


def fetch_store_detail(db: Session, store_id: str):
    # 지점 상세 정보 조회를 위한 쿼리다.
    stmt = (
        select(Store, StoreAggregate, Brand.name, Brand.logo_url)
        .join(StoreAggregate, StoreAggregate.store_id == Store.id)
        .join(Brand, Brand.id == Store.brand_id)
        .where(Store.id == store_id)
    )
    return db.execute(stmt).first()


def fetch_store_breakdown(db: Session, store_id: str):
    # 지점 점수 분해 조회를 위한 쿼리다.
    return db.get(StoreAggregate, store_id)


def fetch_store_reviews(db: Session, store_id: str):
    # 지점 리뷰 리스트 조회를 위한 쿼리다.
    stmt = (
        select(Review, Store.name, Brand.name, Menu.name, Menu.category, User.email)
        .join(Store, Store.id == Review.store_id)
        .join(Brand, Brand.id == Review.brand_id)
        .join(Menu, Menu.id == Review.menu_id)
        .join(User, User.id == Review.user_id)
        .where(Review.store_id == store_id)
        .order_by(Review.created_at.desc())
    )
    return db.execute(stmt).all()
