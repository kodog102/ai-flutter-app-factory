# ARCHITECTURE.md

> Factory의 전체 구조  
> Overall structure of the Factory

## Purpose

- Factory와 Product Repository의 경계, Factory 저장소의 구조, 각 영역의 책임을 정의한다
- Define the boundary between the Factory and Product Repositories, the structure of the Factory repository, and the responsibility of each area
- Product 내부 구현 방법, 도구 선택, 세부 구현 절차는 다루지 않는다
- Do not cover Product implementation methods, tool choices, or detailed implementation procedures

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
- Factory의 목적, 구조, 역할, 순서, 환경의 기준이 된다
- Serve as the source of truth for the Factory purpose, structure, roles, sequence, and environment

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

## Repository Boundary

- Factory와 Product는 독립 Repository와 독립 Git History를 가진다
- The Factory and Product have independent Repositories and independent Git histories
- Factory Repository는 Factory의 목적, 역할, 구조, Product Repository 준비 기준을 소유한다
- The Factory Repository owns the Factory purpose, roles, structure, and Product Repository readiness criteria
- Product Repository는 Product 전용 문서와 내부 개발을 소유한다
- The Product Repository owns Product-specific documents and internal development
- Product는 Factory를 수정하지 않는다
- The Product does not modify the Factory
- Factory는 Product 내부 개발을 수행하지 않는다
- The Factory does not perform internal Product development

## High-Level Lifecycle

아래 단계의 Product 내부 실행은 Product Repository의 책임이다.

Execution within the Product in the stages below is the responsibility of the Product Repository.

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

## Bootstrap Contract

Bootstrap은 특정 코드나 Template을 생성하는 행위로 한정되지 않는다. Bootstrap의 목적은 독립 Product Repository를 준비하고, 새로운 작업 주체가 Factory를 다시 읽지 않아도 Product-local 정보만으로 첫 Agreement를 제안할 수 있는 상태를 만드는 것이다.

Bootstrap is not limited to creating specific code or a Template. Its purpose is to prepare an independent Product Repository so that a new work participant can propose the first Agreement from Product-local information without rereading the Factory.

- Bootstrap은 Repository 경계와 운영 컨텍스트를 준비한다
- Bootstrap prepares the Repository boundary and operating context
- Product Implementation은 승인된 첫 Agreement 이후 Product 내부에서 수행한다
- Product Implementation occurs inside the Product after the first Agreement is approved
- Factory는 Bootstrap 이후 Product 내부 구현에 개입하지 않는다
- The Factory does not participate in internal Product implementation after Bootstrap

### Required Inputs

Bootstrap을 시작하기 전에 다음 입력이 모두 명시되어야 한다.

All of the following inputs must be explicit before Bootstrap begins.

1. Product name / 제품명
2. Product purpose / 한 문장으로 표현한 제품 목적
3. Initial Product Scope or First Intended Outcome / 초기 Product 범위 또는 첫 번째 의도된 결과
4. Exact output path / 정확한 Product Repository 출력 경로
5. Repository mode / 새 Repository 생성 또는 기존 빈 Repository 사용
6. Initial branch name or Repository policy / 초기 branch 이름 또는 적용할 Repository policy

입력은 현재 작업 요청이나 User가 승인한 컨텍스트에서 제공될 수 있다.

Inputs may be provided in the current work request or User-approved context.

Factory는 출력 경로, 디렉터리 이름, 기존 Repository 사용 여부, branch 이름, Product 목적, Product 범위를 임의로 추측하지 않는다.

The Factory does not infer the output path, directory name, existing Repository use, branch name, Product purpose, or Product scope.

필수 입력이 없으면 Bootstrap을 시작하지 않고 질문을 반환한다.

If a required input is missing, do not start Bootstrap and return a question.

### Required Outputs

#### Repository Boundary

- 명시된 위치의 독립 Product Repository
- An independent Product Repository at the explicit location
- Factory와 분리된 Git metadata 및 history
- Git metadata and history separate from the Factory
- Factory 내부의 nested Repository나 submodule이 아님
- Not a nested Repository or submodule inside the Factory
- Factory 파일을 Product에 복사하지 않음
- Do not copy Factory files into the Product

#### Product README

Product Repository의 `README.md`는 Product identity, Product purpose, Current status, Repository-local 시작 지점을 최소한 설명한다.

The Product Repository `README.md` explains at least the Product identity, Product purpose, current status, and Repository-local starting point.

Product 목적과 현재 범위를 이해하기 위해 Factory 문서를 다시 읽을 필요가 없어야 한다.

The Factory documents must not be needed again to understand the Product purpose and current scope.

#### Product AGENTS

Product Repository의 `AGENTS.md`는 최소한 다음을 포함한다.

The Product Repository `AGENTS.md` includes at least the following.

- Repository identity and boundary
- User authority
- 역할과 수정 권한 / Roles and change permissions
- 작은 Agreement 규칙 / Small Agreement rules
- Scope 및 change rules
- Verification policy
- Git policy
- Reporting requirements

Factory 문장을 그대로 복사하지 않고 Product 관점에서 작성한다. 특정 제품, Provider, 모델 또는 IDE 이름을 역할명으로 사용하지 않는다.

Do not copy Factory wording verbatim; write from the Product perspective. Do not use a specific Product, Provider, model, or IDE name as a role name.

#### First Agreement Proposal

Bootstrap 결과에는 첫 Agreement 제안이 포함되어야 하며, 다음 항목을 포함한다.

The Bootstrap result includes a first Agreement proposal with the following fields.

- Goal
- Included Scope
- Excluded Scope
- Acceptance Criteria
- Verification

첫 Agreement는 기본적으로 영구 문서로 저장하지 않는다. Agreement는 현재 작업을 통제하는 실행 계약이다. 승인된 결과가 장기 지식이나 Product 결정이 될 때만 기존 Product SSOT를 갱신한다.

The first Agreement is not stored as a permanent document by default. It is an execution contract for the current work. Update an existing Product SSOT only when an approved result becomes long-term knowledge or a Product decision.

첫 Agreement의 구현은 User 승인 이후 Product Repository에서 수행한다.

Implement the first Agreement in the Product Repository only after User approval.

#### Approved Operational Baseline Handoff

Operational Bootstrap의 최종 결과에는 새로운 작업 주체가 Product Repository 상태를 판단할 수 있는 승인된 운영 기준선 인계가 포함되어야 한다.

The final outputs of Operational Bootstrap include an approved operational baseline handoff that enables a new work participant to evaluate the Product Repository state.

Bootstrap 실행 중에는 Baseline Handoff Proposal을 먼저 생성하며, User가 Ready 상태와 baseline을 승인한 후에만 Approved Operational Baseline Handoff가 된다.

During Bootstrap, a Baseline Handoff Proposal is created first and becomes an Approved Operational Baseline Handoff only after the User approves the Ready state and baseline.

Baseline의 생명주기는 다음과 같다.

The baseline lifecycle is as follows.

1. Product Repository의 최종 Git 상태를 capture한다. / Capture the final Product Git state.
2. Baseline Handoff Proposal을 생성한다. / Create a Baseline Handoff Proposal.
3. Proposal과 Evidence를 User에게 제시한다. / Present the proposal and Evidence to the User.
4. User가 Ready 상태와 baseline을 승인한다. / The User approves the Ready state and baseline.
5. Proposal이 Approved Operational Baseline Handoff가 된다. / The proposal becomes an Approved Operational Baseline Handoff.
6. 승인된 handoff를 새로운 작업 주체에게 전달한다. / Hand the approved handoff to the new work participant.

최소 인계 정보는 다음과 같으며 해당 항목이 없으면 `None`으로 명시한다.

The handoff includes at least the following information and states `None` when an item does not exist.

- Exact Product Repository path
- Current branch
- HEAD commit 또는 commit이 없다는 사실 / HEAD commit or the fact that no commit exists
- Expected staged files
- Expected modified files
- Expected untracked files
- Expected deleted files
- 해당 상태가 User가 승인한 Bootstrap 기준선인지 여부 / Whether the state is a User-approved Bootstrap baseline

Baseline handoff는 Factory 문서 사본이나 Product 기능 및 Architecture 설명이 아니다. Product Repository와 함께 새로운 작업 주체에게 전달되는 runtime handoff metadata이며, 승인된 상태와 예상 밖 변경을 구분하기 위한 운영 상태 정보다.

The baseline handoff is not a copy of Factory documents or a description of Product features or Architecture. It is runtime handoff metadata delivered with the Product Repository to a new work participant so that approved state can be distinguished from unexpected changes.

Baseline handoff는 영구 Product 문서 생성을 요구하지 않으며 특정 Provider, 모델 또는 IDE를 전제하지 않는다.

The baseline handoff does not require a permanent Product document and does not assume a specific Provider, model, or IDE.

Product Repository가 반드시 clean일 필요는 없다. 승인된 staged, modified 또는 untracked Bootstrap 산출물이 있을 수 있다. 실제 상태가 User가 승인한 handoff와 정확히 일치하면 그 사실만으로 중단하지 않는다.

The Product Repository is not required to be clean. Approved staged, modified, or untracked Bootstrap outputs may exist. Do not stop solely for that reason when the actual state exactly matches the User-approved handoff.

실제 상태가 handoff와 다르면 변경 전에 중단하고 보고한다. 승인 기준선이 제공되지 않은 non-clean 상태는 추측하지 않고 중단한다.

If the actual state differs from the handoff, stop and report before making changes. Stop without guessing when a non-clean state has no approved baseline.

### Optional Outputs

다음은 모든 Product에 자동으로 생성하지 않는다.

The following are not created automatically for every Product.

- VISION 문서 / VISION document
- PRODUCT 문서 / PRODUCT document
- DESIGN 문서 / DESIGN document
- ARCHITECTURE 문서 / ARCHITECTURE document
- Decision Records
- License
- 추가 설정 문서 / Additional configuration documents
- 별도의 Agreement 파일 / Separate Agreement file
- 역할별 문서 / Role-specific documents
- Playbook

다음 조건을 모두 만족할 때만 추가한다.

Add one only when all of the following conditions are met.

- README 또는 AGENTS의 기존 Authority로 표현할 수 없음
- Cannot be expressed by the existing authority of README or AGENTS
- 새로운 독립 Authority가 실제로 필요함
- A new independent authority is actually needed
- 첫 Agreement 수행에 반드시 필요함
- It is necessary to perform the first Agreement
- 동일 내용을 다른 문서에 중복하지 않음
- It does not duplicate the same content in another document

Factory 문서 구조를 Product Repository에 그대로 복사하지 않는다.

Do not copy the Factory document structure directly into the Product Repository.

### Bootstrap Sequence

#### Step 1 — Validate Factory Baseline

- Factory Repository 상태를 확인한다
- Inspect the Factory Repository state
- 승인된 기준선과 예상 밖 변경을 구분한다
- Distinguish the approved baseline from unexpected changes
- 현재 SSOT가 읽을 수 있는 일관된 상태인지 확인한다
- Confirm that the current SSOT is in a readable, consistent state

Factory가 반드시 clean 또는 committed 상태여야 한다고 가정하지 않는다. 다만 작업에 영향을 줄 수 있는 변경은 명시적으로 알려진 기준선이어야 한다.

Do not assume that the Factory must be clean or committed. Changes that can affect the work must be an explicitly known baseline.

#### Step 2 — Validate Inputs

- 모든 필수 입력을 확인한다
- Verify all required inputs
- Product 목적과 정확한 출력 경로를 확인한다
- Confirm the Product purpose and exact output path
- 초기 Product 범위 또는 첫 번째 의도된 결과를 확인한다
- Confirm the initial Product scope or first intended outcome
- Repository mode 및 branch policy를 확인한다
- Confirm the Repository mode and branch policy
- 누락된 입력이 있으면 중단한다
- Stop when an input is missing

#### Step 3 — Validate Target

- 출력 경로가 안전한지 확인한다
- Confirm that the output path is safe
- 대상이 존재하면 비어 있거나 명시적으로 허용된 Repository인지 확인한다
- If the target exists, confirm that it is empty or an explicitly allowed Repository
- 기존 파일, 기존 Git history 또는 사용자 데이터와 충돌하면 중단한다
- Stop when it conflicts with existing files, Git history, or user data
- Factory Repository 내부 경로면 중단한다
- Stop when the path is inside the Factory Repository

#### Step 4 — Prepare Repository Boundary

##### New Repository Mode

- Target 검증이 성공한 뒤 명시된 경로를 준비한다
- Prepare the explicit path after Target validation succeeds
- 승인된 branch 이름 또는 Repository policy를 사용해 독립 Git metadata를 초기화한다
- Initialize independent Git metadata using the approved branch name or Repository policy
- Factory Repository 내부에는 생성하지 않는다
- Do not create it inside the Factory Repository

##### Existing Empty Repository Mode

- 기존 Repository임을 확인한다
- Confirm that the Target is an existing Repository
- 기존 Git history와 사용자 데이터를 덮어쓰지 않는다
- Do not overwrite existing Git history or user data
- 이미 존재하는 Git metadata를 다시 초기화하지 않는다
- Do not reinitialize existing Git metadata
- 제공된 Repository policy를 보존한다
- Preserve the provided Repository policy

##### Common Rules

- Architecture Role이 Operational Bootstrap을 조정하고 Repository 경계를 확인한다
- The Architecture Role coordinates Operational Bootstrap and verifies the Repository boundary
- Factory와 Product root가 다른지 확인한다
- Confirm that the Factory and Product roots differ
- commit, remote 추가, push는 Bootstrap에 자동으로 포함하지 않는다
- Do not automatically include commit, adding a remote, or push in Bootstrap
- Product source code나 platform 구현은 이 단계에서 생성하지 않는다
- Do not create Product source code or platform implementation in this step
- 입력과 실제 Target 상태가 다르면 중단한다
- Stop when the inputs and actual Target state differ

#### Step 5 — Prepare Product-local Authority

- Product `README.md`를 작성한다
- Create the Product `README.md`
- Product `AGENTS.md`를 작성한다
- Create the Product `AGENTS.md`
- 필요한 경우에만 추가 Product SSOT를 작성한다
- Create additional Product SSOT only when needed
- Factory 전용 내용과 Product 전용 내용을 혼합하지 않는다
- Do not mix Factory-only and Product-specific content

#### Step 6 — Prepare First Agreement

- Product Repository의 정보만 사용한다
- Use Product Repository information only
- 첫 번째 작은 Agreement를 제안한다
- Propose the first small Agreement
- 구현 전에 User 승인을 기다린다
- Wait for User approval before implementation
- Agreement를 자동으로 파일화하지 않는다
- Do not automatically create a file for the Agreement

#### Step 7 — Verify Ready Product

- Ready 기준을 검증한다
- Verify the Ready criteria
- Factory Repository 무변경을 확인한다
- Confirm that the Factory Repository is unchanged
- Product Repository 상태를 보고한다
- Report the Product Repository state
- Product Repository의 최종 Git 상태를 확인한다
- Confirm the final Git state of the Product Repository
- Baseline Handoff Proposal을 생성한다
- Create a Baseline Handoff Proposal
- Proposal과 Evidence를 User에게 제시한다
- Present the proposal and Evidence to the User
- User가 최종 Ready 상태와 baseline을 승인한다
- The User gives final approval of the Ready state and baseline
- 승인 후 Proposal을 Approved Operational Baseline Handoff로 확정한다
- After approval, confirm the proposal as the Approved Operational Baseline Handoff
- 승인된 handoff를 새로운 작업 주체에게 전달할 수 있는 상태인지 확인한다
- Confirm that the approved handoff can be handed to a new work participant

### Stop Conditions

다음 중 하나라도 발생하면 Bootstrap을 중단하고 추측하지 않는다.

Stop Bootstrap without guessing when any of the following occurs.

- 필수 입력 누락 / Required input is missing
- 출력 경로가 불명확함 / Output path is unclear
- 출력 경로에 기존 사용자 데이터가 있음 / The output path contains existing user data
- 예상하지 못한 기존 Git Repository가 있음 / An unexpected existing Git Repository is present
- Factory와 Product 경계를 분리할 수 없음 / The Factory and Product boundary cannot be separated
- Product 목적, 초기 Product 범위 또는 첫 번째 의도된 결과를 Product-local 문서에 작성할 근거가 없음 / There is no basis to write the Product purpose, initial Product scope, or first intended outcome in Product-local documents
- 역할 또는 승인 권한이 불명확함 / Roles or approval authority are unclear
- 기존 Factory SSOT 사이에 Bootstrap을 바꾸는 충돌이 있음 / Existing Factory SSOT conflict in a way that changes Bootstrap
- Product를 준비하려면 승인되지 않은 Factory 수정이 필요함 / Preparing the Product requires unapproved Factory changes
- 민감정보가 발견됨 / Sensitive information is found
- 승인되지 않은 Product Implementation이 필요함 / Unapproved Product Implementation is required
- 작업 범위를 벗어나는 구조나 문서를 새로 결정해야 함 / A structure or document outside the work scope must be newly decided

#### During Operational Bootstrap

- 승인된 Bootstrap 범위로 생성된 변경과 예상 밖 변경을 구분한다. / Distinguish changes created within the approved Bootstrap scope from unexpected changes.
- 실제 Product Git 상태가 Baseline Handoff Proposal에 capture된 상태와 다르면 중단한다. / Stop when the actual Product Git state differs from the state captured in the Baseline Handoff Proposal.
- Proposal과 Evidence를 User에게 제시하기 전이라는 이유만으로 승인 부재를 중단 조건으로 삼지 않는다. / Do not treat the absence of approval as a stop condition merely because the proposal and Evidence have not yet been presented to the User.
- 범위 밖 파일, 민감정보 또는 예상하지 못한 Git 상태가 있으면 중단한다. / Stop when out-of-scope files, sensitive information, or an unexpected Git state is present.

#### After Ready Approval or New Work Handoff

- 실제 Product Git 상태가 Approved Operational Baseline Handoff와 다르면 중단한다. / Stop when the actual Product Git state differs from the Approved Operational Baseline Handoff.
- non-clean 상태에 Approved Operational Baseline Handoff가 제공되지 않으면 추측하지 않고 중단한다. / Stop without guessing when a non-clean state has no Approved Operational Baseline Handoff.
- 실제 상태가 Approved Operational Baseline Handoff와 정확히 일치하면 non-clean이라는 이유만으로 중단하지 않는다. / Do not stop solely because the state is non-clean when the actual state exactly matches the Approved Operational Baseline Handoff.

중단 보고에는 중단 위치, 확인된 사실, 누락된 입력 또는 결정, 필요한 User 결정, 수행하지 않은 작업을 포함한다.

A stop report includes the stop location, confirmed facts, missing input or decision, required User decision, and work not performed.

### Template and Tooling Policy

현재 Bootstrap Contract는 Template, Generator, CLI 또는 Automation을 전제로 하지 않는다.

The current Bootstrap Contract does not assume a Template, Generator, CLI, or Automation.

Template이 없다는 사실은 운영 컨텍스트 Bootstrap 자체를 막지 않는다. 다만 Template 기반 코드 생성이 현재 Agreement에 포함되어 있다면 Template 부재는 해당 작업의 중단 조건이다.

The absence of a Template does not block operational-context Bootstrap itself. If Template-based code generation is included in the current Agreement, the absence of a Template is a stop condition for that work.

Operational Bootstrap과 Product Generation or Implementation을 다음과 같이 구분한다.

Operational Bootstrap and Product Generation or Implementation are distinguished as follows.

```text
Operational Bootstrap
- Repository boundary
- Product-local authority
- First Agreement readiness

Product Generation or Implementation
- Source code
- Platform files
- Template application
- Toolchain execution
```

이번 문서는 Operational Bootstrap만 정의한다. 기존 Template 또는 Toolchain 관련 설계를 삭제하거나 구현하지 않는다.

This document defines only Operational Bootstrap. It does not remove or implement existing Template or Toolchain designs.

### Ready Product Criteria

다음 조건을 모두 만족해야 Ready Product다.

All of the following conditions must be met for a Ready Product.

Ready 판정 전 baseline은 Proposal이며, User 승인 후 Approved Operational Baseline Handoff가 되어 새로운 작업 주체에게 전달된다.

Before the Ready decision, the baseline is a Proposal; after User approval, it becomes an Approved Operational Baseline Handoff and is handed to the new work participant.

1. Product의 정확한 Repository 위치가 확정되어 있음
2. Factory와 분리된 독립 Repository임
3. Product-local `README.md`가 정체성, 목적, 현재 상태를 설명함
4. Product-local `AGENTS.md`가 권한, 역할, Agreement, 변경, 검증 및 Git 규칙을 설명함
5. 승인된 baseline handoff가 새로운 작업 주체에게 전달 가능한 상태이며, 작업 주체는 이를 사용해 Factory를 다시 읽지 않고 Product를 이해할 수 있음
6. Product-local 문서와 handoff metadata가 실제 Git 상태 비교와 첫 Agreement 제안에 충분함
7. 첫 Agreement에 필수 다섯 항목이 포함되어 있음
8. Product Implementation은 아직 시작되지 않았거나 명시적으로 승인된 범위만 존재함
9. Factory Repository가 Bootstrap으로 인해 변경되지 않음
10. 예상하지 못한 파일, 민감정보 또는 Repository 충돌이 없음
11. Git 상태와 미커밋 Bootstrap 산출물이 승인된 baseline handoff에 명확하게 기록되고 실제 상태와 일치함
12. User가 최종 Ready 상태와 baseline을 승인할 수 있도록 Evidence가 제공됨

1. The exact Product Repository location is confirmed.
2. It is an independent Repository separate from the Factory.
3. The Product-local `README.md` explains identity, purpose, and current status.
4. The Product-local `AGENTS.md` explains authority, roles, Agreement, change, verification, and Git rules.
5. The approved baseline handoff is available for delivery to a new work participant, who can use it to understand the Product without rereading the Factory.
6. The Product-local documents and handoff metadata are sufficient to compare the actual Git state and propose the first Agreement.
7. The first Agreement contains all five required fields.
8. Product Implementation has not started, or only an explicitly approved scope exists.
9. The Factory Repository was not changed by Bootstrap.
10. There are no unexpected files, sensitive information, or Repository conflicts.
11. Git status and uncommitted Bootstrap outputs are clearly recorded in the approved baseline handoff and match the actual state.
12. Evidence is available for the User to give final approval of the Ready state and baseline.

Commit is not automatically assumed to be a Ready Product requirement. When Ready Product outputs remain uncommitted, the approved operational baseline handoff must identify their expected Git state. Commit and push require a separate User request.

## Template and Toolchain Flow

아래 기존 흐름은 별도로 승인된 Product Generation 또는 Implementation을 지원할 수 있다. Bootstrap Contract의 일부가 아니며 Ready Product의 유일한 경로도 아니다.

The existing flow below may support separately approved Product Generation or Implementation. It is not part of the Bootstrap Contract and is not the only path to a Ready Product.

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
Pipeline Result
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

### Pipeline Result

#### Input

- 검증 결과
- Verification result

#### Output

- Pipeline result

Pipeline result만으로 Ready Product 기준을 충족한 것은 아니다.

A Pipeline result alone does not satisfy the Ready Product criteria.
