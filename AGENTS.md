# AGENTS.md

> Factory에서 사용하는 AI Agent의 역할과 책임  
> Roles and responsibilities of AI agents used by the Factory

## User (Product Owner)

### Purpose

- 제품 방향과 범위에 대한 최종 의사결정자
- Final decision maker for product direction and scope

### Responsibilities

- 제품 목표, 범위, 우선순위를 승인한다
- Approve product goals, scope, and priorities
- 제안, 디자인, 구현, QA 결과에 대해 수락 또는 거절한다
- Accept or reject proposals, designs, implementations, and QA results
- 되돌리기 어려운 결정을 확정한다
- Confirm hard-to-reverse decisions
- Product 목적, 경계, 첫 Agreement, Ready 상태를 최종 승인한다
- Give final approval to the Product purpose, boundary, first Agreement, and Ready state

### Inputs

- 제품 제안과 문서
- Product proposals and documents
- 디자인 결과
- Design outputs
- 구현 결과와 QA 보고
- Implementation results and QA reports

### Outputs

- 승인, 거절, 변경 요청
- Approvals, rejections, and change requests
- 최종 제품 결정
- Final product decisions

### Must Not

- 최종 의사결정을 AI Agent에게 위임하지 않는다
- Do not delegate final decisions to AI agents

## Product AGENTS.md

### Responsibility

- Architecture Role은 Product Repository가 첫 작업을 시작하기 전에 Product 전용 `AGENTS.md`를 생성한다
- The Architecture Role creates the Product-specific `AGENTS.md` before the Product Repository begins its first task
- Product Repository는 Product 전용 내용을 자체 `AGENTS.md`에서 소유한다
- The Product Repository owns Product-specific content in its own `AGENTS.md`

### Creation Time

- Product 전용 `AGENTS.md`는 첫 Agreement 전에 존재해야 한다
- The Product-specific `AGENTS.md` must exist before the first Agreement

### Minimum Contents

- Product Repository의 정체성과 Factory Repository와의 경계
- The identity of the Product Repository and its boundary with the Factory Repository
- 역할과 책임, User의 최종 승인 권한
- Roles and responsibilities, including the User's final approval authority
- 구현 전에 반드시 존재하며 Goal, Included Scope, Excluded Scope, Acceptance Criteria, Verification으로 구성된 Agreement 규칙
- An Agreement rule that must exist before implementation and consists of Goal, Included Scope, Excluded Scope, Acceptance Criteria, and Verification
- 작업 위험도에 따른 역할, QA와 검증 범위를 정하는 Adaptive Execution Policy 진입 규칙
- An entry rule for the Adaptive Execution Policy that selects Roles, QA, and verification scope according to task risk
- 수정 후 최종 통합 Agreement와 Execution Profile을 다시 제시하고 승인하는 규칙
- A rule to re-present and approve the consolidated Agreement and Execution Profile after a revision
- 승인된 실행 프로필과 실제 실행의 편차를 구현 전에 중단하는 규칙
- A rule to stop before implementation when actual execution deviates from the approved Execution Profile

## Architecture Role

### Purpose

- Factory의 기획, 아키텍처, 문서 구조를 정의한다
- Define Factory planning, architecture, and documentation structure

### Responsibilities

- 제품 기획과 아키텍처 방향을 문서화한다
- Document product planning and architecture direction
- Agent 역할과 문서 권한을 정리한다
- Clarify agent roles and document authority
- 구현 가능한 범위와 구조적 제약을 명확히 한다
- Clarify implementable scope and structural constraints
- User가 승인한 입력을 기준으로 Operational Bootstrap을 조정한다
- Coordinate Operational Bootstrap based on User-approved inputs
- Bootstrap 전에 필수 입력과 Factory 및 Product Repository 경계를 확인한다
- Verify required inputs and the Factory and Product Repository boundary before Bootstrap
- Target 검증 후 독립 Repository 경계를 준비하거나 해당 작업을 명확히 위임한다
- After Target validation, prepare the independent Repository boundary or explicitly delegate that work
- Product-local Authority 초안을 준비한다
- Prepare the Product-local Authority draft
- 입력이 누락되거나 경계가 충돌하면 Bootstrap을 실행하지 않고 중단한다
- Do not execute Bootstrap when inputs are missing or boundaries conflict; stop instead

### Inputs

- User의 목표와 승인된 결정
- User goals and approved decisions
- 제품 요구사항
- Product requirements

### Outputs

- 기획, 아키텍처, 운영 관련 문서
- Planning, architecture, and operating documents
- Decision 초안
- Decision drafts

### Must Not

- 코드를 구현하지 않는다
- Do not implement code
- Operational Bootstrap 조정 책임을 Product Implementation 권한으로 해석하지 않는다
- Do not treat responsibility for coordinating Operational Bootstrap as authority for Product Implementation
- 승인 없이 구현하지 않는다
- Do not implement without approval
- 최종 제품 결정을 대신하지 않는다
- Do not make final product decisions
- 디자인을 소유하지 않는다
- Do not own design

## Implementation Role

### Purpose

- 승인된 범위를 Flutter로 구현한다
- Implement the approved scope in Flutter

### Responsibilities

- 승인된 기능을 구현한다
- Implement approved features
- Design Role의 결과를 Flutter UI로 재현한다
- Reproduce Design Role outputs as Flutter UI
- 테스트, 분석, 빌드를 수행한다
- Run tests, analysis, and builds
- 구현에 필요한 문서를 동기화한다
- Synchronize documents required by implementation
- 기술 부채와 수동 확인 항목을 보고한다
- Report technical debt and manual verification items

### Inputs

- 승인된 요구사항과 문서
- Approved requirements and documents
- Design Role 결과
- Design Role outputs
- QA 재작업 요청
- QA rework requests

### Outputs

- 구현 코드와 테스트
- Implementation code and tests
- 분석·빌드·테스트 결과
- Analysis, build, and test results
- 구현 보고
- Implementation reports

### Must Not

- Architecture를 변경하지 않는다
- Do not change Architecture
- 제품 방향을 임의로 바꾸지 않는다
- Do not arbitrarily change product direction
- Design Role 결과를 임의로 재설계하지 않는다
- Do not arbitrarily redesign Design Role outputs
- 자기 작업을 최종 승인하지 않는다
- Do not give final approval to its own work
- User가 첫 Agreement를 승인하기 전에는 Product Implementation을 시작하지 않는다
- Do not begin Product Implementation before the User approves the first Agreement

### Constraints

- 기존 저장소 구조가 권한이다
- Existing repository structure is authoritative
- 문서를 중복 생성하지 않는다
- Do not create duplicate documents
- 현재 작업 범위를 넘기지 않는다
- Do not expand the scope beyond the current task
- 이미 요구사항을 충족하는 산출물을 수정하지 않는다
- Do not modify artifacts that already satisfy the requirements
- Single Source of Truth를 유지한다
- Preserve Single Source of Truth

### Implementation Report Format

Implementation Report는 아래 형식을 사용한다.

Implementation Report uses the following format.

- Status
- Files Modified
- Validation
- Open Questions

Status는 아래 값만 허용한다.

Status allows only the following values.

- Implemented
- Updated
- Verified

## Design Role

### Purpose

- UI/UX와 디자인 시스템을 담당한다
- Own UI/UX and the design system

### Responsibilities

- 화면, 상태, 공통 컴포넌트를 설계한다
- Design screens, states, and shared components
- 디자인 토큰과 시각 기준을 정의한다
- Define design tokens and visual standards
- 구현 가능한 디자인 handoff를 제공한다
- Provide implementation-ready design handoff

### Inputs

- 승인된 제품 범위
- Approved product scope
- User의 디자인 관련 결정
- User decisions related to design
- 제품·아키텍처 문서의 제약
- Constraints from product and architecture documents

### Outputs

- 화면 디자인과 디자인 시스템
- Screen designs and design system
- 디자인 handoff 기준
- Design handoff criteria

### Must Not

- 디자인 외 역할을 수행하지 않는다
- Do not take on non-design roles
- 코드를 구현하지 않는다
- Do not implement code
- Architecture를 변경하지 않는다
- Do not change Architecture
- 최종 제품 결정을 대신하지 않는다
- Do not make final product decisions

## QA Role

### Purpose

- 구현과 분리된 관점에서 품질을 검증한다
- Verify quality from a perspective separated from implementation

### Responsibilities

- 요구사항, 문서, 디자인, 변경 diff를 비교한다
- Compare requirements, documents, designs, and change diffs
- 결함과 누락을 분류한다
- Classify defects and gaps
- Pass, Conditional Pass, Fail 중 하나로 판정한다
- Judge as Pass, Conditional Pass, or Fail
- 수정이 필요하면 구현 재작업 범위를 전달한다
- When fixes are needed, pass a concrete rework scope to implementation

### Inputs

- 요구사항과 권한 문서
- Requirements and authoritative documents
- Design Role 결과
- Design Role outputs
- 구현 변경 diff와 검증 결과
- Implementation change diffs and verification results

### Outputs

- 이슈 목록과 심각도
- Issue list with severity
- 품질 판정
- Quality verdict
- 재작업 범위
- Rework scope

### Must Not

- 코드를 수정하지 않는다
- Do not modify code
- 구현 역할을 대신하지 않는다
- Do not take over the implementation role
- 최종 제품 결정을 대신하지 않는다
- Do not make final product decisions

## Adaptive Role Activation

### Purpose

- 작업 위험도와 영향 범위에 맞는 역할만 활성화한다
- Activate only the Roles required by task risk and impact
- 기술 품질을 유지하면서 불필요한 Agent, QA와 검증 반복을 줄인다
- Preserve technical quality while reducing unnecessary Agents, QA, and repeated verification

### Default Activation

- Low 작업은 Main 실행 주체 하나를 기본으로 하고 독립 QA를 생략한다
- Low-risk work defaults to one Main runtime worker and omits independent QA
- Medium 작업은 Implementation과 독립 QA 1회를 기본으로 하며 Architecture와 Design은 실제 책임이 있을 때만 활성화한다
- Medium-risk work defaults to Implementation and one independent QA pass; activate Architecture and Design only when their responsibilities are actually needed
- High 작업은 Architecture, Implementation과 독립 QA를 기본으로 하며 Design은 UI/UX 범위가 있을 때만 활성화한다
- High-risk work defaults to Architecture, Implementation, and independent QA; activate Design only for UI/UX scope
- Repair는 QA가 필수 결함을 발견했을 때만 수행하고 가능한 경우 기존 역할 실행 주체를 재사용한다
- Perform Repair only when QA finds a required defect, and reuse existing Role workers when practical

### Default Agent Instance Budget

- Low: 1
- Medium: 최대 3 / maximum 3
- High: 최대 4 / maximum 4
- 역할 수와 Agent Instances는 동일하지 않으며 같은 실행 주체가 여러 역할을 수행할 수 있다
- Role count and Agent Instances are not the same; one runtime worker may perform multiple Roles
- 상한을 초과해야 하면 이유와 추가 인스턴스가 줄이는 구체적인 위험을 Agreement에 기록한다
- When exceeding a default limit, record the reason and the concrete risk reduced by each additional instance in the Agreement

### Context and Verification

- Main은 승인된 Agreement, 변경 허용 파일, 보호 대상, 필요한 Authority 발췌, 관련 테스트, 알려진 기준선과 검증 명령만 Context Pack으로 전달한다
- Main passes only the approved Agreement, allowed files, protected scope, required Authority excerpts, relevant tests, known baseline, and verification commands as the Context Pack
- QA는 Agreement, 명시된 candidate, diff와 검증 Evidence를 중심으로 판단하며 PASS 범위를 Main이 처음부터 중복 검토하지 않는다
- QA evaluates the Agreement, explicit candidate, diff, and verification Evidence; Main does not repeat the passed review from the beginning
- 위험도, Verification Ladder, Evidence 재사용과 환경 재시도 규칙의 단일 권한은 `Docs/ARCHITECTURE.md`다
- `Docs/ARCHITECTURE.md` is the single authority for risk levels, the Verification Ladder, Evidence reuse, and environment retry rules

### Execution Profile Lock and Deviation Gate

- Agreement 또는 실행 프로필에 수정 요청이 있으면 구현 전에 최신 통합본을 다시 제시하고 User 승인을 기다린다
- When an Agreement or Execution Profile is revised, re-present the latest consolidated version before implementation and wait for User approval
- User 승인은 마지막으로 제시된 통합 Agreement와 Execution Profile에만 적용한다
- User approval applies only to the last presented consolidated Agreement and Execution Profile
- 통합본은 Risk Level, Risk Reasons, Activated Roles, Agent Instances, Role / Instance Mapping, Capability Tier, Context Pack, Verification Ladder, QA Count, Repair Limit, Environment Attempts / Retries / Time Budget와 Stop Conditions를 포함한다
- The consolidated version includes Risk Level, Risk Reasons, Activated Roles, Agent Instances, Role / Instance Mapping, Capability Tier, Context Pack, Verification Ladder, QA Count, Repair Limit, Environment Attempts / Retries / Time Budget, and Stop Conditions
- 구현 전에 Approved Execution Profile과 Planned Actual Execution을 비교한다
- Before implementation, compare the Approved Execution Profile with Planned Actual Execution
- 필수 Role, 독립 QA, Agent Instances, Context Pack, Verification, QA·Repair 예산, 환경 예산 또는 Stop Conditions가 다르면 실행하지 않고 Profile Delta와 이유를 User에게 제시한다
- When required Roles, independent QA, Agent Instances, Context Pack, Verification, QA or Repair budget, environment budget, or Stop Conditions differ, do not execute; present the Profile Delta and reason to the User
- Medium·High의 독립 QA는 Implementation과 다른 Agent Instance 또는 분리된 새 문맥에서 수행하며 Main 자기 검토로 대체하지 않는다
- Independent QA for Medium and High runs in a different Agent Instance or separate fresh context from Implementation and is not replaced by Main self-review
- 필요한 독립 실행 주체를 만들 수 없으면 Main 단독으로 계속하지 않는다
- Do not continue with Main alone when the required independent runtime worker cannot be created
- 실행 중 승인되지 않은 Role, QA, 검증, Repair, 환경 복구 또는 우회를 추가·제거·대체하지 않는다
- Do not add, remove, or substitute unapproved Roles, QA, verification, Repair, environment recovery, or workarounds during execution
- 환경 시도는 최초 1회와 원인이 명확한 재시도 1회, Simulator 또는 Emulator 문제 해결은 기본 10–15분으로 제한하며 예산 소진 후에는 `Environment Blocked`와 남은 수동 확인만 보고한다
- Limit environment work to one initial attempt and one retry with a clear cause, and Simulator or Emulator troubleshooting to 10–15 minutes by default; after exhaustion, report only `Environment Blocked` and remaining manual verification
- Repair는 기존 Execution Profile을 초기화하지 않으며 Required Defect, Allowed Files, Focused Verification, QA Recheck Scope와 Additional Attempt Budget만 Delta로 제시한다
- Repair does not reset the existing Execution Profile; present only Required Defect, Allowed Files, Focused Verification, QA Recheck Scope, and Additional Attempt Budget as its Delta

## Provider Policy

### Purpose

- Role과 Provider를 분리한다
- Separate Roles from Providers

### Rules

- Role은 책임과 권한을 나타낸다
- Roles describe responsibility and authority
- Provider는 Role을 수행하는 교체 가능한 실행 도구다
- Providers are replaceable runtime tools that perform Roles
- 같은 사람이 여러 Role을 수행할 수 있다
- The same person may perform multiple Roles
- 하나의 Provider가 여러 Role을 수행할 수 있다
- One Provider may perform multiple Roles
- Provider가 바뀌어도 Factory 원칙, 역할, 워크플로 문서를 수정하지 않는다
- Changing Providers must not require changes to Factory principles, roles, or workflow documents
