# US-09: 커피맛 목적 점수 계산

## 사용자 스토리

방문자로서 커피맛이 좋은 카페를 보고 싶다. 그래야 분위기보다 맛 평가를 우선해서 카페를 고를 수 있다.

## 목적 점수 초안

`coffeeScore = taste_satisfaction + aroma + clean_finish`

## 사용할 수 있는 현재 데이터

- `taste_satisfaction`
- `coffee_quality`
- `coffee_presence`
- `aroma`
- `clean_finish`
- `aftertaste`

## fallback

- v2는 `taste_satisfaction`을 우선 사용한다.
- 라떼 카테고리는 `coffee_presence`를 보조로 사용한다.

## 백엔드 영향

- 목적 점수 계산 함수에 `coffee` 분기 추가
- 카테고리별 key 차이를 흡수해야 한다.

## 역할별 할 일

### Frontend

- `커피맛` 목적이 감성 추천이 아니라 맛 중심 추천으로 읽히게 문구를 유지한다.

### Backend

- `coffee` 목적 점수를 계산한다.
- 맛 만족도, 향, 깔끔함, 여운 계열 점수를 정렬에 반영한다.

### Designer

- `커피맛` 목적의 라벨과 설명이 너무 기술적으로 보이지 않게 정리한다.

## 수용 기준

- 커피 맛 계열 점수가 높은 매장이 상단에 온다.
- 분위기 점수가 높아도 커피 점수가 낮으면 상단에 오르기 어렵다.
- `v2` 리뷰 데이터만으로 계산된다.

## 검증 메모

- 맛 점수는 높고 분위기 점수는 낮은 매장이 커피 목적에서 상단에 오는지 확인한다.
