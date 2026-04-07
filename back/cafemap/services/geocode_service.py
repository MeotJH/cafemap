from cafemap.repositories import geocode_repository


# ???? ???? ?? ????.


def geocode(address: str):
    # ??? ??? ???? `(lat, lng)`? ????.
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
