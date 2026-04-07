from sqlalchemy import select

from sqlalchemy.orm import Session



from cafemap.models.entities import BrandMenuAggregate, Brand, Menu, Review, Store, User





# ??? ?? ?? ?? ??? ?? ????.





def fetch_rankings(db: Session):

    # ?? ??? ??? DB ???.

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

    # ?? ?? ?? ?? ??? DB ???.

    return db.get(BrandMenuAggregate, ranking_id)





def fetch_ranking_reviews(db: Session, ranking_id: str):

    # ?? ?? ?? ?? ??? DB ???.

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

    # ???? ?? ??? ????.

    stmt = select(Menu).where(Menu.brand_id == brand_id)

    if query:

        stmt = stmt.where(Menu.name.contains(query))

    stmt = stmt.order_by(Menu.name.asc())

    menus = db.execute(stmt).scalars().all()
    unique_menus = []
    seen_names = set()
    for menu in menus:
        if menu.name in seen_names:
            continue
        seen_names.add(menu.name)
        unique_menus.append(menu)
    return unique_menus


