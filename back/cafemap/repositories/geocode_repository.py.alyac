import os
import requests


# NCP 지오코딩 API 호출을 담당하는 레포지토리다.


GEOCODE_ENDPOINT = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"


def geocode_address(address: str):
    # 주소를 좌표로 변환한다.
    key_id = os.getenv("NCP_GEOCODE_API_KEY_ID")
    key = os.getenv("NCP_GEOCODE_API_KEY")
    if not key_id or not key:
        # 키가 없으면 지오코딩을 건너뛰고 호출부에서 기본 좌표 처리한다.
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
