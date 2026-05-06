from sqlalchemy import select

from sqlalchemy.orm import Session



from cafemap.models.entities import Store, StoreAggregate, Brand, Review, Menu, User





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





def fetch_store_detail(db: Session, store_id: str):

    # ?? ?? ?? ??? ???.

    stmt = (

        select(Store, StoreAggregate, Brand.name, Brand.logo_url)

        .join(StoreAggregate, StoreAggregate.store_id == Store.id)

        .join(Brand, Brand.id == Store.brand_id)

        .where(Store.id == store_id)

    )

    return db.execute(stmt).first()





def fetch_store_breakdown(db: Session, store_id: str):

    # ?? ?? ?? ??? ???.

    return db.get(StoreAggregate, store_id)





def fetch_store_reviews(db: Session, store_id: str):

    # ?? ?? ?? ??? ???.

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
