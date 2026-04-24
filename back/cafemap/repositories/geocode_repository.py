import os

import requests


GEOCODE_ENDPOINT = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"


def geocode_address(address: str):
    # NCP geocode API로 주소를 좌표 후보 목록으로 조회한다.
    key_id = os.getenv("NCP_GEOCODE_API_KEY_ID")
    key = os.getenv("NCP_GEOCODE_API_KEY")

    if not key_id or not key:
        # 키가 없으면 호출 대신 빈 결과를 돌려 fallback 흐름을 유지한다.
        return {"addresses": []}

    response = requests.get(
        GEOCODE_ENDPOINT,
        headers={
            "x-ncp-apigw-api-key-id": key_id,
            "x-ncp-apigw-api-key": key,
            "Accept": "application/json",
        },
        params={"query": address},
        timeout=5,
    )
    response.raise_for_status()
    return response.json()

