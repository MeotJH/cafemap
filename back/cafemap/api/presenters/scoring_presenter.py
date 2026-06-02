from cafemap.core.rating_dimensions import (
    scores_json_loads,
    top_highlights,
    visible_scores_for_category,
)
from cafemap.services import store_service


def scores_from_snapshot(scores_json: str | None) -> dict[str, float]:
    return scores_json_loads(scores_json)


def menu_highlights(
    category: str | None,
    raw_scores: str | None,
) -> list[tuple[str, float]]:
    scores = scores_from_snapshot(raw_scores)
    visible_scores = visible_scores_for_category(category, scores)
    return top_highlights(visible_scores)


def score_schema_version(scores: dict[str, float]) -> int:
    if any(
        key in scores
        for key in ("taste_satisfaction", "coffee_presence", "restroom_cleanliness")
    ):
        return 2
    return 1


def store_highlights(raw_scores: str | None) -> list[tuple[str, float]]:
    scores = scores_from_snapshot(raw_scores)
    return top_highlights(scores, score_schema_version(scores))


def store_signal(scores: dict[str, float], key: str) -> float:
    return float(scores.get(key, 0.0))


def dessert_signal(scores: dict[str, float]) -> float:
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


def display_score_for_store(aggregate) -> float:
    return store_service.confidence_weighted_score(
        rating=aggregate.rating,
        review_count=aggregate.review_count,
    )
