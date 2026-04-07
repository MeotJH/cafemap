from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from cafemap.core.rating_dimensions import (
    compute_overall,
    normalize_category,
    normalize_scores,
    normalize_store_scores,
    scores_json_dumps,
    top_highlights,
)
from cafemap.db.session import Base, engine
from cafemap.models.entities import (
    Brand,
    BrandMenuAggregate,
    Menu,
    Review,
    Store,
    StoreAggregate,
    User,
)


# DB ???? ?? ?? ??? ???? ????.

CSV_PATH = Path(__file__).resolve().parents[2] / "korea_cafe_menus.csv"
LOCAL_BRAND_ID = "brand-local"
STORE_TYPE_LOCAL = "local"
STORE_TYPE_FRANCHISE = "franchise"

BRAND_SEEDS: dict[str, dict[str, object]] = {
    "brand-starbucks": {
        "name": "스타벅스",
        "logo_url": "https://upload.wikimedia.org/wikipedia/ko/thumb/9/9f/Starbucks_Corporation_Logo_2011.svg/512px-Starbucks_Corporation_Logo_2011.svg.png",
        "store_name": "스타벅스 시청점",
        "address": "서울 중구 세종대로 110",
        "lat": 37.5663,
        "lng": 126.9779,
    },
    "brand-twosome": {
        "name": "투썸플레이스",
        "logo_url": "https://www.twosome.co.kr/resources/images/common/logo.png",
        "store_name": "투썸플레이스 광화문점",
        "address": "서울 종로구 세종대로 172",
        "lat": 37.5720,
        "lng": 126.9769,
    },
    "brand-ediya": {
        "name": "이디야커피",
        "logo_url": "https://www.ediya.com/images/common/logo.png",
        "store_name": "이디야커피 서울역점",
        "address": "서울 중구 한강대로 405",
        "lat": 37.5547,
        "lng": 126.9706,
    },
    "brand-mega": {
        "name": "메가커피",
        "logo_url": "",
        "store_name": "메가MGC커피 강남역점",
        "address": "서울 강남구 강남대로 396",
        "lat": 37.4981,
        "lng": 127.0276,
    },
    "brand-local": {
        "name": "개인 카페",
        "logo_url": "",
        "store_name": "홍대 로컬 카페",
        "address": "서울 마포구 와우산로 227-15",
        "lat": 37.5617,
        "lng": 126.9257,
    },
}

COMMON_CAFE_MENU_SEEDS: tuple[tuple[str, str], ...] = (
    ("아메리카노", "커피"),
    ("디카페인 아메리카노", "커피"),
    ("에스프레소", "커피"),
    ("롱블랙", "커피"),
    ("카페오레", "라떼"),
    ("카페라떼", "라떼"),
    ("바닐라 라떼", "라떼"),
    ("헤이즐넛 라떼", "라떼"),
    ("연유 라떼", "라떼"),
    ("돌체 라떼", "라떼"),
    ("흑당 라떼", "라떼"),
    ("카푸치노", "라떼"),
    ("카라멜 마끼아또", "라떼"),
    ("모카 라떼", "라떼"),
    ("카페모카", "라떼"),
    ("화이트 모카", "라떼"),
    ("아인슈페너", "시그니처"),
    ("콜드브루", "콜드브루"),
    ("콜드브루 라떼", "콜드브루"),
    ("디카페인 콜드브루", "콜드브루"),
    ("핸드드립", "핸드드립"),
    ("드립커피", "핸드드립"),
    ("시그니처 라떼", "시그니처"),
    ("크림 라떼", "시그니처"),
    ("슈페너 라떼", "시그니처"),
    ("초코 라떼", "디저트음료"),
    ("녹차 라떼", "디저트음료"),
    ("말차 라떼", "디저트음료"),
    ("고구마 라떼", "디저트음료"),
    ("곡물 라떼", "디저트음료"),
    ("밀크티", "디저트음료"),
    ("얼그레이 밀크티", "디저트음료"),
    ("차이 밀크티", "디저트음료"),
    ("아이스티", "디저트음료"),
    ("복숭아 아이스티", "디저트음료"),
    ("레몬티", "디저트음료"),
    ("자몽티", "디저트음료"),
    ("유자차", "디저트음료"),
    ("캐모마일 티", "디저트음료"),
    ("페퍼민트 티", "디저트음료"),
    ("얼그레이 티", "디저트음료"),
    ("녹차", "디저트음료"),
    ("레몬에이드", "디저트음료"),
    ("자몽에이드", "디저트음료"),
    ("청포도에이드", "디저트음료"),
    ("블루레몬에이드", "디저트음료"),
    ("딸기 스무디", "디저트음료"),
    ("망고 스무디", "디저트음료"),
    ("블루베리 스무디", "디저트음료"),
    ("플레인 요거트 스무디", "디저트음료"),
    ("프라페", "디저트음료"),
    ("초코 프라페", "디저트음료"),
    ("쿠키 프라페", "디저트음료"),
)


def init_db():
    # ??? ?? ? ??? ?? ??????? ??? ????.
    Base.metadata.create_all(bind=engine)
    with Session(engine) as db:
        _migrate_scores_json_columns(db)
        seed_if_empty(db)


def _migrate_scores_json_columns(db: Session):
    # ?? SQLite DB? ??? ??? ??? ????.
    if db.bind is None or db.bind.dialect.name != "sqlite":
        return

    targets = {
        "review": ("scores_json", "overall", "user_id", "image_urls_json"),
        "brand_menu_aggregate": ("scores_json",),
        "store_aggregate": ("scores_json", "counts_json"),
        "store": ("store_type", "place_id"),
    }
    for table_name, needed_columns in targets.items():
        columns = db.execute(text(f"PRAGMA table_info('{table_name}')")).fetchall()
        if not columns:
            continue
        column_names = {row[1] for row in columns}
        for column_name in needed_columns:
            if column_name in column_names:
                continue
            if column_name == "overall":
                db.execute(
                    text(
                        f"ALTER TABLE {table_name} "
                        "ADD COLUMN overall FLOAT NOT NULL DEFAULT 0"
                    )
                )
            elif column_name == "user_id":
                db.execute(
                    text(
                        f"ALTER TABLE {table_name} "
                        "ADD COLUMN user_id VARCHAR NOT NULL DEFAULT 'user-seed'"
                    )
                )
            elif column_name == "image_urls_json":
                db.execute(
                    text(
                        f"ALTER TABLE {table_name} "
                        "ADD COLUMN image_urls_json VARCHAR NOT NULL DEFAULT '[]'"
                    )
                )
            elif column_name == "store_type":
                db.execute(
                    text(
                        f"ALTER TABLE {table_name} "
                        "ADD COLUMN store_type VARCHAR NOT NULL DEFAULT 'unknown'"
                    )
                )
            elif column_name == "place_id":
                db.execute(
                    text(
                        f"ALTER TABLE {table_name} "
                        "ADD COLUMN place_id VARCHAR NOT NULL DEFAULT ''"
                    )
                )
            else:
                db.execute(
                    text(
                        f"ALTER TABLE {table_name} "
                        f"ADD COLUMN {column_name} VARCHAR NOT NULL DEFAULT '{{}}'"
                    )
                )
    db.commit()


def _load_menu_rows() -> list[dict[str, str]]:
    with CSV_PATH.open(encoding="utf-8-sig", newline="") as fp:
        return list(csv.DictReader(fp))


def _brand_seeds() -> list[Brand]:
    return [
        Brand(
            id=brand_id,
            name=str(values["name"]),
            logo_url=str(values["logo_url"]),
        )
        for brand_id, values in BRAND_SEEDS.items()
    ]


def _menu_seeds() -> list[Menu]:
    rows = _load_menu_rows()
    menus: list[Menu] = []
    for row in rows:
        category = normalize_category(row.get("category"))
        menus.append(
            Menu(
                id=row["menu_id"],
                brand_id=row["brand_id"],
                name=row["menu_name"],
                image_url="",
                category=category,
            )
        )
    existing_keys = {(menu.brand_id, menu.name) for menu in menus}
    for brand_id in BRAND_SEEDS:
        for menu_name, category in COMMON_CAFE_MENU_SEEDS:
            key = (brand_id, menu_name)
            if key in existing_keys:
                continue
            existing_keys.add(key)
            menus.append(
                Menu(
                    id=f"menu-{brand_id.removeprefix('brand-')}-{_menu_slug(menu_name)}",
                    brand_id=brand_id,
                    name=menu_name,
                    image_url="",
                    category=normalize_category(category),
                )
            )
    return menus


def _menu_slug(name: str) -> str:
    replacements = {
        "아메리카노": "americano",
        "디카페인": "decaf",
        "에스프레소": "espresso",
        "롱블랙": "longblack",
        "카페오레": "cafeaulait",
        "카페라떼": "cafelatte",
        "라떼": "latte",
        "바닐라": "vanilla",
        "헤이즐넛": "hazelnut",
        "연유": "condensedmilk",
        "돌체": "dolce",
        "흑당": "brownsugar",
        "카푸치노": "cappuccino",
        "카라멜": "caramel",
        "마끼아또": "macchiato",
        "모카": "mocha",
        "카페모카": "cafemocha",
        "화이트": "white",
        "아인슈페너": "einspanner",
        "콜드브루": "coldbrew",
        "핸드드립": "handdrip",
        "드립커피": "dripcoffee",
        "시그니처": "signature",
        "크림": "cream",
        "슈페너": "spanner",
        "초코": "choco",
        "녹차": "greentea",
        "말차": "matcha",
        "고구마": "sweetpotato",
        "곡물": "grain",
        "밀크티": "milktea",
        "얼그레이": "earlgrey",
        "차이": "chai",
        "복숭아": "peach",
        "아이스티": "icetea",
        "레몬티": "lemontea",
        "자몽티": "grapefruittea",
        "유자차": "yujatea",
        "캐모마일": "chamomile",
        "페퍼민트": "peppermint",
        "레몬에이드": "lemonade",
        "자몽에이드": "grapefruitade",
        "청포도에이드": "greengrapeade",
        "블루레몬에이드": "bluelemonade",
        "딸기": "strawberry",
        "망고": "mango",
        "블루베리": "blueberry",
        "스무디": "smoothie",
        "플레인": "plain",
        "요거트": "yogurt",
        "프라페": "frappe",
        "쿠키": "cookie",
    }
    slug = name.replace(" ", "-").lower()
    for source, target in replacements.items():
        slug = slug.replace(source, target)
    return slug.strip("-")


def _score_seed(category: str) -> dict[str, float]:
    menu_scores = normalize_scores(
        category,
        {
            "coffee_quality": 4.6,
            "acidity_balance": 4.2,
            "body": 4.3,
            "aftertaste": 4.4,
            "temperature": 4.5,
            "value": 4.1,
            "milk_balance": 4.3,
            "texture": 4.4,
            "sweetness": 4.0,
            "clean_finish": 4.2,
            "refreshing": 4.1,
            "ice_balance": 4.0,
            "aroma": 4.5,
            "clarity": 4.2,
            "signature_balance": 4.3,
            "visuals": 4.4,
            "flavor_balance": 4.2,
            "portion": 4.0,
        },
    )
    store_scores = normalize_store_scores(
        {
            "atmosphere": 4.4,
            "work_friendly": 4.2,
            "quietness": 4.0,
            "seat_comfort": 4.1,
            "outlet_access": 4.0,
            "wifi_quality": 4.1,
            "service": 4.3,
            "revisit_intent": 4.4,
        }
    )
    return {**menu_scores, **store_scores}


def _menu_only_seed(category: str) -> dict[str, float]:
    return normalize_scores(category, _score_seed(category))


def _store_type_for_brand(brand_id: str) -> str:
    return STORE_TYPE_LOCAL if brand_id == LOCAL_BRAND_ID else STORE_TYPE_FRANCHISE


def _dedupe_menus(db: Session, seed_menus: list[Menu]):
    seed_ids_by_key = {(menu.brand_id, menu.name): menu.id for menu in seed_menus}
    menus_by_key: dict[tuple[str, str], list[Menu]] = {}
    for menu in db.scalars(select(Menu).order_by(Menu.brand_id, Menu.name, Menu.id)):
        menus_by_key.setdefault((menu.brand_id, menu.name), []).append(menu)

    for key, duplicates in menus_by_key.items():
        if len(duplicates) <= 1:
            continue

        preferred_id = seed_ids_by_key.get(key)
        canonical = next(
            (menu for menu in duplicates if menu.id == preferred_id),
            duplicates[0],
        )
        for duplicate in duplicates:
            if duplicate.id == canonical.id:
                continue
            _merge_duplicate_menu(db, canonical, duplicate)


def _merge_duplicate_menu(db: Session, canonical: Menu, duplicate: Menu):
    db.query(Review).filter(Review.menu_id == duplicate.id).update(
        {Review.menu_id: canonical.id},
        synchronize_session=False,
    )

    duplicate_aggregates = (
        db.query(BrandMenuAggregate)
        .filter(BrandMenuAggregate.menu_id == duplicate.id)
        .all()
    )
    for aggregate in duplicate_aggregates:
        canonical_aggregate = (
            db.query(BrandMenuAggregate)
            .filter(BrandMenuAggregate.brand_id == aggregate.brand_id)
            .filter(BrandMenuAggregate.menu_id == canonical.id)
            .first()
        )
        if canonical_aggregate is None:
            aggregate.menu_id = canonical.id
            continue
        canonical_aggregate.review_count += aggregate.review_count
        canonical_aggregate.rating = max(canonical_aggregate.rating, aggregate.rating)
        db.delete(aggregate)

    db.delete(duplicate)


def seed_if_empty(db: Session):
    # ???, ??, ?? ??/??? ??? ?? ???? ???.
    now = datetime.now()

    brands = _brand_seeds()
    menus = _menu_seeds()
    seed_user = User(
        id="user-seed",
        email="seed@cafemap.local",
        display_name="CafeMap Seed",
        photo_url="",
        provider="google",
        created_at=now,
        updated_at=now,
    )

    existing_brand_ids = set(db.scalars(select(Brand.id)).all())
    existing_user_ids = set(db.scalars(select(User.id)).all())
    existing_store_ids = set(db.scalars(select(Store.id)).all())
    existing_ranking_ids = set(db.scalars(select(BrandMenuAggregate.id)).all())
    existing_store_aggregate_ids = set(db.scalars(select(StoreAggregate.id)).all())
    existing_review_ids = set(db.scalars(select(Review.id)).all())

    for brand in brands:
        existing = db.get(Brand, brand.id)
        if existing is None:
            db.add(brand)
            continue
        existing.name = brand.name
        existing.logo_url = brand.logo_url
    if seed_user.id not in existing_user_ids:
        db.add(seed_user)

    for menu in menus:
        existing = db.get(Menu, menu.id)
        if existing is None:
            db.add(menu)
            continue
        existing.brand_id = menu.brand_id
        existing.name = menu.name
        existing.image_url = menu.image_url
        existing.category = menu.category

    db.flush()
    _dedupe_menus(db, menus)
    db.flush()

    menus_by_brand: dict[str, Menu] = {}
    for menu in menus:
        menus_by_brand.setdefault(menu.brand_id, menu)

    for brand_id, seed in BRAND_SEEDS.items():
        menu = menus_by_brand.get(brand_id)
        if menu is None:
            continue
        store_id = f"store-{brand_id}"
        review_id = f"review-{brand_id}"
        ranking_id = f"rank-{menu.id}"

        menu_scores = _menu_only_seed(menu.category)
        scores = _score_seed(menu.category)
        overall = compute_overall(menu_scores, fallback=4.2)
        highlights = top_highlights(menu_scores)
        store_type = _store_type_for_brand(brand_id)

        if store_id not in existing_store_ids:
            db.add(
                Store(
                    id=store_id,
                    brand_id=brand_id,
                    name=str(seed["store_name"]),
                    address=str(seed["address"]),
                    store_type=store_type,
                    place_id=store_id,
                    distance_km=0.8,
                    lat=float(seed["lat"]),
                    lng=float(seed["lng"]),
                )
            )
        else:
            existing_store = db.get(Store, store_id)
            if existing_store is not None:
                existing_store.brand_id = brand_id
                existing_store.name = str(seed["store_name"])
                existing_store.address = str(seed["address"])
                existing_store.store_type = store_type
                existing_store.place_id = existing_store.place_id or store_id
                existing_store.distance_km = 0.8
                existing_store.lat = float(seed["lat"])
                existing_store.lng = float(seed["lng"])

        if ranking_id not in existing_ranking_ids:
            db.add(
                BrandMenuAggregate(
                    id=ranking_id,
                    brand_id=brand_id,
                    menu_id=menu.id,
                    rating=overall,
                    review_count=1,
                    highlight_score_a=highlights[0][1],
                    highlight_label_a=highlights[0][0],
                    highlight_score_b=highlights[1][1],
                    highlight_label_b=highlights[1][0],
                    scores_json=scores_json_dumps(menu_scores),
                )
            )
        else:
            existing_ranking = db.get(BrandMenuAggregate, ranking_id)
            if existing_ranking is not None:
                existing_ranking.brand_id = brand_id
                existing_ranking.menu_id = menu.id
                existing_ranking.rating = overall
                existing_ranking.review_count = 1
                existing_ranking.highlight_score_a = highlights[0][1]
                existing_ranking.highlight_label_a = highlights[0][0]
                existing_ranking.highlight_score_b = highlights[1][1]
                existing_ranking.highlight_label_b = highlights[1][0]
                existing_ranking.scores_json = scores_json_dumps(menu_scores)

        if store_id not in existing_store_aggregate_ids:
            db.add(
                StoreAggregate(
                    id=store_id,
                    store_id=store_id,
                    rating=overall,
                    review_count=1,
                    scores_json=scores_json_dumps(scores),
                    counts_json=scores_json_dumps({key: 1 for key in scores}),
                )
            )
        else:
            existing_store_aggregate = db.get(StoreAggregate, store_id)
            if existing_store_aggregate is not None:
                existing_store_aggregate.rating = overall
                existing_store_aggregate.review_count = 1
                existing_store_aggregate.scores_json = scores_json_dumps(scores)
                existing_store_aggregate.counts_json = scores_json_dumps(
                    {key: 1 for key in scores}
                )

        if review_id not in existing_review_ids:
            db.add(
                Review(
                    id=review_id,
                    user_id=seed_user.id,
                    store_id=store_id,
                    brand_id=brand_id,
                    menu_id=menu.id,
                    scores_json=scores_json_dumps(scores),
                    image_urls_json="[]",
                    overall=overall,
                    comment=f"{seed['store_name']}의 대표 메뉴를 기준으로 만든 샘플 리뷰입니다.",
                    created_at=now,
                )
            )
        else:
            existing_review = db.get(Review, review_id)
            if existing_review is not None:
                existing_review.user_id = seed_user.id
                existing_review.store_id = store_id
                existing_review.brand_id = brand_id
                existing_review.menu_id = menu.id
                existing_review.scores_json = scores_json_dumps(scores)
                existing_review.image_urls_json = "[]"
                existing_review.overall = overall
                existing_review.comment = (
                    f"{seed['store_name']}의 대표 메뉴를 기준으로 만든 샘플 리뷰입니다."
                )

    db.commit()
