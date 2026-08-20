# DR-003 — 저장소의 도메인 매핑 소유

상태: 승인됨

## 맥락

Factory는 YAML 같은 외부 소스에서 구성을 읽는다.

구체적인 데이터 접근을 구현하기 전에 일관된 책임 경계가 필요하다.

## 결정

Repository는 raw data를 domain model로 매핑할 책임이 있다.

Data Source는 raw data를 가져오는 일만 담당한다.

책임은 다음과 같이 분리한다.

### 데이터 원천

- raw data를 읽는다
- `Map<String, dynamic>`을 반환한다
- domain model을 알지 않는다
- 어떤 저장 방식도 지원할 수 있다

### 저장소

- Data Source로부터 raw data를 받는다
- raw data를 domain model로 변환한다
- 상위 계층에 domain model을 노출한다

## 이유

이 분리는 저장 관심사를 domain 관심사와 독립적으로 유지한다.

저장 형식이 바뀌어도 domain 계층에 영향을 주지 않아야 한다.

domain 매핑은 한곳에 집중된다.

여러 Data Source가 같은 Repository 구현을 공유할 수 있다.

## 결과

### 이점

- 책임 경계가 명확하다
- 저장 기술에 독립적이다
- 테스트가 쉬워진다
- Data Source를 재사용할 수 있다
- Factory 모듈 전반에서 일관된 구조를 유지한다

### 트레이드오프

- Repository가 매핑 작업을 수행한다
- 추상화 계층이 하나 추가된다

## 적용 범위

이 결정은 다음을 포함한 모든 Factory 모듈에 적용한다.

- Manifest
- Template
- Toolchain
- Settings
- Plugin
- 향후 모듈

## 관련

- `Docs/ARCHITECTURE.md`
- CORE-003
- CORE-004
