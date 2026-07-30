# ROADMAP.md

> Factory V1 작업 순서와 현재 상태
> Factory V1 work sequence and current status

## Current Foundation

- Factory 목적, 역할, Repository 경계와 Operational Bootstrap Contract가 정의되어 있다
- The Factory purpose, roles, Repository boundary, and Operational Bootstrap Contract are defined
- Approved Operational Baseline Handoff lifecycle이 정의되어 있다
- The Approved Operational Baseline Handoff lifecycle is defined
- 현재 runtime은 Executable Flutter V1 계약을 아직 구현하지 않는다
- The current runtime does not yet implement the Executable Flutter V1 contract

## 1. V1 SSOT Alignment

Status: **In Review**

### Goal

- 기존 SSOT를 승인된 Executable Flutter V1 범위와 정렬한다
- Align the existing SSOT with the approved Executable Flutter V1 scope

### Exit Criteria

- Flutter 모바일 iOS/Android 경계와 Factory/Product 책임이 기존 Authority에서 일치한다
- The Flutter mobile iOS/Android boundary and Factory/Product responsibilities are consistent across existing authorities

## 2. Intake and Safe Preflight

Status: **Not Started**

### Goal

- 승인된 V1 입력을 검증하고 미지원·불충분·충돌 요청을 안전하게 중단한다
- Validate approved V1 inputs and safely stop unsupported, insufficient, or conflicting requests

## 3. Flutter Scaffold and Repository Boundary

Status: **Not Started**

### Goal

- 독립 Repository 경계와 iOS/Android Flutter 기본 구조를 준비한다
- Prepare the independent Repository boundary and iOS/Android Flutter base structure

## 4. Product-local Authority and Proposals

Status: **Not Started**

### Goal

- Product-local Authority, First Agreement Proposal과 Baseline Handoff Proposal을 준비한다
- Prepare Product-local authority, the First Agreement Proposal, and the Baseline Handoff Proposal

## 5. Automated Validation

Status: **Not Started**

### Goal

- Factory와 생성 결과의 필수 분석, 테스트와 빌드 검증을 자동으로 판정한다
- Automatically evaluate the required analysis, tests, and build verification for the Factory and generated result

## 6. End-to-End Cross-Product Validation

Status: **Not Started**

### Goal

- 서로 다른 Product 분야에서 같은 V1 계약을 검증한다
- Validate the same V1 contract across different Product domains

단일 Product 결과는 자동으로 Core Standard가 되지 않는다.

A result from one Product does not automatically become a Core Standard.

## 7. V1 Readiness and Release Decision

Status: **Not Started**

### Goal

- Evidence를 바탕으로 User가 V1 Ready 및 release 여부를 최종 승인한다
- Enable the User to give final approval of V1 readiness and release based on Evidence

CLI, Template engine 또는 orchestration 기능은 검증된 필요가 생기기 전까지 V1 필수 조건이 아니다.

A CLI, Template engine, or orchestration capability is not a V1 requirement until a validated need exists.
