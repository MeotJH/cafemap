from sqlalchemy import select
from sqlalchemy.orm import Session

from chickenmap.models.entities import BrandMenuAggregate, Brand, Menu, Review, Store, User


# 브랜드-메뉴 랭킹 관련 데이터 접근 계층이다.


def fetch_rankings(db: Session):
    # 랭킹 리스트 조회를 위한 DB 쿼리다.
    stmt = (
        select(
            BrandMenuAggregate,
            Brand.name,
            Brand.logo_url,
            Menu.name,
            Menu.category,
            Menu.image_url,
        )
        .join(Brand, Brand.id == BrandMenuAggregate.brand_id)
        .join(Menu, Menu.id == BrandMenuAggregate.menu_id)
        .where(BrandMenuAggregate.brand_id != "brand-local")
        .order_by(BrandMenuAggregate.rating.desc())
    )
    return db.execute(stmt).all()


def fetch_ranking_breakdown(db: Session, ranking_id: str):
    # 랭킹 상세 점수 분해 조회를 위한 DB 쿼리다.
    return db.get(BrandMenuAggregate, ranking_id)


def fetch_ranking_reviews(db: Session, ranking_id: str):
    # 랭킹 상세 리뷰 리스트를 위한 DB 쿼리다.
    aggregate = db.get(BrandMenuAggregate, ranking_id)
    if aggregate is None:
        return []

    stmt = (
        select(Review, Store.name, Brand.name, Menu.name, Menu.category, User.email)
        .join(Store, Store.id == Review.store_id)
        .join(Brand, Brand.id == Review.brand_id)
        .join(Menu, Menu.id == Review.menu_id)
        .join(User, User.id == Review.user_id)
        .where(Review.brand_id == aggregate.brand_id)
        .where(Review.menu_id == aggregate.menu_id)
        .order_by(Review.created_at.desc())
    )
    return db.execute(stmt).all()


def fetch_menus_by_brand(db: Session, brand_id: str, query: str | None = None):
    # 브랜드별 메뉴 목록을 조회한다.
    stmt = select(Menu).where(Menu.brand_id == brand_id)
    if query:
        stmt = stmt.where(Menu.name.contains(query))
    stmt = stmt.order_by(Menu.name.asc())
    return db.execute(stmt).scalars().all()
