import json
import re
import uuid
from datetime import datetime
from difflib import SequenceMatcher

from sqlalchemy.orm import Session

from cafemap.core.config import (
    OFFICIAL_HUSBAND_EMAILS,
    OFFICIAL_WIFE_EMAILS,
    REVIEW_IMAGE_LIMIT,
)
from cafemap.core.rating_dimensions import (
    CURRENT_RATING_SCHEMA_VERSION,
    attributes_json_dumps,
    compute_overall,
    normalize_attributes,
    normalize_category,
    normalize_rating_schema_version,
    normalize_scores,
    normalize_store_scores,
    scores_json_dumps,
    scores_json_loads,
    top_highlights,
)
from cafemap.models.entities import (
    Brand,
    BrandMenuAggregate,
    Menu,
    Review,
    Store,
    StoreAggregate,
    User,
)
from cafemap.repositories import review_repository
from cafemap.services import geocode_service

# Review creation, validation, and aggregate update logic.

LOCAL_BRAND_ID = "brand-local"
STORE_TYPE_LOCAL = "local"
STORE_TYPE_FRANCHISE = "franchise"
REVIEWER_WIFE = "WIFE"
REVIEWER_HUSBAND = "HUSBAND"
REVIEWER_USER = "USER"


def get_my_reviews(db: Session, user_id: str):
    # Return reviews authored by the current user.
    return review_repository.fetch_my_reviews(db, user_id)


def get_review(db: Session, review_id: str):
    # Return a single review detail row.
    return review_repository.fetch_review(db, review_id)


def create_review(db: Session, payload, user_id: str):
    # Validate input, persist the review, and refresh aggregates.
    (
        brand,
        menu,
        store,
        aggregate_scores,
        menu_scores,
        resolved_overall,
        temperature_option,
        attributes,
        image_urls,
        rating_schema_version,
    ) = _prepare_review_payload(db, payload)

    review = Review(
        id=f"review-{uuid.uuid4().hex}",
        user_id=user_id,
        store_id=store.id,
        brand_id=brand.id,
        menu_id=menu.id,
        rating_schema_version=rating_schema_version,
        scores_json=scores_json_dumps(aggregate_scores),
        attributes_json=attributes_json_dumps(attributes),
        image_urls_json=json.dumps(image_urls, ensure_ascii=False),
        temperature_option=temperature_option,
        reviewer_type=_reviewer_type_for_user_id(db, user_id),
        overall=resolved_overall,
        comment=payload.comment,
        created_at=datetime.now(),
    )

    db.add(review)

    if (
        brand.id != LOCAL_BRAND_ID
        and rating_schema_version != CURRENT_RATING_SCHEMA_VERSION
    ):

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

    return review, store.name, store.link, brand.name, menu.name


def update_review(db: Session, review_id: str, payload, user_id: str):

    review = db.get(Review, review_id)
    if review is None:
        return None
    if review.user_id != user_id:
        raise PermissionError("You can edit only your own review")

    # 집계를 다시 계산해야 하므로 수정 전 연결 관계를 먼저 보관한다.
    previous_brand_id = review.brand_id
    previous_menu_id = review.menu_id
    previous_store_id = review.store_id

    (
        brand,
        menu,
        store,
        aggregate_scores,
        _menu_scores,
        resolved_overall,
        temperature_option,
        attributes,
        image_urls,
        rating_schema_version,
    ) = _prepare_review_payload(db, payload)

    review.store_id = store.id
    review.brand_id = brand.id
    review.menu_id = menu.id
    review.rating_schema_version = rating_schema_version
    review.scores_json = scores_json_dumps(aggregate_scores)
    review.attributes_json = attributes_json_dumps(attributes)
    review.image_urls_json = json.dumps(image_urls, ensure_ascii=False)
    review.temperature_option = temperature_option
    review.reviewer_type = _reviewer_type_for_user_id(db, user_id)
    review.overall = resolved_overall
    review.comment = payload.comment

    db.flush()

    # 메뉴/매장이 바뀔 수 있으므로 이전 집계와 현재 집계를 모두 재계산 대상으로 잡는다.
    for brand_id, menu_id in {
        (previous_brand_id, previous_menu_id),
        (review.brand_id, review.menu_id),
    }:
        if brand_id != LOCAL_BRAND_ID:
            _rebuild_brand_menu_aggregate(db, brand_id=brand_id, menu_id=menu_id)

    for store_id in {previous_store_id, review.store_id}:
        _rebuild_store_aggregate(db, store_id=store_id)

    db.commit()
    db.refresh(review)
    return review


def _prepare_review_payload(db: Session, payload):

    brand = db.get(Brand, payload.brandId)

    if brand is None:

        raise ValueError("Brand not found")

    menu = _find_best_matching_menu(db, brand.id, payload.menuName)

    if menu is None:
        raise ValueError("Menu must be selected from the standard menu list")

    menu_category = normalize_category(menu.category)
    # 생성과 수정을 같은 정규화 규칙으로 처리하려고 저장 직전 payload 해석을 한곳에 모은다.
    store = _resolve_store_for_payload(db, brand_id=brand.id, payload=payload)

    input_scores = getattr(payload, "scores", {}) or {}
    if not input_scores:
        raise ValueError("scores is required")

    rating_schema_version = normalize_rating_schema_version(
        getattr(payload, "ratingSchemaVersion", 1)
    )
    temperature_option = _normalize_temperature_option(
        getattr(payload, "temperatureOption", "")
    )
    image_urls = _sanitize_image_urls(getattr(payload, "imageUrls", []))
    menu_scores = normalize_scores(
        menu_category,
        input_scores,
        schema_version=rating_schema_version,
    )
    store_scores = normalize_store_scores(
        getattr(payload, "storeScores", {}) or {},
        schema_version=rating_schema_version,
    )
    aggregate_scores = {**menu_scores, **store_scores}
    attributes = normalize_attributes(
        menu_category,
        getattr(payload, "attributes", {}) or {},
        schema_version=rating_schema_version,
        temperature_option=temperature_option,
    )
    resolved_overall = (
        float(payload.overall)
        if payload.overall > 0
        else compute_overall(menu_scores, fallback=0.0)
    )

    return (
        brand,
        menu,
        store,
        aggregate_scores,
        menu_scores,
        resolved_overall,
        temperature_option,
        attributes,
        image_urls,
        rating_schema_version,
    )


def _resolve_store_for_payload(db: Session, *, brand_id: str, payload) -> Store:
    place_id = (getattr(payload, "placeId", "") or "").strip()
    place_link = (getattr(payload, "link", "") or "").strip()
    payload_coords = _coords_from_payload(payload)
    store = _find_existing_store(
        db,
        brand_id,
        payload.storeName,
        payload.address,
        place_id,
    )

    if store is None:
        coords = payload_coords or geocode_service.geocode(payload.address)
        store = Store(
            id=f"store-{uuid.uuid4().hex}",
            brand_id=brand_id,
            name=payload.storeName,
            address=payload.address,
            store_type=_store_type_for_brand(brand_id),
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

    if place_id:
        store.place_id = place_id
    if place_link:
        store.link = place_link
    if payload.address:
        store.address = payload.address

    return store


def _normalize_temperature_option(value: str | None) -> str:
    normalized = (value or "").strip().lower()
    if normalized in {"hot", "ice"}:
        return normalized
    return ""


def _reviewer_type_for_user_id(db: Session, user_id: str) -> str:
    user = db.get(User, user_id)
    normalized = (user.email if user is not None else "").strip().lower()
    if normalized in {email.lower() for email in OFFICIAL_WIFE_EMAILS}:
        return REVIEWER_WIFE
    if normalized in {email.lower() for email in OFFICIAL_HUSBAND_EMAILS}:
        return REVIEWER_HUSBAND
    return REVIEWER_USER


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


def _rebuild_brand_menu_aggregate(db: Session, *, brand_id: str, menu_id: str):
    # 수정은 기존 평균에서 단순 가감이 어렵기 때문에 해당 메뉴 리뷰를 전부 다시 모아 계산한다.

    aggregate = (
        db.query(BrandMenuAggregate)
        .filter(BrandMenuAggregate.brand_id == brand_id)
        .filter(BrandMenuAggregate.menu_id == menu_id)
        .first()
    )

    menu = db.get(Menu, menu_id)
    if menu is None:
        if aggregate is not None:
            db.delete(aggregate)
        return

    reviews = (
        db.query(Review)
        .filter(Review.brand_id == brand_id)
        .filter(Review.menu_id == menu_id)
        .filter(Review.rating_schema_version != CURRENT_RATING_SCHEMA_VERSION)
        .all()
    )

    if not reviews:
        if aggregate is not None:
            db.delete(aggregate)
        return

    normalized_scores = [
        normalize_scores(menu.category, scores_json_loads(review.scores_json))
        for review in reviews
    ]
    averaged_scores = _average_score_maps(normalized_scores)
    average_overall = sum(review.overall for review in reviews) / len(reviews)
    highlights = top_highlights(averaged_scores)

    if aggregate is None:
        aggregate = BrandMenuAggregate(
            id=f"rank-{uuid.uuid4().hex}",
            brand_id=brand_id,
            menu_id=menu_id,
            rating=average_overall,
            review_count=len(reviews),
            highlight_score_a=highlights[0][1],
            highlight_label_a=highlights[0][0],
            highlight_score_b=highlights[1][1],
            highlight_label_b=highlights[1][0],
            scores_json=scores_json_dumps(averaged_scores),
        )
        db.add(aggregate)
        return

    aggregate.rating = average_overall
    aggregate.review_count = len(reviews)
    aggregate.highlight_score_a = highlights[0][1]
    aggregate.highlight_label_a = highlights[0][0]
    aggregate.highlight_score_b = highlights[1][1]
    aggregate.highlight_label_b = highlights[1][0]
    aggregate.scores_json = scores_json_dumps(averaged_scores)


def _update_store_aggregate(
    db: Session,
    store: Store,
    scores: dict[str, float],
    overall: float,
):

    # ?? ??? ?? ??????.

    aggregate = (
        db.query(StoreAggregate).filter(StoreAggregate.store_id == store.id).first()
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


def _rebuild_store_aggregate(db: Session, *, store_id: str):
    # 매장 집계는 항목별 참여 수가 다를 수 있어 평균과 counts_json을 함께 다시 만든다.

    aggregate = (
        db.query(StoreAggregate).filter(StoreAggregate.store_id == store_id).first()
    )
    reviews = db.query(Review).filter(Review.store_id == store_id).all()

    if not reviews:
        if aggregate is not None:
            db.delete(aggregate)
        return

    score_sums: dict[str, float] = {}
    score_counts: dict[str, int] = {}
    for review in reviews:
        scores = scores_json_loads(review.scores_json)
        for key, value in scores.items():
            score_sums[key] = score_sums.get(key, 0.0) + value
            score_counts[key] = score_counts.get(key, 0) + 1

    averaged_scores = {
        key: score_sums[key] / score_counts[key]
        for key in score_sums
        if score_counts.get(key, 0) > 0
    }
    average_overall = sum(review.overall for review in reviews) / len(reviews)

    if aggregate is None:
        aggregate = StoreAggregate(
            id=store_id,
            store_id=store_id,
            rating=average_overall,
            review_count=len(reviews),
            scores_json=scores_json_dumps(averaged_scores),
            counts_json=scores_json_dumps(score_counts),
        )
        db.add(aggregate)
        return

    aggregate.rating = average_overall
    aggregate.review_count = len(reviews)
    aggregate.scores_json = scores_json_dumps(averaged_scores)
    aggregate.counts_json = scores_json_dumps(score_counts)


def _average_score_maps(score_maps: list[dict[str, float]]) -> dict[str, float]:
    if not score_maps:
        return {}

    total_by_key: dict[str, float] = {}
    count_by_key: dict[str, int] = {}
    for score_map in score_maps:
        for key, value in score_map.items():
            total_by_key[key] = total_by_key.get(key, 0.0) + value
            count_by_key[key] = count_by_key.get(key, 0) + 1

    return {
        key: total_by_key[key] / count_by_key[key]
        for key in total_by_key
        if count_by_key.get(key, 0) > 0
    }


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


def _sanitize_image_urls(image_urls: list[str]) -> list[str]:

    if not image_urls:

        return []

    cleaned = [
        url.strip() for url in image_urls if isinstance(url, str) and url.strip()
    ]

    if len(cleaned) > REVIEW_IMAGE_LIMIT:

        raise ValueError(f"At most {REVIEW_IMAGE_LIMIT} images can be attached")

    for url in cleaned:

        if not (url.startswith("http://") or url.startswith("https://")):

            raise ValueError("Invalid image URL")

    return cleaned
