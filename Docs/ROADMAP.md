# ROADMAP.md

> Factory V1 작업 순서와 현재 상태
> Factory V1 work sequence and current status

## Current Foundation

- Factory 목적, 역할, Repository 경계와 Operational Bootstrap Contract가 정의되어 있다
- The Factory purpose, roles, Repository boundary, and Operational Bootstrap Contract are defined
- Approved Operational Baseline Handoff lifecycle이 정의되어 있다
- The Approved Operational Baseline Handoff lifecycle is defined
- 현재 runtime은 검증된 Executable Flutter V1 계약을 구현하며 User가 V1 Ready를 승인했다. Release는 별도 승인을 기다린다
- The current runtime implements the verified Executable Flutter V1 contract, and the User has approved V1 readiness. Release awaits separate approval

## 1. V1 SSOT Alignment

Status: **Completed**

### Goal

- 기존 SSOT를 승인된 Executable Flutter V1 범위와 정렬한다
- Align the existing SSOT with the approved Executable Flutter V1 scope

### Exit Criteria

- Flutter 모바일 iOS/Android 경계와 Factory/Product 책임이 기존 Authority에서 일치한다
- The Flutter mobile iOS/Android boundary and Factory/Product responsibilities are consistent across existing authorities

## 2. Intake and Safe Preflight

Status: **Completed**

### Goal

- 승인된 V1 입력을 검증하고 미지원·불충분·충돌 요청을 안전하게 중단한다
- Validate approved V1 inputs and safely stop unsupported, insufficient, or conflicting requests

검증된 intake와 read-only preflight가 구현되어 있다.

Verified intake and read-only preflight are implemented.

## 3. Flutter Scaffold and Repository Boundary

Status: **Completed**

### Goal

- 독립 Repository 경계와 iOS/Android Flutter 기본 구조를 준비한다
- Prepare the independent Repository boundary and iOS/Android Flutter base structure

New Repository와 Existing Empty Repository mode가 검증되었다.

New Repository and Existing Empty Repository modes are verified.

## 4. Product-local Authority and Proposals

Status: **Completed**

### Goal

- Product-local Authority, First Agreement Proposal과 Baseline Handoff Proposal을 준비한다
- Prepare Product-local authority, the First Agreement Proposal, and the Baseline Handoff Proposal

Product-local README, AGENTS와 두 proposal이 검증되었다.

Product-local README, AGENTS, and both proposals are verified.

## 5. Automated Validation

Status: **Completed**

### Goal

- Factory와 생성 결과의 필수 분석, 테스트와 빌드 검증을 자동으로 판정한다
- Automatically evaluate the required analysis, tests, and build verification for the Factory and generated result

Dependency 준비, analyze, test, Android APK와 iOS Simulator build가 자동 검증된다.

Dependency preparation, analysis, tests, the Android APK build, and the iOS Simulator build are validated automatically.

## 6. End-to-End Cross-Product Validation

Status: **Completed**

### Goal

- 서로 다른 Product 분야에서 같은 V1 계약을 검증한다
- Validate the same V1 contract across different Product domains

서로 다른 Product 분야와 Repository mode에서 반복 가능성과 격리가 검증되었다.

Repeatability and isolation are verified across Product domains and Repository modes.

단일 Product 결과는 자동으로 Core Standard가 되지 않는다.

A result from one Product does not automatically become a Core Standard.

## 7. V1 Readiness and Release Decision

Status: **Completed**

V1 Ready: **Approved**

Release: **V1.2.1 Released**

### Goal

- Evidence를 바탕으로 User가 V1 Ready 및 release 여부를 최종 승인한다
- Enable the User to give final approval of V1 readiness and release based on Evidence

Flutter V1 Ready는 전체 기술 검증과 독립 QA 이후 User가 승인했다. V1.2.1 version, tag와 공개 Release가 완료됐다.

The User approved Flutter V1 Ready after full technical verification and independent QA. The V1.2.1 version, tag, and public Release are complete.

CLI, Template engine 또는 orchestration 기능은 검증된 필요가 생기기 전까지 V1 필수 조건이 아니다.

A CLI, Template engine, or orchestration capability is not a V1 requirement until a validated need exists.

## 8. V1.1 One-run Product Bootstrap

Status: **Completed**

### Goal

- 엄격한 `product_request.yaml` 하나와 한 명령으로 기존 Runtime의 검증된 Flutter Product 시작점을 준비한다
- Prepare a verified Flutter Product starting point through the existing Runtime using one strict `product_request.yaml` and one command

엄격한 `product_request.yaml`과 한 명령을 사용하는 Bootstrap이 구현됐으며 실제 Flutter Product 생성으로 검증됐다. V1.1은 V1 Ready 승인을 보존했으며 V1.2.1 Release는 이후 완료됐다. V1.1은 Product 기능 또는 V1.2 Product Loop를 구현하지 않는다.

Bootstrap using one strict `product_request.yaml` and one command is implemented and verified through actual Flutter Product creation. V1.1 preserved V1 Ready approval, and the V1.2.1 Release was completed later. V1.1 does not implement Product features or the V1.2 Product Loop.

## 9. V1.2 Product Loop Guard

Status: **Completed — User Approved**

### Goal

- Bootstrap 이후 Product Agreement의 기준선, Flutter Health Gate, QA candidate와 Product Context drift 검사를 안전하게 통제한다
- Safely govern the baseline, Flutter Health Gate, QA candidate, and Product Context drift check for Product Agreements after Bootstrap

### Validated Contract Scope

- Product 작업 시작 기준선과 QA candidate 기준선을 분리한다
- Separate the Product work-start baseline from the QA candidate baseline
- QA candidate 이후 상태가 바뀌면 중단하고 새 candidate로 다시 검증한다
- Stop and verify a new candidate when state changes after QA candidate capture
- 기본 format, analyze와 전체 test를 실행하고 영향 범위에 따라 Android 및 iOS build를 추가한다
- Run default format, analyze, and full tests, and add Android and iOS builds according to impact
- milestone 종료 전 기존 Product SSOT와 실제 상태의 drift를 확인한다
- Check drift between existing Product SSOT and actual state before milestone closure
- QA PASS와 User 승인 및 Git 작업을 분리한다
- Keep QA PASS separate from User approval and Git actions

이 단계는 승인된 운영 계약과 공개 Dart Runtime foundation을 구현한다. Agent Adapter, Provider 연동, orchestration과 Product 기능 구현은 포함하지 않는다.

This stage implements the approved operational contract and a public Dart Runtime foundation. It does not include an Agent Adapter, Provider integration, orchestration, or Product feature implementation.

오늘리듬 Flutter Product에서 승인 기준선 검사, 기본 Health Gate, Android·iOS build, candidate와 Factory 불변성 및 독립 QA가 통과했다. 실기기 사용은 User가 제공한 수동 검증 Evidence로 승인됐다.

The approved baseline inspection, default Health Gate, Android and iOS builds, candidate and Factory immutability, and independent QA passed on the OneulRhythm Flutter Product. Physical-device use was approved from User-provided manual verification Evidence.

## 10. V1.2.1 Product Loop Operator Command

Status: **Completed — User Approved**

### Goal

- 기존 V1.2 공개 Runtime을 비개발자와 AI 작업 주체가 사용할 수 있는 단일 command surface로 제공한다
- Expose the existing V1.2 public Runtime through one command surface usable by non-developers and AI work participants
- User 승인과 외부 Product 구현 경계를 보존하는 `capture`와 `validate` 단계를 제공한다
- Provide `capture` and `validate` phases that preserve User approval and external Product implementation boundaries
- 승인된 기준선을 영속 JSON과 SHA-256 Evidence로 전달한다
- Carry the approved baseline through persistent JSON and SHA-256 Evidence

이 단계는 Product 기능 구현, QA 자동 승인, Provider 연동, commit 또는 push를 포함하지 않는다.

This stage does not include Product feature implementation, automated QA approval, Provider integration, commit, or push.

## 11. V1.2 Consumer Readiness Validation

Status: **Completed — User Approved**

### Goal

- Factory 개발 대화가 없는 새 작업 주체가 공개 문서만으로 V1.2 운영 경계를 이해하고 실행할 수 있는지 검증한다
- Verify that fresh work participants without Factory development context can understand and operate the V1.2 boundaries using only public documentation
- 새 Repository, 기존 빈 Repository와 잘못된 Evidence 경계 복구를 독립 시나리오로 확인한다
- Validate New Repository, Existing Empty Repository, and invalid Evidence-boundary recovery as independent scenarios
- Product 구현, User 승인, QA와 Git 작업의 분리를 유지한다
- Preserve separation among Product implementation, User approval, QA, and Git actions

초기 검증에서 기존 빈 Repository의 필수 정책 입력이 공개 사용설명서에 부족함을 확인했다. 기존 SSOT 한 파일을 최소 수정한 뒤 fresh-context 재실행과 독립 QA가 통과했다. Runtime 변경 없이 Consumer Guide blocker가 해소됐으며 V1.2 Consumer Ready 상태를 User가 승인했다.

Initial validation found that the public user guide did not provide the required policy input for an Existing Empty Repository. After a minimal update to one existing SSOT file, a fresh-context rerun and independent QA passed. The Consumer Guide blocker was resolved without Runtime changes, and the User approved V1.2 Consumer Ready status.

## 12. Adaptive Execution Policy Promotion

Status: **Completed — User Approved**

### Goal

- Product 작업의 위험도에 따라 역할, Agent Instances, QA와 검증 범위를 조절한다
- Adjust Roles, Agent Instances, QA, and verification scope according to Product task risk
- 기술 품질을 유지하면서 작은 작업의 과잉 QA, 전체 검증 반복과 환경 재시도를 줄인다
- Preserve technical quality while reducing excessive QA, repeated full verification, and environment retries for small work

### Validated Evidence

- 여러 Product의 Low 산출물 생성 작업에서 High 분류와 독립 QA가 반복적으로 과도했음
- High classification and independent QA were repeatedly excessive for Low-risk artifact-generation work across Products
- Medium 기능 작업은 제한된 Context Pack과 독립 QA 1회로 안정적으로 완료됨
- Medium feature work completed reliably with a bounded Context Pack and one independent QA pass
- 네이티브 알림과 플랫폼 경계 작업에서는 High 분류와 독립 QA가 실제 중요 결함을 발견함
- High classification and independent QA found material defects in native notification and platform-boundary work
- Simulator 재시도 한도는 환경 장애에 대한 무기한 우회를 방지함
- Simulator retry limits prevented indefinite workarounds for environment failures

검증된 결과를 Low·Medium·High 분류, Agent Instances 상한, Context Pack, Verification Ladder, Evidence 재사용, 환경 재시도 예산과 분리된 품질·효율 판정으로 기존 SSOT에 반영했다. 특정 Provider, 모델 또는 IDE는 Core 정책에 포함하지 않는다. Product Loop Runtime 동작은 이 문서 정책 승격에서 변경하지 않는다.

The verified results are reflected in existing authorities as Low, Medium, and High classification, Agent Instance limits, Context Pack, Verification Ladder, Evidence reuse, environment retry budgets, and separate quality and efficiency verdicts. The Core policy does not include a specific Provider, model, or IDE. This documentation promotion does not change Product Loop Runtime behavior.

## 13. Execution Profile Lock & Deviation Gate

Status: **Completed — User Approved**

### Goal

- 수정된 Agreement가 최종 통합본과 Execution Profile을 다시 승인한 뒤에만 실행되도록 고정한다
- Lock execution so a revised Agreement runs only after the final consolidated version and Execution Profile are approved
- 승인된 역할, 독립 QA, 검증, Repair와 환경 예산에서 임의로 벗어나는 실행을 중단한다
- Stop execution that deviates without approval from Roles, independent QA, verification, Repair, or environment budgets

### Delivered Contract

- 최종 통합 Agreement와 Execution Profile 승인 규칙, Approved-vs-Planned 사전 Gate와 Runtime Deviation Gate를 기존 SSOT와 생성 Product `AGENTS.md`에 반영한다
- Reflect final consolidated Agreement and Execution Profile approval, the Approved-vs-Planned pre-execution Gate, and the Runtime Deviation Gate in existing SSOTs and generated Product `AGENTS.md`
- Medium·High 독립 QA의 별도 instance 또는 새 문맥, 독립 실행 주체 생성 불가 시 중단, Repair Delta와 Approved-vs-Actual 결과 보고를 요구한다
- Require a separate instance or fresh context for Medium and High independent QA, stopping when an independent runtime worker cannot be created, Repair Deltas, and an Approved-vs-Actual final report
- 환경 검증을 최초 1회, 원인이 명확한 재시도 1회 및 기본 10–15분으로 제한하고 예산 소진 후 우회를 금지한다
- Limit environment verification to one initial attempt, one retry with a clear cause, and a default 10–15 minutes, and prohibit workarounds after budget exhaustion

이 정책 보강은 특정 Provider, 모델 또는 IDE를 전제하지 않으며 Product Loop Runtime schema나 동작을 변경하지 않는다.

This policy reinforcement does not assume a specific Provider, model, or IDE and does not change Product Loop Runtime schema or behavior.

## 14. Direct Approval Action Boundary

Status: **Completed — User Approved**

### Goal

- 실기기 설치, 서명, 외부 업로드, Release와 같은 직접 승인 작업이 User 승인을 직접 확인할 수 있는 실행 주체에서만 수행되도록 한다
- Ensure that Direct Approval Actions such as physical-device installation, signing, external upload, and Release are performed only by a runtime worker that can directly verify User approval
- 서브에이전트의 승인 가시성 차이로 인한 반복 중단과 임의 우회를 방지한다
- Prevent repeated stops and unapproved workarounds caused by different approval visibility in downstream agents

### Delivered Contract

- Agreement에서 Direct Approval Actions와 Direct Executor를 명시하며, 해당 작업이 없으면 `None`으로 기록한다
- State Direct Approval Actions and the Direct Executor in the Agreement, or record `None` when no such action exists
- 실제 실행 주체가 승인된 Direct Executor와 다르면 작업 전에 Profile Delta 승인을 요구한다
- Require approval of a Profile Delta before action when the actual runtime worker differs from the approved Direct Executor
- User 승인 메시지를 직접 확인할 수 없는 하위 실행 주체는 준비, 진단, 구현 또는 QA만 수행한다
- Limit downstream workers that cannot directly verify the User approval message to preparation, diagnosis, implementation, or QA

이 경계는 특정 Provider, 모델 또는 IDE에 의존하지 않으며 자동 승인 권한을 만들지 않는다.

This boundary does not depend on a specific Provider, model, or IDE and does not create automatic approval authority.

## 15. Current Verified Gaps

Status: **Active Baseline — 2026-08-20**

### Verified Baseline

- Factory 기준점은 동기화된 `main@2f7f76593e98baacc4bc841e5696fc9694690e0f`이며 공개 Release는 `v1.2.2`다
- The Factory baseline is synchronized at `main@2f7f76593e98baacc4bc841e5696fc9694690e0f`, and the public Release is `v1.2.2`
- P0 CI Compatibility Recovery는 GitHub Actions run `32333512924`가 `main@203066f`에서 green인 Evidence와 함께 완료됐다
- P0 CI Compatibility Recovery is completed with green Evidence from GitHub Actions run `32333512924` at `main@203066f`
- 일반 테스트는 185개 통과했고 실제 환경 통합 테스트 14개는 opt-in 조건으로 생략됐다
- The normal suite passed 185 tests, while 14 real-environment integration tests were skipped behind opt-in guards
- 이전 원격 CI 기준점 `d31cecd`는 Dart 3.13에서 두 개의 `unawaited_return_in_try_block` 분석 경고로 실패했으나 P0에서 해결됐다
- The prior remote CI baseline `d31cecd` failed on Dart 3.13 because of two `unawaited_return_in_try_block` analysis warnings, which P0 resolved
  - `lib/core/bootstrap/bootstrap_executor.dart:1722`
  - `lib/core/product_loop/factory_product_loop_command.dart:89`

### Confirmed Problems

1. 실제 Git·Flutter 통합 테스트가 기본 CI에서 실행되지 않아 로컬 증거에 의존한다.
   Real Git and Flutter integration tests do not run in default CI and depend on local evidence.
2. Adaptive Execution Policy와 Execution Profile Lock은 문서와 생성 Product Authority에는 반영됐지만 모든 실행 경계에서 구조화된 runtime 검증으로 강제되지는 않는다.
   Adaptive Execution Policy and Execution Profile Lock are reflected in documents and generated Product Authority but are not yet enforced by structured runtime validation at every execution boundary.
3. 기존 Product의 `AGENTS.md` drift를 자동으로 진단하거나 동기화하는 read-only 경로가 없다.
   There is no read-only path that automatically diagnoses or synchronizes `AGENTS.md` drift in existing Products.
4. 현재 진입 명령과 입력 준비는 비개발자에게 여전히 개발 도구 중심이다.
   Current entry commands and input preparation remain developer-tool-oriented for non-developers.
5. 대형 실행 파일과 장문 Authority, 사용 여부가 불명확한 legacy template·generator·metadata가 유지보수 비용과 권한 혼동을 만든다.
   A large executor, long authority documents, and legacy template, generator, and metadata with unclear active use create maintenance cost and authority ambiguity.

## 16. Flutter Factory Completion Program

Status: **In Progress — P2 Next**

### P0 — CI Compatibility Recovery

Status: **Completed**

Goal:

- 현재 stable Dart 환경에서 발생하는 두 분석 경고를 동작 변경 없이 해결하고 공개 CI 신뢰를 복구한다
- Resolve the two analysis warnings on the current stable Dart environment without behavior change and restore trustworthy public CI

Exit Criteria:

- Repository format, analyze와 일반 테스트가 현재 stable toolchain에서 통과한다
- Repository format, analyze, and normal tests pass on the current stable toolchain
- GitHub Actions의 동일 검증이 green이다
- The equivalent GitHub Actions checks are green
- Bootstrap과 Product Loop 동작 회귀가 없으며 승인된 파일만 변경된다
- Bootstrap and Product Loop behavior do not regress, and only approved files change

Evidence:

- GitHub Actions run `32333512924`는 `main@203066f`에서 green이다
- GitHub Actions run `32333512924` is green at `main@203066f`

### P1 — V1.2.2 SSOT and Release Closure

Status: **Completed — User Approved**

Goal:

- 완료 정책, version metadata, README, Roadmap, tag와 공개 Release를 하나의 승인 기준점으로 정렬한다
- Align completed policies, version metadata, README, Roadmap, tag, and public Release to one approved baseline

Exit Criteria:

- V1.2.2 문서·version·tag·Release가 동일 commit을 가리킨다
- V1.2.2 documents, version, tag, and Release point to the same commit
- Adaptive Execution, Execution Profile Lock와 Direct Approval Action 상태가 실제 Git 결과와 일치한다
- Adaptive Execution, Execution Profile Lock, and Direct Approval Action statuses match actual Git results
- 공개 CI가 green이며 push, tag와 Release는 각각 명시적인 Direct Approval Action 승인을 받는다
- Public CI is green, and push, tag, and Release each receive explicit Direct Approval Action approval

Release Closure Evidence:

- `v1.2.2` tag는 `2f7f76593e98baacc4bc841e5696fc9694690e0f`를 정확히 가리킨다
- The `v1.2.2` tag resolves exactly to `2f7f76593e98baacc4bc841e5696fc9694690e0f`
- [Flutter Factory v1.2.2 — Stabilization](https://github.com/kodog102/ai-flutter-app-factory/releases/tag/v1.2.2) 공개 Release는 draft와 prerelease가 아니며 `2026-08-20T05:04:01Z`에 게시됐다
- The [Flutter Factory v1.2.2 — Stabilization](https://github.com/kodog102/ai-flutter-app-factory/releases/tag/v1.2.2) public Release is neither draft nor prerelease and was published at `2026-08-20T05:04:01Z`
- Candidate CI run `32334095801`은 같은 commit에서 33초 만에 green이었다
- Candidate CI run `32334095801` was green in 33 seconds at the same commit
- V1.2.2 version, 문서, tag와 공개 Release의 기준점 차이가 해소됐다
- The V1.2.2 version, document, tag, and public Release baseline drift is resolved

### P2 — Real Integration CI

Status: **Pending — Next Authorized Proposal**

Goal:

- 빠른 기본 CI와 실제 Git·Flutter 통합 검증을 분리해 공개 Evidence로 남긴다
- Separate fast default CI from real Git and Flutter integration validation and retain both as public Evidence

Exit Criteria:

- 기본 CI는 빠른 format·analyze·test 신호를 유지한다
- Default CI retains a fast format, analyze, and test signal
- Bootstrap과 Product Loop 실제 통합 시나리오는 별도 자동 또는 수동 workflow에서 재현 가능하다
- Real Bootstrap and Product Loop integration scenarios are reproducible in a separate automatic or manual workflow
- 실패 원인, 실행 환경과 결과가 공개 실행 기록에 남고 비밀값은 노출되지 않는다
- Failure causes, environment, and results are retained in public run evidence without exposing secrets

### P3 — Product Authority Audit

Status: **Pending — Blocked by P2**

Goal:

- 기존 Product Authority의 누락과 drift를 변경 없이 진단하는 read-only 경로를 제공한다
- Provide a read-only path that diagnoses missing fields and drift in existing Product Authority without mutation

Exit Criteria:

- Product `AGENTS.md`의 계약 version, 필수 항목과 알려진 drift를 구조화된 결과로 반환한다
- Return the Product `AGENTS.md` contract version, required fields, and known drift as a structured result
- 진단은 Product와 Factory 파일을 수정하지 않으며 불명확한 상태에서 fail-closed 한다
- Diagnosis does not modify Product or Factory files and fails closed on ambiguous state
- 기존 Product와 새 Bootstrap Product에서 독립 검증을 통과한다
- Independent validation passes on an existing Product and a newly bootstrapped Product

### P4 — Executable Execution Profile Validation

Status: **Pending — Blocked by P3**

Goal:

- 승인된 Execution Profile과 Planned·Actual 실행의 편차를 Provider 비종속 구조로 검증한다
- Validate deviations between the approved Execution Profile and Planned or Actual execution with a Provider-independent structure

Exit Criteria:

- 필수 Profile 필드, Direct Approval Actions와 Direct Executor를 typed 또는 구조화된 값으로 표현한다
- Represent required Profile fields, Direct Approval Actions, and Direct Executor as typed or structured values
- 승인 누락과 편차는 Product 변경 전에 결정적인 Stop 결과를 반환한다
- Missing approval and deviations return deterministic Stop results before Product mutation
- 자동 승인, 자동 권한 확장 또는 Main 자기 QA를 허용하지 않는다
- Do not allow automatic approval, automatic authority expansion, or Main self-QA

### P5 — Non-developer Usability

Status: **Pending — Blocked by P4**

Goal:

- 비개발자가 환경과 입력을 확인하고 sample Flutter Product를 한 진입점에서 준비할 수 있게 한다
- Enable a non-developer to check the environment and inputs and prepare a sample Flutter Product from one entry point

Exit Criteria:

- read-only `doctor`, 요청 파일 준비 도움과 dry-run 결과를 제공한다
- Provide a read-only `doctor`, request-file preparation help, and dry-run result
- 긴 개발 명령을 외우지 않아도 되는 짧고 문서화된 실행 경로가 있다
- Provide a short, documented execution path that does not require memorizing long development commands
- 새 사용자가 공개 User Guide만으로 sample Product를 준비하고 승인 지점과 중단 사유를 이해한다
- A new user can prepare a sample Product using only the public User Guide and understand approval gates and stop reasons

### P6 — Security and Resilience Hardening

Status: **Pending — Blocked by P5**

Goal:

- 경로, symlink, ownership, TOCTOU, 입력 공격과 dependency·CI 공급망 위험에 대한 방어를 강화한다
- Strengthen defenses against path, symlink, ownership, TOCTOU, input attacks, and dependency or CI supply-chain risks

Exit Criteria:

- 승인된 위협 목록과 회귀 테스트가 존재하고 CI에서 검증된다
- An approved threat list and regression tests exist and run in CI
- cleanup과 rollback의 ownership 보존 규칙에 회귀가 없다
- Cleanup and rollback ownership-preservation rules do not regress
- dependency와 workflow 권한은 최소 권한 원칙으로 검토되고 기록된다
- Dependencies and workflow permissions are reviewed and recorded under least privilege

### P7 — Structure and Legacy Closure

Status: **Pending — Blocked by P6**

Goal:

- 검증 Evidence를 보존하면서 대형 executor를 책임별로 분리하고 legacy 자산의 권한과 존치 여부를 확정한다
- Split the large executor by responsibility while preserving validation Evidence, and decide the authority and retention of legacy assets

Exit Criteria:

- characterization tests 이후에만 executor 구조를 변경하며 public API 호환성을 유지한다
- Change executor structure only after characterization tests and preserve public API compatibility
- legacy template, generator와 metadata는 활성 경로로 복구되거나 승인 후 제거·격리된다
- Legacy template, generator, and metadata are either restored as active paths or removed or isolated after approval
- 핵심 Authority가 중복 없이 더 짧게 탐색 가능하고 전체 검증이 통과한다
- Core Authority is shorter and easier to navigate without duplication, and full validation passes

## 17. Version Targets

- `V1.2.2 — Stabilization`: P0과 P1 완료
- `V1.2.2 — Stabilization`: Complete P0 and P1
- `V1.3 — Executable Operating Policy`: P2, P3와 P4 완료
- `V1.3 — Executable Operating Policy`: Complete P2, P3, and P4
- `V1.4 — Accessible and Hardened Factory`: P5, P6와 P7 완료
- `V1.4 — Accessible and Hardened Factory`: Complete P5, P6, and P7

## 18. Progression Lock

- 고도화 작업은 `P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7` 순서로 수행한다
- Perform advancement work in the order `P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7`
- 이전 단계의 Exit Criteria, 독립 QA, User 결과 승인과 commit이 완료되기 전에는 다음 단계를 시작하지 않는다
- Do not begin the next phase until the previous phase completes its Exit Criteria, independent QA, User result approval, and commit
- 각 단계는 Agreement와 Execution Profile 승인 후 구현하며 push, tag, Release와 외부 게시 작업은 별도의 Direct Approval Action 승인을 요구한다
- Implement each phase only after Agreement and Execution Profile approval; push, tag, Release, and external publication require separate Direct Approval Action approval
- 순서, 목표, 범위 또는 Exit Criteria를 변경하려면 최신 통합 Roadmap Delta를 제시하고 User 승인을 받는다
- To change order, goals, scope, or Exit Criteria, present the latest consolidated Roadmap Delta and obtain User approval
- 실패와 환경 차단은 Evidence로 기록하되 다음 단계로 건너뛰거나 우선순위를 자동 변경하지 않는다
- Record failures and environment blocks as Evidence, but do not skip phases or automatically change priority
- 미완료 단계를 Ready 또는 Released로 표현하지 않는다
- Do not describe an incomplete phase as Ready or Released

현재 다음 작업은 **P2 — Real Integration CI** 제안 하나뿐이다.

The only current next task is the **P2 — Real Integration CI** proposal.
