import os
from typing import Any

import requests


NAVER_LOCAL_ENDPOINT = "https://openapi.naver.com/v1/search/local.json"


def search_places(query: str, display: int = 5, start: int = 1) -> dict[str, Any]:
    client_id = os.getenv("NAVER_LOCAL_CLIENT_ID")
    client_secret = os.getenv("NAVER_LOCAL_CLIENT_SECRET")
    if not client_id or not client_secret:
        raise RuntimeError("NAVER_LOCAL_CLIENT_ID or NAVER_LOCAL_CLIENT_SECRET is missing")

    response = requests.get(
        NAVER_LOCAL_ENDPOINT,
        headers={
            "X-Naver-Client-Id": client_id,
            "X-Naver-Client-Secret": client_secret,
        },
        params={
            "query": query,
            "display": max(1, min(display, 5)),
            "start": max(1, min(start, 1000)),
        },
        timeout=5,
    )
    response.raise_for_status()
    return response.json()
