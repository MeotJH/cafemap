import hashlib
import os
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any

import requests


NAVER_LOCAL_ENDPOINT = "https://openapi.naver.com/v1/search/local.json"
KAKAO_LOCAL_KEYWORD_ENDPOINT = "https://dapi.kakao.com/v2/local/search/keyword.json"
KAKAO_LOCAL_CATEGORY_ENDPOINT = "https://dapi.kakao.com/v2/local/search/category.json"


@dataclass(frozen=True)
class PlaceSearchQuery:
    query: str
    display: int = 5
    start: int = 1
    lat: float | None = None
    lng: float | None = None
    radius_m: int | None = None
    rect: str | None = None
    sort: str | None = None
    category_group_code: str | None = None


@dataclass(frozen=True)
class PlaceSearchItem:
    provider: str
    provider_id: str
    name: str
    address: str
    road_address: str
    category: str
    phone: str
    link: str
    mapx: int
    mapy: int
    lat: float | None = None
    lng: float | None = None

    @property
    def place_id(self) -> str:
        raw = "|".join(
            [
                self.provider,
                self.provider_id,
                self.name,
                self.road_address or self.address,
                str(self.mapx),
                str(self.mapy),
            ]
        )
        return f"{self.provider}-" + hashlib.sha1(raw.encode("utf-8")).hexdigest()[:24]


class PlaceSearchProvider(ABC):
    provider_name: str

    @abstractmethod
    def search_places(self, query: PlaceSearchQuery) -> list[PlaceSearchItem]:
        raise NotImplementedError


class NaverPlaceSearchProvider(PlaceSearchProvider):
    provider_name = "naver"

    def __init__(self, *, client_id: str, client_secret: str) -> None:
        self._client_id = client_id
        self._client_secret = client_secret

    def search_places(self, query: PlaceSearchQuery) -> list[PlaceSearchItem]:
        response = requests.get(
            NAVER_LOCAL_ENDPOINT,
            headers={
                "X-Naver-Client-Id": self._client_id,
                "X-Naver-Client-Secret": self._client_secret,
            },
            params={
                "query": query.query,
                "display": max(1, min(query.display, 5)),
                "start": max(1, min(query.start, 1000)),
            },
            timeout=5,
        )
        response.raise_for_status()
        payload = response.json()
        return [
            PlaceSearchItem(
                provider=self.provider_name,
                provider_id=str(item.get("link", "") or item.get("title", "")),
                name=_clean_naver_title(item.get("title", "")),
                address=item.get("address", "") or "",
                road_address=item.get("roadAddress", "") or "",
                category=item.get("category", "") or "",
                phone=item.get("telephone", "") or "",
                link=item.get("link", "") or "",
                mapx=int(item.get("mapx", 0) or 0),
                mapy=int(item.get("mapy", 0) or 0),
                lat=_to_wgs84_lat(item.get("mapy")),
                lng=_to_wgs84_lng(item.get("mapx")),
            )
            for item in payload.get("items", [])
        ]


class KakaoPlaceSearchProvider(PlaceSearchProvider):
    provider_name = "kakao"

    def __init__(self, *, rest_api_key: str) -> None:
        self._rest_api_key = rest_api_key

    def search_places(self, query: PlaceSearchQuery) -> list[PlaceSearchItem]:
        use_category_search = _should_use_kakao_category_search(query)
        params: dict[str, Any] = {
            "page": _page_from_start(query.start, query.display),
            "size": max(1, min(query.display, 15)),
        }
        if use_category_search:
            params["category_group_code"] = query.category_group_code
        else:
            params["query"] = query.query
        if query.category_group_code:
            params["category_group_code"] = query.category_group_code
        if query.rect:
            params["rect"] = query.rect
        else:
            if query.lng is not None:
                params["x"] = str(query.lng)
            if query.lat is not None:
                params["y"] = str(query.lat)
            if query.radius_m is not None:
                params["radius"] = max(0, min(query.radius_m, 20000))
        if query.sort:
            params["sort"] = query.sort

        response = requests.get(
            KAKAO_LOCAL_CATEGORY_ENDPOINT if use_category_search else KAKAO_LOCAL_KEYWORD_ENDPOINT,
            headers={"Authorization": f"KakaoAK {self._rest_api_key}"},
            params=params,
            timeout=5,
        )
        response.raise_for_status()
        payload = response.json()
        return [
            PlaceSearchItem(
                provider=self.provider_name,
                provider_id=str(item.get("id", "")),
                name=item.get("place_name", "") or "",
                address=item.get("address_name", "") or "",
                road_address=item.get("road_address_name", "") or "",
                category=item.get("category_name", "") or "",
                phone=item.get("phone", "") or "",
                link=item.get("place_url", "") or "",
                mapx=_to_scaled_coord(item.get("x")),
                mapy=_to_scaled_coord(item.get("y")),
                lat=_to_float(item.get("y")),
                lng=_to_float(item.get("x")),
            )
            for item in payload.get("documents", [])
        ]


def get_place_search_provider() -> PlaceSearchProvider:
    provider_name = (os.getenv("PLACE_SEARCH_PROVIDER") or "").strip().lower()
    kakao_key = os.getenv("KAKAO_REST_API_KEY")
    naver_id = os.getenv("NAVER_LOCAL_CLIENT_ID")
    naver_secret = os.getenv("NAVER_LOCAL_CLIENT_SECRET")

    if provider_name in {"", "kakao"} and kakao_key:
        return KakaoPlaceSearchProvider(rest_api_key=kakao_key)
    if provider_name == "naver":
        if not naver_id or not naver_secret:
            raise RuntimeError("NAVER_LOCAL_CLIENT_ID or NAVER_LOCAL_CLIENT_SECRET is missing")
        return NaverPlaceSearchProvider(client_id=naver_id, client_secret=naver_secret)
    if kakao_key:
        return KakaoPlaceSearchProvider(rest_api_key=kakao_key)
    if naver_id and naver_secret:
        return NaverPlaceSearchProvider(client_id=naver_id, client_secret=naver_secret)
    raise RuntimeError("No place search provider credentials are configured")


def _clean_naver_title(raw: str) -> str:
    import html
    import re

    tag_re = re.compile(r"<[^>]+>")
    return html.unescape(tag_re.sub("", raw)).strip()


def _to_float(value: Any) -> float | None:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _to_scaled_coord(value: Any) -> int:
    number = _to_float(value)
    if number is None:
        return 0
    return int(round(number * 10000000))


def _to_wgs84_lat(value: Any) -> float | None:
    number = _to_float(value)
    if number is None:
        return None
    lat = number / 10000000.0
    return lat if abs(lat) <= 90 else None


def _to_wgs84_lng(value: Any) -> float | None:
    number = _to_float(value)
    if number is None:
        return None
    lng = number / 10000000.0
    return lng if abs(lng) <= 180 else None


def _page_from_start(start: int, size: int) -> int:
    safe_size = max(1, min(size, 15))
    safe_start = max(1, start)
    return max(1, ((safe_start - 1) // safe_size) + 1)


def _should_use_kakao_category_search(query: PlaceSearchQuery) -> bool:
    if query.category_group_code != "CE7":
        return False
    normalized = "".join(query.query.strip().lower().split())
    return normalized in {"", "\uCE74\uD398", "cafe", "coffee"}
