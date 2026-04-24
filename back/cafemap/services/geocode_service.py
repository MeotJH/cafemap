from cafemap.repositories import geocode_repository


def geocode(address: str):
    # 첫 번째 geocode 결과를 `(lat, lng)` 튜플로 정규화한다.
    payload = geocode_repository.geocode_address(address)
    addresses = payload.get("addresses", [])
    if not addresses:
        return None
    first = addresses[0]
    try:
        lat = float(first.get("y", 0.0))
        lng = float(first.get("x", 0.0))
    except (TypeError, ValueError):
        return None
    return lat, lng
