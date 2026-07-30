# AI Flutter App Factory

## Overview

이 저장소는 새로운 Product Repository가 일관된 운영 규칙을 갖고 즉시 첫 작업을 시작할 수 있도록 준비하는 Factory다.

This repository is a Factory that prepares a new Product Repository with consistent operating rules so that it can begin its first task immediately.

## Mission

Product Repository가 자체 문서와 명확한 책임 경계를 갖춘 운영 가능한 상태가 되도록 한다.

Make a Product Repository operational through its own documents and clear responsibility boundaries.

## Ready Outcome

Product Repository만으로 첫 Agreement를 시작할 수 있는 상태

A state where the first Agreement can begin from the Product Repository alone

## Operating Principle

빠른 생성 + 작은 승인 + 빠른 개선

Fast Creation + Small Agreements + Rapid Iteration

## Bootstrap Entry

Bootstrap을 시작하기 전에 Product name, Product purpose, 초기 Product 범위 또는 첫 번째 의도된 결과, 정확한 output path, Repository mode, 초기 branch 이름 또는 Repository policy를 제공한다.

Before starting Bootstrap, provide the Product name, Product purpose, initial Product scope or first intended outcome, exact output path, Repository mode, and initial branch name or Repository policy.

Bootstrap Contract의 전체 입력, 출력, 순서, 중단 조건, Ready Product 기준은 [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md)가 단일 권한을 가진다.

[Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md) is the single authority for the Bootstrap Contract inputs, outputs, sequence, stop conditions, and Ready Product criteria.

Ready Product는 새로운 작업 주체가 Factory를 다시 읽지 않고 Product Repository만으로 첫 Agreement를 제안할 수 있는 상태다.

A Ready Product is a state in which a new work participant can propose the first Agreement from the Product Repository alone without rereading the Factory.

## Role Model

- Roles are stable.
- Providers are replaceable.
- Product development takes priority over Factory design.

## Repository Structure

```text
.
├── AGENTS.md
├── README.md
├── factory.yaml
├── factory_manifest.json
└── Docs/
    ├── ARCHITECTURE.md
    ├── DESIGN.md
    ├── PRODUCT.md
    ├── ROADMAP.md
    ├── SETUP.md
    ├── VISION.md
    └── Decisions/
        ├── README.md
        ├── DR-001-ai-role-handoff.md
        └── DR-002-minimal-documentation.md
```

## Getting Started

1. `README.md`
2. `AGENTS.md`
3. `Docs/VISION.md`
4. `Docs/ARCHITECTURE.md`
5. `factory.yaml`

## Foundation Documents

- `AGENTS.md` — AI Agent의 역할과 책임 / Roles and responsibilities of AI agents
- `Docs/VISION.md` — Factory의 존재 목적과 설계 원칙 / Factory purpose and design principles
- `Docs/ARCHITECTURE.md` — Factory의 전체 구조 / Overall Factory structure
- `Docs/ROADMAP.md` — 작업 순서와 단계별 완료 조건 / Work sequence and phase completion criteria

## Development Status

현재 상태: **Foundation Phase**

Current status: **Foundation Phase**

## License

`LICENSE` 파일을 참고한다.

See the `LICENSE` file.
