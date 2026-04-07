import os
from typing import Any

import requests


# 네이버 지역 검색 API 호출을 담당하는 레포지토리다.


NAVER_LOCAL_ENDPOINT = "https://openapi.naver.com/v1/search/local.json"


def search_places(query: str, display: int = 5) -> dict[str, Any]:
    # 네이버 지역 검색 API를 호출해 원본 응답을 반환한다.
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
            "display": display,
        },
        timeout=5,
    )
    response.raise_for_status()
    return response.json()
