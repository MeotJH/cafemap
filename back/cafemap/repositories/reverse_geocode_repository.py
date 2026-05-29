import os

import requests

REVERSE_GEOCODE_ENDPOINT = "https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc"


def reverse_geocode(*, lat: float, lng: float) -> dict:
    key_id = os.getenv("NCP_GEOCODE_API_KEY_ID")
    key = os.getenv("NCP_GEOCODE_API_KEY")
    if not key_id or not key:
        return {"results": []}

    response = requests.get(
        REVERSE_GEOCODE_ENDPOINT,
        headers={
            "x-ncp-apigw-api-key-id": key_id,
            "x-ncp-apigw-api-key": key,
            "Accept": "application/json",
        },
        params={
            "coords": f"{lng},{lat}",
            "orders": "admcode",
            "output": "json",
        },
        timeout=5,
    )
    response.raise_for_status()
    return response.json()
