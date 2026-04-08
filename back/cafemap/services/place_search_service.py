import hashlib
import html
import math
import re

import requests

from cafemap.repositories import place_search_repository


_TAG_RE = re.compile(r"<[^>]+>")
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


def _clean_title(raw: str) -> str:
    return html.unescape(_TAG_RE.sub("", raw)).strip()


def _is_allowed_category(category: str) -> bool:
    value = (category or "").strip()
    return value in _ALLOWED_CATEGORIES or "카페" in value


def search_places(
    query: str,
    display: int = 5,
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float | None = None,
    pages: int | None = None,
) -> list[dict]:
    requested_display = max(1, min(display, 25))
    page_count = max(1, min(pages or math.ceil(requested_display / 5), 5))
    per_page = 5
    queries = _search_queries(query, lat=lat, lng=lng)
    query_page_count = 1 if len(queries) > 1 else page_count

    results: list[dict] = []
    seen_place_ids: set[str] = set()

    for search_query in queries:
        for page_index in range(query_page_count):
            start = page_index * per_page + 1
            try:
                payload = place_search_repository.search_places(
                    query=search_query,
                    display=per_page,
                    start=start,
                )
            except requests.RequestException:
                break
            items = payload.get("items", [])
            if not items:
                break

            for item in items:
                parsed = _result_from_item(item, lat=lat, lng=lng)
                if parsed is None:
                    continue
                place_id = parsed["placeId"]
                if place_id in seen_place_ids:
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

    if lat is not None and lng is not None:
        results.sort(key=lambda item: item["distanceKm"] or float("inf"))

    return results[:requested_display]


def _search_queries(query: str, *, lat: float | None, lng: float | None) -> list[str]:
    base = query.strip()
    if not base:
        return ["카페"]
    normalized = _normalize_match_text(base)
    if lat is None or lng is None:
        return [base]
    if normalized not in {"카페", "cafe", "coffee"}:
        return [base]
    return [base, "커피", "디저트 카페", "베이커리 카페"]


def _result_from_item(
    item: dict,
    *,
    lat: float | None,
    lng: float | None,
) -> dict | None:
    name = _clean_title(item.get("title", ""))
    category = item.get("category", "")
    if not _is_allowed_category(category):
        return None
    brand_id, brand_name = _infer_brand_hint(name)
    mapx = int(item.get("mapx", 0) or 0)
    mapy = int(item.get("mapy", 0) or 0)
    coords = _coords_from_map(mapx=mapx, mapy=mapy)
    distance_km = None
    if coords is not None and lat is not None and lng is not None:
        distance_km = _distance_km(lat, lng, coords[0], coords[1])

    return {
        "name": name,
        "address": item.get("address", ""),
        "roadAddress": item.get("roadAddress", ""),
        "category": category,
        "phone": item.get("telephone", ""),
        "link": item.get("link", ""),
        "placeId": _place_id_for_item(name=name, item=item),
        "brandId": brand_id,
        "brandName": brand_name,
        "mapx": mapx,
        "mapy": mapy,
        "lat": coords[0] if coords is not None else None,
        "lng": coords[1] if coords is not None else None,
        "distanceKm": distance_km,
    }


def _infer_brand_hint(name: str) -> tuple[str, str]:
    normalized = _normalize_match_text(name)
    for brand_id, brand_name, tokens in _BRAND_HINTS:
        if any(_normalize_match_text(token) in normalized for token in tokens):
            return brand_id, brand_name
    return "", ""


def _normalize_match_text(value: str) -> str:
    return re.sub(r"[^0-9a-z가-힣]", "", value.strip().lower())


def _coords_from_map(mapx: int, mapy: int) -> tuple[float, float] | None:
    if mapx == 0 or mapy == 0:
        return None
    lat = mapy / 10000000.0
    lng = mapx / 10000000.0
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


def _place_id_for_item(name: str, item: dict) -> str:
    raw = "|".join(
        [
            item.get("link", ""),
            name,
            item.get("roadAddress", "") or item.get("address", ""),
            str(item.get("mapx", "")),
            str(item.get("mapy", "")),
        ]
    )
    return "naver-" + hashlib.sha1(raw.encode("utf-8")).hexdigest()[:24]
