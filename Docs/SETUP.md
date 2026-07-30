# SETUP.md

> Factory 개발, 실행과 생성 결과 검증을 위한 환경 경계
> Environment boundaries for Factory development, execution, and generated-result verification

## Principles

- 실행 전에 현재 환경과 Repository 상태를 확인한다
- Inspect the current environment and Repository state before execution
- 특정 IDE를 필수 조건으로 만들지 않는다
- Do not make a specific IDE a requirement
- 이미 정상인 도구나 시스템 설정을 불필요하게 변경하지 않는다
- Do not unnecessarily change working tools or system settings
- 로그인, 라이선스, 관리자 권한 또는 서명 관련 조치는 User 승인이 필요할 수 있다
- Login, licensing, administrator privileges, or signing-related actions may require User approval
- 인증정보나 비밀정보를 Repository에 기록하지 않는다
- Do not record credentials or secrets in a Repository

## Factory Development Environment

Factory source를 검토하고 구현하려면 Repository가 요구하는 Dart 환경과 dependency를 사용할 수 있어야 한다.

Reviewing and implementing Factory source requires access to the Dart environment and dependencies required by the Repository.

Factory 구현 검증은 해당 Agreement에서 승인된 분석과 테스트 범위만 수행한다.

Factory implementation verification performs only the analysis and test scope approved by the relevant Agreement.

## Factory Execution Prerequisites

Executable V1을 실행하기 전에 다음 상태를 확인한다.

Confirm the following before running Executable V1.

- Git을 사용할 수 있음
- Git is available
- 공식 Flutter toolchain과 iOS 및 Android platform toolchain을 사용할 수 있음
- The official Flutter toolchain and iOS and Android platform toolchains are available
- 승인된 V1 입력과 안전한 output path가 제공됨
- Approved V1 inputs and a safe output path are provided
- 필요한 파일 시스템 권한이 있음
- Required file-system permissions are available

필수 환경을 확인할 수 없으면 Bootstrap을 진행하지 않는다. 상세 중단 조건은 `Docs/ARCHITECTURE.md`가 소유한다.

Do not continue Bootstrap when a required environment cannot be verified. `Docs/ARCHITECTURE.md` owns the detailed stop conditions.

## Generated Product Verification Environment

생성된 Product는 Flutter 기본 dependency 준비, 정적 분석, 기본 테스트, Android APK build와 iOS Simulator build를 수행할 수 있는 환경에서 검증한다.

Verify the generated Product in an environment that can prepare default Flutter dependencies, run static analysis and default tests, and build an Android APK and an iOS Simulator target.

필수 검증을 환경 또는 toolchain 문제로 수행할 수 없으면 Ready로 판정하지 않고 확인된 상태와 필요한 User 조치를 보고한다.

When an environment or toolchain issue prevents required verification, do not judge the Product as Ready; report the confirmed state and required User action.

## Responsibility Boundary

- Factory 환경 준비는 Factory source와 runtime 검증을 지원한다
- Factory environment preparation supports Factory source and runtime verification
- Factory 실행 환경은 Bootstrap을 수행한다
- The Factory execution environment performs Bootstrap
- 생성된 Product의 검증 환경은 Bootstrap 결과만 검증하며 Product 기능을 결정하지 않는다
- The generated Product verification environment verifies only the Bootstrap result and does not decide Product features
