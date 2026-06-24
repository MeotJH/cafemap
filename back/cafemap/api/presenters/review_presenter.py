import json

from fastapi import Request

from cafemap.core.rating_dimensions import attributes_json_loads
from cafemap.schemas.cafemap import ReviewMediaItem, ReviewOut

from .media_presenter import (
    resolve_asset_url,
    resolve_review_media_url,
    resolve_video_thumbnail_url,
)
from .scoring_presenter import scores_from_snapshot


def image_urls_from_snapshot(image_urls_json: str | None) -> list[str]:
    if not image_urls_json:
        return []
    try:
        parsed = json.loads(image_urls_json)
    except (TypeError, ValueError):
        return []
    if not isinstance(parsed, list):
        return []
    return [item.strip() for item in parsed if isinstance(item, str) and item.strip()]


def review_media_item_from_snapshot(
    item: dict[str, object],
    request: Request,
) -> ReviewMediaItem | None:
    raw_url = str(item.get("url", "")).strip()
    if not raw_url:
        return None
    raw_thumbnail_url = str(item.get("thumbnailUrl", "") or "").strip()
    duration_ms = item.get("durationMs")
    return ReviewMediaItem(
        type=str(item.get("type", "image")).strip().lower() or "image",
        url=resolve_review_media_url(request, raw_url),
        thumbnailUrl=(
            resolve_asset_url(request, raw_thumbnail_url)
            if raw_thumbnail_url
            else resolve_video_thumbnail_url(request, raw_url)
        ),
        durationMs=(
            int(duration_ms)
            if isinstance(duration_ms, (int, float)) and duration_ms >= 0
            else None
        ),
    )


def media_items_from_snapshot(
    media_items_json: str | None,
    image_urls_json: str | None,
    request: Request,
) -> list[ReviewMediaItem]:
    parsed_items: list[dict[str, object]] = []
    if media_items_json:
        try:
            parsed = json.loads(media_items_json)
        except (TypeError, ValueError):
            parsed = []
        if isinstance(parsed, list):
            parsed_items = [item for item in parsed if isinstance(item, dict)]

    if not parsed_items:
        parsed_items = [
            {"type": "image", "url": url}
            for url in image_urls_from_snapshot(image_urls_json)
        ]

    media_items: list[ReviewMediaItem] = []
    for item in parsed_items:
        media_item = review_media_item_from_snapshot(item, request)
        if media_item is not None:
            media_items.append(media_item)
    return media_items


def to_review_out(
    *,
    request: Request,
    review,
    store_name: str,
    store_address: str = "",
    place_id: str = "",
    store_link: str,
    lat: float | None = None,
    lng: float | None = None,
    brand_name: str,
    brand_id: str = "",
    menu_name: str,
    menu_category: str,
    user_email: str | None,
) -> ReviewOut:
    return ReviewOut(
        id=review.id,
        storeName=store_name,
        address=store_address,
        placeId=place_id,
        link=store_link,
        lat=lat,
        lng=lng,
        temperatureOption=review.temperature_option,
        brandId=brand_id,
        brandName=brand_name,
        menuName=menu_name,
        menuCategory=menu_category,
        reviewerType=(getattr(review, "reviewer_type", None) or "USER"),
        ratingSchemaVersion=(getattr(review, "rating_schema_version", None) or 1),
        scores=scores_from_snapshot(review.scores_json),
        attributes=attributes_json_loads(getattr(review, "attributes_json", None)),
        overall=review.overall,
        comment=review.comment,
        userEmail=user_email or "",
        imageUrls=image_urls_from_snapshot(review.image_urls_json),
        mediaItems=media_items_from_snapshot(
            review.media_items_json,
            review.image_urls_json,
            request,
        ),
        createdAt=review.created_at,
    )
