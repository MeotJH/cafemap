# US-06: 데이트 목적 점수 계산

## 사용자 스토리

방문자로서 데이트에 어울리는 카페를 보고 싶다. 그래야 분위기와 맛이 모두 괜찮은 카페를 빠르게 고를 수 있다.

## 목적 점수 초안

`dateScore = atmosphere + taste + revisit_intent`

## 사용할 수 있는 현재 데이터

- `atmosphere`
- `taste_satisfaction`
- `coffee_quality`
- `coffee_presence`
- `revisit_intent`

## fallback

- `taste_satisfaction`이 없으면 `coffee_quality`를 사용한다.
- 둘 다 없고 라떼 계열이면 `coffee_presence`를 사용한다.
- 목적 점수 구성 값이 하나도 없으면 해당 매장은 목적 랭킹에서 제외하거나 점수 0으로 처리한다.

## 백엔드 영향

- 목적 점수 계산 함수에 `date` 분기 추가
- `v2` review score만 읽도록 한다.

## 역할별 할 일

### Frontend

- 목적 설명 문구가 실제 계산 기준과 크게 어긋나지 않도록 유지한다.

### Backend

- `date` 목적 점수를 계산한다.
- 분위기, 맛 만족도, 재방문 의사 조합이 상단 정렬에 반영되도록 한다.

### Designer

- `데이트` 라벨이 기대하는 추천 감성과 실제 계산 신호가 맞는지 검토한다.

## 수용 기준

- 분위기와 맛 점수가 높은 매장이 데이트 랭킹 상단에 온다.
- 목적 점수 산출에 사용된 값이 없어도 API가 실패하지 않는다.
- 기존 부부픽 랭킹과 다른 정렬 결과가 나올 수 있다.

## 검증 메모

- 목적 정렬 테스트로 높은 데이트 점수 매장이 위에 오는지 확인한다.
