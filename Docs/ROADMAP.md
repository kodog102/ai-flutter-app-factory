# ROADMAP.md

> Factory V1 작업 순서와 현재 상태

## 현재 기반

- Factory 목적, 역할, Repository 경계와 Operational Bootstrap Contract가 정의되어 있다
- Approved Operational Baseline Handoff lifecycle이 정의되어 있다
- 현재 runtime은 검증된 Executable Flutter V1 계약을 구현하며 User가 V1 Ready를 승인했다. Release는 별도 승인을 기다린다

## 1. V1 단일 기준 정보원 정렬

상태: **완료**

### 목표

- 기존 SSOT를 승인된 Executable Flutter V1 범위와 정렬한다

### 종료 기준

- Flutter 모바일 iOS/Android 경계와 Factory/Product 책임이 기존 Authority에서 일치한다

## 2. 입력 수집과 안전 사전 점검

상태: **완료**

### 목표

- 승인된 V1 입력을 검증하고 미지원·불충분·충돌 요청을 안전하게 중단한다

검증된 intake와 read-only preflight가 구현되어 있다.

## 3. Flutter 기본 구조와 저장소 경계

상태: **완료**

### 목표

- 독립 Repository 경계와 iOS/Android Flutter 기본 구조를 준비한다

New Repository와 Existing Empty Repository mode가 검증되었다.

## 4. 제품 내부 권한과 제안

상태: **완료**

### 목표

- Product-local Authority, First Agreement Proposal과 Baseline Handoff Proposal을 준비한다

Product-local README, AGENTS와 두 proposal이 검증되었다.

## 5. 자동 검증

상태: **완료**

### 목표

- Factory와 생성 결과의 필수 분석, 테스트와 빌드 검증을 자동으로 판정한다

Dependency 준비, analyze, test, Android APK와 iOS Simulator build가 자동 검증된다.

## 6. 제품 간 전체 흐름 검증

상태: **완료**

### 목표

- 서로 다른 Product 분야에서 같은 V1 계약을 검증한다

서로 다른 Product 분야와 Repository mode에서 반복 가능성과 격리가 검증되었다.

단일 Product 결과는 자동으로 Core Standard가 되지 않는다.

## 7. V1 준비 완료와 출시 결정

상태: **완료**

V1 준비 완료: **승인됨**

출시: **V1.2.1 출시됨**

### 목표

- Evidence를 바탕으로 User가 V1 Ready 및 release 여부를 최종 승인한다

Flutter V1 Ready는 전체 기술 검증과 독립 QA 이후 User가 승인했다. V1.2.1 version, tag와 공개 Release가 완료됐다.

CLI, Template engine 또는 orchestration 기능은 검증된 필요가 생기기 전까지 V1 필수 조건이 아니다.

## 8. V1.1 한 번 실행 제품 Bootstrap

상태: **완료**

### 목표

- 엄격한 `product_request.yaml` 하나와 한 명령으로 기존 Runtime의 검증된 Flutter Product 시작점을 준비한다

엄격한 `product_request.yaml`과 한 명령을 사용하는 Bootstrap이 구현됐으며 실제 Flutter Product 생성으로 검증됐다. V1.1은 V1 Ready 승인을 보존했으며 V1.2.1 Release는 이후 완료됐다. V1.1은 Product 기능 또는 V1.2 Product Loop를 구현하지 않는다.

## 9. V1.2 제품 루프 보호

상태: **완료 — 사용자 승인**

### 목표

- Bootstrap 이후 Product Agreement의 기준선, Flutter Health Gate, QA candidate와 Product Context drift 검사를 안전하게 통제한다

### 검증된 계약 범위

- Product 작업 시작 기준선과 QA candidate 기준선을 분리한다
- QA candidate 이후 상태가 바뀌면 중단하고 새 candidate로 다시 검증한다
- 기본 format, analyze와 전체 test를 실행하고 영향 범위에 따라 Android 및 iOS build를 추가한다
- milestone 종료 전 기존 Product SSOT와 실제 상태의 drift를 확인한다
- QA PASS와 User 승인 및 Git 작업을 분리한다

이 단계는 승인된 운영 계약과 공개 Dart Runtime foundation을 구현한다. Agent Adapter, Provider 연동, orchestration과 Product 기능 구현은 포함하지 않는다.

오늘리듬 Flutter Product에서 승인 기준선 검사, 기본 Health Gate, Android·iOS build, candidate와 Factory 불변성 및 독립 QA가 통과했다. 실기기 사용은 User가 제공한 수동 검증 Evidence로 승인됐다.

## 10. V1.2.1 제품 루프 운영 명령

상태: **완료 — 사용자 승인**

### 목표

- 기존 V1.2 공개 Runtime을 비개발자와 AI 작업 주체가 사용할 수 있는 단일 command surface로 제공한다
- User 승인과 외부 Product 구현 경계를 보존하는 `capture`와 `validate` 단계를 제공한다
- 승인된 기준선을 영속 JSON과 SHA-256 Evidence로 전달한다

이 단계는 Product 기능 구현, QA 자동 승인, Provider 연동, commit 또는 push를 포함하지 않는다.

## 11. V1.2 소비자 준비 상태 검증

상태: **완료 — 사용자 승인**

### 목표

- Factory 개발 대화가 없는 새 작업 주체가 공개 문서만으로 V1.2 운영 경계를 이해하고 실행할 수 있는지 검증한다
- 새 Repository, 기존 빈 Repository와 잘못된 Evidence 경계 복구를 독립 시나리오로 확인한다
- Product 구현, User 승인, QA와 Git 작업의 분리를 유지한다

초기 검증에서 기존 빈 Repository의 필수 정책 입력이 공개 사용설명서에 부족함을 확인했다. 기존 SSOT 한 파일을 최소 수정한 뒤 fresh-context 재실행과 독립 QA가 통과했다. Runtime 변경 없이 Consumer Guide blocker가 해소됐으며 V1.2 Consumer Ready 상태를 User가 승인했다.

## 12. 적응형 실행 정책 승격

상태: **완료 — 사용자 승인**

### 목표

- Product 작업의 위험도에 따라 역할, Agent Instances, QA와 검증 범위를 조절한다
- 기술 품질을 유지하면서 작은 작업의 과잉 QA, 전체 검증 반복과 환경 재시도를 줄인다

### 검증된 증거

- 여러 Product의 Low 산출물 생성 작업에서 High 분류와 독립 QA가 반복적으로 과도했음
- Medium 기능 작업은 제한된 Context Pack과 독립 QA 1회로 안정적으로 완료됨
- 네이티브 알림과 플랫폼 경계 작업에서는 High 분류와 독립 QA가 실제 중요 결함을 발견함
- Simulator 재시도 한도는 환경 장애에 대한 무기한 우회를 방지함

검증된 결과를 Low·Medium·High 분류, Agent Instances 상한, Context Pack, Verification Ladder, Evidence 재사용, 환경 재시도 예산과 분리된 품질·효율 판정으로 기존 SSOT에 반영했다. 특정 Provider, 모델 또는 IDE는 Core 정책에 포함하지 않는다. Product Loop Runtime 동작은 이 문서 정책 승격에서 변경하지 않는다.

## 13. 실행 프로필 잠금과 편차 관문

상태: **완료 — 사용자 승인**

### 목표

- 수정된 Agreement가 최종 통합본과 Execution Profile을 다시 승인한 뒤에만 실행되도록 고정한다
- 승인된 역할, 독립 QA, 검증, Repair와 환경 예산에서 임의로 벗어나는 실행을 중단한다

### 제공된 계약

- 최종 통합 Agreement와 Execution Profile 승인 규칙, Approved-vs-Planned 사전 Gate와 Runtime Deviation Gate를 기존 SSOT와 생성 Product `AGENTS.md`에 반영한다
- Medium·High 독립 QA의 별도 instance 또는 새 문맥, 독립 실행 주체 생성 불가 시 중단, Repair Delta와 Approved-vs-Actual 결과 보고를 요구한다
- 환경 검증을 최초 1회, 원인이 명확한 재시도 1회 및 기본 10–15분으로 제한하고 예산 소진 후 우회를 금지한다

이 정책 보강은 특정 Provider, 모델 또는 IDE를 전제하지 않으며 Product Loop Runtime schema나 동작을 변경하지 않는다.

## 14. 직접 승인 작업 경계

상태: **완료 — 사용자 승인**

### 목표

- 실기기 설치, 서명, 외부 업로드, Release와 같은 직접 승인 작업이 User 승인을 직접 확인할 수 있는 실행 주체에서만 수행되도록 한다
- 서브에이전트의 승인 가시성 차이로 인한 반복 중단과 임의 우회를 방지한다

### 제공된 계약

- Agreement에서 Direct Approval Actions와 Direct Executor를 명시하며, 해당 작업이 없으면 `None`으로 기록한다
- 실제 실행 주체가 승인된 Direct Executor와 다르면 작업 전에 Profile Delta 승인을 요구한다
- User 승인 메시지를 직접 확인할 수 없는 하위 실행 주체는 준비, 진단, 구현 또는 QA만 수행한다

이 경계는 특정 Provider, 모델 또는 IDE에 의존하지 않으며 자동 승인 권한을 만들지 않는다.

## 15. 현재 확인된 공백

상태: **활성 기준선 — 2026-08-20**

### 검증된 기준선

- Factory 기준점은 동기화된 `main@2f7f76593e98baacc4bc841e5696fc9694690e0f`이며 공개 Release는 `v1.2.2`다
- P0 CI Compatibility Recovery는 GitHub Actions run `32333512924`가 `main@203066f`에서 green인 Evidence와 함께 완료됐다
- 일반 테스트는 185개 통과했고 실제 환경 통합 테스트 14개는 opt-in 조건으로 생략됐다
- 이전 원격 CI 기준점 `d31cecd`는 Dart 3.13에서 두 개의 `unawaited_return_in_try_block` 분석 경고로 실패했으나 P0에서 해결됐다
  - `lib/core/bootstrap/bootstrap_executor.dart:1722`
  - `lib/core/product_loop/factory_product_loop_command.dart:89`

### 확인된 문제

1. 실제 Git·Flutter 통합 테스트가 기본 CI에서 실행되지 않아 로컬 증거에 의존한다.
2. Adaptive Execution Policy와 Execution Profile Lock은 문서와 생성 Product Authority에는 반영됐지만 모든 실행 경계에서 구조화된 runtime 검증으로 강제되지는 않는다.
3. 기존 Product의 `AGENTS.md` 편차를 자동 동기화하는 경로는 없으며, 읽기 전용 감사 결과의 적용은 별도 승인된 Agreement가 필요하다.
4. 현재 진입 명령과 입력 준비는 비개발자에게 여전히 개발 도구 중심이다.
5. 대형 실행 파일과 장문 Authority, 사용 여부가 불명확한 legacy template·generator·metadata가 유지보수 비용과 권한 혼동을 만든다.

## 16. Flutter 팩토리 완성 계획

상태: **진행 중 — P6-2 의존성과 자동화 공급망 검토 준비**

### P0 — CI 호환성 복구

상태: **완료**

목표:

- 현재 stable Dart 환경에서 발생하는 두 분석 경고를 동작 변경 없이 해결하고 공개 CI 신뢰를 복구한다

종료 기준:

- Repository format, analyze와 일반 테스트가 현재 stable toolchain에서 통과한다
- GitHub Actions의 동일 검증이 green이다
- Bootstrap과 Product Loop 동작 회귀가 없으며 승인된 파일만 변경된다

증거:

- GitHub Actions run `32333512924`는 `main@203066f`에서 green이다

### P1 — V1.2.2 단일 기준 정보원과 출시 마감

상태: **완료 — 사용자 승인**

목표:

- 완료 정책, version metadata, README, Roadmap, tag와 공개 Release를 하나의 승인 기준점으로 정렬한다

종료 기준:

- V1.2.2 문서·version·tag·Release가 동일 commit을 가리킨다
- Adaptive Execution, Execution Profile Lock와 Direct Approval Action 상태가 실제 Git 결과와 일치한다
- 공개 CI가 green이며 push, tag와 Release는 각각 명시적인 Direct Approval Action 승인을 받는다

출시 마감 증거:

- `v1.2.2` tag는 `2f7f76593e98baacc4bc841e5696fc9694690e0f`를 정확히 가리킨다
- [Flutter Factory v1.2.2 — Stabilization](https://github.com/kodog102/ai-flutter-app-factory/releases/tag/v1.2.2) 공개 Release는 draft와 prerelease가 아니며 `2026-08-20T05:04:01Z`에 게시됐다
- Candidate CI run `32334095801`은 같은 commit에서 33초 만에 green이었다
- V1.2.2 version, 문서, tag와 공개 Release의 기준점 차이가 해소됐다

### P2 — 실제 통합 CI

상태: **완료 — 사용자 승인**

목표:

- 빠른 기본 CI와 실제 Git·Flutter 통합 검증을 분리해 공개 Evidence로 남긴다

종료 기준:

- 기본 CI는 빠른 format·analyze·test 신호를 유지한다
- Bootstrap과 Product Loop 실제 통합 시나리오는 별도 자동 또는 수동 workflow에서 재현 가능하다
- 실패 원인, 실행 환경과 결과가 공개 실행 기록에 남고 비밀값은 노출되지 않는다

### 공개 검증 증거

- User가 `main@306b9fcb837bd3723dc775233c57b9367babaef6`의 P2 범위를 승인했으며 [GitHub Actions run 32364191119](https://github.com/kodog102/ai-flutter-app-factory/actions/runs/32364191119)는 전체 성공했다
- 전체 실행은 20m42s였고 8/8 matrix job이 green이었으며 opt-in 실제 통합 테스트 14개가 각각 한 번씩 실행됐다
- 작업별 실행 시간: Product Loop Guard 5m52s, Executor Cross-domain 10m17s, Executor Staged and Rollback 11m26s, Executor Existing and Tracked 13m58s
- 작업별 실행 시간: Executor Ownership and Hook 11m29s, Factory Product Loop Command 1m02s, Executor New Repository 5m51s, Factory Bootstrap Command 10m18s

P2와 P3 종료 기준이 충족됐다. P4와 P5도 사용자 승인과 커밋을 마쳤으며 P6-1은 구현 결과 승인과 커밋을 완료했다. P6-2 이후 단계의 진행 잠금은 유지한다.

### P3 — 제품 권한 감사

상태: **완료 — 사용자 승인**

목표:

- 기존 Product Authority의 누락과 편차를 변경 없이 진단하는 읽기 전용 경로를 제공한다

종료 기준:

- Product `AGENTS.md`의 계약 버전, 필수 항목과 알려진 편차를 구조화된 결과로 반환한다
- 진단은 Product와 Factory 파일을 수정하지 않으며 불명확한 상태에서 실패 폐쇄한다
- 기존 Product와 새 Bootstrap Product에서 독립 검증을 통과한다

구현 결과:

- `ProductAuthorityContract`가 권한 계약 버전 1과 필수 항목을 정의한다
- `ProductAuthorityAuditor`가 독립 Git Repository와 Product `AGENTS.md`를 변경 없이 검사한다
- 안전한 입력은 준수·편차 보고로, 신뢰할 수 없는 경계와 파일 상태는 구조화된 중단으로 반환한다
- 새 Bootstrap Product와 기존 Product를 대상으로 한 검증 후보를 제공한다
- User가 `main@e24b5d9572ee0b4553f64faa0f4a7b43f3da3244`의 P3 결과를 승인했다

### P4 — 실행 가능한 실행 프로필 검증

상태: **완료 — 사용자 승인**

목표:

- 승인된 실행 프로필과 계획·실제 실행의 편차를 공급자 비종속 구조로 검증한다

종료 기준:

- 필수 프로필 필드, 직접 승인 작업과 직접 실행 주체를 자료형 또는 구조화된 값으로 표현한다
- 승인 누락과 편차는 Product 변경 전에 결정적인 중단 결과를 반환한다
- 자동 승인, 자동 권한 확장 또는 Main 자기 QA를 허용하지 않는다

구현 결과:

- `ExecutionProfile`이 역할, 실행 주체, 문맥 묶음, 직접 승인 경계와 검증·환경 예산을 불변 값으로 표현한다
- `ExecutionProfileValidator`가 정규화된 제안 SHA-256, 승인 증거와 계획·실제 실행 편차를 구조화해 검사한다
- 승인 증거 누락, Main 자기 QA, 직접 실행 주체 오류와 예산 초과를 작업 실행 없이 중단한다
- 일치 결과는 사용자 승인, QA 통과 또는 Product 변경 권한을 자동 선언하지 않는다
- User가 `main@8fe35cd3b44df69f8814e9a1718fc4fc1790afdc`의 P4 결과를 승인했다

### P5 — 비개발자 사용성

상태: **완료 — 사용자 승인**

목표:

- 비개발자가 환경과 입력을 확인하고 예시 Flutter Product를 한 진입점에서 준비할 수 있게 한다

종료 기준:

- 읽기 전용 `doctor`, 요청 파일 준비 도움과 `dry-run` 결과를 제공한다
- 긴 개발 명령을 외우지 않아도 되는 짧고 문서화된 실행 경로가 있다
- 새 사용자가 공개 User Guide만으로 예시 Product를 준비하고 승인 지점과 중단 사유를 이해한다

구현 결과:

- 기존 `factory_bootstrap` 진입점에 환경 확인, 요청 예시 출력과 실행 전 검사 모드를 추가했다
- 환경 확인은 Factory Repository와 Dart, Flutter, Git, iOS 및 Android 도구를 변경 없이 검사하고 안전한 요약만 반환한다
- 요청 예시는 파일을 만들지 않고 표준 출력에만 표시하며 필수 자리표시는 직접 수정해야 하는 값으로 제공한다
- 실행 전 검사는 실제 실행과 같은 요청 해석 및 사전 검사를 재사용하지만 실행기를 호출하거나 Product와 Git을 변경하지 않는다
- 안내 모드의 성공을 `Ready` 또는 `Approved`로 표현하지 않고 기존 실제 실행 경로와 종료 의미를 유지한다
- User가 `main@0cfab7200437be4d8a22d5b8c4efc02d916a833f`의 P5 결과와 commit을 승인했다

### P6 — 보안과 복원력 강화

상태: **진행 중 — P6-1 완료, P6-2 준비**

목표:

- 경로, symlink, ownership, TOCTOU, 입력 공격과 dependency·CI 공급망 위험에 대한 방어를 강화한다

종료 기준:

- 승인된 위협 목록과 회귀 테스트가 존재하고 CI에서 검증된다
- cleanup과 rollback의 ownership 보존 규칙에 회귀가 없다
- dependency와 workflow 권한은 최소 권한 원칙으로 검토되고 기록된다

P6-1 구현 결과:

- 경로, 심볼릭 링크, 초기 staging, 실패한 외부 명령, 최종 소유권과 기존 Repository 복구 위협을 기존 방어 및 회귀 테스트와 연결했다
- 모든 staging 재귀 정리는 승인된 소유권 manifest와 정리 직전 manifest가 정확히 일치할 때만 수행하도록 단일 경로로 통합했다
- 초기 소유권 획득 전 외부 파일, 실패한 scaffold·검증 명령의 부분 변경과 설치 직전 심볼릭 링크 경쟁 조건을 실패 폐쇄로 검증한다
- 실제 Git·Flutter 환경에서 초기 staging 외부 파일 보존을 검증하는 통합 후보를 추가했다
- 운영체제 경로 API의 마지막 검사와 변경 사이에 남는 짧은 TOCTOU 창은 잔여 위험으로 유지한다
- 사용자가 `main@67e9e7f390d56f7b082ad8ec4255d4d7b7924fb4`의 P6-1 결과와 커밋을 승인했다
- 의존성과 자동화 최소 권한 검토는 P6-2 범위로 남긴다

### P7 — 구조와 이전 요소 마감

상태: **대기 — P6에 의해 차단됨**

목표:

- 검증 Evidence를 보존하면서 대형 executor를 책임별로 분리하고 legacy 자산의 권한과 존치 여부를 확정한다

종료 기준:

- characterization tests 이후에만 executor 구조를 변경하며 public API 호환성을 유지한다
- legacy template, generator와 metadata는 활성 경로로 복구되거나 승인 후 제거·격리된다
- 핵심 Authority가 중복 없이 더 짧게 탐색 가능하고 전체 검증이 통과한다

## 17. 버전 목표

- `V1.2.2 — Stabilization`: P0과 P1 완료
- `V1.3 — Executable Operating Policy`: P2, P3와 P4 완료
- `V1.4 — Accessible and Hardened Factory`: P5, P6와 P7 완료

## 18. 진행 잠금

- 고도화 작업은 `P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7` 순서로 수행한다
- 이전 단계의 Exit Criteria, 독립 QA, User 결과 승인과 commit이 완료되기 전에는 다음 단계를 시작하지 않는다
- 각 단계는 Agreement와 Execution Profile 승인 후 구현하며 push, tag, Release와 외부 게시 작업은 별도의 Direct Approval Action 승인을 요구한다
- 순서, 목표, 범위 또는 Exit Criteria를 변경하려면 최신 통합 Roadmap Delta를 제시하고 User 승인을 받는다
- 실패와 환경 차단은 Evidence로 기록하되 다음 단계로 건너뛰거나 우선순위를 자동 변경하지 않는다
- 미완료 단계를 Ready 또는 Released로 표현하지 않는다

현재 진행 중인 작업은 **P6-2 — 의존성과 자동화 공급망 검토** 하나뿐이다. 아직 구현은 시작하지 않았다.
