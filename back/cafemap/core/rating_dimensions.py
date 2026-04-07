import json


CATEGORY_RATING_DIMENSIONS = {
    "커피": [
        "coffee_quality",
        "acidity_balance",
        "body",
        "aftertaste",
        "temperature",
        "value",
    ],
    "라떼": [
        "coffee_quality",
        "milk_balance",
        "texture",
        "sweetness",
        "temperature",
        "value",
    ],
    "콜드브루": [
        "coffee_quality",
        "clean_finish",
        "body",
        "refreshing",
        "ice_balance",
        "value",
    ],
    "핸드드립": [
        "coffee_quality",
        "aroma",
        "acidity_balance",
        "clarity",
        "aftertaste",
        "value",
    ],
    "시그니처": [
        "signature_balance",
        "coffee_quality",
        "sweetness",
        "texture",
        "visuals",
        "value",
    ],
    "디저트음료": [
        "flavor_balance",
        "sweetness",
        "texture",
        "visuals",
        "portion",
        "value",
    ],
}

FALLBACK_CATEGORY = "커피"

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
    return FALLBACK_CATEGORY


def normalize_scores(category: str | None, scores: dict[str, float]) -> dict[str, float]:
    allowed = CATEGORY_RATING_DIMENSIONS[normalize_category(category)]
    normalized: dict[str, float] = {}
    for key in allowed:
        raw = scores.get(key, 3.0)
        value = float(raw)
        normalized[key] = max(0.0, min(5.0, value))
    return normalized


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
    ordered = sorted(scores.items(), key=lambda item: item[1], reverse=True)
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
