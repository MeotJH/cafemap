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

    scores_json_dumps,

    scores_json_loads,

    top_highlights,

)

from cafemap.repositories import review_repository

from cafemap.services import geocode_service





# ?? ???? ?? ????.

LOCAL_BRAND_ID = "brand-local"





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



    normalized_input_menu = _normalize_menu_name(payload.menuName)

    menu = _find_best_matching_menu(db, brand.id, payload.menuName)

    if menu is None:

        menu = Menu(

            id=f"menu-{uuid.uuid4().hex}",

            brand_id=brand.id,

            name=payload.menuName.strip(),

            image_url="",

            category=_classify_menu_category(normalized_input_menu),

        )

        db.add(menu)

    menu_category = normalize_category(menu.category)



    store = (

        db.query(Store)

        .filter(Store.brand_id == brand.id)

        .filter(Store.name == payload.storeName)

        .first()

    )

    if store is None:

        coords = geocode_service.geocode(payload.address)

        store = Store(

            id=f"store-{uuid.uuid4().hex}",

            brand_id=brand.id,

            name=payload.storeName,

            address=payload.address,

            distance_km=0.0,

            lat=coords[0] if coords else 0.0,

            lng=coords[1] if coords else 0.0,

        )

        db.add(store)

    elif store.lat == 0.0 and store.lng == 0.0 and payload.address:

        coords = geocode_service.geocode(payload.address)

        if coords:

            store.lat, store.lng = coords



    input_scores = getattr(payload, "scores", {}) or {}

    if not input_scores:

        raise ValueError("scores is required")

    image_urls = _sanitize_image_urls(getattr(payload, "imageUrls", []))

    normalized_scores = normalize_scores(menu_category, input_scores)

    resolved_overall = float(payload.overall) if payload.overall > 0 else compute_overall(normalized_scores, fallback=0.0)



    review = Review(

        id=f"review-{uuid.uuid4().hex}",

        user_id=user_id,

        store_id=store.id,

        brand_id=brand.id,

        menu_id=menu.id,

        scores_json=scores_json_dumps(normalized_scores),

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

            scores=normalized_scores,

            overall=resolved_overall,

        )

    _update_store_aggregate(

        db,

        store=store,

        scores=normalized_scores,

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





def _find_best_matching_menu(db: Session, brand_id: str, raw_name: str) -> Menu | None:

    # ?? ??? ??? ?? ???? ?? ????.

    menus = db.query(Menu).filter(Menu.brand_id == brand_id).all()

    if not menus:

        return None



    stripped = raw_name.strip()

    for existing in menus:

        if existing.name.strip() == stripped:

            return existing



    normalized_target = _normalize_menu_name(stripped)

    if not normalized_target:

        return None



    # 1) ??? ??? ?? ?? ??? ?? ????.

    for existing in menus:

        if _normalize_menu_name(existing.name) == normalized_target:

            return existing



    # 2) ?? ??? ??? ??? ???? ? ??? ????.

    best_menu: Menu | None = None

    best_score = 0.0

    for existing in menus:

        score = SequenceMatcher(

            a=normalized_target,

            b=_normalize_menu_name(existing.name),

        ).ratio()

        if score > best_score:

            best_score = score

            best_menu = existing



    if best_menu is not None and best_score >= 0.80:

        return best_menu

    return None





def _classify_menu_category(normalized_name: str) -> str:

    # ? ?? ?? ? ?? ????? ?? ???? ????.

    if "후라이드" in normalized_name:

        return "후라이드"

    if "양념" in normalized_name:

        return "양념"

    if "간장" in normalized_name or "소이" in normalized_name:

        return "양념"

    if "숯불" in normalized_name or "바베큐" in normalized_name or "구이" in normalized_name:

        return "구이"

    return "기타"





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

