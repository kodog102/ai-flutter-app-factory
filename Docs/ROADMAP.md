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

Status: **In Review**

V1 Ready: **Approved**

Release: **Pending User Decision**

### Goal

- Evidence를 바탕으로 User가 V1 Ready 및 release 여부를 최종 승인한다
- Enable the User to give final approval of V1 readiness and release based on Evidence

Flutter V1 Ready는 전체 기술 검증과 독립 QA 이후 User가 승인했다. Version, release identifier, tag, push와 publication은 아직 승인되지 않았다.

The User approved Flutter V1 Ready after full technical verification and independent QA. Version, release identifier, tag, push, and publication have not yet been approved.

CLI, Template engine 또는 orchestration 기능은 검증된 필요가 생기기 전까지 V1 필수 조건이 아니다.

A CLI, Template engine, or orchestration capability is not a V1 requirement until a validated need exists.

## 8. V1.1 One-run Product Bootstrap

Status: **Completed**

### Goal

- 엄격한 `product_request.yaml` 하나와 한 명령으로 기존 Runtime의 검증된 Flutter Product 시작점을 준비한다
- Prepare a verified Flutter Product starting point through the existing Runtime using one strict `product_request.yaml` and one command

엄격한 `product_request.yaml`과 한 명령을 사용하는 Bootstrap이 구현됐으며 실제 Flutter Product 생성으로 검증됐다. V1 Ready 승인과 Release Pending 상태는 유지한다. V1.1은 Product 기능 또는 V1.2 Product Loop를 구현하지 않는다.

Bootstrap using one strict `product_request.yaml` and one command is implemented and verified through actual Flutter Product creation. Preserve V1 Ready approval and Release Pending status. V1.1 does not implement Product features or the V1.2 Product Loop.

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

Status: **Implemented — User Approval Pending**

### Goal

- 기존 V1.2 공개 Runtime을 비개발자와 AI 작업 주체가 사용할 수 있는 단일 command surface로 제공한다
- Expose the existing V1.2 public Runtime through one command surface usable by non-developers and AI work participants
- User 승인과 외부 Product 구현 경계를 보존하는 `capture`와 `validate` 단계를 제공한다
- Provide `capture` and `validate` phases that preserve User approval and external Product implementation boundaries
- 승인된 기준선을 영속 JSON과 SHA-256 Evidence로 전달한다
- Carry the approved baseline through persistent JSON and SHA-256 Evidence

이 단계는 Product 기능 구현, QA 자동 승인, Provider 연동, commit 또는 push를 포함하지 않는다.

This stage does not include Product feature implementation, automated QA approval, Provider integration, commit, or push.
