# VISION.md

> Factory의 존재 목적과 설계 원칙  
> Purpose of the Factory and its design principles

## Mission

- 새로운 Product Repository가 일관된 운영 규칙을 갖고 즉시 첫 작업을 시작할 수 있도록 준비한다
- Prepare a new Product Repository with consistent operating rules so that it can begin its first task immediately

## Vision

- Product Repository가 자체 문서만으로 첫 Agreement를 시작할 수 있는 상태를 반복 가능하게 만든다
- Make it repeatable for a Product Repository to reach a state where it can begin its first Agreement from its own documents
- 단일 Product에 종속되지 않는 Factory 기반을 유지한다
- Keep a Factory foundation that is not tied to a single Product

## Core Principles

### Single Source of Truth

- 각 주제는 하나의 권한 문서만 가진다
- Each subject has only one authoritative document

### Decision First

- 되돌리기 어려운 방향은 구현 전에 결정한다
- Hard-to-reverse direction is decided before implementation

### AI Collaboration

- AI는 역할이 분리된 상태로 협력한다
- AI collaborates with separated roles

### Small & Reviewable Changes

- 변경은 작고 검토 가능해야 한다
- Changes must be small and reviewable

### Reusable Foundation

- Factory는 다음 제품에도 재사용 가능해야 한다
- The Factory must be reusable for the next product

### Factory-Centered Validation

- Factory가 중심 Product다
- The Factory is the primary product
- 테스트 Product는 Factory 가설을 검증하기 위한 실험 수단이다
- Test Products are experiments used to validate Factory hypotheses
- Product 완성도는 Factory의 성공 기준이 아니다
- Product completeness is not a success criterion for the Factory
- 충분한 증거가 확보되면 테스트 Product를 완성하지 않고 Product 실험을 중단할 수 있다
- A Product experiment may stop without completing the test Product once sufficient evidence has been obtained
- 한 Product의 결과를 자동으로 Core Standard로 승격하지 않는다
- Results from a single Product are not automatically promoted to Core Standards
- 검증된 학습만 기존 Factory SSOT에 최소 반영한다
- Only validated learning is incorporated minimally into the existing Factory SSOT

## Non-Goals

- 특정 제품의 비전을 대신하지 않는다
- Do not replace a specific product vision
- 완성된 범용 앱 프레임워크를 제공하지 않는다
- Do not provide a finished general-purpose app framework
- 자동으로 제품을 출시하지 않는다
- Do not automatically ship products
- 서버, 결제, 계정 인프라를 기본 포함하지 않는다
- Do not include server, payment, or account infrastructure by default
- 모든 결정을 자동화하지 않는다
- Do not automate every decision
