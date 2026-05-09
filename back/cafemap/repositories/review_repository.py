from sqlalchemy import select

from sqlalchemy.orm import Session



from cafemap.models.entities import Review, Store, Brand, Menu, User





# ?? ?? ??? ?? ????.





def fetch_my_reviews(db: Session, user_id: str):

    # ? ?? ?? ??? ???.

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

        .where(Review.user_id == user_id)

        .order_by(Review.created_at.desc())

    )

    return db.execute(stmt).all()





def fetch_review(db: Session, review_id: str):

    # ?? ??? ????.

    stmt = (

        select(
            Review,
            Store,
            Brand.name,
            Menu.name,
            Menu.category,
            User.email,
        )

        .join(Store, Store.id == Review.store_id)

        .join(Brand, Brand.id == Review.brand_id)

        .join(Menu, Menu.id == Review.menu_id)

        .join(User, User.id == Review.user_id)

        .where(Review.id == review_id)

    )

    return db.execute(stmt).first()
