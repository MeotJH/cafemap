import json


CATEGORY_RATING_DIMENSIONS = {
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

STORE_EXPERIENCE_DIMENSIONS = [
    "atmosphere",
    "work_friendly",
    "quietness",
    "seat_comfort",
    "outlet_access",
    "wifi_quality",
    "service",
    "revisit_intent",
]

RATING_DIMENSION_LABELS = {
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


def normalize_category(category: str | None) -> str:
    value = (category or "").strip()
    if value in CATEGORY_RATING_DIMENSIONS:
        return value
    alias = CATEGORY_ALIASES.get(value)
    if alias in CATEGORY_RATING_DIMENSIONS:
        return alias
    return FALLBACK_CATEGORY


def normalize_scores(category: str | None, scores: dict[str, float]) -> dict[str, float]:
    allowed = CATEGORY_RATING_DIMENSIONS[normalize_category(category)]
    normalized: dict[str, float] = {}
    for key in allowed:
        raw = scores.get(key, 3.0)
        value = float(raw)
        normalized[key] = max(0.0, min(5.0, value))
    return normalized


def visible_scores_for_category(
    category: str | None,
    scores: dict[str, float] | None,
) -> dict[str, float]:
    source = scores or {}
    allowed = CATEGORY_RATING_DIMENSIONS[normalize_category(category)]
    filtered = {
        key: float(source[key])
        for key in allowed
        if key in source
    }
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


def normalize_store_scores(scores: dict[str, float] | None) -> dict[str, float]:
    source = scores or {}
    normalized: dict[str, float] = {}
    for key in STORE_EXPERIENCE_DIMENSIONS:
        if key not in source:
            continue
        value = float(source[key])
        normalized[key] = max(0.0, min(5.0, value))
    return normalized


def compute_overall(scores: dict[str, float], fallback: float = 0.0) -> float:
    if not scores:
        return fallback
    return sum(scores.values()) / len(scores)


def top_highlights(scores: dict[str, float]) -> list[tuple[str, float]]:
    if not scores:
        return [("평가 없음", 0.0), ("평가 없음", 0.0)]
    visible_scores = [
        item
        for item in scores.items()
        if item[0] not in LEGACY_HIGHLIGHT_DIMENSIONS
    ]
    source = visible_scores or list(scores.items())
    ordered = sorted(source, key=lambda item: item[1], reverse=True)
    padded = (ordered + [("평가 없음", 0.0), ("평가 없음", 0.0)])[:2]
    return [(RATING_DIMENSION_LABELS.get(key, key), value) for key, value in padded]


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
