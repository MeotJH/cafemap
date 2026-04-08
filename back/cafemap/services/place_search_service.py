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


def search_places(query: str, display: int = 5) -> list[dict]:
    payload = place_search_repository.search_places(query=query, display=display)
    items = payload.get("items", [])

    results = []
    for item in items:
        name = _clean_title(item.get("title", ""))
        category = item.get("category", "")
        if not _is_allowed_category(category):
            continue
        brand_id, brand_name = _infer_brand_hint(name)

        results.append(
            {
                "name": name,
                "address": item.get("address", ""),
                "roadAddress": item.get("roadAddress", ""),
                "category": category,
                "phone": item.get("telephone", ""),
                "link": item.get("link", ""),
                "placeId": _place_id_for_item(name=name, item=item),
                "brandId": brand_id,
                "brandName": brand_name,
                "mapx": int(item.get("mapx", 0) or 0),
                "mapy": int(item.get("mapy", 0) or 0),
            }
        )
    return results


def _infer_brand_hint(name: str) -> tuple[str, str]:
    normalized = _normalize_match_text(name)
    for brand_id, brand_name, tokens in _BRAND_HINTS:
        if any(_normalize_match_text(token) in normalized for token in tokens):
            return brand_id, brand_name
    return "", ""


def _normalize_match_text(value: str) -> str:
    return re.sub(r"[^0-9a-z가-힣]", "", value.strip().lower())


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
