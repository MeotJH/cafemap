import json

LEGACY_RATING_SCHEMA_VERSION = 1
CURRENT_RATING_SCHEMA_VERSION = 2

V1_CATEGORY_RATING_DIMENSIONS = {
    "coffee": [
        "coffee_quality",
        "acidity_balance",
        "body",
        "aftertaste",
        "temperature",
        "value",
    ],
    "latte": [
        "coffee_quality",
        "milk_balance",
        "texture",
        "sweetness",
        "temperature",
        "value",
    ],
    "cold_brew": [
        "coffee_quality",
        "clean_finish",
        "body",
        "refreshing",
        "ice_balance",
        "value",
    ],
    "hand_drip": [
        "coffee_quality",
        "aroma",
        "acidity_balance",
        "clarity",
        "aftertaste",
        "value",
    ],
    "tea": [
        "flavor_balance",
        "sweetness",
        "texture",
        "visuals",
        "portion",
        "value",
    ],
    "dessert": [
        "flavor_balance",
        "sweetness",
        "texture",
        "visuals",
        "portion",
        "value",
    ],
}

V2_COFFEE_DIMENSIONS = [
    "taste_satisfaction",
    "aroma",
    "body",
    "clean_finish",
    "aftertaste",
    "value",
]

V2_LATTE_DIMENSIONS = [
    "taste_satisfaction",
    "coffee_presence",
    "milk_balance",
    "texture",
    "aftertaste",
    "value",
]

V2_CATEGORY_RATING_DIMENSIONS = {
    "coffee": V2_COFFEE_DIMENSIONS,
    "latte": V2_LATTE_DIMENSIONS,
    "cold_brew": V2_COFFEE_DIMENSIONS,
    "hand_drip": [
        "taste_satisfaction",
        "aroma",
        "clean_finish",
        "aftertaste",
        "body",
        "value",
    ],
    "tea": [
        "taste_satisfaction",
        "aroma",
        "clean_finish",
        "aftertaste",
        "portion",
        "value",
    ],
    "dessert": [
        "taste_satisfaction",
        "texture",
        "visuals",
        "portion",
        "value",
    ],
}

# Backward-compatible aliases used by legacy call sites.
CATEGORY_RATING_DIMENSIONS = V1_CATEGORY_RATING_DIMENSIONS

CATEGORY_ALIASES = {
    "coffee": "coffee",
    "커피": "coffee",
    "latte": "latte",
    "라떼": "latte",
    "cold_brew": "cold_brew",
    "coldbrew": "cold_brew",
    "콜드브루": "cold_brew",
    "hand_drip": "hand_drip",
    "handdrip": "hand_drip",
    "핸드드립": "hand_drip",
    "tea": "tea",
    "차": "tea",
    "signature": "coffee",
    "시그니처": "coffee",
    "dessert": "dessert",
    "디저트": "dessert",
    "디저트음료": "dessert",
}

LEGACY_HIGHLIGHT_DIMENSIONS = {"signature_balance"}

FALLBACK_CATEGORY = "coffee"

V1_STORE_EXPERIENCE_DIMENSIONS = [
    "atmosphere",
    "work_friendly",
    "quietness",
    "seat_comfort",
    "outlet_access",
    "wifi_quality",
    "service",
    "revisit_intent",
]

V2_STORE_EXPERIENCE_DIMENSIONS = [
    "atmosphere",
    "quietness",
    "seat_comfort",
    "restroom_cleanliness",
    "service",
    "revisit_intent",
]

# Backward-compatible alias used by legacy call sites.
STORE_EXPERIENCE_DIMENSIONS = V1_STORE_EXPERIENCE_DIMENSIONS

V1_RATING_DIMENSION_LABELS = {
    "coffee_quality": "원두 품질",
    "acidity_balance": "산미 밸런스",
    "body": "바디감",
    "aftertaste": "여운",
    "temperature": "온도 만족도",
    "value": "가성비",
    "milk_balance": "우유 밸런스",
    "texture": "질감",
    "sweetness": "단맛 밸런스",
    "clean_finish": "깔끔함",
    "refreshing": "청량감",
    "ice_balance": "얼음 비율",
    "aroma": "향",
    "clarity": "클린컵",
    "signature_balance": "시그니처 완성도",
    "visuals": "비주얼",
    "flavor_balance": "맛 조화",
    "portion": "양",
    "atmosphere": "분위기",
    "work_friendly": "작업하기 좋음",
    "quietness": "조용함",
    "seat_comfort": "좌석 편안함",
    "outlet_access": "콘센트 접근성",
    "wifi_quality": "와이파이",
    "service": "응대",
    "revisit_intent": "재방문 의사",
}

V2_RATING_DIMENSION_LABELS = {
    **V1_RATING_DIMENSION_LABELS,
    "taste_satisfaction": "맛 만족도",
    "value": "가격 만족도",
    "coffee_presence": "커피 맛",
    "clean_finish": "깔끔함",
    "restroom_cleanliness": "화장실 청결",
}

# Backward-compatible alias used by legacy call sites.
RATING_DIMENSION_LABELS = V1_RATING_DIMENSION_LABELS

V2_MENU_ATTRIBUTE_KEYS = {
    "coffee": ["flavor_profile", "roast_level", "temperature_option"],
    "latte": ["temperature_option", "sweetness_level"],
    "cold_brew": ["flavor_profile", "roast_level", "temperature_option"],
    "hand_drip": ["flavor_profile", "roast_level", "temperature_option"],
    "tea": ["temperature_option", "sweetness_level"],
    "dessert": ["sweetness_level"],
}

V2_STORE_ATTRIBUTE_KEYS = ["outlet_available", "wifi_usable"]

RATING_ATTRIBUTE_LABELS = {
    "flavor_profile": "맛 성향",
    "roast_level": "로스팅",
    "sweetness_level": "단맛 정도",
    "temperature_option": "온도",
    "outlet_available": "콘센트",
    "wifi_usable": "와이파이",
}

RATING_ATTRIBUTE_VALUE_LABELS = {
    "flavor_profile": {
        "acidic": "산미",
        "balanced": "균형",
        "nutty": "고소",
        "unknown": "잘 모르겠음",
    },
    "roast_level": {
        "light": "라이트",
        "medium": "미디엄",
        "dark": "다크",
        "unknown": "잘 모르겠음",
    },
    "sweetness_level": {
        "low": "덜 달게",
        "medium": "적당히 달게",
        "high": "달게",
        "unknown": "잘 모르겠음",
    },
    "temperature_option": {
        "hot": "HOT",
        "ice": "ICE",
        "unspecified": "미선택",
    },
    "outlet_available": {
        "yes": "콘센트 있음",
        "no": "콘센트 없음",
        "unknown": "잘 모르겠음",
    },
    "wifi_usable": {
        "good": "와이파이 좋음",
        "bad": "와이파이 아쉬움",
        "not_used": "안 써봄",
        "unknown": "잘 모르겠음",
    },
}


def normalize_rating_schema_version(value) -> int:
    try:
        parsed = int(value or LEGACY_RATING_SCHEMA_VERSION)
    except (TypeError, ValueError):
        return LEGACY_RATING_SCHEMA_VERSION
    if parsed >= CURRENT_RATING_SCHEMA_VERSION:
        return CURRENT_RATING_SCHEMA_VERSION
    return LEGACY_RATING_SCHEMA_VERSION


def normalize_category(category: str | None) -> str:
    value = (category or "").strip()
    if value in V1_CATEGORY_RATING_DIMENSIONS:
        return value
    alias = CATEGORY_ALIASES.get(value)
    if alias in V1_CATEGORY_RATING_DIMENSIONS:
        return alias
    return FALLBACK_CATEGORY


def category_dimensions_for_schema(
    category: str | None,
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
) -> list[str]:
    version = normalize_rating_schema_version(schema_version)
    normalized_category = normalize_category(category)
    source = (
        V2_CATEGORY_RATING_DIMENSIONS
        if version == CURRENT_RATING_SCHEMA_VERSION
        else V1_CATEGORY_RATING_DIMENSIONS
    )
    return list(source[normalized_category])


def store_dimensions_for_schema(
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
    *,
    include_optional: bool = False,
) -> list[str]:
    _ = include_optional
    version = normalize_rating_schema_version(schema_version)
    if version == CURRENT_RATING_SCHEMA_VERSION:
        return list(V2_STORE_EXPERIENCE_DIMENSIONS)
    return list(V1_STORE_EXPERIENCE_DIMENSIONS)


def rating_label(
    key: str,
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
) -> str:
    version = normalize_rating_schema_version(schema_version)
    labels = (
        V2_RATING_DIMENSION_LABELS
        if version == CURRENT_RATING_SCHEMA_VERSION
        else V1_RATING_DIMENSION_LABELS
    )
    return labels.get(key, key)


def normalize_scores(
    category: str | None,
    scores: dict[str, float],
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
) -> dict[str, float]:
    allowed = category_dimensions_for_schema(category, schema_version)
    normalized: dict[str, float] = {}
    for key in allowed:
        raw = scores.get(key, 3.0)
        value = float(raw)
        normalized[key] = max(0.0, min(5.0, value))
    return normalized


def visible_scores_for_category(
    category: str | None,
    scores: dict[str, float] | None,
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
) -> dict[str, float]:
    source = scores or {}
    allowed = category_dimensions_for_schema(category, schema_version)
    filtered = {key: float(source[key]) for key in allowed if key in source}
    if filtered:
        return filtered
    without_legacy = {
        key: float(value)
        for key, value in source.items()
        if key not in LEGACY_HIGHLIGHT_DIMENSIONS
    }
    if without_legacy:
        return without_legacy
    return {key: float(value) for key, value in source.items()}


def normalize_store_scores(
    scores: dict[str, float] | None,
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
) -> dict[str, float]:
    source = scores or {}
    normalized: dict[str, float] = {}
    for key in store_dimensions_for_schema(schema_version, include_optional=True):
        if key not in source:
            continue
        value = float(source[key])
        normalized[key] = max(0.0, min(5.0, value))
    return normalized


def normalize_attributes(
    category: str | None,
    attributes: dict[str, str] | None,
    *,
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
    temperature_option: str | None = None,
) -> dict[str, str]:
    if normalize_rating_schema_version(schema_version) != CURRENT_RATING_SCHEMA_VERSION:
        return {}

    normalized_category = normalize_category(category)
    allowed_keys = set(V2_MENU_ATTRIBUTE_KEYS[normalized_category])
    allowed_keys.update(V2_STORE_ATTRIBUTE_KEYS)
    source = attributes or {}
    result: dict[str, str] = {}

    for key in allowed_keys:
        raw = source.get(key)
        if key == "temperature_option" and not raw:
            raw = temperature_option
        values = RATING_ATTRIBUTE_VALUE_LABELS.get(key, {})
        fallback = "not_used" if key == "wifi_usable" else "unknown"
        if key == "temperature_option":
            fallback = "unspecified"
        parsed = str(raw or fallback).strip().lower()
        if parsed not in values:
            parsed = fallback
        result[key] = parsed

    return result


def compute_overall(scores: dict[str, float], fallback: float = 0.0) -> float:
    if not scores:
        return fallback
    return sum(scores.values()) / len(scores)


def top_highlights(
    scores: dict[str, float],
    schema_version: int | None = LEGACY_RATING_SCHEMA_VERSION,
) -> list[tuple[str, float]]:
    if not scores:
        return [("평가 없음", 0.0), ("평가 없음", 0.0)]
    visible_scores = [
        item for item in scores.items() if item[0] not in LEGACY_HIGHLIGHT_DIMENSIONS
    ]
    source = visible_scores or list(scores.items())
    ordered = sorted(source, key=lambda item: item[1], reverse=True)
    padded = (ordered + [("평가 없음", 0.0), ("평가 없음", 0.0)])[:2]
    return [(rating_label(key, schema_version), value) for key, value in padded]


def scores_json_dumps(scores: dict) -> str:
    return json.dumps(scores, ensure_ascii=False)


def scores_json_loads(raw: str | None) -> dict[str, float]:
    if not raw:
        return {}
    try:
        data = json.loads(raw)
    except (TypeError, ValueError):
        return {}
    if not isinstance(data, dict):
        return {}
    normalized: dict[str, float] = {}
    for key, value in data.items():
        try:
            normalized[str(key)] = float(value)
        except (TypeError, ValueError):
            continue
    return normalized


def attributes_json_dumps(attributes: dict) -> str:
    return json.dumps(attributes, ensure_ascii=False)


def attributes_json_loads(raw: str | None) -> dict[str, str]:
    if not raw:
        return {}
    try:
        data = json.loads(raw)
    except (TypeError, ValueError):
        return {}
    if not isinstance(data, dict):
        return {}
    return {
        str(key): str(value)
        for key, value in data.items()
        if isinstance(key, str) and value is not None
    }
