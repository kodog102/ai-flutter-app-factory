# ARCHITECTURE.md

> Factory의 전체 구조  
> Overall structure of the Factory

## Purpose

- Factory 저장소의 구조와 각 영역의 책임을 정의한다
- Define the structure of the Factory repository and the responsibility of each area
- 구현 방법, 도구 선택, 세부 작업 절차는 다루지 않는다
- Do not cover implementation methods, tool choices, or detailed work procedures

## Repository First Rule

- 저장소가 진실의 원천이다
- The repository is the source of truth
- 지시사항이 현재 저장소 구조와 충돌하면 저장소를 따른다
- If an instruction conflicts with the current repository structure, follow the repository
- 불일치는 Open Questions에 보고한다
- Report the discrepancy in Open Questions

## Repository Structure

현재 저장소 기준 구조다.

This is the structure of the current repository.

```text
.
├── AGENTS.md
├── LICENSE
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

## Foundation Layers

### Identity

- Factory가 무엇인지 식별한다
- Identify what the Factory is
- 이름, 역할 경계, 저장소 소개가 여기에 속한다
- Name, role boundaries, and repository introduction belong here

### Configuration

- Factory 수준의 최소 설정을 담는다
- Hold minimal Factory-level configuration
- 프로젝트별 앱 설정은 포함하지 않는다
- Do not include project-specific app configuration

### Knowledge

- 권한 있는 문서와 결정을 담는다
- Hold authoritative documents and decisions
- 제품, 구조, 디자인, 순서, 환경의 기준이 된다
- Serve as the source of truth for product, structure, design, sequence, and environment

### Assets

- 디자인·정적 산출물의 위치를 담당한다
- Own the place for design and static artifacts
- 현재 저장소에는 Assets 디렉터리가 없다
- The current repository has no Assets directory

## Directory Responsibilities

### `/` (Repository Root)

- Factory Identity와 Configuration 파일을 둔다
- Place Factory Identity and Configuration files
- Knowledge와 Assets의 진입점이 된다
- Serve as the entry point to Knowledge and Assets

### `Docs/`

- Knowledge 계층의 권한 문서를 둔다
- Place authoritative Knowledge documents
- 문서마다 하나의 주제만 담당한다
- Each document owns a single subject

### `Docs/Decisions/`

- 되돌리기 어려운 결정 기록의 위치다
- Hold records of hard-to-reverse decisions
- Decision의 세부 내용 자체는 이 문서에 복사하지 않는다
- Do not copy Decision details into this document

## High-Level Lifecycle

### Decision

- 되돌리기 어려운 방향을 확정한다
- Confirm hard-to-reverse direction

### Architecture

- Factory와 제품의 구조를 정의한다
- Define the structure of the Factory and the product

### Implementation

- 승인된 범위를 구현한다
- Implement the approved scope

### Verification

- 구현 결과를 검증한다
- Verify implementation results

## Factory Pipeline

단방향 진행만 한다.

Progresses in one direction only.

```text
Initialize
    ↓
Select Template
    ↓
Create Project
    ↓
Apply Manifest
    ↓
Execute Toolchains
    ↓
Verify
    ↓
Ready
```

### Initialize

#### Input

- Factory 진입 요청
- Factory entry request

#### Output

- 초기화된 Factory 컨텍스트
- Initialized Factory context

### Select Template

#### Input

- 초기화된 Factory 컨텍스트
- Initialized Factory context

#### Output

- 선택된 템플릿
- Selected template

### Create Project

#### Input

- 선택된 템플릿
- Selected template

#### Output

- 생성된 프로젝트
- Created project

### Apply Manifest

#### Input

- 생성된 프로젝트
- Created project
- Factory Manifest

#### Output

- Manifest가 적용된 프로젝트
- Project with Manifest applied

### Execute Toolchains

#### Input

- Manifest가 적용된 프로젝트
- Project with Manifest applied

#### Output

- Toolchain 실행 결과
- Toolchain execution result

### Verify

#### Input

- Toolchain 실행 결과
- Toolchain execution result

#### Output

- 검증 결과
- Verification result

### Ready

#### Input

- 검증 결과
- Verification result

#### Output

- 준비 완료된 프로젝트
- Ready project
