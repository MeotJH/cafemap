import hashlib
import html
import re

from cafemap.repositories import place_search_repository


_TAG_RE = re.compile(r"<[^>]+>")
_ALLOWED_CATEGORIES = {
    "카페,디저트",
    "카페",
    "음식점>카페,디저트",
    "음식점>카페",
}


def _clean_title(raw: str) -> str:
    return html.unescape(_TAG_RE.sub("", raw)).strip()


def _is_allowed_category(category: str) -> bool:
    value = (category or "").strip()
    return value in _ALLOWED_CATEGORIES or "카페" in value


def search_places(query: str, display: int = 5) -> list[dict]:
    payload = place_search_repository.search_places(query=query, display=display)
    items = payload.get("items", [])

    results = []
    for item in items:
        name = _clean_title(item.get("title", ""))
        category = item.get("category", "")
        if not _is_allowed_category(category):
            continue

        results.append(
            {
                "name": name,
                "address": item.get("address", ""),
                "roadAddress": item.get("roadAddress", ""),
                "category": category,
                "phone": item.get("telephone", ""),
                "link": item.get("link", ""),
                "placeId": _place_id_for_item(name=name, item=item),
                "mapx": int(item.get("mapx", 0) or 0),
                "mapy": int(item.get("mapy", 0) or 0),
            }
        )
    return results


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
