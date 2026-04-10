# 백엔드 아키텍처 리뷰

## 목표

- 현재 `back/` 구조가 어떤 아키텍처 성격을 가지는지 파악한다.
- 레이어 분리, 객체지향 구조, FastAPI 백엔드 설계 적용 정도를 판단한다.
- 유지보수성, 역할 분리, 코드 가독성 측면의 강점과 약점을 정리한다.
- 필요한 경우 `memory/backend.md`에 백엔드 설계 및 코드스타일 규약을 추가한다.

## 작업 단위

### BAR1. 구조 파악

- `back/cafemap` 패키지 구조 확인
- `api`, `services`, `repositories`, `models`, `schemas`, `db`, `core` 책임 구분 확인

### BAR2. 요청 흐름 파악

- route에서 service와 repository를 어떻게 사용하는지 확인
- DB 세션과 schema/model 흐름을 확인

### BAR3. 아키텍처 판단

- layered architecture 성격 판단
- 객체지향 요소와 역할 분리 정도 판단
- 설계 패턴 적용 정도 판단

### BAR4. 유지보수성 판단

- 대형 파일, 책임 혼합, 스크립트와 앱 코드 혼재 여부 확인
- 주석 및 읽기 쉬운 구조 기준 충족 여부 확인

### BAR5. 규약 보강

- 필요 시 `memory/backend.md`에 설계 및 코드스타일 규약 추가

## 완료 기준

- 현재 백엔드 구조를 설명할 수 있다.
- 레이어 구조와 한계를 구분해서 말할 수 있다.
- 유지보수 규약이 부족하면 `memory/backend.md`에 반영되어 있다.
