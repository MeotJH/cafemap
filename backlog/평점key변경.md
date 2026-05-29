# 평점 key 변경

## 목적
- 운영 데이터가 쌓인 기존 평점 key를 안전하게 보존하면서, 앞으로의 리뷰 작성은 더 직관적인 v2 평가 기준으로 전환한다.
- 사용자가 전문 지식 없이도 실제 방문 경험을 기준으로 평가할 수 있는 항목만 0~5점 평가로 남긴다.
- 산미/고소함/로스팅 정도처럼 좋고 나쁨보다 "맛 성향"에 가까운 요소는 평점이 아니라 선택형 메타데이터로 분리한다.

## 현재 문제
- 현재 일부 평가항목은 사용자가 매번 평가하기 어렵거나, 전문적인 판단을 요구한다.
- 기존 항목 예시:
  - `coffee_quality`: 원두 품질
  - `acidity_balance`: 산미 밸런스
  - `temperature`: 온도 만족도
  - `outlet_access`: 콘센트 접근성
  - `wifi_quality`: 와이파이
- 특히 `원두 품질`은 일반 사용자가 판단하기 어렵고, `산미/고소함`은 좋고 나쁨보다 맛 방향성에 가깝다.
- `콘센트 접근성`, `와이파이`는 작업 목적 방문자에게는 중요하지만 모든 방문자가 매번 경험하지 않는다.

## 핵심 원칙
- 기존 key의 의미를 바꾸지 않는다.
- 기존 리뷰와 집계는 기존 스키마(v1) 기준으로 계속 표시할 수 있게 둔다.
- 새 평가항목은 새 key와 새 schema version으로 쌓는다.
- 의미가 다른 항목끼리는 평균내거나 추천 계산에서 섞지 않는다.
- 0~5점 평가는 "좋고 나쁨"이 명확한 항목만 사용한다.
- 맛 성향, 로스팅 성향, 온도 옵션처럼 방향성/선택에 가까운 값은 독립 변수로 저장한다.

## v1 보존 정책
- 기존 데이터는 그대로 둔다.
- 기존 key는 legacy key로 유지한다.
- 기존 상세 화면이나 리뷰 상세에서 legacy 리뷰는 내부 schema에 맞는 기존 항목명으로 표시한다.
- v1 집계와 v2 집계는 같은 평균으로 합치지 않는다.
- "비슷한 평가의 카페" 추천도 같은 schema version끼리 비교하는 방향이 안전하다.

## v2 설계 방향

### 평점 항목과 독립 변수 분리
- 평점 항목:
  - 0~5점으로 평가한다.
  - 만족도, 품질, 쾌적함처럼 좋고 나쁨의 방향이 있어야 한다.
- 독립 변수:
  - 점수 평균에 직접 반영하지 않는다.
  - 취향 매칭, 필터, 설명에 사용한다.
  - 예: `HOT / ICE`, `산미형 / 균형형 / 고소한형`, `라이트 / 미디엄 / 다크`, `덜 달게 / 적당히 / 달게`

### 커피 맛 성향 독립 변수
- `산미`와 `고소함`은 서로 어느 정도 배타적인 맛 성향이다.
- 둘을 각각 0~5점으로 두면 "약해서 낮은 점수"인지 "나빠서 낮은 점수"인지 해석이 흐려진다.
- 따라서 아래처럼 선택형으로 분리한다.

```text
flavorProfile:
- acidic
- balanced
- nutty
- unknown
```

표시안:

```text
산미형
균형형
고소한형
잘 모르겠음
```

### 단맛 정도 독립 변수
- `단맛`도 0~5점 만족도로 두면 해석이 흐려진다.
- 어떤 사람은 단맛이 강해서 좋아하고, 어떤 사람은 단맛이 약해서 좋아한다.
- 따라서 단맛은 좋고 나쁨의 점수보다 "얼마나 달았는가"를 기록하는 선택값이 더 적합하다.

```text
sweetnessLevel:
- low
- medium
- high
- unknown
```

표시안:

```text
덜 달게
적당히 달게
달게
잘 모르겠음
```

### 로스팅 성향 독립 변수
- 로스팅 정도는 품질 점수가 아니라 성향 정보다.
- 0~5점보다 선택형이 맞다.

```text
roastLevel:
- light
- medium
- dark
- unknown
```

표시안:

```text
라이트
미디엄
다크
잘 모르겠음
```

### 온도 옵션
- 기존 `temperature_option`처럼 리뷰 당시 마신 음료의 상태로 기록한다.

```text
temperatureOption:
- hot
- ice
- unspecified
```

## v2 평점 key 제안

### 커피 기본
- 대상: 아메리카노, 에스프레소, 롱블랙, 일반 커피류

```text
taste_satisfaction = 맛 만족도
aroma = 향
body = 바디감
clean_finish = 깔끔함
aftertaste = 여운
value = 가격 만족도
```

독립 변수:

```text
flavor_profile = 산미형 / 균형형 / 고소한형 / 잘 모르겠음
roast_level = 라이트 / 미디엄 / 다크 / 잘 모르겠음
temperature_option = HOT / ICE
```

### 핸드드립
- 대상: 핸드드립, 드립커피
- 핸드드립은 향과 여운을 중요하게 보되, 너무 전문적인 항목은 피한다.

```text
taste_satisfaction = 맛 만족도
aroma = 향
clean_finish = 깔끔함
aftertaste = 여운
body = 바디감
value = 가격 만족도
```

독립 변수:

```text
flavor_profile = 산미형 / 균형형 / 고소한형 / 잘 모르겠음
roast_level = 라이트 / 미디엄 / 다크 / 잘 모르겠음
temperature_option = HOT / ICE
```

### 라떼
- 대상: 카페라떼, 바닐라 라떼, 카푸치노 등 우유 기반 메뉴

```text
taste_satisfaction = 맛 만족도
coffee_presence = 커피 맛
milk_balance = 우유 밸런스
texture = 질감
aftertaste = 여운
value = 가격 만족도
```

독립 변수:

```text
temperature_option = HOT / ICE
sweetness_level = 덜 달게 / 적당히 달게 / 달게 / 잘 모르겠음
```

### 콜드브루
- 대상: 콜드브루, 디카페인 콜드브루
- 평가항목은 `커피 기본`과 동일하게 둔다.
- 이유:
  - 사용자는 콜드브루도 아메리카노처럼 "커피 맛"으로 평가하는 경우가 많다.
  - 별도 key를 두면 비교/집계가 불필요하게 복잡해진다.
  - 청량감, 얼음 비율 같은 항목은 매번 핵심 평가 요소가 되기 어렵다.

### 콜드브루 라떼
- 대상: 콜드브루 라떼
- 평가항목은 `라떼`와 동일하게 둔다.
- 이유:
  - 우유가 들어간 순간 사용자가 체감하는 핵심은 커피 원액보다 우유 밸런스, 질감, 커피 맛 존재감이다.
  - 따라서 콜드브루 라떼는 콜드브루가 아니라 라떼 계열 평가로 보는 편이 자연스럽다.

### 차
- 대상: 밀크티, 티, 유자차 등

```text
taste_satisfaction = 맛 만족도
aroma = 향
clean_finish = 깔끔함
aftertaste = 여운
portion = 양
value = 가격 만족도
```

독립 변수:

```text
temperature_option = HOT / ICE
sweetness_level = 덜 달게 / 적당히 달게 / 달게 / 잘 모르겠음
```

### 디저트 / 디저트음료
- 현재 구조는 비교적 직관적이므로 크게 바꾸지 않는다.
- `맛 조화`보다 `맛 만족도`가 더 쉽다.

```text
taste_satisfaction = 맛 만족도
texture = 식감
visuals = 비주얼
portion = 양
value = 가격 만족도
```

독립 변수:

```text
sweetness_level = 덜 달게 / 적당히 달게 / 달게 / 잘 모르겠음
```

## v2 가게 평가 key 제안

### 0~5점 필수 평가
- 대부분의 방문자가 경험할 수 있고 좋고 나쁨이 명확한 항목만 둔다.

```text
atmosphere = 분위기
quietness = 조용함
seat_comfort = 좌석 편안함
restroom_cleanliness = 화장실 청결
service = 응대
revisit_intent = 재방문 의사
```

### 선택형/옵션 평가
- 작업 목적 방문자에게는 중요하지만 모든 방문자가 매번 경험하지 않는 항목이다.
- 필수 0~5점으로 두면 데이터 품질이 낮아질 수 있다.

```text
work_friendly = 작업하기 좋음
outlet_available = 콘센트 있음 / 없음 / 모름
wifi_usable = 와이파이 좋음 / 안 좋음 / 안 써봄
```

## v1에서 v2로의 변경 매핑

### label 변경으로 처리 가능한 후보
- 의미가 크게 바뀌지 않는 항목만 label 변경 가능하다.

```text
body = 바디감 유지
aftertaste = 여운 유지
value = 가성비 -> 가격 만족도
quietness = 조용함 유지
seat_comfort = 좌석 편안함 유지
service = 응대 유지
revisit_intent = 재방문 의사 유지
```

### 새 key로 분리해야 하는 후보
- 기존 key의 의미와 다르면 새 key로 만든다.

```text
coffee_quality -> taste_satisfaction
acidity_balance -> flavor_profile 독립 변수
temperature -> 삭제 또는 temperature_option으로만 처리
outlet_access -> outlet_available 선택형
wifi_quality -> wifi_usable 선택형
restroom_cleanliness 신규 추가
coffee_presence 신규 추가
```

## 데이터 저장 방향

### 리뷰 단위
- 리뷰에 schema version을 저장한다.

```text
rating_schema_version = 1
rating_schema_version = 2
```

- v2 리뷰에는 점수와 독립 변수를 분리해서 저장한다.

```text
scores_json = {
  "taste_satisfaction": 4.5,
  "aroma": 4.0,
  "body": 4.2,
  "clean_finish": 4.4,
  "aftertaste": 4.1,
  "value": 3.8
}

attributes_json = {
  "flavor_profile": "nutty",
  "roast_level": "medium",
  "temperature_option": "ice",
  "outlet_available": "unknown",
  "wifi_usable": "not_used"
}
```

### 집계 단위
- v1 aggregate와 v2 aggregate를 섞지 않는다.
- 최소 구현은 기존 aggregate에 schema version 기준 필터를 추가하거나, v2 aggregate를 별도 산출하는 방식이다.
- 추천/유사도 계산은 같은 schema version의 점수끼리만 비교한다.

## 화면 표시 방향

### 리뷰 작성
- 새 리뷰 작성은 v2 평가항목으로 진행한다.
- 산미/고소함/로스팅은 점수 슬라이더가 아니라 선택형 컨트롤로 제공한다.
- 작업 관련 항목은 선택형 또는 optional로 둔다.

### 리뷰 상세
- legacy 리뷰는 기존 항목명과 기존 점수로 표시한다.
- 신규 리뷰는 신규 항목명, 신규 점수, 독립 변수로 표시한다.
- 화면에는 schema 이름을 직접 노출하지 않는다.

### 가게 상세
- v2 데이터가 충분하면 v2 상세 평가를 우선 표시한다.
- v2 데이터가 부족하면 기존 v1 상세 평가를 유지한다.
- 화면에는 `v1`, `v2`, `기존 기준`, `새 기준` 같은 schema 용어를 노출하지 않는다.
- v1/v2를 같은 평균으로 합치지 않는다.

### 비슷한 평가의 카페
- v2 데이터가 충분한 카페끼리는 v2 key 기준으로 유사도를 계산한다.
- v2 데이터가 부족한 경우에는 v1 기준 추천을 유지하거나 섹션을 숨긴다.
- 산미형/고소한형 같은 독립 변수는 점수 유사도가 아니라 필터/가중치로 사용할 수 있다.

## 개발 백로그
- 아래 순서는 운영 데이터 보존을 우선으로 둔 구현 순서다.
- 각 feature는 가능한 작게 쪼갰고, 앞 feature가 끝나면 다음 feature를 독립적으로 검증할 수 있게 구성한다.
- 원칙:
  - v1 데이터는 건드리지 않는다.
  - v2 저장 구조를 먼저 만든 뒤 UI를 전환한다.
  - v2 집계/추천은 v2 데이터가 쌓인 뒤 켠다.

### Feature 0. 최종 평가 UX 사양 확정

#### 디자이너 할 일
- [x] 리뷰 작성 화면에서 점수 항목과 선택형 항목을 시각적으로 분리한다.
- [x] `flavor_profile` 선택 UI 문구를 확정한다.
  - 산미형
  - 균형형
  - 고소한형
  - 잘 모르겠음
- [x] `roast_level` 선택 UI 문구를 확정한다.
  - 라이트
  - 미디엄
  - 다크
  - 잘 모르겠음
- [x] `sweetness_level` 선택 UI 문구를 확정한다.
  - 덜 달게
  - 적당히 달게
  - 달게
  - 잘 모르겠음
- [x] 선택형 항목을 필수로 둘지 선택으로 둘지 메뉴 카테고리별로 정한다.
- [x] 리뷰 상세에는 schema 구분 문구를 표시하지 않는다.
  - 내부 분기만 하고 화면에는 자연스러운 평가항목/취향 chip만 표시한다.

#### 백엔드 할 일
- [x] 디자이너 확정 문구를 API enum 값과 분리해서 기록한다.
- [x] enum 값은 영어 key로 고정한다.
  - `acidic`, `balanced`, `nutty`, `unknown`
  - `light`, `medium`, `dark`, `unknown`
  - `low`, `medium`, `high`, `unknown`

#### 프론트 할 일
- [x] 확정된 문구를 `rating_dimensions.dart`에 넣을 수 있는 형태로 정리한다.
- [x] 리뷰 작성 UI에서 점수와 선택형 항목이 섞여 보이지 않는 와이어프레임을 잡는다.

#### 수용조건
- v2에서 점수로 받을 항목과 선택으로 받을 항목이 명확히 구분된다.
- 각 선택형 값의 저장 key와 화면 label이 1:1로 정리된다.

### Feature 1. rating schema version 저장 기반 추가

상태: 완료

#### 백엔드 할 일
- [x] `review` 테이블에 `rating_schema_version` 컬럼을 추가한다.
- [x] 기존 리뷰의 기본값은 `1`로 둔다.
- [x] 신규 리뷰 생성 시 기본 schema version을 `2`로 저장할 수 있게 한다.
- [x] 기존 create review API가 schema version 없이 호출돼도 깨지지 않게 fallback을 둔다.
- [x] `ReviewOut` 응답에 `ratingSchemaVersion`을 추가한다.
- [x] 기존 리뷰 조회 API 전체에 `ratingSchemaVersion`을 포함한다.
  - 가게 리뷰
  - 내 리뷰
  - 리뷰 상세
  - 메뉴 랭킹 리뷰

#### 프론트 할 일
- [x] `Review` 엔티티에 `ratingSchemaVersion` 필드를 추가한다.
- [x] remote review/store/ranking API 파서에 `ratingSchemaVersion`을 추가한다.
- [x] mock review 데이터에 v1/v2 샘플을 각각 준비한다.
- [x] schema version이 없으면 `1`로 처리하는 fallback을 둔다.

#### 수용조건
- 기존 리뷰는 v1로 식별된다.
- 새 리뷰는 v2로 저장할 준비가 된다.
- 기존 화면은 schema version 필드 추가 후에도 표시가 깨지지 않는다.

### Feature 2. v2 rating dimension 상수 추가

#### 백엔드 할 일
- [x] `back/cafemap/core/rating_dimensions.py`에 v2 상수를 추가한다.
- [x] v1 상수와 v2 상수를 분리한다.
- [x] 메뉴 카테고리별 v2 점수 key를 추가한다.
  - 커피 기본
  - 핸드드립
  - 라떼
  - 차
  - 디저트/디저트음료
- [x] 콜드브루는 커피 기본 상수를 재사용하게 한다.
- [x] 콜드브루 라떼는 라떼 상수를 재사용하게 한다.
- [x] v2 store score key를 추가한다.
  - `atmosphere`
  - `quietness`
  - `seat_comfort`
  - `restroom_cleanliness`
  - `service`
  - `revisit_intent`
- [x] v2 선택형 attribute key 목록을 추가한다.
  - `flavor_profile`
  - `roast_level`
  - `sweetness_level`
  - `temperature_option`
  - `outlet_available`
  - `wifi_usable`

#### 프론트 할 일
- [x] `front/lib/core/constants/rating_dimensions.dart`에 v2 상수를 추가한다.
- [x] 백엔드와 key 이름이 완전히 같은지 맞춘다.
- [x] v1 label과 v2 label을 분리한다.
- [x] 선택형 attribute label map을 추가한다.
- [x] 콜드브루/콜드브루 라떼 카테고리 매핑을 정리한다.

#### 수용조건
- 프론트/백엔드 v2 key가 일치한다.
- v1 key는 삭제되지 않는다.
- 콜드브루는 커피 기본, 콜드브루 라떼는 라떼 기준을 따른다.

### Feature 3. v2 리뷰 저장 계약 확장

#### 백엔드 할 일
- [x] `ReviewCreateIn`에 `ratingSchemaVersion`을 추가한다.
- [x] `ReviewCreateIn`에 `attributes` 또는 `attributesJson` 구조를 추가한다.
- [x] `review` 테이블에 `attributes_json` 컬럼을 추가한다.
- [x] v2 점수는 v2 allowed key만 저장되게 normalize한다.
- [x] v2 선택형 attribute는 허용 enum만 저장되게 normalize한다.
- [x] 알 수 없는 attribute 값은 `unknown` 또는 빈 값으로 정리한다.
- [x] `temperature_option` 기존 컬럼과 v2 `temperature_option` attribute 관계를 정한다.
  - 권장: 기존 컬럼은 유지하고 v2 attributes에도 표시용으로 동기화하거나, 기존 컬럼을 source of truth로 둔다.

#### 프론트 할 일
- [x] `ReviewCreateRequest`에 `ratingSchemaVersion`을 추가한다.
- [x] `ReviewCreateRequest`에 선택형 `attributes`를 추가한다.
- [x] 리뷰 생성 payload에 v2 점수와 attributes를 함께 보낸다.
- [x] 기존 v1 payload 생성 경로가 있으면 깨지지 않게 둔다.

#### 수용조건
- v2 리뷰 생성 payload가 DB에 저장된다.
- v2 점수 key와 선택형 attribute key가 섞여 저장되지 않는다.
- 기존 API 클라이언트가 schema version 없이 호출해도 실패하지 않는다.

### Feature 4. 리뷰 작성 v2 UI 적용

#### 디자이너 할 일
- [x] 리뷰 작성 화면에서 메뉴 선택 후 점수 항목 순서를 확정한다.
- [x] 선택형 컨트롤은 `ChoiceChip` 또는 segmented control 중 하나로 확정한다.
- [x] `잘 모르겠음` 선택지가 시각적으로 과하게 강조되지 않게 한다.
- [x] 작업 관련 선택형 항목의 노출 위치를 정한다.
  - 점수 평가 아래
  - 가게 경험 평가 아래
  - 접기/선택 섹션

#### 프론트 할 일
- [x] 메뉴 카테고리별 v2 점수 항목을 렌더링한다.
- [x] 커피 기본 메뉴에 `flavor_profile`, `roast_level`, `temperature_option` 선택 UI를 붙인다.
- [x] 핸드드립에 `flavor_profile`, `roast_level`, `temperature_option` 선택 UI를 붙인다.
- [x] 라떼에 `temperature_option`, `sweetness_level` 선택 UI를 붙인다.
- [x] 차에 `temperature_option`, `sweetness_level` 선택 UI를 붙인다.
- [x] 디저트/디저트음료에 `sweetness_level` 선택 UI를 붙인다.
- [x] 가게 평가에서 `restroom_cleanliness` 점수 항목을 추가한다.
- [x] `outlet_available`, `wifi_usable` 선택 UI를 optional로 추가한다.
- [x] 기존 `outlet_access`, `wifi_quality` 점수 UI는 v2 작성 화면에서 제거한다.
- [x] v2 점수 항목 초기값과 submit validation을 정리한다.

#### 백엔드 할 일
- [x] 프론트가 보내는 v2 payload 예시로 API validation을 확인한다.
- [x] 누락 가능한 optional attribute 처리 정책을 확정한다.

#### 수용조건
- 새 리뷰 작성은 v2 항목으로 진행된다.
- 산미/고소함/단맛/로스팅은 점수가 아니라 선택형으로 입력된다.
- 작업 관련 항목은 필수 점수 입력을 강요하지 않는다.

### Feature 5. 리뷰 상세/카드 표시 분기

#### 프론트 할 일
- [x] 리뷰 카드에서 schema별 표시를 내부 분기한다.
- [x] 리뷰 상세에서 기존 점수는 기존 label로 표시한다.
- [x] 리뷰 상세에서 신규 점수는 신규 label로 표시한다.
- [x] 독립 변수는 작은 badge 또는 chip으로 표시한다.
  - HOT/ICE
  - 산미형/균형형/고소한형
  - 라이트/미디엄/다크
  - 덜 달게/적당히/달게
- [x] schema version이 없거나 알 수 없는 값이면 v1 fallback을 적용한다.

#### 디자이너 할 일
- [x] 독립 변수 badge 스타일을 정한다.
- [x] 사용자 화면에는 schema 용어를 노출하지 않기로 정한다.

#### 백엔드 할 일
- [x] `ReviewOut`에 v2 attributes가 내려오는지 확인한다.
- [x] 기존 리뷰 응답에 빈 attributes가 있어도 안전하게 응답한다.

#### 수용조건
- 기존 리뷰 상세는 자연스러운 기존 항목명으로 보인다.
- 새 리뷰 상세는 자연스러운 신규 항목명과 선택형 취향 정보가 같이 보인다.
- 여러 schema가 한 화면에 섞여도 라벨이 틀리지 않고 schema 용어는 노출되지 않는다.

### Feature 6. 가게 상세 집계 v1/v2 분리

#### 백엔드 할 일
- [x] store breakdown 집계에서 schema version 기준 필터를 추가한다.
- [x] v2 리뷰가 있는 경우 v2 breakdown을 계산한다.
- [x] v2 리뷰 수가 기준 미만이면 v1 breakdown을 fallback으로 반환할지 결정한다.
- [x] 응답에 `ratingSchemaVersion` 또는 `breakdownSchemaVersion`을 포함한다.
- [x] v1/v2 count를 함께 내려줄지 결정한다.

#### 프론트 할 일
- [x] 가게 상세의 `상세 항목 평가`가 응답 schema version에 맞는 label을 사용하게 한다.
- [x] v2 데이터 부족 fallback 정책을 정한다.
  - 화면 문구를 별도 노출하지 않고 기존 평가를 자연스럽게 fallback한다.
- [x] 기존 v1 breakdown도 계속 표시 가능하게 둔다.

#### 디자이너 할 일
- [x] schema 기준 표시 문구는 노출하지 않기로 정한다.
- [x] 가게 상세 fallback은 별도 강조 없이 기존 섹션에 자연스럽게 배치한다.

#### 수용조건
- v1 집계와 v2 집계가 같은 평균으로 합쳐지지 않는다.
- 가게 상세가 schema version에 맞는 label을 사용한다.
- v2 데이터가 부족해도 화면이 비지 않는다.

### Feature 7. 랭킹/추천/유사 카페 v2 대응

#### 백엔드 할 일
- [x] 메뉴 랭킹 집계에서 v1/v2 혼합 여부를 점검한다.
- [x] store ranking 계산에서 schema version 기준을 정한다.
- [x] `비슷한 평가의 카페` 유사도 계산에서 같은 schema version끼리만 비교한다.
- [x] v2 데이터가 부족하면 v1 기준 추천을 유지하거나 빈 결과를 반환한다.
- [x] `flavor_profile`, `roast_level`, `sweetness_level`은 점수 유사도가 아니라 filter 또는 가중치로만 사용한다.

#### 프론트 할 일
- [x] 유사 카페 섹션에서 신규 결과와 fallback 결과를 구분 없이 자연스럽게 표시한다.
- [x] 유사도 설명 문구를 schema 용어 없이 유지한다.

#### 디자이너 할 일
- [x] 유사 카페 설명 문구를 schema 용어 없이 정한다.
- [x] v2 데이터 부족 시 섹션 숨김/표시 정책을 정한다.

#### 수용조건
- 유사도 계산에서 의미가 다른 key가 섞이지 않는다.
- 독립 변수는 평균 점수에 들어가지 않는다.
- v2 데이터가 적어도 추천 섹션이 깨지지 않는다.

### Feature 8. 운영 데이터 전환과 QA

#### 백엔드 할 일
- [ ] 운영 DB에 컬럼 추가 migration을 준비한다.
- [ ] 기존 리뷰 수, v1/v2 리뷰 수를 확인할 수 있는 간단한 진단 스크립트를 준비한다.
- [ ] 배포 후 v2 리뷰 생성이 정상 저장되는지 로그 포인트를 정한다.
- [ ] 기존 v1 API 응답이 깨지지 않는지 smoke test를 추가한다.

#### 프론트 할 일
- [ ] v1 리뷰만 있는 가게 상세를 확인한다.
- [ ] v2 리뷰만 있는 가게 상세를 확인한다.
- [ ] v1/v2 리뷰가 섞인 가게 상세를 확인한다.
- [ ] 리뷰 작성에서 각 메뉴 카테고리별 v2 항목이 맞게 나오는지 확인한다.
- [ ] 모바일 좁은 화면에서 선택형 chip이 넘치지 않는지 확인한다.

#### 디자이너 할 일
- [ ] 실제 운영 데이터 기준으로 v1/v2 혼합 화면을 리뷰한다.
- [ ] 선택형 항목이 너무 많아 보이면 1차 출시에서 일부를 접거나 optional로 내린다.

#### 수용조건
- 기존 운영 리뷰가 손상되지 않는다.
- 새 리뷰는 v2 기준으로 저장된다.
- 기존 화면, 랭킹, 리뷰 상세, 유사 카페 섹션이 모두 fallback을 가진다.
- 배포 후 v2 데이터가 얼마나 쌓이는지 확인할 수 있다.

## 최소 출시 순서
1. Feature 0: 평가 UX 사양 확정
2. Feature 1: schema version 저장 기반
3. Feature 2: v2 상수 추가
4. Feature 3: v2 저장 계약 확장
5. Feature 4: 리뷰 작성 v2 UI 적용
6. Feature 5: 리뷰 상세/카드 표시 분기
7. Feature 6: 가게 상세 집계 분리
8. Feature 7: 유사 카페/랭킹 v2 대응
9. Feature 8: 운영 전환 QA

## 리스크
- v2 초기에는 데이터가 적어서 랭킹/유사도 품질이 낮을 수 있다.
- 기존 v1 평가와 v2 평가를 섞어 평균내면 데이터 의미가 깨진다.
- 선택형 독립 변수를 너무 많이 추가하면 리뷰 작성 피로도가 커질 수 있다.
- 메뉴 카테고리별 평가항목이 지나치게 달라지면 집계와 비교가 어려워질 수 있다.

## 권장 결정
- 기존 key는 legacy로 유지한다.
- 새 리뷰부터 `rating_schema_version = 2`를 저장한다.
- v2 점수 항목은 "만족도 평가"에 집중한다.
- 산미/고소함/로스팅은 점수가 아니라 독립 선택값으로 저장한다.
- 가게 평가는 `화장실 청결`을 추가하고, `콘센트`, `와이파이`는 선택형으로 내린다.
