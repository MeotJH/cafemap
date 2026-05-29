# Feature: 홈 상황별 추천 카페

## 문제

홈 화면은 현재 아내픽, 남편픽, 오늘의 부부픽 중심으로 추천을 보여준다. 사용자는 "지금 어떤 목적으로 카페를 찾는지"에 따라 더 빠르게 랭킹으로 진입할 수 있어야 한다.

## 목표

홈에 상황별 추천 진입점을 추가하고, 선택한 목적에 맞는 카페 랭킹으로 이동시킨다.

## 1차 범위

- 홈에 `상황별 추천 카페` 섹션을 추가한다.
- 목적은 `데이트`, `대화`, `사진`, `커피맛`, `오래 앉기` 5개로 시작한다.
- 목적 선택 시 랭킹 화면으로 이동한다.
- 랭킹 화면은 선택한 목적에 맞는 제목, 설명, 정렬 결과를 보여준다.
- 백엔드는 `v2` 리뷰 점수와 attribute를 조합해서 목적별 점수를 계산한다.

## 제외 범위

- 사용자 개인별 선호 학습
- 찜하기 기반 추천
- 주차, 역 근처, 웨이팅, 가격대 필터
- 지도 반경 추천
- 목적별 상세 필터 조합 UI

## 현재 데이터로 가능한 이유

- 매장 랭킹에는 `coupleScore`, `wifeScore`, `husbandScore`, `userScore`가 이미 있다.
- `v2` 리뷰 점수에는 분위기, 조용함, 좌석 편안함, 응대, 재방문 의사, 맛 만족도 계열 점수가 있다.
- `v2` 리뷰 attribute에는 일부 커피 취향, 콘센트, 와이파이 정보가 있다.

## 사용자 스토리 파일

- `recommendation-home-us01-purpose-catalog.md`
- `recommendation-home-us02-home-section.md`
- `recommendation-home-us03-home-to-ranking-navigation.md`
- `recommendation-home-us04-ranking-purpose-mode.md`
- `recommendation-home-us05-ranking-api-purpose-param.md`
- `recommendation-home-us06-date-purpose-score.md`
- `recommendation-home-us07-conversation-purpose-score.md`
- `recommendation-home-us08-photo-purpose-score.md`
- `recommendation-home-us09-coffee-purpose-score.md`
- `recommendation-home-us10-long-stay-purpose-score.md`
- `recommendation-home-us11-purpose-ranking-empty-state.md`
- `recommendation-home-us12-verification.md`

## 완료 기준

- 홈에서 5개 목적이 노출된다.
- 각 목적 선택 시 해당 목적 랭킹으로 이동한다.
- 목적별 랭킹이 기존 전체 랭킹과 다른 기준으로 정렬된다.
- 데이터가 부족한 목적은 깨지지 않고 빈 상태나 fallback 정렬을 보여준다.
- 프론트 `flutter analyze`와 백엔드 목적 점수 계산 검증이 통과한다.
