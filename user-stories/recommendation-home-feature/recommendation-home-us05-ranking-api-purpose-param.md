# US-05: 목적별 랭킹 API 파라미터 추가

## 사용자 스토리

방문자로서 목적을 선택했을 때 그 목적에 맞게 정렬된 카페를 보고 싶다. 그래야 단순 평점순이 아니라 상황에 맞는 랭킹을 볼 수 있다.

## 범위

- `/api/cafemap/store-rankings`에 `purpose` query parameter를 추가한다.
- 기존 `type=couple|wife|husband|user`는 유지한다.
- `purpose`가 없으면 기존 정렬을 유지한다.
- `purpose`가 있으면 목적 점수를 계산해 정렬한다.

## 정렬 규칙 초안

1. 목적 점수 높은 순
2. 부부픽 또는 선택 audience 점수 높은 순
3. 재방문 의사 높은 순
4. 리뷰 수 높은 순

## 백엔드 영향

- `back/cafemap/api/router.py`
- `back/cafemap/services/store_service.py`
- 필요하면 목적 key 상수 추가

## 프론트 영향

- `front/lib/data/remote/ranking_api.dart`
- `front/lib/domain/repositories/ranking_repository.dart`
- `front/lib/data/repositories/remote_ranking_repository.dart`
- ranking provider family parameter 확장

## 역할별 할 일

### Frontend

- 랭킹 API 호출에 `purpose` query parameter를 전달한다.
- provider와 repository 계약을 확장하되 기존 호출은 유지한다.

### Backend

- `/api/cafemap/store-rankings`에 `purpose` 파라미터를 추가한다.
- 파라미터 유무에 따라 기존 정렬과 목적 정렬을 분기한다.

### Designer

- 목적 랭킹이 `추천순`으로 보일 때 사용자에게 혼란이 없도록 명칭을 정한다.

## 수용 기준

- `GET /api/cafemap/store-rankings?purpose=date`가 정상 응답한다.
- `purpose`가 없을 때 기존 응답 순서가 유지된다.
- 지원하지 않는 purpose의 처리 정책이 테스트된다.

## 검증 메모

- API shape가 기존 프론트 파서와 호환되는지 확인한다.
