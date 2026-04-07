from sqlalchemy.orm import Session

from cafemap.core.rating_dimensions import scores_json_loads, top_highlights
from cafemap.repositories import store_repository


# ?? ???? ?? ????.


def get_nearby_stores(db: Session):
    # ??/??? ??? ?? ??? ????.
    return store_repository.fetch_nearby_stores(db)


def get_store_rankings(db: Session):
    rows = store_repository.fetch_store_rankings(db)
    ranked = []
    for store, aggregate, brand_name, brand_logo_url in rows:
        display_score = confidence_weighted_score(
            rating=aggregate.rating,
            review_count=aggregate.review_count,
        )
        highlights = top_highlights(scores_json_loads(aggregate.scores_json))
        ranked.append(
            (
                display_score,
                aggregate.review_count,
                store,
                aggregate,
                brand_name,
                brand_logo_url,
                highlights,
            )
        )
    ranked.sort(key=lambda row: (row[0], row[1]), reverse=True)
    return ranked


def get_store_detail(db: Session, store_id: str):
    # ?? ?? ??? ????.
    return store_repository.fetch_store_detail(db, store_id)


def get_store_breakdown(db: Session, store_id: str):
    # ?? ?? ?? ??? ????.
    return store_repository.fetch_store_breakdown(db, store_id)


def get_store_reviews(db: Session, store_id: str):
    # ?? ?? ??? ????.
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
