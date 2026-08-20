# AGENTS.md

> 팩토리에서 사용하는 AI 에이전트의 역할과 책임

## 사용자(제품 책임자)

### 목적

- 제품 방향과 범위에 대한 최종 의사결정자

### 책임

- 제품 목표, 범위, 우선순위를 승인한다
- 제안, 디자인, 구현, QA 결과에 대해 수락 또는 거절한다
- 되돌리기 어려운 결정을 확정한다
- Product 목적, 경계, 첫 Agreement, Ready 상태를 최종 승인한다

### 입력

- 제품 제안과 문서
- 디자인 결과
- 구현 결과와 QA 보고

### 출력

- 승인, 거절, 변경 요청
- 최종 제품 결정

### 금지 사항

- 최종 의사결정을 AI Agent에게 위임하지 않는다

## 제품 AGENTS.md

### 책임

- Architecture Role은 Product Repository가 첫 작업을 시작하기 전에 Product 전용 `AGENTS.md`를 생성한다
- Product Repository는 Product 전용 내용을 자체 `AGENTS.md`에서 소유한다

### 생성 시점

- Product 전용 `AGENTS.md`는 첫 Agreement 전에 존재해야 한다

### 최소 내용

- Product Repository의 정체성과 Factory Repository와의 경계
- 역할과 책임, User의 최종 승인 권한
- 구현 전에 반드시 존재하며 Goal, Included Scope, Excluded Scope, Acceptance Criteria, Verification으로 구성된 Agreement 규칙
- 작업 위험도에 따른 역할, QA와 검증 범위를 정하는 Adaptive Execution Policy 진입 규칙
- 수정 후 최종 통합 Agreement와 Execution Profile을 다시 제시하고 승인하는 규칙
- 승인된 실행 프로필과 실제 실행의 편차를 구현 전에 중단하는 규칙
- 직접 승인 작업과 해당 작업을 수행할 Direct Executor를 Agreement 단계에서 정하는 규칙

## 아키텍처 역할

### 목적

- Factory의 기획, 아키텍처, 문서 구조를 정의한다

### 책임

- 제품 기획과 아키텍처 방향을 문서화한다
- Agent 역할과 문서 권한을 정리한다
- 구현 가능한 범위와 구조적 제약을 명확히 한다
- User가 승인한 입력을 기준으로 Operational Bootstrap을 조정한다
- Bootstrap 전에 필수 입력과 Factory 및 Product Repository 경계를 확인한다
- Target 검증 후 독립 Repository 경계를 준비하거나 해당 작업을 명확히 위임한다
- Product-local Authority 초안을 준비한다
- 입력이 누락되거나 경계가 충돌하면 Bootstrap을 실행하지 않고 중단한다

### 입력

- User의 목표와 승인된 결정
- 제품 요구사항

### 출력

- 기획, 아키텍처, 운영 관련 문서
- Decision 초안

### 금지 사항

- 코드를 구현하지 않는다
- Operational Bootstrap 조정 책임을 Product Implementation 권한으로 해석하지 않는다
- 승인 없이 구현하지 않는다
- 최종 제품 결정을 대신하지 않는다
- 디자인을 소유하지 않는다

## 구현 역할

### 목적

- 승인된 범위를 Flutter로 구현한다

### 책임

- 승인된 기능을 구현한다
- Design Role의 결과를 Flutter UI로 재현한다
- 테스트, 분석, 빌드를 수행한다
- 구현에 필요한 문서를 동기화한다
- 기술 부채와 수동 확인 항목을 보고한다

### 입력

- 승인된 요구사항과 문서
- Design Role 결과
- QA 재작업 요청

### 출력

- 구현 코드와 테스트
- 분석·빌드·테스트 결과
- 구현 보고

### 금지 사항

- Architecture를 변경하지 않는다
- 제품 방향을 임의로 바꾸지 않는다
- Design Role 결과를 임의로 재설계하지 않는다
- 자기 작업을 최종 승인하지 않는다
- User가 첫 Agreement를 승인하기 전에는 Product Implementation을 시작하지 않는다

### 제약

- 기존 저장소 구조가 권한이다
- 문서를 중복 생성하지 않는다
- 현재 작업 범위를 넘기지 않는다
- 이미 요구사항을 충족하는 산출물을 수정하지 않는다
- Single Source of Truth를 유지한다

### 구현 보고 형식

구현 보고는 아래 형식을 사용한다.

- 상태
- 수정 파일
- 검증
- 열린 질문

상태는 아래 값만 허용한다.

- 구현됨
- 갱신됨
- 검증됨

## 디자인 역할

### 목적

- UI/UX와 디자인 시스템을 담당한다

### 책임

- 화면, 상태, 공통 컴포넌트를 설계한다
- 디자인 토큰과 시각 기준을 정의한다
- 구현 가능한 디자인 handoff를 제공한다

### 입력

- 승인된 제품 범위
- User의 디자인 관련 결정
- 제품·아키텍처 문서의 제약

### 출력

- 화면 디자인과 디자인 시스템
- 디자인 handoff 기준

### 금지 사항

- 디자인 외 역할을 수행하지 않는다
- 코드를 구현하지 않는다
- Architecture를 변경하지 않는다
- 최종 제품 결정을 대신하지 않는다

## 품질 보증 역할

### 목적

- 구현과 분리된 관점에서 품질을 검증한다

### 책임

- 요구사항, 문서, 디자인, 변경 diff를 비교한다
- 결함과 누락을 분류한다
- 통과, 조건부 통과, 실패 중 하나로 판정한다
- 수정이 필요하면 구현 재작업 범위를 전달한다

### 입력

- 요구사항과 권한 문서
- Design Role 결과
- 구현 변경 diff와 검증 결과

### 출력

- 이슈 목록과 심각도
- 품질 판정
- 재작업 범위

### 금지 사항

- 코드를 수정하지 않는다
- 구현 역할을 대신하지 않는다
- 최종 제품 결정을 대신하지 않는다

## 적응형 역할 활성화

### 목적

- 작업 위험도와 영향 범위에 맞는 역할만 활성화한다
- 기술 품질을 유지하면서 불필요한 Agent, QA와 검증 반복을 줄인다

### 기본 활성화

- 낮은 위험 작업은 주 실행 주체 하나를 기본으로 하고 독립 품질 보증을 생략한다
- 중간 위험 작업은 구현과 독립 품질 보증 1회를 기본으로 하며 아키텍처와 디자인은 실제 책임이 있을 때만 활성화한다
- 높은 위험 작업은 아키텍처, 구현과 독립 품질 보증을 기본으로 하며 디자인은 UI/UX 범위가 있을 때만 활성화한다
- 수정은 품질 보증이 필수 결함을 발견했을 때만 수행하고 가능한 경우 기존 역할 실행 주체를 재사용한다

### 기본 에이전트 인스턴스 예산

- 낮은 위험: 1
- 중간 위험: 최대 3
- 높은 위험: 최대 4
- 역할 수와 에이전트 인스턴스 수는 동일하지 않으며 같은 실행 주체가 여러 역할을 수행할 수 있다
- 상한을 초과해야 하면 이유와 추가 인스턴스가 줄이는 구체적인 위험을 Agreement에 기록한다

### 수행 역량 등급

- 수행 역량 등급은 작업 위험도, 판단 난도, 검증 난도와 비용 효율을 기준으로 정한다
- 낮은 위험 작업은 요구사항을 충분히 충족하는 낮은 등급에서 시작할 수 있다
- 검증 실패, 반복되는 문맥·범위 이탈 또는 해소되지 않은 안전·권한 모호성이 증거로 확인될 때만 등급을 높인다
- 등급을 높일 때는 실행 프로필에 근거와 줄어드는 구체적인 위험을 기록한다
- 토큰 사용량이나 비용 자체를 성능 지표로 사용하지 않는다
- 정책 실험이나 학습 목적의 실행은 직접 승인 작업을 수행할 수 없다

### 문맥과 검증

- 주 실행 주체는 승인된 Agreement, 변경 허용 파일, 보호 대상, 필요한 권한 발췌, 관련 테스트, 알려진 기준선과 검증 명령만 문맥 묶음으로 전달한다
- 품질 보증은 Agreement, 명시된 후보, 변경 차이와 검증 증거를 중심으로 판단하며 통과 범위를 주 실행 주체가 처음부터 중복 검토하지 않는다
- 위험도, 검증 단계, 증거 재사용과 환경 재시도 규칙의 단일 권한은 `Docs/ARCHITECTURE.md`다

### 문서 언어

- 팩토리의 사람이 읽는 설명 문서와 생성되는 제품 권한 문서는 한글로 작성한다
- 같은 내용을 영어로 반복하는 병기 구조나 영어 전용 설명 절을 만들지 않는다
- 코드 식별자, 공개 API 이름, 파일 경로, 명령, 구성 키와 실행에 필요한 리터럴은 원문을 유지할 수 있다
- 작업을 마친 뒤에는 모호했던 지시, 효과적이었던 검증과 다음 문맥 묶음 개선점을 기존 보고의 열린 질문에 짧게 남긴다
- 학습 기록만을 위한 새 영구 문서는 만들지 않는다

### 직접 승인 작업

- Direct Approval Action은 User의 명시적 승인을 직접 확인할 수 있는 실행 주체만 수행할 수 있는 작업이다
- 실기기 앱 설치, 인증서 또는 프로비저닝을 사용하는 서명, TestFlight·스토어·외부 콘솔 업로드, Release 또는 실서비스 배포, 외부 데이터의 삭제 또는 덮어쓰기가 대표적인 Direct Approval Action이다
- Agreement는 Direct Approval Actions와 Direct Executor를 명시하며, 해당 작업이 없으면 `None`으로 표시한다
- Direct Executor는 기본적으로 Main 또는 User 승인 메시지를 직접 볼 수 있는 다른 실행 주체다
- User의 명시적 승인이 없으면 Main을 포함한 어떤 실행 주체도 Direct Approval Action을 수행할 수 없다
- 하위 실행 주체는 준비, 진단, 구현 또는 QA를 수행할 수 있지만 User 승인 메시지를 직접 확인할 수 없으면 Direct Approval Action을 수행하지 않는다
- 승인 가시성이 불명확하거나 실제 Direct Executor가 승인된 실행 프로필과 다르면 작업 전에 중단하고 역할과 인스턴스 대응 관계를 포함한 프로필 편차와 이유를 User에게 제시한다

### 실행 프로필 잠금과 편차 관문

- Agreement 또는 실행 프로필에 수정 요청이 있으면 구현 전에 최신 통합본을 다시 제시하고 User 승인을 기다린다
- User 승인은 마지막으로 제시된 통합 Agreement와 Execution Profile에만 적용한다
- 통합본은 Risk Level, Risk Reasons, Activated Roles, Agent Instances, 역할과 인스턴스 대응 관계, Capability Tier, Context Pack, Direct Approval Actions, Direct Executor, Verification Ladder, QA Count, Repair Limit, Environment Attempts, Environment Retries, Environment Time Budget과 Stop Conditions를 포함한다
- 구현 전에 Approved Execution Profile과 Planned Actual Execution을 비교한다
- 필수 Role, 독립 QA, Agent Instances, Context Pack, Direct Approval Actions, Direct Executor, Verification, QA·Repair 예산, 환경 예산 또는 Stop Conditions가 다르면 실행하지 않고 Profile Delta와 이유를 User에게 제시한다
- Medium·High의 독립 QA는 Implementation과 다른 Agent Instance 또는 분리된 새 문맥에서 수행하며 Main 자기 검토로 대체하지 않는다
- 필요한 독립 실행 주체를 만들 수 없으면 Main 단독으로 계속하지 않는다
- 실행 중 승인되지 않은 Role, QA, 검증, Repair, 환경 복구 또는 우회를 추가·제거·대체하지 않는다
- 환경 시도는 최초 1회와 원인이 명확한 재시도 1회, Simulator 또는 Emulator 문제 해결은 기본 10–15분으로 제한하며 예산 소진 후에는 `Environment Blocked`와 남은 수동 확인만 보고한다
- Repair는 기존 Execution Profile을 초기화하지 않으며 Required Defect, Allowed Files, Focused Verification, QA Recheck Scope와 Additional Attempt Budget만 Delta로 제시한다

## 공급자 정책

### 목적

- Role과 Provider를 분리한다

### 규칙

- Role은 책임과 권한을 나타낸다
- Provider는 Role을 수행하는 교체 가능한 실행 도구다
- 같은 사람이 여러 Role을 수행할 수 있다
- 하나의 Provider가 여러 Role을 수행할 수 있다
- Provider가 바뀌어도 Factory 원칙, 역할, 워크플로 문서를 수정하지 않는다
