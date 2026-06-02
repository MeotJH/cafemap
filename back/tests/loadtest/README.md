# CafeMap Load Test

이 폴더는 CafeMap 백엔드의 공개 read API를 대상으로 하는 기본 Locust 부하 테스트 세트입니다.

## 목적

- 공개 조회 endpoint의 응답시간, 에러율, 처리량을 빠르게 본다.
- 운영 전에 병목이 되는 read API를 먼저 찾는다.
- write API를 건드리지 않고 안전하게 읽기 부하만 확인한다.

## 설치

가장 안전한 방식은 load test 전용 가상환경을 따로 쓰는 것입니다.
Locust는 일부 HTTP 의존성 버전을 별도로 요구할 수 있어서, 메인 백엔드 개발 venv와 분리하는 편이 안전합니다.

### 권장: 전용 가상환경

```powershell
cd back
python -m venv .venv-loadtest
.\.venv-loadtest\Scripts\python -m pip install -r tests\loadtest\requirements.txt
```

### 대안: 기존 백엔드 가상환경

간단히 확인만 할 때는 기존 백엔드 venv에도 설치할 수 있습니다.
다만 이 경우 Locust 의존성 때문에 `requests` 같은 패키지 버전이 바뀔 수 있습니다.

```powershell
cd back
.\venv\Scripts\python -m pip install -r tests\loadtest\requirements.txt
```

## 실행

로컬 서버가 `http://127.0.0.1:8000` 에 떠 있다고 가정:

```powershell
cd back
.\.venv-loadtest\Scripts\python -m locust -f tests\loadtest\locustfile.py --host http://127.0.0.1:8000
```

웹 UI:

- `http://localhost:8089`

처음 권장값:

- Users: `10`
- Spawn rate: `2`

그 다음 순서:

1. `10 users`
2. `30 users`
3. `50 users`
4. `100 users`

## 세부 endpoint 활성화

기본 시나리오는 공개 목록 API를 바로 호출합니다.
스토어 상세/리뷰/랭킹 상세는 실제 ID를 환경 변수로 주면 함께 호출합니다.

```powershell
$env:CAFEMAP_LOADTEST_STORE_ID="store_123"
$env:CAFEMAP_LOADTEST_RANKING_ID="ranking_123"
.\.venv-loadtest\Scripts\python -m locust -f tests\loadtest\locustfile.py --host http://127.0.0.1:8000
```

## headless 실행 예시

CLI로 바로 실행할 수도 있습니다.

```powershell
.\.venv-loadtest\Scripts\python -m locust `
  -f tests\loadtest\locustfile.py `
  --host http://127.0.0.1:8000 `
  --headless `
  --users 30 `
  --spawn-rate 5 `
  --run-time 3m
```

## 처음 볼 지표

- `Median response time`
- `95% percentile`
- `Requests/s`
- `Failures`

해석 기준 예시:

- `95%ile < 500ms`: 양호
- `95%ile 1s 이상`: 병목 후보
- `Failures > 1%`: 우선 로그/DB/외부 의존성 확인

## 주의사항

- 처음부터 운영 서버에 바로 치지 말고 로컬이나 staging에서 시작합니다.
- write API는 넣지 않습니다.
- 결과는 응답시간만 보지 말고 서버 CPU, 메모리, DB 상태, 컨테이너 로그와 같이 봅니다.
- 현재 구조에서 병목 후보는 `store detail`, `store reviews`, `visit-media`, `thumbnail` 같은 응답 조립/외부 I/O 구간입니다.
