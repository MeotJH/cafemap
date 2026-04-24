from datetime import datetime

import json

import uuid

import re

from difflib import SequenceMatcher

from sqlalchemy.orm import Session



from cafemap.models.entities import Brand, Menu, Store, Review, BrandMenuAggregate, StoreAggregate

from cafemap.core.rating_dimensions import (

    compute_overall,

    normalize_category,

    normalize_scores,

    normalize_store_scores,

    scores_json_dumps,

    scores_json_loads,

    top_highlights,

)

from cafemap.repositories import review_repository

from cafemap.services import geocode_service





# ?? ???? ?? ????.

LOCAL_BRAND_ID = "brand-local"
STORE_TYPE_LOCAL = "local"
STORE_TYPE_FRANCHISE = "franchise"





def get_my_reviews(db: Session, user_id: str):

    # ? ?? ??? ????.

    return review_repository.fetch_my_reviews(db, user_id)





def get_review(db: Session, review_id: str):

    # ?? ??? ????.

    return review_repository.fetch_review(db, review_id)





def create_review(db: Session, payload, user_id: str):

    # ??? ???? ????.

    brand = db.get(Brand, payload.brandId)

    if brand is None:

        raise ValueError("Brand not found")



    menu = _find_best_matching_menu(db, brand.id, payload.menuName)

    if menu is None:
        raise ValueError("Menu must be selected from the standard menu list")

    menu_category = normalize_category(menu.category)



    place_id = (getattr(payload, "placeId", "") or "").strip()
    place_link = (getattr(payload, "link", "") or "").strip()
    payload_coords = _coords_from_payload(payload)
    store = _find_existing_store(
        db,
        brand.id,
        payload.storeName,
        payload.address,
        place_id,
    )

    if store is None:

        coords = payload_coords or geocode_service.geocode(payload.address)

        store = Store(

            id=f"store-{uuid.uuid4().hex}",

            brand_id=brand.id,

            name=payload.storeName,

            address=payload.address,

            store_type=_store_type_for_brand(brand.id),

            place_id=place_id,

            link=place_link,

            distance_km=0.0,

            lat=coords[0] if coords else 0.0,

            lng=coords[1] if coords else 0.0,

        )

        db.add(store)

    elif store.lat == 0.0 and store.lng == 0.0:

        coords = payload_coords or (
            geocode_service.geocode(payload.address) if payload.address else None
        )

        if coords:

            store.lat, store.lng = coords

    if store is not None and place_id and not store.place_id:
        store.place_id = place_id
    if store is not None and place_link and not store.link:
        store.link = place_link



    input_scores = getattr(payload, "scores", {}) or {}

    if not input_scores:

        raise ValueError("scores is required")

    image_urls = _sanitize_image_urls(getattr(payload, "imageUrls", []))

    menu_scores = normalize_scores(menu_category, input_scores)
    store_scores = normalize_store_scores(getattr(payload, "storeScores", {}) or {})
    aggregate_scores = {**menu_scores, **store_scores}

    resolved_overall = float(payload.overall) if payload.overall > 0 else compute_overall(menu_scores, fallback=0.0)



    review = Review(

        id=f"review-{uuid.uuid4().hex}",

        user_id=user_id,

        store_id=store.id,

        brand_id=brand.id,

        menu_id=menu.id,

        scores_json=scores_json_dumps(aggregate_scores),

        image_urls_json=json.dumps(image_urls, ensure_ascii=False),

        overall=resolved_overall,

        comment=payload.comment,

        created_at=datetime.now(),

    )

    db.add(review)

    if brand.id != LOCAL_BRAND_ID:

        _update_brand_menu_aggregate(

            db,

            brand_id=brand.id,

            menu=menu,

            scores=menu_scores,

            overall=resolved_overall,

        )

    _update_store_aggregate(

        db,

        store=store,

        scores=aggregate_scores,

        overall=resolved_overall,

    )



    db.commit()

    db.refresh(review)

    return review, store.name, brand.name, menu.name





def _update_brand_menu_aggregate(

    db: Session,

    brand_id: str,

    menu: Menu,

    scores: dict[str, float],

    overall: float,

):

    # ???-?? ??? ?? ??????.

    aggregate = (

        db.query(BrandMenuAggregate)

        .filter(BrandMenuAggregate.brand_id == brand_id)

        .filter(BrandMenuAggregate.menu_id == menu.id)

        .first()

    )

    if aggregate is None:

        highlights = top_highlights(scores)

        aggregate = BrandMenuAggregate(

            id=f"rank-{uuid.uuid4().hex}",

            brand_id=brand_id,

            menu_id=menu.id,

            rating=overall,

            review_count=1,

            highlight_score_a=highlights[0][1],

            highlight_label_a=highlights[0][0],

            highlight_score_b=highlights[1][1],

            highlight_label_b=highlights[1][0],

            scores_json=scores_json_dumps(scores),

        )

        db.add(aggregate)

        return



    count = aggregate.review_count

    new_count = count + 1

    current_scores = scores_json_loads(aggregate.scores_json)

    merged_scores = _merge_average_scores(current_scores, scores, count, new_count)



    aggregate.scores_json = scores_json_dumps(merged_scores)

    aggregate.rating = (aggregate.rating * count + overall) / new_count

    aggregate.review_count = new_count



    highlights = top_highlights(merged_scores)

    aggregate.highlight_label_a = highlights[0][0]

    aggregate.highlight_score_a = highlights[0][1]

    aggregate.highlight_label_b = highlights[1][0]

    aggregate.highlight_score_b = highlights[1][1]





def _update_store_aggregate(

    db: Session,

    store: Store,

    scores: dict[str, float],

    overall: float,

):

    # ?? ??? ?? ??????.

    aggregate = (

        db.query(StoreAggregate)

        .filter(StoreAggregate.store_id == store.id)

        .first()

    )

    if aggregate is None:

        initial_counts = {key: 1 for key in scores}

        aggregate = StoreAggregate(

            id=store.id,

            store_id=store.id,

            rating=overall,

            review_count=1,

            scores_json=scores_json_dumps(scores),

            counts_json=scores_json_dumps(initial_counts),

        )

        db.add(aggregate)

        return



    count = aggregate.review_count

    new_count = count + 1

    current_scores = scores_json_loads(aggregate.scores_json)

    current_counts = _counts_json_loads(aggregate.counts_json)

    merged_scores, merged_counts = _merge_store_scores_with_counts(

        current_scores=current_scores,

        current_counts=current_counts,

        incoming_scores=scores,

    )



    aggregate.scores_json = scores_json_dumps(merged_scores)

    aggregate.counts_json = scores_json_dumps(merged_counts)

    aggregate.rating = (aggregate.rating * count + overall) / new_count

    aggregate.review_count = new_count





def _merge_average_scores(

    current: dict[str, float],

    incoming: dict[str, float],

    current_count: int,

    new_count: int,

) -> dict[str, float]:

    keys = set(current) | set(incoming)

    merged: dict[str, float] = {}

    for key in keys:

        base = current.get(key, incoming.get(key, 0.0))

        merged[key] = (base * current_count + incoming.get(key, base)) / new_count

    return merged





def _counts_json_loads(raw: str | None) -> dict[str, int]:

    if not raw:

        return {}

    try:

        data = json.loads(raw)

    except (TypeError, ValueError):

        return {}

    if not isinstance(data, dict):

        return {}



    counts: dict[str, int] = {}

    for key, value in data.items():

        try:

            parsed = int(value)

        except (TypeError, ValueError):

            continue

        if parsed > 0:

            counts[str(key)] = parsed

    return counts





def _merge_store_scores_with_counts(

    *,

    current_scores: dict[str, float],

    current_counts: dict[str, int],

    incoming_scores: dict[str, float],

) -> tuple[dict[str, float], dict[str, int]]:

    merged_scores = dict(current_scores)

    merged_counts = dict(current_counts)



    for key, incoming_value in incoming_scores.items():

        prev_count = merged_counts.get(key, 0)

        prev_avg = merged_scores.get(key, 0.0)

        next_count = prev_count + 1

        merged_scores[key] = (prev_avg * prev_count + incoming_value) / next_count

        merged_counts[key] = next_count



    return merged_scores, merged_counts





def _normalize_menu_name(name: str) -> str:

    # ??? ???: ??/????? ???? ???? ????.

    normalized = name.strip().lower()

    normalized = re.sub(r"\s+", "", normalized)

    normalized = re.sub(r"[^0-9a-z가-힣]", "", normalized)

    return normalized


def _menu_match_keys(name: str) -> set[str]:
    normalized = _normalize_menu_name(name)
    keys = {normalized} if normalized else set()
    if "아메리카노" in normalized:
        keys.add(re.sub(r"^(아이스|핫)", "", normalized))
    if "americano" in normalized:
        keys.add(re.sub(r"^(ice|iced|hot)", "", normalized))
    return {key for key in keys if key}


def _normalize_place_text(value: str | None) -> str:
    normalized = (value or "").strip().lower()
    normalized = re.sub(r"\s+", "", normalized)
    normalized = re.sub(r"[^0-9a-z가-힣]", "", normalized)
    return normalized


def _store_type_for_brand(brand_id: str) -> str:
    return STORE_TYPE_LOCAL if brand_id == LOCAL_BRAND_ID else STORE_TYPE_FRANCHISE


def _find_existing_store(
    db: Session,
    brand_id: str,
    store_name: str,
    address: str | None,
    place_id: str | None,
) -> Store | None:
    normalized_place_id = (place_id or "").strip()
    if normalized_place_id:
        store = (
            db.query(Store)
            .filter(Store.brand_id == brand_id)
            .filter(Store.place_id == normalized_place_id)
            .first()
        )
        if store is not None:
            return store

    store = (
        db.query(Store)
        .filter(Store.brand_id == brand_id)
        .filter(Store.name == store_name)
        .first()
    )
    if store is not None:
        return store

    normalized_name = _normalize_place_text(store_name)
    normalized_address = _normalize_place_text(address)
    if not normalized_name or not normalized_address:
        return None

    candidates = db.query(Store).filter(Store.brand_id == brand_id).all()
    for candidate in candidates:
        if (
            _normalize_place_text(candidate.name) == normalized_name
            and _normalize_place_text(candidate.address) == normalized_address
        ):
            return candidate
    return None


def _coords_from_payload(payload) -> tuple[float, float] | None:
    lat = getattr(payload, "lat", None)
    lng = getattr(payload, "lng", None)
    if lat is None or lng is None:
        return None
    try:
        lat = float(lat)
        lng = float(lng)
    except (TypeError, ValueError):
        return None
    if lat == 0.0 and lng == 0.0:
        return None
    if abs(lat) > 90 or abs(lng) > 180:
        return None
    return lat, lng





def _find_best_matching_menu(db: Session, brand_id: str, raw_name: str) -> Menu | None:

    # ?? ??? ??? ?? ???? ?? ????.

    menus = db.query(Menu).filter(Menu.brand_id == brand_id).all()

    if not menus:

        return None



    stripped = raw_name.strip()

    for existing in menus:

        if existing.name.strip() == stripped:

            return existing



    target_keys = _menu_match_keys(stripped)

    if not target_keys:

        return None



    # 1) ??? ??? ?? ?? ??? ?? ????.

    for existing in menus:

        if target_keys & _menu_match_keys(existing.name):

            return existing



    # 2) ?? ??? ??? ??? ???? ? ??? ????.

    best_menu: Menu | None = None

    best_score = 0.0

    for existing in menus:
        existing_keys = _menu_match_keys(existing.name)
        if not existing_keys:
            continue

        score = max(
            SequenceMatcher(a=target, b=existing_key).ratio()
            for target in target_keys
            for existing_key in existing_keys
        )

        if score > best_score:

            best_score = score

            best_menu = existing



    if best_menu is not None and best_score >= 0.80:

        return best_menu

    return None





def _classify_menu_category(normalized_name: str) -> str:

    if "라떼" in normalized_name or "latte" in normalized_name:
        return "라떼"
    if "콜드브루" in normalized_name or "coldbrew" in normalized_name:
        return "콜드브루"
    if "핸드드립" in normalized_name or "드립" in normalized_name:
        return "핸드드립"
    if "시그니처" in normalized_name or "signature" in normalized_name:
        return "시그니처"
    if "스무디" in normalized_name or "프라페" in normalized_name or "에이드" in normalized_name:
        return "디저트음료"
    return "커피"





def _sanitize_image_urls(image_urls: list[str]) -> list[str]:

    if not image_urls:

        return []

    cleaned = [url.strip() for url in image_urls if isinstance(url, str) and url.strip()]

    if len(cleaned) > 2:

        raise ValueError("At most 2 images can be attached")

    for url in cleaned:

        if not (url.startswith("http://") or url.startswith("https://")):

            raise ValueError("Invalid image URL")

    return cleaned
