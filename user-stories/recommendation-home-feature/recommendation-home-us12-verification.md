# US-12: 상황별 추천 검증

## 사용자 스토리

개발자로서 상황별 추천 기능이 기존 홈/랭킹 흐름을 깨지 않았는지 확인하고 싶다. 그래야 작은 단위로 배포할 수 있다.

## 검증 범위

- 홈 섹션 노출
- 목적 선택 후 랭킹 이동
- 목적별 API 응답
- 기존 랭킹 동작 유지
- 인코딩 손상 여부

## 프론트 검증

- `flutter analyze`
- 홈 화면에서 5개 목적이 보이는지 확인
- 목적 선택 시 query parameter가 유지되는지 확인
- 기존 아내픽/남편픽/부부픽 섹션이 유지되는지 확인

## 백엔드 검증

- `GET /api/cafemap/store-rankings`
- `GET /api/cafemap/store-rankings?purpose=date`
- `GET /api/cafemap/store-rankings?purpose=conversation`
- `GET /api/cafemap/store-rankings?purpose=photo`
- `GET /api/cafemap/store-rankings?purpose=coffee`
- `GET /api/cafemap/store-rankings?purpose=long_stay`

## 테스트 포인트

- purpose가 없으면 기존 정렬이 유지된다.
- purpose가 있으면 목적 점수 기준으로 정렬된다.
- `v1` 리뷰만 있는 매장은 목적 랭킹에서 제외된다.
- 한국어 문구가 깨지지 않는다.

## 역할별 할 일

### Frontend

- `flutter analyze`
- 홈 진입, 목적 클릭, 랭킹 진입, 빈 상태 문구를 확인한다.

### Backend

- 목적별 API 응답과 정렬 결과를 검증한다.
- 리뷰 데이터 샘플로 목적 점수 계산이 실제로 달라지는지 확인한다.

### Designer

- 홈 진입점과 랭킹 헤더 문구가 목적 의미를 제대로 전달하는지 확인한다.
- 작은 화면에서 텍스트 길이와 카드 밀도를 검토한다.

## 수용 기준

- 프론트 정적 분석이 통과한다.
- 백엔드 목적 점수 계산 검증이 통과한다.
- 기존 `/home` 응답 계약은 변경하지 않는다.
- 변경된 API 계약은 프론트 파서와 일치한다.
