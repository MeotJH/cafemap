# Feature: 리뷰 미디어 업로드 확장

## 문제

리뷰 작성 화면은 현재 사진만 첨부할 수 있고, 첨부 가능 개수도 사진 기준으로만 정의되어 있다. 사용자는 매장의 분위기, 좌석 구성, 소음, 음료 제조 과정처럼 사진 한 장으로 전달하기 어려운 정보를 짧은 영상으로 남기고 싶어도 방법이 없다.

또한 현재 제한은 "사진 최대 5장" 기준이라, 영상을 허용하려면 첨부 규칙을 "사진/영상 합산 최대 5개"로 다시 정의해야 한다.

## 목표

- 리뷰 작성 및 수정 화면에서 사진과 영상을 함께 첨부할 수 있게 한다.
- 첨부 제한을 `사진/영상 합산 최대 5개`로 통일한다.
- 기존 사진 리뷰는 그대로 유지하면서, 새로 작성되는 리뷰는 혼합 미디어를 저장/조회/노출할 수 있게 한다.

## 1차 범위

- 리뷰 작성 화면에서 사진과 영상을 같은 첨부 영역에서 다룬다.
- 사용자는 사진 또는 영상을 선택/추가/삭제할 수 있다.
- 전체 첨부 수는 사진과 영상을 합산해 최대 5개다.
- 리뷰 수정 화면에서도 기존 미디어와 신규 미디어를 합산해 최대 5개를 유지한다.
- 백엔드는 리뷰 미디어를 사진 전용 URL 목록이 아니라 미디어 타입을 포함하는 구조로 저장/검증한다.
- 리뷰 상세/목록/내 리뷰/매장 리뷰 응답에서 미디어 목록을 내려준다.
- 영상은 업로드 후 재생 가능한 URL로 저장된다.
- 영상 대표 썸네일 정책을 정의한다.

## 제외 범위

- 영상 편집, 자르기, 필터 적용
- 대용량 장문 영상 업로드
- 신고, 모더레이션, 저작권 탐지
- 영상 자막/음성 분석

## 데이터 및 아키텍처 가정

- 현재 리뷰는 `imageUrls` 중심으로 저장/응답하고 있다.
- 1차에서는 `review.media` 또는 `mediaItems` 같은 새 구조를 도입하고, 기존 `imageUrls`는 하위 호환 또는 점진 제거 전략이 필요하다.
- 각 미디어 항목은 최소한 아래 필드를 가진다.
  - `type`: `image` | `video`
  - `url`
  - `thumbnailUrl`: 영상일 때 필수 여부를 정책으로 결정
  - `durationMs`: 영상일 때 선택
  - `sortOrder`
- 업로드 방식은 현재 사진처럼 presigned URL 기반을 유지하는 편이 가장 작다.
- 영상은 업로드 직후 서버에서 H.264/AAC MP4로 변환하고 `processed` 객체 URL을 리뷰에 저장한다.
- 영상은 사진보다 용량이 크므로 파일 크기 제한, 허용 확장자, 허용 MIME 타입을 별도로 정의해야 한다.
- 썸네일은
  - 클라이언트 생성 후 같이 업로드하거나
  - 서버/후처리에서 생성하거나
  - 1차에서는 영상 플레이스홀더 이미지를 사용한다.
- 1차 구현은 복잡도를 낮추기 위해 "클라이언트가 대표 프레임 썸네일 생성 후 함께 업로드" 또는 "플레이스홀더 썸네일 사용" 중 하나를 선택해야 한다.

## 제안 방향

- 첨부 규칙은 "최대 5개" 하나로 단순화한다.
- UI에서는 사진과 영상을 섞어 보여주되, 각 항목에 타입 배지와 재생 표시를 둔다.
- 1차에서는 영상 길이를 짧은 클립 중심으로 제한한다.
  - 예: 최대 30초
- 1차에서는 허용 포맷을 모바일/웹 공통 분모로 좁힌다.
  - 예: `image/jpeg`, `image/png`, `image/webp`, `video/mp4`, `video/quicktime`
- 전체 화면 영상은 `muted + playsInline` 조건으로 자동재생한다.
- 1차에서는 리뷰 정렬/평점/랭킹 로직은 바꾸지 않고 첨부 UX와 저장 모델만 확장한다.

## 현재 운영 영상 흐름

아래 흐름은 영상 재생을 위한 설계 불변조건이다. 임의로 단계를 생략하거나 전달 방식을 바꾸지 않는다.

1. 프론트가 presigned PUT URL을 발급받아 원본 영상을 S3 `review-images/<user-id>/...`에 업로드한다.
2. 프론트가 영상 처리 API를 호출한다.
3. 백엔드가 원본을 H.264/AAC MP4로 변환하고 `review-images/<user-id>/processed/media-job-....mp4`에 저장한다.
4. 리뷰 DB의 `media_items_json`에는 원본이 아닌 `processed` 객체 URL을 저장한다.
5. 조회 API는 raw S3 URL을 그대로 노출하지 않고 `/api/cafemap/assets/media?src=...` URL로 변환한다.
6. media endpoint는 객체 권한을 검증한 뒤 presigned S3 GET URL로 redirect한다.
7. 실제 영상 바이트와 Range 요청은 S3가 직접 처리한다.

### 반드시 지킬 점

- media endpoint에서 Python/FastAPI가 영상 바이트를 직접 `StreamingResponse`로 중계하지 않는다.
- iPhone Chrome도 Safari와 같은 WebKit을 사용한다. 백엔드 직접 스트리밍은 데스크톱에서 동작해도 iPhone에서 첫 프레임 후 검은 화면이 될 수 있다.
- 최종 S3 응답이 `Accept-Ranges: bytes`를 제공하고 Range 요청에 `206 Partial Content`와 올바른 `Content-Range`를 반환해야 한다.
- Flutter Web의 `video_player_web`은 직접 의존성으로 유지한다. generated web plugin registrant에 `VideoPlayerPlugin.registerWith(registrar)`가 없으면 `UnimplementedError: init() has not been implemented`가 발생한다.
- iOS WebKit 자동재생을 위해 재생 전 `setVolume(0)`을 호출하고 `playsInline` 동작을 유지한다.
- 기존 `processed` 경로를 원본 URL로 되돌리면 HEVC/HDR 원본이 저장될 수 있어 브라우저 호환성이 깨진다.

### 회귀 검증

- 데스크톱 Chrome과 실제 iPhone Chrome/Safari에서 같은 영상을 재생한다.
- API media URL이 `307`로 presigned S3 URL을 반환하는지 확인한다.
- redirect를 따라 `Range: bytes=0-1023` 요청 시 최종 S3 응답이 `206`인지 확인한다.
- 신규 업로드 후 DB URL이 `/processed/media-job-....mp4`인지 확인한다.
- `flutter clean && flutter pub get && flutter build web --release` 후 generated registrant에 `VideoPlayerPlugin.registerWith`가 포함되는지 확인한다.

## 주요 결정 필요 사항

- 응답 계약을 `imageUrls` 유지 + `mediaItems` 추가로 갈지, `mediaItems`로 통합할지
- 영상 썸네일을 클라이언트 생성으로 갈지, 서버 생성으로 갈지
- 영상 최대 길이와 최대 파일 크기
- 웹에서의 파일 선택 UX를 단일 선택기로 갈지, 사진/영상 분리 액션으로 갈지
- 기존 리뷰 데이터 마이그레이션을 할지, 조회 시 변환만 할지

## 사용자 스토리 파일

- `review-media-upload-us01-media-contract-and-rules.md`
- `review-media-upload-us02-review-write-ui-and-picker.md`
- `review-media-upload-us03-review-edit-existing-media.md`
- `review-media-upload-us04-upload-api-and-validation.md`
- `review-media-upload-us05-review-read-model-and-rendering.md`
- `review-media-upload-us06-verification-and-rollout.md`

## 완료 기준

- 리뷰 작성 화면에서 사진/영상 혼합 첨부가 가능하다.
- 첨부 제한은 사진/영상 합산 최대 5개로 일관되게 동작한다.
- 리뷰 생성/수정 API가 혼합 미디어 payload를 검증하고 저장한다.
- 리뷰 조회 응답에서 각 항목의 미디어 타입을 구분할 수 있다.
- 수정 화면에서 기존 미디어 삭제 및 신규 미디어 추가를 함께 처리할 수 있다.
- 허용되지 않은 타입, 길이, 용량, 개수 초과에 대해 사용자 친화적 오류가 나온다.
- 최소 검증으로 프론트 `flutter analyze`와 백엔드 리뷰 API 테스트/검증이 통과한다.
