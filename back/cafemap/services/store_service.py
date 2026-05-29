from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy.orm import Session

from cafemap.core.config import REVIEW_IMAGE_LIMIT
from cafemap.core.rating_dimensions import (
    CURRENT_RATING_SCHEMA_VERSION,
    LEGACY_HIGHLIGHT_DIMENSIONS,
    attributes_json_loads,
    category_dimensions_for_schema,
    normalize_rating_schema_version,
    scores_json_loads,
    store_dimensions_for_schema,
    top_highlights,
)
from cafemap.models.entities import Store
from cafemap.repositories import store_repository

REVIEWER_WIFE = "WIFE"
REVIEWER_HUSBAND = "HUSBAND"
REVIEWER_USER = "USER"
RANKING_COUPLE = "couple"
RANKING_WIFE = "wife"
RANKING_HUSBAND = "husband"
RANKING_USER = "user"
RANKING_PURPOSE_DATE = "date"
RANKING_PURPOSE_CONVERSATION = "conversation"
RANKING_PURPOSE_PHOTO = "photo"
RANKING_PURPOSE_COFFEE = "coffee"
RANKING_PURPOSE_LONG_STAY = "long_stay"
SUPPORTED_RANKING_PURPOSES = {
    RANKING_PURPOSE_DATE,
    RANKING_PURPOSE_CONVERSATION,
    RANKING_PURPOSE_PHOTO,
    RANKING_PURPOSE_COFFEE,
    RANKING_PURPOSE_LONG_STAY,
}
MIN_SIMILAR_COMMON_DIMENSIONS = 3
MAX_RATING_SCORE = 5.0


@dataclass
class AggregatedMenu:
    menu_name: str
    store_name: str
    score_sum: float = 0.0
    count: int = 0

    @property
    def average_score(self) -> float:
        if self.count <= 0:
            return 0.0
        return self.score_sum / self.count


@dataclass
class SimilarStoreResult:
    store: Store
    brand_name: str
    rating: float
    review_count: int
    rating_schema_version: int
    similarity_score: float
    matched_dimensions: list[str]


@dataclass
class RatingBreakdownResult:
    scores: dict[str, float]
    overall: float
    rating_schema_version: int
    review_count: int


def get_nearby_stores(db: Session):
    return store_repository.fetch_nearby_stores(db)


def get_store_rankings(
    db: Session,
    ranking_type: str = RANKING_COUPLE,
    purpose: str | None = None,
):
    rows = store_repository.fetch_store_rankings(db)
    ranked = []
    normalized_purpose = normalize_ranking_purpose(purpose)
    segmented = {
        item["storeId"]: item
        for item in _build_segmented_rankings(db, include_private=True)
    }

    for store, aggregate, brand_name, brand_logo_url in rows:
        display_score = confidence_weighted_score(
            rating=aggregate.rating,
            review_count=aggregate.review_count,
        )
        highlights = top_highlights(scores_json_loads(aggregate.scores_json))
        segmented_item = segmented.get(store.id)
        if segmented_item is None:
            continue
        audience_score = _score_for_ranking_type(segmented_item, ranking_type)
        if audience_score <= 0:
            continue
        purpose_score = _purpose_score(segmented_item, normalized_purpose)
        if normalized_purpose is not None and purpose_score <= 0:
            continue
        ranked.append(
            (
                purpose_score,
                audience_score,
                segmented_item["latestVisitedAt"] or datetime.min,
                segmented_item["revisitScore"],
                display_score,
                aggregate.review_count,
                store,
                aggregate,
                brand_name,
                brand_logo_url,
                highlights,
                segmented_item,
            )
        )

    if normalized_purpose is None:
        ranked.sort(
            key=lambda row: (row[1], row[3], row[2], row[5]),
            reverse=True,
        )
    else:
        ranked.sort(
            key=lambda row: (row[0], row[1], row[3], row[2], row[5]),
            reverse=True,
        )

    sanitized = []
    for row in ranked:
        item = dict(row[11])
        _strip_private_fields(item)
        sanitized.append((*row[:11], item))
    return sanitized


def get_home_summary(db: Session) -> dict[str, object]:
    rankings = _build_segmented_rankings(db)
    wife_top = [item for item in rankings if item["wifeScore"] > 0]
    wife_top.sort(
        key=lambda item: (item["wifeScore"], item["revisitScore"]), reverse=True
    )

    husband_top = [item for item in rankings if item["husbandScore"] > 0]
    husband_top.sort(
        key=lambda item: (item["husbandScore"], item["revisitScore"]),
        reverse=True,
    )

    couple_top = [item for item in rankings if item["coupleScore"] > 0]
    couple_top.sort(
        key=lambda item: (item["coupleScore"], item["revisitScore"]),
        reverse=True,
    )

    recent = [item for item in rankings if item["latestVisitedAt"] is not None]
    recent.sort(key=lambda item: item["latestVisitedAt"], reverse=True)

    menu_map = _build_recommended_menus(db)
    recommended_menus = sorted(
        menu_map.values(),
        key=lambda item: (item.average_score, item.count),
        reverse=True,
    )[:3]

    return {
        "featuredCafe": couple_top[0] if couple_top else None,
        "wifeTop": wife_top[:3],
        "husbandTop": husband_top[:3],
        "recentCafes": recent[:6],
        "recommendedMenus": recommended_menus,
    }


def get_store_detail(db: Session, store_id: str):
    return store_repository.fetch_store_detail(db, store_id)


def get_store_breakdown(db: Session, store_id: str):
    rows = store_repository.fetch_store_reviews(db, store_id)
    if rows:
        schema_version = _preferred_schema_version(review for review, *_ in rows)
        scores, overall, review_count = _average_review_rows(
            rows,
            schema_version=schema_version,
        )
        if review_count > 0:
            return RatingBreakdownResult(
                scores=scores,
                overall=overall,
                rating_schema_version=schema_version,
                review_count=review_count,
            )

    aggregate = store_repository.fetch_store_breakdown(db, store_id)
    if aggregate is None:
        return None
    return RatingBreakdownResult(
        scores=scores_json_loads(aggregate.scores_json),
        overall=aggregate.rating,
        rating_schema_version=1,
        review_count=aggregate.review_count,
    )


def get_similar_stores(
    db: Session,
    store_id: str,
    limit: int = 3,
) -> list[SimilarStoreResult] | None:
    rows = store_repository.fetch_all_store_review_rows(db)
    stores = _build_store_comparison_payloads(rows)
    current = stores.get(store_id)
    if current is None:
        return None

    current_schema = (
        CURRENT_RATING_SCHEMA_VERSION
        if current["schemas"].get(CURRENT_RATING_SCHEMA_VERSION, {}).get("count", 0) > 0
        else 1
    )
    current_scores = _comparable_scores(
        current["schemas"].get(current_schema, {}).get("scores", {})
    )
    if not current_scores:
        return []

    candidates: list[SimilarStoreResult] = []
    for candidate_id, payload in stores.items():
        if candidate_id == store_id:
            continue

        candidate_schema_payload = payload["schemas"].get(current_schema, {})
        candidate_scores = _comparable_scores(
            candidate_schema_payload.get("scores", {})
        )
        common_dimensions = sorted(set(current_scores) & set(candidate_scores))
        if len(common_dimensions) < MIN_SIMILAR_COMMON_DIMENSIONS:
            continue

        differences = [
            (key, abs(current_scores[key] - candidate_scores[key]))
            for key in common_dimensions
        ]
        distance = sum(diff for _, diff in differences) / len(differences)
        similarity_score = max(0.0, 1.0 - (distance / MAX_RATING_SCORE))
        matched_dimensions = [
            key
            for key, _ in sorted(differences, key=lambda item: (item[1], item[0]))[:3]
        ]
        candidates.append(
            SimilarStoreResult(
                store=payload["store"],
                brand_name=str(payload["brand_name"]),
                rating=float(candidate_schema_payload.get("overall", 0.0)),
                review_count=int(candidate_schema_payload.get("count", 0)),
                rating_schema_version=current_schema,
                similarity_score=similarity_score,
                matched_dimensions=matched_dimensions,
            )
        )

    candidates.sort(
        key=lambda item: (
            item.similarity_score,
            item.rating,
            item.review_count,
        ),
        reverse=True,
    )
    return candidates[:limit]


def get_store_reviews(db: Session, store_id: str):
    return store_repository.fetch_store_reviews(db, store_id)


def confidence_weighted_score(
    *,
    rating: float,
    review_count: int,
    global_average: float = 4.0,
    prior_weight: int = 5,
) -> float:
    if review_count <= 0:
        return global_average
    return ((rating * review_count) + (global_average * prior_weight)) / (
        review_count + prior_weight
    )


def _comparable_scores(scores: dict[str, float]) -> dict[str, float]:
    return {
        key: max(0.0, min(MAX_RATING_SCORE, float(value)))
        for key, value in scores.items()
        if key not in LEGACY_HIGHLIGHT_DIMENSIONS and float(value) > 0
    }


def _preferred_schema_version(reviews) -> int:
    for review in reviews:
        if _review_schema_version(review) == CURRENT_RATING_SCHEMA_VERSION:
            return CURRENT_RATING_SCHEMA_VERSION
    return 1


def _review_schema_version(review) -> int:
    return normalize_rating_schema_version(
        getattr(review, "rating_schema_version", None)
    )


def _allowed_score_keys(category: str | None, schema_version: int) -> set[str]:
    keys = set(category_dimensions_for_schema(category, schema_version))
    keys.update(store_dimensions_for_schema(schema_version, include_optional=True))
    return keys


def _visible_review_scores(review, category: str | None) -> dict[str, float]:
    schema_version = _review_schema_version(review)
    allowed = _allowed_score_keys(category, schema_version)
    source = scores_json_loads(getattr(review, "scores_json", None))
    return {
        key: float(value)
        for key, value in source.items()
        if key in allowed and key not in LEGACY_HIGHLIGHT_DIMENSIONS
    }


def _average_review_rows(
    rows, *, schema_version: int
) -> tuple[dict[str, float], float, int]:
    score_sums: dict[str, float] = {}
    score_counts: dict[str, int] = {}
    overall_sum = 0.0
    review_count = 0

    for review, *rest in rows:
        menu_category = rest[4] if len(rest) >= 5 else None
        if _review_schema_version(review) != schema_version:
            continue
        review_count += 1
        overall_sum += float(getattr(review, "overall", 0.0) or 0.0)
        for key, value in _visible_review_scores(review, menu_category).items():
            score_sums[key] = score_sums.get(key, 0.0) + value
            score_counts[key] = score_counts.get(key, 0) + 1

    averaged_scores = {
        key: score_sums[key] / score_counts[key]
        for key in score_sums
        if score_counts.get(key, 0) > 0
    }
    overall = overall_sum / review_count if review_count > 0 else 0.0
    return averaged_scores, overall, review_count


def _build_store_comparison_payloads(rows) -> dict[str, dict[str, object]]:
    store_map: dict[str, dict[str, object]] = {}

    for review, store, brand_name, _, _, menu_category, _ in rows:
        payload = store_map.get(store.id)
        if payload is None:
            payload = {
                "store": store,
                "brand_name": brand_name,
                "schemas": {},
            }
            store_map[store.id] = payload

        schema_version = _review_schema_version(review)
        schemas = payload["schemas"]
        schema_payload = schemas.get(schema_version)
        if schema_payload is None:
            schema_payload = {
                "score_sums": {},
                "score_counts": {},
                "scores": {},
                "overall_sum": 0.0,
                "overall": 0.0,
                "count": 0,
            }
            schemas[schema_version] = schema_payload

        schema_payload["overall_sum"] = float(schema_payload["overall_sum"]) + float(
            getattr(review, "overall", 0.0) or 0.0
        )
        schema_payload["count"] = int(schema_payload["count"]) + 1
        score_sums = schema_payload["score_sums"]
        score_counts = schema_payload["score_counts"]
        for key, value in _visible_review_scores(review, menu_category).items():
            score_sums[key] = score_sums.get(key, 0.0) + value
            score_counts[key] = score_counts.get(key, 0) + 1

    for payload in store_map.values():
        for schema_payload in payload["schemas"].values():
            count = int(schema_payload["count"])
            score_sums = schema_payload["score_sums"]
            score_counts = schema_payload["score_counts"]
            schema_payload["scores"] = {
                key: score_sums[key] / score_counts[key]
                for key in score_sums
                if score_counts.get(key, 0) > 0
            }
            schema_payload["overall"] = (
                float(schema_payload["overall_sum"]) / count if count > 0 else 0.0
            )

    return store_map


def _score_for_ranking_type(item: dict[str, object], ranking_type: str) -> float:
    if ranking_type == RANKING_WIFE:
        return float(item["wifeScore"])
    if ranking_type == RANKING_HUSBAND:
        return float(item["husbandScore"])
    if ranking_type == RANKING_USER:
        return float(item["userScore"])
    return float(item["coupleScore"])


def _build_recommended_menus(db: Session) -> dict[tuple[str, str], AggregatedMenu]:
    rows = store_repository.fetch_all_store_review_rows(db)
    menu_map: dict[tuple[str, str], AggregatedMenu] = {}
    for review, store, _, _, menu_name, _, _ in rows:
        key = (store.id, menu_name)
        aggregate = menu_map.get(key)
        if aggregate is None:
            aggregate = AggregatedMenu(menu_name=menu_name, store_name=store.name)
            menu_map[key] = aggregate
        aggregate.score_sum += float(review.overall)
        aggregate.count += 1
    return menu_map


def _build_segmented_rankings(
    db: Session,
    *,
    include_private: bool = False,
) -> list[dict[str, object]]:
    rows = store_repository.fetch_all_store_review_rows(db)
    store_map: dict[str, dict[str, object]] = {}

    for review, store, brand_name, brand_logo_url, _, menu_category, user_email in rows:
        payload = store_map.get(store.id)
        if payload is None:
            payload = {
                "id": store.id,
                "storeId": store.id,
                "storeName": store.name,
                "brandName": brand_name,
                "district": _extract_district(getattr(store, "address", "")),
                "storeType": getattr(store, "store_type", "unknown"),
                "isLocal": getattr(store, "store_type", "unknown") == "local"
                or getattr(store, "brand_id", "") == "brand-local",
                "link": getattr(store, "link", ""),
                "rating": 0.0,
                "displayScore": 0.0,
                "reviewCount": 0,
                "distanceKm": float(getattr(store, "distance_km", 0.0) or 0.0),
                "imageUrl": brand_logo_url or "",
                "imageUrls": [],
                "lat": float(getattr(store, "lat", 0.0) or 0.0),
                "lng": float(getattr(store, "lng", 0.0) or 0.0),
                "coffeeQualityScore": 0.0,
                "topLabelA": "",
                "topScoreA": 0.0,
                "topLabelB": "",
                "topScoreB": 0.0,
                "workFriendlyScore": 0.0,
                "quietnessScore": 0.0,
                "dessertScore": 0.0,
                "coupleScore": 0.0,
                "wifeScore": 0.0,
                "husbandScore": 0.0,
                "userScore": 0.0,
                "revisitScore": 0.0,
                "summary": "",
                "tags": [],
                "latestVisitedAt": None,
                "_reviewScoreSum": 0.0,
                "_reviewCount": 0,
                "_wifeTotal": 0.0,
                "_wifeCount": 0,
                "_husbandTotal": 0.0,
                "_husbandCount": 0,
                "_userTotal": 0.0,
                "_userCount": 0,
                "_revisitTotal": 0.0,
                "_revisitCount": 0,
                "_scoreTotalsBySchema": {},
                "_scoreCountsBySchema": {},
                "_schemaCounts": {},
                "_attributeTotals": {},
                "_attributePositiveTotals": {},
            }
            store_map[store.id] = payload

        schema_version = _review_schema_version(review)
        schema_counts = payload["_schemaCounts"]
        schema_counts[schema_version] = int(schema_counts.get(schema_version, 0)) + 1
        payload["_reviewScoreSum"] = float(payload["_reviewScoreSum"]) + float(
            review.overall
        )
        payload["_reviewCount"] = int(payload["_reviewCount"]) + 1
        if (
            payload["latestVisitedAt"] is None
            or review.created_at > payload["latestVisitedAt"]
        ):
            payload["latestVisitedAt"] = review.created_at

        reviewer_type = (
            getattr(review, "reviewer_type", None) or REVIEWER_USER
        ).upper()
        if reviewer_type == REVIEWER_WIFE:
            payload["_wifeTotal"] = float(payload["_wifeTotal"]) + float(review.overall)
            payload["_wifeCount"] = int(payload["_wifeCount"]) + 1
        elif reviewer_type == REVIEWER_HUSBAND:
            payload["_husbandTotal"] = float(payload["_husbandTotal"]) + float(
                review.overall
            )
            payload["_husbandCount"] = int(payload["_husbandCount"]) + 1
        else:
            payload["_userTotal"] = float(payload["_userTotal"]) + float(review.overall)
            payload["_userCount"] = int(payload["_userCount"]) + 1

        scores = _visible_review_scores(review, menu_category)
        revisit = scores.get("revisit_intent")
        if revisit is not None:
            payload["_revisitTotal"] = float(payload["_revisitTotal"]) + float(revisit)
            payload["_revisitCount"] = int(payload["_revisitCount"]) + 1

        if schema_version == CURRENT_RATING_SCHEMA_VERSION:
            attributes = attributes_json_loads(getattr(review, "attributes_json", None))
            _accumulate_attribute_signal(
                payload,
                "outlet_available",
                attributes.get("outlet_available"),
            )
            _accumulate_attribute_signal(
                payload,
                "wifi_usable",
                attributes.get("wifi_usable"),
            )

        for image_url in _image_urls_from_snapshot(review.image_urls_json):
            image_urls = payload["imageUrls"]
            if (
                isinstance(image_urls, list)
                and len(image_urls) < REVIEW_IMAGE_LIMIT
                and image_url not in image_urls
            ):
                image_urls.append(image_url)

        totals_by_schema = payload["_scoreTotalsBySchema"]
        counts_by_schema = payload["_scoreCountsBySchema"]
        totals = totals_by_schema.setdefault(schema_version, {})
        counts = counts_by_schema.setdefault(schema_version, {})
        for key, value in scores.items():
            totals[key] = totals.get(key, 0.0) + float(value)
            counts[key] = counts.get(key, 0) + 1

    results: list[dict[str, object]] = []
    for payload in store_map.values():
        review_count = int(payload["_reviewCount"])
        if review_count <= 0:
            continue

        schema_counts = payload["_schemaCounts"]
        schema_version = (
            CURRENT_RATING_SCHEMA_VERSION
            if schema_counts.get(CURRENT_RATING_SCHEMA_VERSION, 0) > 0
            else 1
        )
        score_totals = payload["_scoreTotalsBySchema"].get(schema_version, {})
        score_counts = payload["_scoreCountsBySchema"].get(schema_version, {})
        avg_scores = {
            key: score_totals[key] / score_counts[key]
            for key in score_totals
            if score_counts.get(key, 0) > 0
        }
        highlights = top_highlights(avg_scores, schema_version)
        wife_score = _safe_average(payload["_wifeTotal"], payload["_wifeCount"])
        husband_score = _safe_average(
            payload["_husbandTotal"], payload["_husbandCount"]
        )
        user_score = _safe_average(payload["_userTotal"], payload["_userCount"])
        couple_score = 0.0
        if wife_score > 0 and husband_score > 0:
            couple_score = (wife_score + husband_score) / 2
        elif wife_score > 0:
            couple_score = wife_score
        elif husband_score > 0:
            couple_score = husband_score

        payload["rating"] = float(payload["_reviewScoreSum"]) / review_count
        payload["displayScore"] = confidence_weighted_score(
            rating=float(payload["rating"]),
            review_count=review_count,
        )
        payload["reviewCount"] = review_count
        payload["ratingSchemaVersion"] = schema_version
        payload["coffeeQualityScore"] = float(
            avg_scores.get("taste_satisfaction", avg_scores.get("coffee_quality", 0.0))
        )
        payload["workFriendlyScore"] = float(avg_scores.get("work_friendly", 0.0))
        payload["quietnessScore"] = float(avg_scores.get("quietness", 0.0))
        payload["dessertScore"] = _dessert_signal(avg_scores)
        payload["topLabelA"] = highlights[0][0]
        payload["topScoreA"] = highlights[0][1]
        payload["topLabelB"] = highlights[1][0]
        payload["topScoreB"] = highlights[1][1]
        payload["wifeScore"] = wife_score
        payload["husbandScore"] = husband_score
        payload["userScore"] = user_score
        payload["coupleScore"] = couple_score
        payload["revisitScore"] = _safe_average(
            payload["_revisitTotal"],
            payload["_revisitCount"],
        )
        if include_private:
            payload["_avgScores"] = (
                avg_scores if schema_version == CURRENT_RATING_SCHEMA_VERSION else {}
            )
        payload["tags"] = [label for label, score in highlights if label and score > 0][
            :3
        ]
        payload["summary"] = _build_summary(payload)
        if not include_private:
            _strip_private_fields(payload)
        results.append(payload)

    return results


def normalize_ranking_purpose(value: str | None) -> str | None:
    normalized = (value or "").strip().lower()
    if normalized in SUPPORTED_RANKING_PURPOSES:
        return normalized
    return None


def _extract_district(address: str | None) -> str:
    normalized = (address or "").strip()
    if not normalized:
        return ""

    tokens = [token.strip() for token in normalized.split() if token.strip()]
    for token in tokens:
        if token.endswith(("구", "군")):
            return token
    for token in tokens:
        if token.endswith("시"):
            return token
    return ""


def _dessert_signal(scores: dict[str, float]) -> float:
    values = [
        scores.get("taste_satisfaction"),
        scores.get("flavor_balance"),
        scores.get("sweetness"),
        scores.get("texture"),
        scores.get("visuals"),
        scores.get("portion"),
    ]
    parsed = [float(value) for value in values if value is not None]
    if not parsed:
        return 0.0
    return sum(parsed) / len(parsed)


def _safe_average(total: object, count: object) -> float:
    parsed_count = int(count)
    if parsed_count <= 0:
        return 0.0
    return float(total) / parsed_count


def _accumulate_attribute_signal(
    payload: dict[str, object],
    key: str,
    value: str | None,
) -> None:
    if not value:
        return
    totals = payload["_attributeTotals"]
    totals[key] = int(totals.get(key, 0)) + 1

    normalized = value.strip().lower()
    is_positive = (key == "outlet_available" and normalized == "yes") or (
        key == "wifi_usable" and normalized == "good"
    )
    if is_positive:
        positive_totals = payload["_attributePositiveTotals"]
        positive_totals[key] = int(positive_totals.get(key, 0)) + 1


def _purpose_score(item: dict[str, object], purpose: str | None) -> float:
    if purpose is None:
        return 0.0

    scores = item.get("_avgScores", {})
    if not isinstance(scores, dict):
        scores = {}

    taste_score = _first_positive_score(
        scores,
        "taste_satisfaction",
        "coffee_quality",
        "coffee_presence",
    )
    outlet_score = max(
        _score_value(scores, "outlet_access"),
        _attribute_ratio_score(item, "outlet_available"),
    )
    wifi_score = max(
        _score_value(scores, "wifi_quality"),
        _attribute_ratio_score(item, "wifi_usable"),
    )
    image_bonus = 5.0 if item.get("imageUrls") else 0.0

    if purpose == RANKING_PURPOSE_DATE:
        return _average_scores(
            _score_value(scores, "atmosphere"),
            taste_score,
            _score_value(scores, "revisit_intent"),
        )
    if purpose == RANKING_PURPOSE_CONVERSATION:
        return _average_scores(
            _score_value(scores, "quietness"),
            _score_value(scores, "seat_comfort"),
            _score_value(scores, "service"),
            fallback=_score_value(scores, "atmosphere"),
        )
    if purpose == RANKING_PURPOSE_PHOTO:
        return _average_scores(
            _score_value(scores, "atmosphere"),
            _score_value(scores, "visuals"),
            _score_value(scores, "restroom_cleanliness"),
            fallback=image_bonus,
        )
    if purpose == RANKING_PURPOSE_COFFEE:
        return _average_scores(
            taste_score,
            _score_value(scores, "aroma"),
            _score_value(scores, "clean_finish"),
            fallback=_score_value(scores, "aftertaste"),
        )
    if purpose == RANKING_PURPOSE_LONG_STAY:
        return _average_scores(
            _score_value(scores, "seat_comfort"),
            _score_value(scores, "work_friendly"),
            outlet_score,
            wifi_score,
            _score_value(scores, "service"),
        )
    return 0.0


def _average_scores(*values: float, fallback: float = 0.0) -> float:
    parsed = [float(value) for value in values if float(value) > 0]
    if parsed:
        return sum(parsed) / len(parsed)
    return fallback


def _score_value(scores: dict[str, object], key: str) -> float:
    try:
        return max(0.0, float(scores.get(key, 0.0)))
    except (TypeError, ValueError):
        return 0.0


def _first_positive_score(scores: dict[str, object], *keys: str) -> float:
    for key in keys:
        value = _score_value(scores, key)
        if value > 0:
            return value
    return 0.0


def _attribute_ratio_score(item: dict[str, object], key: str) -> float:
    totals = item.get("_attributeTotals", {})
    positive_totals = item.get("_attributePositiveTotals", {})
    if not isinstance(totals, dict) or not isinstance(positive_totals, dict):
        return 0.0
    total = int(totals.get(key, 0))
    if total <= 0:
        return 0.0
    positive = int(positive_totals.get(key, 0))
    return (positive / total) * 5.0


def _image_urls_from_snapshot(image_urls_json: str | None) -> list[str]:
    if not image_urls_json:
        return []
    try:
        parsed = json.loads(image_urls_json)
    except (TypeError, ValueError):
        return []
    if not isinstance(parsed, list):
        return []
    return [item.strip() for item in parsed if isinstance(item, str) and item.strip()]


def _build_summary(payload: dict[str, object]) -> str:
    tags = payload["tags"]
    store_name = payload["storeName"]
    if isinstance(tags, list) and len(tags) >= 2:
        return f"{store_name}은 {tags[0]}과 {tags[1]} 평가가 좋았던 카페예요."
    if isinstance(tags, list) and tags:
        return f"{store_name}은 {tags[0]} 평가가 두드러졌던 카페예요."
    if float(payload["coupleScore"]) > 0:
        if float(payload["wifeScore"]) > 0 and float(payload["husbandScore"]) > 0:
            return f"{store_name}은 두 사람이 모두 좋게 평가한 카페예요."
        return f"{store_name}은 부부 중 한 명 이상이 좋게 평가한 카페예요."
    if float(payload["wifeScore"]) > 0:
        return f"{store_name}은 아내 기준 만족도가 높았던 카페예요."
    if float(payload["husbandScore"]) > 0:
        return f"{store_name}은 남편 기준 만족도가 높았던 카페예요."
    if float(payload["userScore"]) > 0:
        return f"{store_name}은 사용자 평가가 쌓인 카페예요."
    return f"{store_name}은 방문 리뷰가 기록된 카페예요."


def _strip_private_fields(payload: dict[str, object]) -> None:
    for key in list(payload.keys()):
        if key.startswith("_"):
            del payload[key]
