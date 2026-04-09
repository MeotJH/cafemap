import functools
import re

import requests

from cafemap.repositories import reverse_geocode_repository


@functools.lru_cache(maxsize=128)
def _lookup_administrative_area(lat: float, lng: float) -> tuple[str, str]:
    try:
        payload = reverse_geocode_repository.reverse_geocode(lat=lat, lng=lng)
    except requests.RequestException:
        return "", ""

    results = payload.get("results", [])
    if not results:
        return "", ""

    region = results[0].get("region", {})
    area2 = (region.get("area2") or {}).get("name", "").strip()
    area3 = (region.get("area3") or {}).get("name", "").strip()
    return area2, area3


def area_query_tokens(*, lat: float, lng: float) -> list[str]:
    area2, area3 = _lookup_administrative_area(round(lat, 5), round(lng, 5))
    tokens: list[str] = []

    if area3:
        tokens.append(area3)
        simplified = re.sub(r"(\d+)동$", "동", area3)
        if simplified != area3:
            tokens.append(simplified)
    if area2:
        tokens.append(area2)

    seen: set[str] = set()
    unique_tokens: list[str] = []
    for token in tokens:
        if not token or token in seen:
            continue
        seen.add(token)
        unique_tokens.append(token)
    return unique_tokens
