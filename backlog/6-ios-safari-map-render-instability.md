# 6. iPhone Safari 맵 렌더링 불안정

## 문제 요약
- 2026-05-06 기준, iPhone Safari에서 `/map` 진입 시 지도가 보이지 않는 현상이 있었다.
- 같은 시점에 iPad에서는 지도가 정상 노출됐다.
- 네트워크 관찰상 `https://oapi.map.naver.com/openapi/v3/maps.js?ncpKeyId=...` 요청 자체는 로드되는 경우가 확인됐다.
- 따라서 단순 `maps.js` 미로딩보다는 iPhone Safari 전용 초기화 타이밍, DOM 크기, 또는 캐시/리로드 영향 가능성이 더 높다.

## 관찰 기록
- `/map` 라우팅 자체가 안 되는지부터 의심했으나, 이후 확인 흐름상 라우팅만의 문제로 보이진 않았다.
- 초기에 `maps.js`가 안 보이는 것처럼 보였지만, 다시 확인했을 때는 해당 스크립트가 실제로 로드되고 있었다.
- 아이패드에서는 같은 배포본으로 지도가 보였고, 아이폰에서만 증상이 나타났다.
- 로그 확인을 위해 아래 파일에 디버그 로그만 추가했다.
  - [front/lib/main.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/main.dart)
  - [front/lib/app/router.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/app/router.dart)
  - [front/lib/presentation/pages/main_shell.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/presentation/pages/main_shell.dart)
- 이후 2026-05-06에 프런트 재배포를 수행한 뒤, 사용자가 다시 확인했을 때 아이폰에서도 지도가 갑자기 노출됐다.

## 이번 배포에서 실제로 바뀐 것
- `/map` 라우트 진입 로그 추가
- 하단 탭에서 `/map`으로 이동하는 로그 추가
- 앱 부트스트랩 시 `NAVER_MAP_CLIENT_ID` 존재 여부 로그 강화
- 중요:
  - `MapHomePage`
  - `naver_map_view_web.dart`
  - `flutter_naver_map_web`
  의 실제 지도 렌더링 로직은 수정하지 않았다.

## "갑자기 보이기 시작한" 시점 해석
- 이번 변경으로 지도가 고쳐졌다고 단정할 수 없다.
- 가능성이 높은 해석:
  - 재배포로 `main.dart.js`가 새로 배포되며 Safari가 앱 자산을 다시 로드했다.
  - iPhone Safari에서 캐시된 번들/서비스워커/초기화 타이밍이 바뀌며 우연히 정상 경로를 탔다.
  - 지도 컨테이너 크기 또는 DOM 준비 타이밍이 재현 시점마다 달라지는 불안정 이슈일 수 있다.
- 즉, 현재 상태는 "해결"이 아니라 "재현이 멈춘 상태"로 취급해야 한다.

## 현재 1순위 가설
- `flutter_naver_map_web` 내부는 DOM 요소의 `getBoundingClientRect()` 값을 보고 `width > 0 && height > 0`일 때만 지도 초기화를 진행한다.
- iPhone Safari에서만 지도 컨테이너 크기가 초기 순간 0 또는 비정상 값으로 잡히면 초기화가 건너뛰어질 수 있다.
- 대체 가설:
  - Safari 캐시/서비스워커 영향
  - `onMapReady` 이전 단계에서의 레이스 컨디션
  - iPhone Safari 전용 WebView/viewport 처리 차이

## 다음 재현 시 우선 확인할 로그
- `MapHomePage` 진입 로그
- `buildNaverMapView` 호출 시점의 좌표/마커 수
- `onMapReady` 호출 여부
- 첫 viewport 계산 여부
- 웹 맵 DOM 요소의 width/height
- iPhone Safari에서 새로고침 직후와 탭 이동 후의 차이

## 후속 작업 제안
- [ ] `MapHomePage`와 [naver_map_view_web.dart](/Users/eldorado/WorkSpace/cafemap/front/lib/presentation/widgets/naver_map_view_web.dart)에 단계별 로그를 추가한다.
- [ ] iPhone Safari에서 첫 진입, 새로고침, 탭 재진입 케이스를 분리해 재현 패턴을 기록한다.
- [ ] DOM 크기 0 이슈가 확인되면 지도 마운트 재시도 또는 레이아웃 안정화 처리를 추가한다.
- [ ] 캐시 영향이 의심되면 서비스워커/정적 자산 캐시 정책을 점검한다.
- [ ] 필요 시 `flutter_naver_map_web` 패키지 포크 또는 대체 렌더링 전략을 검토한다.

## 수용조건
- iPhone Safari에서 `/map` 첫 진입 시 지도가 안정적으로 노출된다.
- 동일 기기에서 새로고침 후에도 재현 없이 지도가 노출된다.
- 하단 탭으로 다른 화면을 오간 뒤 다시 `/map`에 와도 노출이 유지된다.
- "왜 갑자기 보였다가 안 보이는지"를 로그나 재현 절차로 설명할 수 있다.

## 메모
- 이번 기록의 핵심은 "로그 추가 후 재배포하니 갑자기 보였다"는 사실 자체를 남기는 것이다.
- 다만 이번 배포는 렌더링 수정이 아니라 로그 추가였으므로, 이 현상을 실제 수정 효과로 오해하면 안 된다.
