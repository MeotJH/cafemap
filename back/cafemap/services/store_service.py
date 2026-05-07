from __future__ import annotations

import json

from dataclasses import dataclass
from datetime import datetime

from sqlalchemy.orm import Session

from cafemap.core.rating_dimensions import scores_json_loads, top_highlights
from cafemap.repositories import store_repository


REVIEWER_WIFE = "WIFE"
REVIEWER_HUSBAND = "HUSBAND"
REVIEWER_USER = "USER"
RANKING_COUPLE = "couple"
RANKING_WIFE = "wife"
RANKING_HUSBAND = "husband"
RANKING_USER = "user"


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


def get_nearby_stores(db: Session):
    return store_repository.fetch_nearby_stores(db)


def get_store_rankings(db: Session, ranking_type: str = RANKING_COUPLE):
    rows = store_repository.fetch_store_rankings(db)
    ranked = []
    segmented = {item["storeId"]: item for item in _build_segmented_rankings(db)}

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
        ranked.append(
            (
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

    ranked.sort(key=lambda row: (row[0], row[2], row[1], row[4]), reverse=True)
    return ranked


def get_home_summary(db: Session) -> dict[str, object]:
    rankings = _build_segmented_rankings(db)
    wife_top = [
        item for item in rankings if item["wifeScore"] > 0
    ]
    wife_top.sort(key=lambda item: (item["wifeScore"], item["revisitScore"]), reverse=True)

    husband_top = [
        item for item in rankings if item["husbandScore"] > 0
    ]
    husband_top.sort(
        key=lambda item: (item["husbandScore"], item["revisitScore"]),
        reverse=True,
    )

    couple_top = [
        item for item in rankings if item["coupleScore"] > 0
    ]
    couple_top.sort(
        key=lambda item: (item["coupleScore"], item["revisitScore"]),
        reverse=True,
    )

    recent = [
        item for item in rankings if item["latestVisitedAt"] is not None
    ]
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
    return store_repository.fetch_store_breakdown(db, store_id)


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


def _build_segmented_rankings(db: Session) -> list[dict[str, object]]:
    rows = store_repository.fetch_all_store_review_rows(db)
    store_map: dict[str, dict[str, object]] = {}

    for review, store, brand_name, brand_logo_url, _, _, user_email in rows:
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
                "_scoreTotals": {},
            }
            store_map[store.id] = payload

        payload["_reviewScoreSum"] = float(payload["_reviewScoreSum"]) + float(review.overall)
        payload["_reviewCount"] = int(payload["_reviewCount"]) + 1
        if payload["latestVisitedAt"] is None or review.created_at > payload["latestVisitedAt"]:
            payload["latestVisitedAt"] = review.created_at

        reviewer_type = (getattr(review, "reviewer_type", None) or REVIEWER_USER).upper()
        if reviewer_type == REVIEWER_WIFE:
            payload["_wifeTotal"] = float(payload["_wifeTotal"]) + float(review.overall)
            payload["_wifeCount"] = int(payload["_wifeCount"]) + 1
        elif reviewer_type == REVIEWER_HUSBAND:
            payload["_husbandTotal"] = float(payload["_husbandTotal"]) + float(review.overall)
            payload["_husbandCount"] = int(payload["_husbandCount"]) + 1
        else:
            payload["_userTotal"] = float(payload["_userTotal"]) + float(review.overall)
            payload["_userCount"] = int(payload["_userCount"]) + 1

        scores = scores_json_loads(review.scores_json)
        revisit = scores.get("revisit_intent")
        if revisit is not None:
            payload["_revisitTotal"] = float(payload["_revisitTotal"]) + float(revisit)
            payload["_revisitCount"] = int(payload["_revisitCount"]) + 1

        for image_url in _image_urls_from_snapshot(review.image_urls_json):
            image_urls = payload["imageUrls"]
            if (
                isinstance(image_urls, list)
                and len(image_urls) < 2
                and image_url not in image_urls
            ):
                image_urls.append(image_url)

        totals = payload["_scoreTotals"]
        for key, value in scores.items():
            totals[key] = totals.get(key, 0.0) + float(value)

    results: list[dict[str, object]] = []
    for payload in store_map.values():
        review_count = int(payload["_reviewCount"])
        if review_count <= 0:
            continue

        avg_scores = {
            key: total / review_count
            for key, total in payload["_scoreTotals"].items()
        }
        highlights = top_highlights(avg_scores)
        wife_score = _safe_average(payload["_wifeTotal"], payload["_wifeCount"])
        husband_score = _safe_average(payload["_husbandTotal"], payload["_husbandCount"])
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
        payload["coffeeQualityScore"] = float(avg_scores.get("coffee_quality", 0.0))
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
        payload["tags"] = [
            label
            for label, score in highlights
            if label and score > 0
        ][:3]
        payload["summary"] = _build_summary(payload)
        _strip_private_fields(payload)
        results.append(payload)

    return results


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
        scores.get("flavor_balance"),
        scores.get("sweetness"),
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


def _image_urls_from_snapshot(image_urls_json: str | None) -> list[str]:
    if not image_urls_json:
        return []
    try:
        parsed = json.loads(image_urls_json)
    except (TypeError, ValueError):
        return []
    if not isinstance(parsed, list):
        return []
    return [
        item.strip()
        for item in parsed
        if isinstance(item, str) and item.strip()
    ]


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
