from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PreferenceSpec:
    id: str
    label: str
    label_short: str
    score_keys: list[str]
    reason_labels: list[str]
    match_mode: str = "average"


_PREFERENCE_SPECS: dict[str, PreferenceSpec] = {
    "quiet_place": PreferenceSpec(
        id="quiet_place",
        label="조용한 곳",
        label_short="조용함",
        score_keys=["quietness"],
        reason_labels=["조용함"],
    ),
    "work_friendly": PreferenceSpec(
        id="work_friendly",
        label="작업하기 좋은 곳",
        label_short="작업",
        score_keys=["work_friendly"],
        reason_labels=["작업 적합성"],
    ),
    "good_atmosphere": PreferenceSpec(
        id="good_atmosphere",
        label="분위기가 좋은 곳",
        label_short="분위기",
        score_keys=["atmosphere"],
        reason_labels=["분위기"],
    ),
    "good_coffee": PreferenceSpec(
        id="good_coffee",
        label="커피 맛이 좋은 곳",
        label_short="커피 맛",
        score_keys=["coffee_quality"],
        reason_labels=["커피 맛"],
    ),
    "good_value": PreferenceSpec(
        id="good_value",
        label="가성비가 좋은 곳",
        label_short="가성비",
        score_keys=["value"],
        reason_labels=["가성비"],
    ),
    "kind_service": PreferenceSpec(
        id="kind_service",
        label="응대가 친절한 곳",
        label_short="친절함",
        score_keys=["service"],
        reason_labels=["응대"],
    ),
    "seat_comfortable": PreferenceSpec(
        id="seat_comfortable",
        label="좌석이 편안한 곳",
        label_short="편안함",
        score_keys=["seat_comfort"],
        reason_labels=["좌석 편안함"],
    ),
}


def get_preference_specs() -> dict[str, PreferenceSpec]:
    return _PREFERENCE_SPECS


def parse_preference_ids(raw: str | None) -> list[str]:
    if not raw:
        return []

    seen: set[str] = set()
    parsed: list[str] = []
    for part in raw.split(","):
        value = part.strip()
        if not value or value in seen or value not in _PREFERENCE_SPECS:
            continue
        seen.add(value)
        parsed.append(value)
        if len(parsed) >= 3:
            break
    return parsed


def compute_personalized_score(
    scores: dict[str, float],
    preference_ids: list[str],
    *,
    fallback_score: float,
) -> float:
    if not preference_ids:
        return fallback_score

    values: list[float] = []
    for preference_id in preference_ids:
        spec = _PREFERENCE_SPECS.get(preference_id)
        if spec is None:
            continue
        for score_key in spec.score_keys:
            if score_key not in scores:
                continue
            values.append(float(scores[score_key]))
    if not values:
        return fallback_score
    return sum(values) / len(values)


def build_personalized_reasons(
    scores: dict[str, float],
    preference_ids: list[str],
) -> list[str]:
    if not preference_ids:
        return []

    reasons: list[str] = []
    for preference_id in preference_ids:
        spec = _PREFERENCE_SPECS.get(preference_id)
        if spec is None:
            continue
        for score_key, reason_label in zip(spec.score_keys, spec.reason_labels):
            if score_key not in scores:
                continue
            score = float(scores[score_key])
            if score <= 0:
                continue
            reasons.append(f"{reason_label} {score:.1f}")
            if len(reasons) >= 2:
                return reasons
    return reasons


def is_personalized_match(score: float) -> bool:
    return score >= 4.0
