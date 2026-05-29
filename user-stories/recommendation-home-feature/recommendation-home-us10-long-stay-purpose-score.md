# US-10: 오래 앉기 목적 점수 계산

## 사용자 스토리

방문자로서 오래 앉기 좋은 카페를 보고 싶다. 그래야 작업, 독서, 긴 대화에 맞는 카페를 빠르게 찾을 수 있다.

## 목적 점수 초안

`longStayScore = seat_comfort + outlet + wifi + service`

## 사용할 수 있는 현재 데이터

- `seat_comfort`
- `work_friendly`
- `outlet_access`
- `wifi_quality`
- `service`
- `outlet_available`
- `wifi_usable`

## 현재 데이터 제약

- v2에는 콘센트와 와이파이가 score가 아니라 attribute로 있다.
- 따라서 1차 구현은 `v2` score와 attribute를 함께 보는 방식이 필요하다.

## fallback

- v2 리뷰는 `seat_comfort`, `service`에 `outlet_available=yes`, `wifi_usable=good` 보조 가산점을 더한다.

## 백엔드 영향

- 목적 점수 계산 함수에 `long_stay` 분기 추가
- review attributes json을 읽는 계산이 필요하다.

## 역할별 할 일

### Frontend

- `오래 앉기` 목적이 작업/독서/긴 대화 용도라는 점이 드러나게 설명을 유지한다.

### Backend

- `long_stay` 목적 점수를 계산한다.
- 좌석, 콘센트, 와이파이, 응대 신호를 조합한다.

### Designer

- `오래 앉기`가 너무 길게 보이지 않도록 UI 라벨 표현을 검토한다.

## 수용 기준

- 콘센트/와이파이 정보가 있는 매장이 오래 앉기 랭킹에서 유리하다.
- `v2` 데이터가 없는 매장은 목적 랭킹에서 제외될 수 있다.
- 데이터가 부족해도 API가 실패하지 않는다.

## 검증 메모

- 와이파이/콘센트 attribute가 있는 매장이 상단으로 올라오는지 확인한다.
