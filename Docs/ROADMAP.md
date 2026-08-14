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

Status: **Implemented — User Result Approval Pending**

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

Status: **Implemented — User Result Approval Pending**

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
