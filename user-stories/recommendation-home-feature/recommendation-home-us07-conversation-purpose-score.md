# US-07: 대화 목적 점수 계산

## 사용자 스토리

방문자로서 대화하기 좋은 카페를 보고 싶다. 그래야 조용하고 편하게 머물 수 있는 카페를 빠르게 찾을 수 있다.

## 목적 점수 초안

`conversationScore = quietness + seat_comfort + service`

## 사용할 수 있는 현재 데이터

- `quietness`
- `seat_comfort`
- `service`
- `atmosphere`

## fallback

- `seat_comfort`가 없으면 `atmosphere`를 보조 점수로 사용한다.
- 문서 원문에는 `분위기 및 친절도`가 적혀 있지만, 대화 목적에서는 `quietness`를 핵심값으로 둔다.

## 백엔드 영향

- 목적 점수 계산 함수에 `conversation` 분기 추가
- `v2` store experience score만 고려한다.

## 역할별 할 일

### Frontend

- 대화 목적 설명이 `조용함` 중심이라는 점을 화면 문구에 반영한다.

### Backend

- `conversation` 목적 점수를 계산한다.
- 조용함, 좌석 편안함, 응대를 중심으로 정렬되게 한다.

### Designer

- `대화` 목적의 기대 경험을 짧은 설명 문구로 정리한다.

## 수용 기준

- 조용함 점수가 낮은 매장은 대화 랭킹 상단에 오르기 어렵다.
- 응대 점수만 높고 조용함 데이터가 없으면 fallback 기준으로 계산된다.
- 점수 데이터가 부족한 경우에도 응답은 정상 반환된다.

## 검증 메모

- 대화 목적 랭킹에서 조용함이 낮은 카페가 상단에 오르지 않는지 샘플로 확인한다.
