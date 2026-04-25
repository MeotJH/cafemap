# 5. 리뷰 작성 메뉴 정렬 개선 + 개인카페 핫/아이스 옵션

## 목표
- 리뷰 작성 화면에서 메뉴를 찾기 쉽게 만든다.
- 가나다순 대신 사용자가 자주 고르는 기본 커피 메뉴가 먼저 보이게 한다.
- 현재 `디저트음료`에 섞여 있는 `차` 메뉴를 별도 카테고리로 분리한다.
- 브랜드/개인카페 공통으로 `핫 / 아이스`를 별도 선택할 수 있게 한다.
- 이 옵션이 UI에서만 존재하지 않고, API/DB까지 자연스럽게 저장되도록 한다.

## 문제 정리
- 현재 메뉴 리스트는 백엔드에서 `Menu.name.asc()`로 정렬되어 있어 사용 흐름보다 사전순이 우선이다.
- 이미 [init_db.py](/Users/eldorado/WorkSpace/cafemap/back/cafemap/db/init_db.py:69)의 `COMMON_CAFE_MENU_SEEDS`는
  `아메리카노 -> 디카페인 아메리카노 -> 에스프레소 -> 카페라떼 ...`처럼 더 자연스러운 순서를 갖고 있는데,
  조회 시 다시 가나다순으로 덮어쓴다.
- 현재 `디저트음료` 카테고리에 차 메뉴와 디저트성 음료가 함께 섞여 있다.
  - 예: `유자차`, `얼그레이 티`, `페퍼민트 티`와 `초코 라떼`, `스무디`, `에이드`, `프라페`
- `핫/아이스`는 현재 `menu`에도 없고 `review`에도 없어서, 선택 UI를 추가해도 저장 위치가 없다.

## 제안 방향

### 1. 메뉴 정렬 정책
- 먼저 카테고리 체계를 `차`와 `디저트음료`로 분리한다.
- 정렬은 프론트 임시 정렬이 아니라 메뉴 API 기준으로 맞춘다.
- 우선순위는 아래 순서를 기본안으로 둔다.
  - 1순위: `COMMON_CAFE_MENU_SEEDS`에 정의된 표준 메뉴 순서
  - 2순위: 같은 카테고리 내 나머지 메뉴
  - 3순위: 같은 그룹 안에서는 가나다순
- 카테고리 우선순위 기본안:
  - `커피`
  - `라떼`
  - `콜드브루`
  - `핸드드립`
  - `차`
  - `시그니처`
  - `디저트음료`
- 기대 결과:
  - 사용자가 가장 자주 찾는 `아메리카노`, `카페라떼`가 상단에 온다.
  - `차`가 에이드/스무디/프라페와 분리되어 더 자연스럽게 보인다.
  - 시드/표준메뉴 기준과 실제 조회 순서가 일치한다.

### 1-1. 카테고리 분리 기준
- 새 카테고리:
  - `차`
  - `디저트음료`
- `차`로 이동할 메뉴 기본안:
  - `밀크티`
  - `얼그레이 밀크티`
  - `차이 밀크티`
  - `레몬티`
  - `자몽티`
  - `유자차`
  - `캐모마일 티`
  - `페퍼민트 티`
  - `얼그레이 티`
  - `녹차`
- `디저트음료` 유지 메뉴 기본안:
  - `초코 라떼`
  - `녹차 라떼`
  - `말차 라떼`
  - `고구마 라떼`
  - `곡물 라떼`
  - `에이드`
  - `스무디`
  - `프라페`
- 주의:
  - `녹차 라떼`, `말차 라떼`는 차 원료 기반이지만 사용자 경험상 `디저트음료`에 두는 편이 더 자연스럽다.
  - 필요하면 2차에서 `티라떼` 계열을 다시 세분화할 수 있다.

### 2. 핫/아이스 데이터 모델
- `menu` 테이블에 `핫/아이스`를 넣지 않는다.
- `review` 테이블에 `temperature_option` 필드를 추가한다.
- 권장 값:
  - `""` 또는 `unspecified`
  - `hot`
  - `ice`
- 이유:
  - 같은 `아메리카노`를 `핫/아이스` 때문에 다른 메뉴로 쪼개지 않게 할 수 있다.
  - 메뉴 랭킹/집계는 기존 `menu_id` 기준을 유지할 수 있다.
  - 표시용 badge는 `menuName + temperatureOption` 조합으로 충분히 만들 수 있다.

## 왜 `review.temperature_option`이 자연스러운가
- `menu`는 표준 메뉴 사전이다.
  - `아메리카노` 자체가 메뉴이고, `핫/아이스`는 주문 옵션에 가깝다.
- `review`는 실제 사용자가 마신 한 잔의 기록이다.
  - 같은 메뉴라도 이번엔 `핫`, 다음엔 `아이스`일 수 있다.
- 이 구조면:
  - 메뉴 검색은 단순하다.
  - 집계는 기존 로직을 거의 유지할 수 있다.
  - 나중에 `샷 추가`, `디카페인`, `연하게` 같은 옵션이 생겨도 같은 패턴으로 확장 가능하다.

## UI 기본안

### 리뷰 작성 화면
- 위치:
  - [review_write_page.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/presentation/pages/review_write_page.dart)의
    `표준 메뉴 검색 후 선택` 아래
- 노출 조건:
  - 브랜드/개인카페 공통으로 노출
  - 메뉴가 선택된 뒤 노출
- 컴포넌트:
  - [store_detail_page.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/presentation/pages/store_detail_page.dart)의
    `커피 / 가게` 분리 UI와 같은 `ChoiceChip` 스타일 사용
- 선택지 기본안:
  - `핫`
  - `아이스`

### 온도 선택 노출 규칙 기본안
- must-have v1:
  - `커피`, `라떼`, `차` 카테고리에서 `핫 / 아이스` 선택 허용
- 기본 숨김:
  - `디저트음료`는 `핫 / 아이스` 선택 UI를 기본적으로 노출하지 않음
- follow-up:
  - `시그니처`는 메뉴별 정책이 필요하면 2차 확장
- 이유:
  - category 단위만으로도 1차 UX는 크게 좋아진다.
  - 프랜차이즈든 개인카페든 공통 UX를 줄 수 있다.
  - 차 메뉴까지 자연스럽게 `핫/아이스` 선택 대상으로 포함할 수 있다.
  - 에이드/스무디/프라페처럼 명확히 차가운 음료를 잘못 `핫`으로 고르는 문제를 줄일 수 있다.

## 백엔드 영향

### DB
- `review` 테이블에 `temperature_option VARCHAR` 추가
- 기존 `menu.category` 값 중 차 계열 메뉴를 `차`로 재분류하는 마이그레이션 또는 시드 보정 필요
- SQLite 마이그레이션:
  - [init_db.py](/Users/eldorado/WorkSpace/cafemap/back/cafemap/db/init_db.py) 의 기존 `ALTER TABLE` 패턴에 맞춰 추가

### ORM / Schema
- [entities.py](/Users/eldorado/WorkSpace/cafemap/back/cafemap/models/entities.py)
  - `Review.temperature_option`
- [cafemap.py](/Users/eldorado/WorkSpace/cafemap/back/cafemap/schemas/cafemap.py)
  - `ReviewCreateIn.temperatureOption`
  - `ReviewOut.temperatureOption`
- 카테고리 상수 동기화:
  - [rating_dimensions.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/core/constants/rating_dimensions.dart)
  - [rating_dimensions.py](/Users/eldorado/WorkSpace/cafemap/back/cafemap/core/rating_dimensions.py)
  - 현재 `디저트음료`를 `차`와 `디저트음료`로 나누는 계약 변경 포함

### Service / Repository
- 리뷰 생성 시 `temperatureOption` 저장
- 리뷰 상세 / 내 리뷰 / 가게 리뷰 / 랭킹 리뷰 응답에 모두 포함
- 메뉴 조회 정렬은 [brand_menu_repository.py](/Users/eldorado/WorkSpace/cafemap/back/cafemap/repositories/brand_menu_repository.py)
  에서 공통 정책으로 처리
- 메뉴 조회 전 또는 시드 시점에 차/디저트 재분류 규칙 적용

## 프론트 영향

### 엔티티 / API
- `Review`
- `ReviewCreateRequest`
- 리뷰 관련 remote adapter 전부

### 화면
- [review_write_page.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/presentation/pages/review_write_page.dart)
  - 메뉴 정렬 반영
  - 브랜드/개인카페 공통 `핫/아이스` 선택 UI 추가
  - 선택값 검증 및 submit payload 포함
- 추천 표시 위치:
  - [review_card.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/presentation/widgets/review_card.dart)
  - [review_detail_page.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/presentation/pages/review_detail_page.dart)
- 표시 방식 기본안:
  - `아메리카노` 옆에 작은 badge `HOT` / `ICE`

## 구현 순서 제안
1. `디저트음료`를 `차`와 `디저트음료`로 나누는 카테고리 규칙을 정의한다.
2. 프론트/백엔드 rating dimension 상수와 메뉴 데이터 분류를 함께 맞춘다.
3. 메뉴 정렬 정책을 백엔드 메뉴 API에 도입한다.
4. `review.temperature_option` 계약을 DB/ORM/schema/API에 추가한다.
5. 리뷰 작성 화면에 `핫/아이스` 선택 UI를 넣는다.
6. 리뷰 상세/리스트에 temperature badge를 노출한다.
7. 정적 검증과 최소 흐름 검증을 수행한다.

## 수용조건
- 리뷰 작성 메뉴 목록에서 `아메리카노`, `카페라떼` 같은 기본 커피 메뉴가 상단에 온다.
- 기존 `디저트음료`에 섞여 있던 차 메뉴가 `차` 카테고리로 분리된다.
- 리뷰 작성에서 메뉴 선택 후 `핫/아이스`를 고를 수 있다.
- 선택값은 리뷰 생성 API로 전달되고 DB에 저장된다.
- 리뷰 상세/리스트 응답에서 temperature option을 다시 받을 수 있다.
- 기존 메뉴 랭킹과 리뷰 집계는 `menu_id` 기준으로 유지되어 깨지지 않는다.

## 범위 밖
- 메뉴별 복잡한 옵션 체계 확장
  - 예: `샷 추가`, `디카페인`, `시럽 변경`
- temperature option 기준 별도 랭킹 분리

## 리스크
- `시그니처`는 `핫/아이스` 가능 여부가 메뉴마다 달라 단순 category rule이 과할 수 있다.
- 기존 데이터 중 `디저트음료`로 저장된 차 메뉴를 어떤 기준으로 `차`로 이동할지 명확한 규칙이 필요하다.
- 기존 리뷰는 `temperature_option`이 비어 있으므로 표시 시 자연스러운 fallback이 필요하다.
- 메뉴 정렬을 백엔드에서 바꾸면 다른 화면도 동일한 순서를 받게 되므로, 의도된 전역 변경인지 확인이 필요하다.

## 권장 결정
- 이번 1차 구현은 아래로 제한하는 것이 가장 안전하다.
  - 카테고리: `디저트음료`를 `차`와 `디저트음료`로 분리
  - 메뉴 정렬: 백엔드 공통 정렬 정책 적용
  - temperature option: 브랜드/개인카페 공통 + `커피/라떼/차` 우선
  - 리뷰 카드/상세에 badge 표시
