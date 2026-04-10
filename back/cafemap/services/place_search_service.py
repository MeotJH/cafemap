import math
import re
import logging

import requests

from cafemap.repositories import place_search_repository
from cafemap.services import reverse_geocode_service

logger = logging.getLogger(__name__)


_ALLOWED_CATEGORIES = {
    "카페,디저트",
    "카페",
    "음식점>카페,디저트",
    "음식점>카페",
}
_BRAND_HINTS = (
    ("brand-starbucks", "스타벅스", ("스타벅스", "starbucks")),
    ("brand-twosome", "투썸플레이스", ("투썸", "투썸플레이스", "twosome")),
    ("brand-ediya", "이디야커피", ("이디야", "이디야커피", "ediya")),
    ("brand-mega", "메가커피", ("메가커피", "메가mgc", "메가mgc커피", "mega")),
)


def search_places(
    query: str,
    display: int = 5,
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float | None = None,
    pages: int | None = None,
    south_lat: float | None = None,
    west_lng: float | None = None,
    north_lat: float | None = None,
    east_lng: float | None = None,
) -> list[dict]:
    provider = place_search_repository.get_place_search_provider()
    requested_display = max(1, min(display, 45))
    per_page = 15 if provider.provider_name == "kakao" else 5
    max_pages = 3 if provider.provider_name == "kakao" else 5
    page_count = max(1, min(pages or math.ceil(requested_display / per_page), max_pages))
    queries = _search_queries(query, lat=lat, lng=lng)
    radius_m = min(20000, int(round(radius_km * 1000))) if radius_km is not None else None
    rect = _rect_string(
        south_lat=south_lat,
        west_lng=west_lng,
        north_lat=north_lat,
        east_lng=east_lng,
    )
    category_group_code = "CE7" if _is_cafe_query(query) else None
    sort = (
        "distance"
        if provider.provider_name == "kakao"
        and lat is not None
        and lng is not None
        and rect is None
        else None
    )

    results: list[dict] = []
    seen_place_ids: set[str] = set()

    _collect_results(
        provider=provider,
        queries=queries,
        per_page=per_page,
        page_count=page_count,
        lat=lat,
        lng=lng,
        radius_m=radius_m,
        rect=rect,
        sort=sort,
        category_group_code=category_group_code,
        south_lat=south_lat,
        west_lng=west_lng,
        north_lat=north_lat,
        east_lng=east_lng,
        radius_km=radius_km,
        requested_display=requested_display,
        seen_place_ids=seen_place_ids,
        results=results,
    )

    # 위치 기준 검색에서 0건인 경우, 전역 키워드 검색으로 한 번 더 시도한다.
    if (
        not results
        and lat is not None
        and lng is not None
        and query.strip()
        and not _is_cafe_query(query)
    ):
        _collect_results(
            provider=provider,
            queries=[query.strip()],
            per_page=per_page,
            page_count=page_count,
            lat=lat,
            lng=lng,
            radius_m=None,
            rect=None,
            sort=None,
            category_group_code=category_group_code,
            south_lat=None,
            west_lng=None,
            north_lat=None,
            east_lng=None,
            radius_km=None,
            requested_display=requested_display,
            seen_place_ids=seen_place_ids,
            results=results,
        )

    if lat is not None and lng is not None:
        results.sort(key=lambda item: item["distanceKm"] or float("inf"))

    logger.info(
        "place_search query=%s provider=%s result_count=%s lat=%s lng=%s rect=%s",
        query,
        provider.provider_name,
        len(results),
        lat,
        lng,
        bool(rect),
    )
    return results[:requested_display]


def _collect_results(
    *,
    provider: place_search_repository.PlaceSearchProvider,
    queries: list[str],
    per_page: int,
    page_count: int,
    lat: float | None,
    lng: float | None,
    radius_m: int | None,
    rect: str | None,
    sort: str | None,
    category_group_code: str | None,
    south_lat: float | None,
    west_lng: float | None,
    north_lat: float | None,
    east_lng: float | None,
    radius_km: float | None,
    requested_display: int,
    seen_place_ids: set[str],
    results: list[dict],
) -> None:
    for search_query in queries:
        for page_index in range(page_count):
            start = page_index * per_page + 1
            try:
                items = provider.search_places(
                    place_search_repository.PlaceSearchQuery(
                        query=search_query,
                        display=per_page,
                        start=start,
                        lat=lat,
                        lng=lng,
                        radius_m=radius_m,
                        rect=rect,
                        sort=sort,
                        category_group_code=category_group_code,
                    )
                )
            except requests.RequestException as exc:
                logger.warning(
                    "place_search upstream_error query=%s provider=%s page=%s error=%s",
                    search_query,
                    provider.provider_name,
                    page_index + 1,
                    str(exc),
                )
                break

            if not items:
                break

            for item in items:
                parsed = _result_from_item(item, lat=lat, lng=lng)
                if parsed is None:
                    continue

                place_id = parsed["placeId"]
                if place_id in seen_place_ids:
                    continue

                if _has_bounds(south_lat, west_lng, north_lat, east_lng):
                    if parsed["lat"] is None or parsed["lng"] is None:
                        continue
                    if not _is_in_bounds(
                        parsed["lat"],
                        parsed["lng"],
                        south_lat=south_lat,
                        west_lng=west_lng,
                        north_lat=north_lat,
                        east_lng=east_lng,
                    ):
                        continue

                if radius_km is not None and parsed["distanceKm"] is not None:
                    if parsed["distanceKm"] > radius_km:
                        continue

                seen_place_ids.add(place_id)
                results.append(parsed)

            if len(items) < per_page:
                break
            if len(results) >= requested_display:
                break
        if len(results) >= requested_display:
            break


def _search_queries(query: str, *, lat: float | None, lng: float | None) -> list[str]:
    base = query.strip()
    if not base:
        return ["카페"]

    normalized = _normalize_match_text(base)
    if lat is None or lng is None:
        return [base]
    if normalized not in {"카페", "cafe", "coffee"}:
        return [base]

    queries = [base]
    for token in reverse_geocode_service.area_query_tokens(lat=lat, lng=lng):
        queries.append(f"{token} {base}")
    queries.extend(["커피", "디저트 카페", "베이커리 카페"])

    seen: set[str] = set()
    unique_queries: list[str] = []
    for item in queries:
        normalized_item = item.strip()
        if not normalized_item or normalized_item in seen:
            continue
        seen.add(normalized_item)
        unique_queries.append(normalized_item)
    return unique_queries


def _result_from_item(
    item: place_search_repository.PlaceSearchItem,
    *,
    lat: float | None,
    lng: float | None,
) -> dict | None:
    name = item.name.strip()
    category = item.category.strip()
    if not _is_allowed_category(category):
        return None

    brand_id, brand_name = _infer_brand_hint(name)
    coords = _coords_from_place(item)
    distance_km = None
    if coords is not None and lat is not None and lng is not None:
        distance_km = _distance_km(lat, lng, coords[0], coords[1])

    return {
        "name": name,
        "address": item.address,
        "roadAddress": item.road_address,
        "category": category,
        "phone": item.phone,
        "link": item.link,
        "placeId": item.place_id,
        "brandId": brand_id,
        "brandName": brand_name,
        "mapx": item.mapx,
        "mapy": item.mapy,
        "lat": coords[0] if coords is not None else None,
        "lng": coords[1] if coords is not None else None,
        "distanceKm": distance_km,
    }


def _is_allowed_category(category: str) -> bool:
    value = (category or "").strip()
    return value in _ALLOWED_CATEGORIES or "카페" in value


def _infer_brand_hint(name: str) -> tuple[str, str]:
    normalized = _normalize_match_text(name)
    for brand_id, brand_name, tokens in _BRAND_HINTS:
        if any(_normalize_match_text(token) in normalized for token in tokens):
            return brand_id, brand_name
    return "", ""


def _normalize_match_text(value: str) -> str:
    return re.sub(r"[^0-9a-z가-힣]", "", value.strip().lower())


def _coords_from_place(
    item: place_search_repository.PlaceSearchItem,
) -> tuple[float, float] | None:
    if item.lat is not None and item.lng is not None:
        if abs(item.lat) <= 90 and abs(item.lng) <= 180:
            return item.lat, item.lng
    if item.mapx == 0 or item.mapy == 0:
        return None
    lat = item.mapy / 10000000.0
    lng = item.mapx / 10000000.0
    if abs(lat) > 90 or abs(lng) > 180:
        return None
    return lat, lng


def _distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius_km = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    haversine = (
        math.sin(d_lat / 2) ** 2
        + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(d_lng / 2) ** 2
    )
    arc = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine))
    return radius_km * arc


def _has_bounds(
    south_lat: float | None,
    west_lng: float | None,
    north_lat: float | None,
    east_lng: float | None,
) -> bool:
    return all(value is not None for value in (south_lat, west_lng, north_lat, east_lng))


def _is_in_bounds(
    lat: float,
    lng: float,
    *,
    south_lat: float | None,
    west_lng: float | None,
    north_lat: float | None,
    east_lng: float | None,
) -> bool:
    if not _has_bounds(south_lat, west_lng, north_lat, east_lng):
        return True
    return south_lat <= lat <= north_lat and west_lng <= lng <= east_lng


def _is_cafe_query(query: str) -> bool:
    normalized = _normalize_match_text(query)
    return normalized in {"", "카페", "cafe", "coffee"}


def _rect_string(
    *,
    south_lat: float | None,
    west_lng: float | None,
    north_lat: float | None,
    east_lng: float | None,
) -> str | None:
    if not _has_bounds(south_lat, west_lng, north_lat, east_lng):
        return None
    return f"{west_lng},{south_lat},{east_lng},{north_lat}"
