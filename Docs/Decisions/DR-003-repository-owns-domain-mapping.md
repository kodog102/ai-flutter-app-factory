# DR-003 — Repository Owns Domain Mapping

상태 / Status: Accepted

## 맥락 / Context

Factory는 YAML 같은 외부 소스에서 구성을 읽는다.

Future sources may include JSON, Remote Config, Database, or APIs.

구체적인 데이터 접근을 구현하기 전에 일관된 책임 경계가 필요하다.

A consistent responsibility boundary is required before implementing concrete data access.

## 결정 / Decision

Repository는 raw data를 domain model로 매핑할 책임이 있다.

The Repository is responsible for mapping raw data into domain models.

Data Source는 raw data를 가져오는 일만 담당한다.

The Data Source is responsible only for retrieving raw data.

책임은 다음과 같이 분리한다.

Responsibilities are separated as follows.

### Data Source

- raw data를 읽는다
- Read raw data
- `Map<String, dynamic>`을 반환한다
- Return `Map<String, dynamic>`
- domain model을 알지 않는다
- Know nothing about domain models
- 어떤 저장 방식도 지원할 수 있다
- Support any storage mechanism

### Repository

- Data Source로부터 raw data를 받는다
- Receive raw data from Data Source
- raw data를 domain model로 변환한다
- Convert raw data into domain models
- 상위 계층에 domain model을 노출한다
- Expose domain models to upper layers

## 이유 / Rationale

이 분리는 저장 관심사를 domain 관심사와 독립적으로 유지한다.

This separation keeps storage concerns independent from domain concerns.

저장 형식이 바뀌어도 domain 계층에 영향을 주지 않아야 한다.

Changing the storage format should not affect the domain layer.

domain 매핑은 한곳에 집중된다.

Domain mapping remains centralized in a single location.

여러 Data Source가 같은 Repository 구현을 공유할 수 있다.

This approach also allows multiple data sources to share the same repository implementation.

## 결과 / Consequences

### 이점 / Benefits

- 책임 경계가 명확하다
- Clear responsibility boundaries
- 저장 기술에 독립적이다
- Storage technology independence
- 테스트가 쉬워진다
- Easier testing
- Data Source를 재사용할 수 있다
- Reusable Data Sources
- Factory 모듈 전반에서 일관된 구조를 유지한다
- Consistent architecture across Factory modules

### 트레이드오프 / Trade-offs

- Repository가 매핑 작업을 수행한다
- Repository performs mapping work
- 추상화 계층이 하나 추가된다
- One additional abstraction layer

## 적용 범위 / Applies To

이 결정은 다음을 포함한 모든 Factory 모듈에 적용한다.

This decision applies to every Factory module including:

- Manifest
- Template
- Toolchain
- Settings
- Plugin
- Future modules

## 관련 / Related

- `Docs/ARCHITECTURE.md`
- CORE-003
- CORE-004
