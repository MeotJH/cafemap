import re

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

    stmt = stmt.order_by(Menu.name.asc())

    menus = db.execute(stmt).scalars().all()
    if query:
        query_keys = _menu_search_keys(query)
        menus = [
            menu
            for menu in menus
            if query_keys & _menu_search_keys(menu.name)
            or _normalize_menu_search_text(query) in _normalize_menu_search_text(menu.name)
        ]
    unique_menus = []
    seen_names = set()
    for menu in menus:
        if menu.name in seen_names:
            continue
        seen_names.add(menu.name)
        unique_menus.append(menu)
    return unique_menus


def _normalize_menu_search_text(value: str) -> str:
    normalized = value.strip().lower()
    normalized = re.sub(r"\s+", "", normalized)
    normalized = re.sub(r"[^0-9a-z가-힣]", "", normalized)
    return normalized


def _menu_search_keys(value: str) -> set[str]:
    normalized = _normalize_menu_search_text(value)
    keys = {normalized} if normalized else set()
    if "아메리카노" in normalized:
        keys.add(re.sub(r"^(아이스|핫)", "", normalized))
    if "americano" in normalized:
        keys.add(re.sub(r"^(ice|iced|hot)", "", normalized))
    return {key for key in keys if key}

