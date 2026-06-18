from fastapi import Request

from cafemap.schemas.cafemap import (
    HomeRecommendedMenuOut,
    HomeSummaryOut,
    SimilarStoreOut,
    StoreRankingOut,
    StoreSummaryOut,
    StoreVisitMediaPageOut,
)

from .media_presenter import (
    resolve_media_gallery_url,
    resolve_store_image_url,
    resolve_thumbnail_url,
)
from .review_presenter import review_media_item_from_snapshot
from .scoring_presenter import (
    dessert_signal,
    display_score_for_store,
    scores_from_snapshot,
    store_highlights,
    store_signal,
)


def store_type_for_response(store) -> str:
    return (getattr(store, "store_type", None) or "unknown").strip() or "unknown"


def is_local_store(store) -> bool:
    store_type = store_type_for_response(store)
    return store_type == "local" or getattr(store, "brand_id", "") == "brand-local"


def to_store_ranking_out(request: Request, item: dict) -> StoreRankingOut:
    image_url = resolve_store_image_url(request, item["imageUrl"])
    image_urls = [
        resolve_media_gallery_url(request, url)
        for url in item.get("imageUrls", [])
        if isinstance(url, str) and url.strip()
    ]
    return StoreRankingOut(
        id=item["id"],
        storeId=item["storeId"],
        storeName=item["storeName"],
        brandName=item["brandName"],
        district=item.get("district", ""),
        storeType=item["storeType"],
        isLocal=bool(item["isLocal"]),
        link=item["link"],
        rating=float(item["rating"]),
        displayScore=float(item["displayScore"]),
        reviewCount=int(item["reviewCount"]),
        distanceKm=float(item["distanceKm"]),
        imageUrl=image_url,
        thumbnailImageUrl=resolve_thumbnail_url(request, item["imageUrl"]),
        imageUrls=image_urls,
        thumbnailImageUrls=[
            resolve_thumbnail_url(request, url)
            for url in item.get("imageUrls", [])
            if isinstance(url, str) and url.strip()
        ],
        lat=float(item["lat"]),
        lng=float(item["lng"]),
        coffeeQualityScore=float(item["coffeeQualityScore"]),
        topLabelA=item["topLabelA"],
        topScoreA=float(item["topScoreA"]),
        topLabelB=item["topLabelB"],
        topScoreB=float(item["topScoreB"]),
        workFriendlyScore=float(item["workFriendlyScore"]),
        quietnessScore=float(item["quietnessScore"]),
        dessertScore=float(item["dessertScore"]),
        coupleScore=float(item["coupleScore"]),
        wifeScore=float(item["wifeScore"]),
        husbandScore=float(item["husbandScore"]),
        userScore=float(item["userScore"]),
        revisitScore=float(item["revisitScore"]),
        summary=item["summary"],
        tags=list(item["tags"]),
        latestVisitedAt=item["latestVisitedAt"],
    )


def to_store_summary_out(
    *,
    request: Request,
    store,
    aggregate,
    brand_name: str,
    brand_logo_url: str,
    visit_media_items: list[dict[str, object]] | None = None,
    has_visit_media_more: bool = False,
    visit_media_next_cursor: str | None = None,
) -> StoreSummaryOut:
    scores = scores_from_snapshot(aggregate.scores_json)
    highlights = store_highlights(aggregate.scores_json)
    return StoreSummaryOut(
        id=store.id,
        name=store.name,
        brandName=brand_name,
        storeType=store_type_for_response(store),
        isLocal=is_local_store(store),
        address=store.address,
        link=store.link,
        rating=aggregate.rating,
        displayScore=display_score_for_store(aggregate),
        reviewCount=aggregate.review_count,
        distanceKm=store.distance_km,
        imageUrl=resolve_store_image_url(request, brand_logo_url),
        lat=store.lat,
        lng=store.lng,
        coffeeQualityScore=store_signal(scores, "coffee_quality"),
        workFriendlyScore=store_signal(scores, "work_friendly"),
        quietnessScore=store_signal(scores, "quietness"),
        dessertScore=dessert_signal(scores),
        topLabelA=highlights[0][0],
        topScoreA=highlights[0][1],
        topLabelB=highlights[1][0],
        topScoreB=highlights[1][1],
        visitMediaItems=[
            media_item
            for raw_item in (visit_media_items or [])
            if (media_item := review_media_item_from_snapshot(raw_item, request))
            is not None
        ],
        hasVisitMediaMore=has_visit_media_more,
        visitMediaNextCursor=visit_media_next_cursor,
    )


def to_home_summary_out(request: Request, payload: dict) -> HomeSummaryOut:
    return HomeSummaryOut(
        featuredCafe=(
            to_store_ranking_out(request, payload["featuredCafe"])
            if payload["featuredCafe"] is not None
            else None
        ),
        wifeTop=[to_store_ranking_out(request, item) for item in payload["wifeTop"]],
        husbandTop=[
            to_store_ranking_out(request, item) for item in payload["husbandTop"]
        ],
        recentCafes=[
            to_store_ranking_out(request, item) for item in payload["recentCafes"]
        ],
        recommendedMenus=[
            HomeRecommendedMenuOut(
                menuName=item.menu_name,
                storeName=item.store_name,
                score=item.average_score,
            )
            for item in payload["recommendedMenus"]
        ],
    )


def to_store_visit_media_page_out(
    request: Request,
    page,
) -> StoreVisitMediaPageOut:
    return StoreVisitMediaPageOut(
        items=[
            media_item
            for raw_item in page.items
            if (media_item := review_media_item_from_snapshot(raw_item, request))
            is not None
        ],
        nextCursor=page.next_cursor,
        hasMore=page.has_more,
    )


def to_similar_store_out(item) -> SimilarStoreOut:
    return SimilarStoreOut(
        storeId=item.store.id,
        name=item.store.name,
        brandName=item.brand_name,
        address=item.store.address,
        rating=item.rating,
        reviewCount=item.review_count,
        lat=item.store.lat,
        lng=item.store.lng,
        similarityScore=item.similarity_score,
        ratingSchemaVersion=item.rating_schema_version,
        matchedDimensions=item.matched_dimensions,
    )
