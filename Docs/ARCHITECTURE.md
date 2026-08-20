# ARCHITECTURE.md

> Factory의 전체 구조  

## 목적

- Factory와 Product Repository의 경계, Factory 저장소의 구조, 각 영역의 책임을 정의한다
- Factory Bootstrap의 실행 계약을 정의하되 Product 기능 구현 방법과 세부 도구 호출 절차는 다루지 않는다

## 저장소 우선 규칙

- 저장소가 진실의 원천이다
- 지시사항이 현재 저장소 구조와 충돌하면 저장소를 따른다
- 불일치는 Open Questions에 보고한다

## 저장소 구조

현재 저장소 기준 구조다.

```text
.
├── AGENTS.md
├── LICENSE
├── README.md
├── bin/
│   ├── factory_bootstrap.dart            # active V1.1 command entrypoint
│   └── factory_product_loop.dart         # active V1.2.1 command entrypoint
├── factory.yaml                         # inactive legacy metadata
├── factory_manifest.json                # inactive legacy metadata
├── lib/
│   ├── ai_flutter_app_factory.dart       # active Executable V1 public API
│   └── core/
│       ├── bootstrap/                    # active Executable V1 runtime
│       ├── product_loop/                 # active V1.2 runtime and V1.2.1 command layer
│       ├── factory/                      # inactive legacy source
│       ├── generator/                    # inactive legacy source
│       └── template/                     # inactive legacy source
└── Docs/
    ├── ARCHITECTURE.md
    ├── DESIGN.md
    ├── PRODUCT.md
    ├── ROADMAP.md
    ├── SETUP.md
    ├── USER_GUIDE.md
    ├── VISION.md
    ├── Architecture/
    │   └── Template-Specification.md
    └── Decisions/
        ├── README.md
        ├── DR-001-ai-role-handoff.md
        ├── DR-002-minimal-documentation.md
        └── DR-003-repository-owns-domain-mapping.md
```

## 기반 계층

### 정체성

- Factory가 무엇인지 식별한다
- 이름, 역할 경계, 저장소 소개가 여기에 속한다

### 구성

- Factory 수준의 최소 설정을 담는다
- 프로젝트별 앱 설정은 포함하지 않는다

### 지식

- 권한 있는 문서와 결정을 담는다
- Factory의 목적, 구조, 역할, 순서, 환경의 기준이 된다

### 자산

- 디자인·정적 산출물의 위치를 담당한다
- 현재 저장소에는 Assets 디렉터리가 없다

## 디렉터리 책임

### `/`(저장소 루트)

- Factory Identity와 Configuration 파일을 둔다
- Knowledge와 Assets의 진입점이 된다

### `Docs/`

- Knowledge 계층의 권한 문서를 둔다
- 문서마다 하나의 주제만 담당한다

### `Docs/Decisions/`

- 되돌리기 어려운 결정 기록의 위치다
- Decision의 세부 내용 자체는 이 문서에 복사하지 않는다

## 저장소 경계

- Factory와 Product는 독립 Repository와 독립 Git History를 가진다
- Factory Repository는 Factory의 목적, 역할, 구조, Product Repository 준비 기준을 소유한다
- Product Repository는 Product 전용 문서와 내부 개발을 소유한다
- Product는 Factory를 수정하지 않는다
- Factory는 Product 내부 개발을 수행하지 않는다

## 상위 수준 생명주기

아래 단계의 Product 내부 실행은 Product Repository의 책임이다.

Factory Bootstrap은 이 Product 내부 lifecycle 전에 독립 Repository, 운영 Authority와 승인된 기술적 시작 상태를 준비한다.

### 결정

- 되돌리기 어려운 방향을 확정한다

### 아키텍처

- Factory와 제품의 구조를 정의한다

### 구현

- 승인된 범위를 구현한다

### 검증

- 구현 결과를 검증한다

## Bootstrap 계약

Bootstrap은 특정 코드나 Template을 생성하는 행위로 한정되지 않는다. Bootstrap의 목적은 독립 Product Repository를 준비하고, 새로운 작업 주체가 Factory를 다시 읽지 않아도 Product-local 정보만으로 첫 Agreement를 제안할 수 있는 상태를 만드는 것이다.

- Bootstrap은 Repository 경계와 운영 컨텍스트를 준비한다
- Product Implementation은 Ready 검증, Baseline Handoff Proposal 제시, Ready 상태와 baseline에 대한 User 승인, 첫 Product Agreement 승인이 모두 완료된 이후 Product 내부에서 수행한다
- Factory는 Bootstrap 이후 Product 내부 구현에 개입하지 않는다

### 운영 Bootstrap과 실행형 Bootstrap

Operational Bootstrap은 모든 Product에 필요한 Repository 경계, Product-local 운영 Authority, 첫 Agreement 준비 상태와 baseline lifecycle을 정의한다.

Executable Flutter Bootstrap은 Factory V1의 Operational Bootstrap 적용 범위다. Operational Bootstrap을 유지하면서 Flutter/Dart 기반 iOS 및 Android 기본 구조와 필수 기술 검증을 추가한다.

외부 consumer의 공식 Executable V1 실행 경계는 package-root `ai_flutter_app_factory.dart`와 `FlutterAppFactoryRuntime` façade다. Façade는 기존 preflight와 executor를 조정하며 별도의 Bootstrap Architecture나 동작을 정의하지 않는다.

### V1.1 한 번 실행 명령 경계

V1.1 명령은 Factory 밖의 명시적 절대 경로에 있는 `product_request.yaml` 하나를 엄격하게 검사하고 기존 열 개 입력의 `BootstrapRequest`로 변환한다. parse 또는 schema 실패 시 Runtime을 호출하지 않는다.

```text
product_request.yaml
→ strict request adapter
→ BootstrapRequest
→ FlutterAppFactoryRuntime.inspect
→ BootstrapPreflightReady only
→ FlutterAppFactoryRuntime.execute
→ versioned JSON result and Korean-first summary
```

V1.1 command layer는 기존 Runtime의 preflight, 실행, ownership, rollback 또는 승인 의미를 대체하지 않는다. Product 기능을 구현하거나 Provider를 호출하지 않는다. V1.2 Product Loop Guard Runtime foundation은 아래 별도 계약을 따르며, Agent Adapter는 구현되어 있지 않다.

### V1.2 제품 루프 보호 계약

V1.2 Product Loop Guard는 Bootstrap 이후 Product Repository 안에서 수행되는 작은 Agreement의 기준선, 검증과 승인 경계를 정의한다. 이 계약은 특정 Provider, 모델 또는 IDE를 전제하지 않는다.

현재 V1.2 범위는 운영 계약과 이를 실행하는 공개 Dart Runtime foundation이다. Agent Adapter, Provider 연동과 orchestration은 구현되어 있지 않다.

```text
captureBaseline
→ ProductLoopBaselineProposal
→ inspect expected baseline
→ ProductLoopGuardReady
→ external approved Product implementation
→ validate QA candidate and Flutter Health Gate
→ ProductLoopCandidateValidated | ProductLoopValidationStopped
```

Runtime은 Product 기능을 구현하거나 Product Context 의미를 승인하지 않는다. 승인된 외부 구현 전후의 Repository 상태와 기술 검증 Evidence만 제공한다.

#### V1.2.1 명령 경계

V1.2.1 command layer는 기존 Product Loop Guard Runtime의 승인 의미를 바꾸지 않고 단일 실행 창구를 제공한다.

```text
strict product_loop_request.yaml
→ capture
→ persistent baseline proposal JSON + SHA-256
→ User baseline approval
→ external approved Product implementation
→ validate with the approved SHA-256
→ persistent candidate validation Evidence
→ risk-based independent QA when required
→ User result approval
```

- 요청 파일과 Evidence 디렉터리는 Factory 및 Product Repository 밖에 존재한다
- Capture artifact는 요청 파일 hash, build policy와 immutable Product snapshot을 포함한다
- Validate는 현재 요청과 artifact 및 User가 전달한 승인 SHA-256이 모두 일치할 때만 Health Gate를 실행한다
- command는 결과 artifact를 쓰기 직전에 요청 파일, 승인 baseline과 Evidence 디렉터리 ownership을 다시 검사한다
- command layer는 외부 Product 구현, QA 판정, User 승인 또는 Git 작업을 수행하지 않는다
- 성공 결과도 QA와 User 승인은 `Pending`, commit은 `NotPerformed`로 유지한다

#### 제품 작업 기준선

- Agreement 구현 전에 Product root, branch, HEAD와 staged, modified, untracked 및 deleted 상태를 capture한다
- clean committed 상태는 HEAD를 내용 식별자로 사용하고, non-clean 상태는 staged·unstaged diff와 untracked 파일 내용을 식별할 수 있는 hash, manifest 또는 동등한 immutable snapshot Evidence를 함께 capture한다
- User가 승인한 기준선 또는 Approved Operational Baseline Handoff와 실제 상태를 비교한다
- 승인된 non-clean 상태는 허용하지만 알려지지 않은 차이가 있으면 수정 전에 중단한다
- Product 작업 기준선은 Bootstrap Ready 상태를 다시 승인하거나 Factory를 다시 읽도록 요구하지 않는다

#### 품질 보증 후보 기준선

- 구현과 자체 검증이 끝나면 QA가 검토할 Product 상태를 별도 candidate baseline으로 capture한다
- candidate에는 최소한 Product root, branch, HEAD, 전체 Git status와 Product 내용 변경을 식별하는 Evidence가 포함된다
- clean committed candidate는 HEAD로 내용을 고정하고, non-clean candidate는 staged·unstaged diff와 untracked 파일 내용을 식별할 수 있는 hash, manifest 또는 동등한 immutable snapshot identifier를 사용한다
- QA는 명시된 candidate와 Agreement, diff 및 검증 Evidence만 판정한다
- candidate capture 이후 Product 상태가 바뀌면 기존 QA 판정을 사용하지 않고 중단한 뒤 새 candidate로 다시 검증한다

#### Flutter 상태 검증 관문

Flutter Product의 기본 Health Gate는 다음 검증을 포함한다.

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

- Agreement, dependency, platform 또는 release 영향 범위에 따라 Android APK와 iOS Simulator build를 추가한다
- Agreement는 수행할 build와 생략할 검증 및 이유를 명시한다
- 필수 검증이 실패하거나 실행되지 못하면 QA PASS 또는 완료 상태를 제안하지 않는다

#### 적응형 실행 정책

Adaptive Execution Policy는 외부 Product 구현에서 작업 위험도에 맞는 역할, Agent Instances, QA와 검증 범위를 선택하는 운영 계약이다. 특정 Provider, 모델 또는 IDE를 전제하지 않는다.

이 정책은 V1.2.1 Product Loop Runtime의 고정된 기준선, Health Gate, QA candidate와 승인 의미를 변경하지 않는다. 현재 Runtime을 실행하면 그 Runtime에 정의된 기술 검증은 그대로 수행된다. Adaptive Execution Policy는 외부 구현 역할과 추가 검증을 불필요하게 확대하지 않기 위한 Core 운영 기준이다.

##### 실행 프로필 잠금

Agreement 또는 Execution Profile에 수정 요청이 한 번이라도 있으면 구현 전에 최신 통합본을 다시 제시한다. User 승인은 마지막으로 제시된 통합본에만 적용하며, 이전 버전이나 부분 수정안에 임의로 연결하지 않는다.

통합본은 다음 실행 계약을 빠짐없이 포함한다.

```text
Risk Level
Risk Reasons
Activated Roles
Agent Instances
Role / Instance Mapping
Capability Tier
Context Pack
Direct Approval Actions
Direct Executor
Verification Ladder
QA Count
Repair Limit
Environment Attempts / Retries / Time Budget
Stop Conditions
```

##### 실행 전 프로필 관문

구현 전에 Approved Execution Profile과 Planned Actual Execution을 비교한다. 필수 Role, 독립 QA, Agent Instances, Context Pack, Direct Approval Actions, Direct Executor, Verification Ladder, QA·Repair 횟수, 환경 시도·재시도·시간 예산 또는 Stop Conditions 중 하나라도 다르면 구현이나 추가 검증을 시작하지 않는다. 대신 차이, 이유와 필요한 Profile Delta를 User에게 제시하고 승인을 기다린다.

##### 직접 승인 작업 경계

Direct Approval Action은 User의 명시적 승인을 직접 확인할 수 있는 실행 주체만 수행할 수 있는 작업이다. Agreement는 Direct Approval Actions와 Direct Executor를 명시하며, 해당 작업이 없으면 `None`으로 표시한다.

대표적인 Direct Approval Action은 실기기 앱 설치, 인증서 또는 프로비저닝을 사용하는 서명, TestFlight·스토어·외부 콘솔 업로드, Release 또는 실서비스 배포, 외부 데이터의 삭제 또는 덮어쓰기다. 빌드 산출물 생성은 실제 배포가 아니며, 이 자체만으로 Direct Approval Action이 되지 않는다.

Direct Executor는 기본적으로 Main 또는 User 승인 메시지를 직접 볼 수 있는 다른 실행 주체다. User의 명시적 승인 없이는 Main을 포함한 어떤 실행 주체도 Direct Approval Action을 수행할 수 없다. 하위 실행 주체는 준비, 진단, 구현 또는 QA를 수행할 수 있지만 승인 메시지를 직접 확인할 수 없으면 Direct Approval Action을 수행하지 않는다.

승인 가시성이 불명확하거나 실제 Direct Executor가 승인된 실행 프로필과 다르면 해당 작업 전에 중단한다. 실행하지 않은 상태에서 역할과 인스턴스 대응 관계, 차이와 이유를 포함한 프로필 편차를 User에게 제시하고 승인을 기다린다.

##### 독립 품질 보증 인스턴스 규칙

Medium과 High에서 요구되는 Independent QA는 Implementation과 다른 Agent Instance 또는 분리된 새 문맥에서 수행한다. Main의 자기 검토로 대체하지 않으며, 필요한 독립 실행 주체를 만들 수 없으면 Main 단독으로 계속하지 않는다. QA에는 Agreement, 명시된 candidate, diff와 검증 Evidence만 전달한다.

##### 실행 편차와 환경 예산 관문

실행 중 User 승인 없이 Role 또는 QA를 추가·제거하거나, 검증 범위를 강화·약화하거나, Repair·환경 시도·환경 복구·다른 플랫폼 또는 도구 우회를 추가하지 않는다. 환경 실패는 기능 Repair나 Risk Level 변경의 근거가 아니다.

환경 검증은 최초 시도 1회와 실패 원인이 명확할 때의 재시도 1회를 기본 한도로 하며, Simulator 또는 Emulator 복구를 포함한 문제 해결은 기본 10–15분 안에서 중단한다. 예산을 소진하면 서비스 재시작, Simulator 초기화, 다른 기기 사용 또는 다른 우회로 진행하지 않고 `Environment Blocked`와 남은 수동 확인만 보고한다.

##### 수정과 실제 보고 관문

Repair는 기존 Execution Profile을 자동으로 초기화하지 않는다. Repair 제안은 Required Defect, Allowed Files, Focused Verification, QA Recheck Scope와 Additional Attempt Budget만 Delta로 제시하며, 새 Agent Instance가 필요하면 이유를 명시한다.

최종 보고에는 아래 Approved-vs-Actual 비교를 포함한다. 승인되지 않은 편차가 있으면 Technical Result가 PASS여도 Adaptive Policy Safety는 FAIL이다.

```text
Approved vs Actual

Risk Level:
Roles:
Agent Instances:
Role / Instance Mapping:
Context Pack:
Direct Approval Actions:
Direct Executor:
QA Count:
Repair Count:
Verification Level:
Environment Attempts:
Environment Retries:
Environment Time:
Deviations:
```

##### 위험도 분류

**낮은 위험**

- 문구, 색상, spacing, 작은 문서 또는 명백하고 제한된 단일 파일 변경
- 소스, dependency, 서명 또는 원격 상태를 바꾸지 않는 기존 검증 코드의 빌드 산출물 생성
- 기본 실행은 Main 실행 주체 1개, 독립 QA 생략, 관련 검증만 수행한다

**중간 위험**

- 일반 기능, 여러 파일의 사용자 흐름 또는 비파괴적 상태·저장 동작 변경
- Implementation과 독립 QA 1회를 기본으로 하며 Architecture와 Design은 해당 책임이 실제로 필요할 때만 활성화한다

**높은 위험**

- 데이터 모델·migration·저장 호환성, 네이티브 플랫폼 경계, 알림, Live Activity, Widget, 인증, 결제, 보안, 실제 원격 배포, 파괴적 작업 또는 대규모 구조 변경
- Architecture, Implementation과 독립 QA를 기본으로 하며 UI/UX 범위가 있을 때만 Design을 활성화한다

빌드 산출물 생성은 실제 배포가 아니다. 환경 오류나 Simulator 장애도 Risk Level을 높이는 근거가 아니다. User가 명시적으로 더 강한 검증을 요청하면 그 요청을 따른다.

##### 역할과 에이전트 예산

기본 Agent Instances 상한은 Low 1, Medium 3, High 4다. 역할 수와 Agent Instances를 같은 값으로 취급하지 않으며 하나의 실행 주체가 여러 역할을 수행할 수 있다. 상한을 초과하면 이유와 추가 인스턴스가 줄이는 구체적인 위험을 Agreement에 기록한다.

Repair는 QA가 필수 결함을 발견했을 때만 수행한다. 가능한 경우 기존 역할 실행 주체를 재사용하고, Repair QA는 필수 결함과 영향을 받은 회귀 범위에 집중한다.

##### 수행 역량 등급

수행 역량 등급은 작업 위험도, 판단 난도, 검증 난도와 비용 효율을 함께 고려해 정한다.

- 낮은 위험 작업은 요구사항을 충분히 충족하는 낮은 등급에서 시작할 수 있다
- 검증 실패, 반복되는 문맥·범위 이탈 또는 해소되지 않은 안전·권한 모호성이 증거로 확인될 때만 등급을 높인다
- 등급을 높일 때는 실행 프로필에 근거와 줄어드는 구체적인 위험을 기록한다
- 토큰 사용량이나 비용 자체를 성능 지표로 사용하지 않는다
- 정책 실험이나 학습 목적의 실행은 직접 승인 작업을 수행할 수 없다

##### 문맥 묶음

Main은 하위 작업 주체에게 다음 최소 Context Pack을 전달한다.

- 승인된 Agreement
- 변경 허용 파일과 보호 대상
- 필요한 Authority 발췌
- 관련 테스트
- 알려진 기준선과 검증 명령

하위 작업 주체는 전체 Repository 문서를 반복해서 읽지 않는다. 범위 밖 조회가 필요하면 이유와 조회 대상을 보고한다.

##### 검증 단계

```text
V0  scope, diff, format, and static document checks
V1  focused tests
V2  analyze and full tests
V3  affected platform builds
V4  Simulator or Emulator
V5  physical device, live service, or actual deployment environment
```

Agreement의 위험과 Acceptance Criteria를 증명하는 최소 단계까지만 수행한다. 모든 작업이 V5까지 갈 필요는 없으며 상위 단계는 하위 단계로 증명할 수 없는 위험이 있을 때만 활성화한다.

##### 증거 재사용

소스와 dependency 기준선, 영향을 받는 플랫폼 설정, 검증 대상과 검증 환경에 영향을 주는 설정이 모두 같으면 기존 Evidence를 재사용할 수 있다. 기준 commit, hash 또는 동일성을 확인한 방법과 검증 생략 이유를 보고한다.

##### 재시도와 시간 예산

환경 검증은 최초 시도 1회와 실패 원인이 명확할 때의 재시도 1회를 기본 한도로 한다. Simulator 또는 Emulator 문제 해결은 기본 10–15분 안에서 중단한다. 한도를 소진하면 Risk Level을 높이거나 무기한 우회하지 않고 환경 차단과 남은 수동 확인을 보고한다.

##### 원격 검증 효율 보호

- 원격 검증은 최신 동일 범위 Evidence로 예상 소요 시간을 계산하고, 예상 shard가 15분을 넘으면 실행 전에 분할한다.
- 첫 timeout 뒤에는 구조적 sharding을 검토하기 전 timeout만 늘리는 Repair를 금지한다.
- 상태 확인은 시작, 예상 완료 시점, 최종의 최대 세 번으로 제한하며 Main은 연속 polling하지 않는다.
- 확인 예산을 소진하면 실행 URL을 인계하고 능동 monitoring을 중단한다.
- 원격 실패 뒤에는 같은 Agreement 안에서 재시도하지 않는다.

##### 품질 보증과 결과 경계

- Low는 독립 QA를 기본 생략한다
- Medium은 독립 QA 1회를 기본으로 한다
- High는 독립 QA를 필수로 한다
- QA PASS 후 Main은 같은 범위를 처음부터 중복 검토하지 않는다

최종 판정은 Technical Quality, Product Ready, Adaptive Policy Safety와 Adaptive Policy Efficiency를 분리한다. 기술 결과가 PASS여도 불필요한 역할, 전체 테스트 반복 또는 환경 재시도가 있었다면 Efficiency는 개선 필요 또는 FAIL일 수 있다.

##### 보고 경계

기본 User 보고는 결과, 변경 또는 산출물, 수행한 검증, 남은 수동 확인과 Git·배포 여부만 포함한다. 상세 Agent·명령·토큰 Evidence는 High 작업, 실패·Repair, 정책 실험 또는 User 요청이 있을 때 확장한다. 측정할 수 없는 값은 추정하지 않는다.

User 요청 없이 README, release 상태 또는 다른 Product 문서를 동기화하지 않는다.

##### 학습 환류

작업을 마친 주 실행 주체는 모호했던 지시, 효과적이었던 검증과 다음 문맥 묶음 개선점을 기존 결과 보고의 열린 질문에 짧게 남긴다. 학습 기록만을 위한 새 영구 문서는 만들지 않으며, 검증된 학습만 기존 단일 기준 정보원에 최소 반영한다.

#### 제품 문맥 이탈 관문

- milestone 종료 전에 Product-local `README.md`, `AGENTS.md`, 승인된 기준선과 실제 Product 상태를 비교한다
- 승인된 장기 기능, 범위 또는 운영 규칙이 달라졌을 때만 기존 Product SSOT를 최소 수정한다
- 임시 Agreement, 구현 세부 정보 또는 자동 추론을 영구 Product 지식으로 만들지 않는다
- Product Context의 의미적 정확성을 자동 판정하는 기능은 현재 V1.2 계약에 포함하지 않는다

#### 제품 루프 승인 경계

- QA PASS는 User 승인, commit, push, Ready 또는 release를 의미하지 않는다
- User가 candidate 결과와 Product Context를 승인한 뒤에만 다음 작업 또는 별도 승인된 Git 작업으로 진행한다
- commit, push, tag와 release는 각각 명시적인 User 요청이 필요하다

#### 제품 루프 중단 조건

다음 중 하나라도 발생하면 기존 candidate 또는 QA 판정을 사용하지 않고 중단한다.

- 승인된 Product 작업 기준선이 없거나 실제 상태와 다름
- 구현 또는 QA 중 예상하지 못한 파일이나 Git 상태가 나타남
- QA candidate capture 이후 Product 상태가 변경됨
- 필수 Flutter Health Gate가 실패하거나 실행되지 못함
- Product Context drift가 해결되지 않았거나 명시적으로 제외되지 않음
- 민감정보, 범위 밖 변경 또는 Repository 경계 충돌이 발견됨

Flutter scaffold와 기본 검증은 Factory Bootstrap 책임이다. Product 기능, 데이터 모델, UI, backend, 인증, 외부 서비스와 Product별 package는 Product-local Agreement가 소유한다.

Factory V1은 Flutter Web, Flutter Desktop 또는 비 Flutter 기술 스택을 지원하지 않는다. 미지원 요청을 다른 기술로 대체하거나 추측하지 않는다.

### 필수 입력

Executable V1 Bootstrap을 시작하기 전에 다음 입력이 모두 명시되어야 한다.

1. Product 표시 이름
2. 한 문장으로 표현한 제품 목적
3. 초기 Product 범위 또는 첫 번째 의도된 결과
4. 정확한 Product Repository 출력 경로
5. 새 Repository 생성 또는 기존 빈 Repository 사용
6. 초기 branch 이름 또는 적용할 Repository policy
7. Flutter project name과 identifier
8. Organization 식별자
9. 요청 기술
10. 대상 플랫폼

입력은 현재 작업 요청이나 User가 승인한 컨텍스트에서 제공될 수 있다.

Factory는 어떤 필수 입력도 임의로 추측하지 않는다.

- Requested technology는 Flutter/Dart여야 한다
- Flutter project name은 Flutter가 허용하는 identifier 형식이어야 한다
- Organization identifier는 명시적으로 입력해야 한다
- Target platforms는 iOS와 Android여야 한다
- 필수 입력이 누락되거나 모호하거나 지원 범위와 다르면 중단한다

필수 입력이 없으면 Bootstrap을 시작하지 않고 질문을 반환한다.

### 필수 출력

#### 저장소 경계

- 명시된 위치의 독립 Product Repository
- Factory와 분리된 Git metadata 및 history
- Factory 내부의 nested Repository나 submodule이 아님
- Factory 파일을 Product에 복사하지 않음

#### Flutter 모바일 기본 구조

- 공식 Flutter toolchain으로 생성된 iOS 및 Android 기본 구조
- Flutter 기본 dependency가 준비된 상태
- 별도 Factory Template을 생성하거나 복사하지 않음
- Product별 package나 기능을 추가하지 않음

#### 기술 검증 증거

- Flutter dependency 준비 성공
- 정적 분석 통과
- 기본 테스트 통과
- Android APK build 통과
- iOS Simulator build 통과

환경 또는 toolchain 문제로 필수 검증을 수행할 수 없으면 Ready로 판정하지 않는다.

#### 제품 README

Product Repository의 `README.md`는 Product identity, Product purpose, Current status, Repository-local 시작 지점을 최소한 설명한다.

Product 목적과 현재 범위를 이해하기 위해 Factory 문서를 다시 읽을 필요가 없어야 한다.

#### 제품 AGENTS

Product Repository의 `AGENTS.md`는 최소한 다음을 포함한다.

- 저장소 정체성과 경계
- 사용자 권한
- 역할과 수정 권한
- 작은 Agreement 규칙
- 범위와 변경 규칙
- 검증 정책
- Git 정책
- 보고 요구사항
- Direct Approval Actions와 Direct Executor
- 한글 문서 규칙

Factory 문장을 그대로 복사하지 않고 Product 관점에서 작성한다. 특정 제품, Provider, 모델 또는 IDE 이름을 역할명으로 사용하지 않는다.

사람이 읽는 Factory 설명 문서와 생성되는 Product 권한 문서는 한글로 작성한다. 같은 내용을 영어로 반복하는 병기 구조나 영어 전용 설명 절을 만들지 않는다. 코드 식별자, 공개 API 이름, 파일 경로, 명령, 구성 키와 실행 리터럴은 원문을 유지할 수 있다.

#### 첫 Agreement 제안

Bootstrap 결과에는 첫 Agreement 제안이 포함되어야 하며, 다음 항목을 포함한다.

- 목표
- 포함 범위
- 제외 범위
- 인수 기준
- 검증

첫 Agreement는 기본적으로 영구 문서로 저장하지 않는다. Agreement는 현재 작업을 통제하는 실행 계약이다. 승인된 결과가 장기 지식이나 Product 결정이 될 때만 기존 Product SSOT를 갱신한다.

첫 Agreement의 구현은 User 승인 이후 Product Repository에서 수행한다.

#### 실행 보고

First Agreement Proposal, Baseline Handoff Proposal, Bootstrap execution report와 Validation Evidence는 실행 결과로 User에게 제시하며 영구 Product 문서로 만들지 않는다.

User 승인 이후에만 Baseline Handoff Proposal이 Approved Operational Baseline Handoff가 된다.

#### 승인된 운영 기준선 인계

Operational Bootstrap의 최종 결과에는 새로운 작업 주체가 Product Repository 상태를 판단할 수 있는 승인된 운영 기준선 인계가 포함되어야 한다.

Bootstrap 실행 중에는 Baseline Handoff Proposal을 먼저 생성하며, User가 Ready 상태와 baseline을 승인한 후에만 Approved Operational Baseline Handoff가 된다.

Baseline의 생명주기는 다음과 같다.

1. Product Repository의 최종 Git 상태를 capture한다.
2. Baseline Handoff Proposal을 생성한다.
3. Proposal과 Evidence를 User에게 제시한다.
4. User가 Ready 상태와 baseline을 승인한다.
5. Proposal이 Approved Operational Baseline Handoff가 된다.
6. 승인된 handoff를 새로운 작업 주체에게 전달한다.

최소 인계 정보는 다음과 같으며 해당 항목이 없으면 `None`으로 명시한다.

- 정확한 제품 저장소 경로
- 현재 브랜치
- HEAD commit 또는 commit이 없다는 사실
- 예상 staged 파일
- 예상 modified 파일
- 예상 untracked 파일
- 예상 deleted 파일
- 해당 상태가 User가 승인한 Bootstrap 기준선인지 여부

Baseline handoff는 Factory 문서 사본이나 Product 기능 및 Architecture 설명이 아니다. Product Repository와 함께 새로운 작업 주체에게 전달되는 runtime handoff metadata이며, 승인된 상태와 예상 밖 변경을 구분하기 위한 운영 상태 정보다.

Baseline handoff는 영구 Product 문서 생성을 요구하지 않으며 특정 Provider, 모델 또는 IDE를 전제하지 않는다.

Product Repository가 반드시 clean일 필요는 없다. 승인된 staged, modified 또는 untracked Bootstrap 산출물이 있을 수 있다. 실제 상태가 User가 승인한 handoff와 정확히 일치하면 그 사실만으로 중단하지 않는다.

실제 상태가 handoff와 다르면 변경 전에 중단하고 보고한다. 승인 기준선이 제공되지 않은 non-clean 상태는 추측하지 않고 중단한다.

### 선택 출력

다음은 모든 Product에 자동으로 생성하지 않는다.

- VISION 문서
- PRODUCT 문서
- DESIGN 문서
- ARCHITECTURE 문서
- Decision 기록
- License
- 추가 설정 문서
- 별도의 Agreement 파일
- 역할별 문서
- Playbook

다음 조건을 모두 만족할 때만 추가한다.

- README 또는 AGENTS의 기존 Authority로 표현할 수 없음
- 새로운 독립 Authority가 실제로 필요함
- 첫 Agreement 수행에 반드시 필요함
- 동일 내용을 다른 문서에 중복하지 않음

Factory 문서 구조를 Product Repository에 그대로 복사하지 않는다.

### Bootstrap 순서

#### 1단계 — 팩토리 기준선 검증

- Factory Repository 상태를 확인한다
- 승인된 기준선과 예상 밖 변경을 구분한다
- 현재 SSOT가 읽을 수 있는 일관된 상태인지 확인한다

Factory가 반드시 clean 또는 committed 상태여야 한다고 가정하지 않는다. 다만 작업에 영향을 줄 수 있는 변경은 명시적으로 알려진 기준선이어야 한다.

#### 2단계 — 입력 검증

- 모든 필수 입력을 확인한다
- Product 정보, Repository 정보, Flutter project name과 organization identifier를 확인한다
- Requested technology가 Flutter/Dart이고 target platforms가 iOS와 Android인지 확인한다
- 입력이 누락되거나 모호하거나 지원 범위와 다르면 중단한다

#### 3단계 — 대상 검증

- 출력 경로가 안전한지 확인한다
- 대상이 존재하면 비어 있거나 명시적으로 허용된 Repository인지 확인한다
- 기존 파일, 기존 Git history 또는 사용자 데이터와 충돌하면 중단한다
- Factory Repository 내부 경로면 중단한다
- 다른 Repository와 충돌하는 경로면 중단한다

#### 4단계 — 저장소 경계 준비

##### 새 저장소 방식

- 명시된 output path가 존재하지 않는지 확인한다
- Target 검증이 성공한 뒤 명시된 경로를 준비한다
- 승인된 branch 이름 또는 Repository policy를 사용해 독립 Git metadata를 초기화한다
- Factory Repository 내부에는 생성하지 않는다

##### 기존 빈 저장소 방식

- 기존 Repository임을 확인한다
- Product 파일 또는 예상하지 못한 내용이 없는지 확인한다
- 기존 Git history와 사용자 데이터를 덮어쓰지 않는다
- 이미 존재하는 Git metadata를 다시 초기화하지 않는다
- 제공된 Repository policy를 보존한다

##### 공통 규칙

- Architecture Role이 Operational Bootstrap을 조정하고 Repository 경계를 확인한다
- Factory와 Product root가 다른지 확인한다
- commit, remote 추가, push는 Bootstrap에 자동으로 포함하지 않는다
- Product source code나 platform 구현은 이 단계에서 생성하지 않는다
- 입력과 실제 Target 상태가 다르면 중단한다

#### 5단계 — Flutter 기본 구조와 제품 내부 권한 준비

- 공식 Flutter toolchain으로 iOS 및 Android 기본 구조를 준비한다
- Flutter 기본 dependency만 준비한다
- Factory Template을 생성하거나 복사하지 않는다
- Product 기능과 Product별 package를 추가하지 않는다

- Product `README.md`를 작성한다
- Product `AGENTS.md`를 작성한다
- 필요한 경우에만 추가 Product SSOT를 작성한다
- Factory 전용 내용과 Product 전용 내용을 혼합하지 않는다

#### 6단계 — 첫 Agreement 준비

- Product Repository의 정보만 사용한다
- 첫 번째 작은 Agreement를 제안한다
- Step 7의 Ready 검증과 baseline 승인 후 첫 Product Agreement에 대한 User 승인을 기다린다
- Agreement를 자동으로 파일화하지 않는다

#### 7단계 — 준비 완료 제품 검증

- Ready 기준을 검증한다
- Flutter dependency 준비, 정적 분석, 기본 테스트, Android APK build와 iOS Simulator build를 검증한다
- Factory Repository 무변경을 확인한다
- Product Repository 상태를 보고한다
- Product Repository의 최종 Git 상태를 확인한다
- Baseline Handoff Proposal을 생성한다
- Proposal과 Evidence를 User에게 제시한다
- User가 최종 Ready 상태와 baseline을 승인한다
- 승인 후 Proposal을 Approved Operational Baseline Handoff로 확정한다
- 승인된 handoff를 새로운 작업 주체에게 전달할 수 있는 상태인지 확인한다

### 중단 조건

다음 중 하나라도 발생하면 Bootstrap을 중단하고 추측하지 않는다.

- 필수 입력 누락
- Requested technology가 Flutter/Dart가 아님
- Target platforms가 iOS와 Android가 아님
- Flutter project name이 허용된 identifier 형식이 아님
- Organization identifier가 누락되거나 모호함
- 출력 경로가 불명확함
- 출력 경로에 기존 사용자 데이터가 있음
- 예상하지 못한 기존 Git Repository가 있음
- Factory와 Product 경계를 분리할 수 없음
- Product 목적, 초기 Product 범위 또는 첫 번째 의도된 결과를 Product-local 문서에 작성할 근거가 없음
- 역할 또는 승인 권한이 불명확함
- 기존 Factory SSOT 사이에 Bootstrap을 바꾸는 충돌이 있음
- Product를 준비하려면 승인되지 않은 Factory 수정이 필요함
- 민감정보가 발견됨
- 필수 Flutter 또는 platform toolchain을 확인할 수 없음
- dependency 준비, 정적 분석, 기본 테스트 또는 필수 build가 실패함
- 승인되지 않은 Product Implementation이 필요함
- 작업 범위를 벗어나는 구조나 문서를 새로 결정해야 함

#### 운영 Bootstrap 중

- 승인된 Bootstrap 범위로 생성된 변경과 예상 밖 변경을 구분한다.
- 실제 Product Git 상태가 Baseline Handoff Proposal에 capture된 상태와 다르면 중단한다.
- Proposal과 Evidence를 User에게 제시하기 전이라는 이유만으로 승인 부재를 중단 조건으로 삼지 않는다.
- 범위 밖 파일, 민감정보 또는 예상하지 못한 Git 상태가 있으면 중단한다.

#### 준비 완료 승인 또는 새 작업 인계 후

- 실제 Product Git 상태가 Approved Operational Baseline Handoff와 다르면 중단한다.
- non-clean 상태에 Approved Operational Baseline Handoff가 제공되지 않으면 추측하지 않고 중단한다.
- 실제 상태가 Approved Operational Baseline Handoff와 정확히 일치하면 non-clean이라는 이유만으로 중단하지 않는다.

중단 보고에는 중단 위치, 확인된 사실, 누락된 입력 또는 결정, 필요한 User 결정, 수행하지 않은 작업을 포함한다.

### Template과 도구 정책

Operational Bootstrap은 Template, Generator, CLI 또는 Automation을 전제로 하지 않는다.

Executable Flutter V1은 존재하지 않는 Template에 의존하지 않는다. 공식 Flutter toolchain을 runtime 구성으로 사용해 iOS와 Android 구조를 준비하며, 별도 Factory Template을 생성하거나 복사하지 않는다.

실행 도구는 교체 가능한 runtime 구성이며 Factory의 역할, 계약 또는 생성 결과의 권한이 아니다. CLI, Template engine 또는 orchestration은 V1 필수 조건이 아니다.

```text
Operational Bootstrap
- Repository boundary
- Product-local authority
- First Agreement readiness

Executable Flutter Bootstrap
- iOS and Android Flutter scaffold
- Default Flutter dependencies
- Required technical verification

Product Implementation
- Product features and data models
- Product UI
- Backend, authentication, and external services
- Product-specific packages
```

기존 Template 및 Generator 설계는 현재 V1 실행 경로가 아니다. 후속 검증과 별도 승인 전까지 V1 계약에 포함하지 않는다.

`factory.yaml`, `factory_manifest.json`, `lib/core/factory/`, `lib/core/template/`, `lib/core/generator/`와 Template Specification은 inactive legacy 자산이며 package-root V1 API에서 사용하거나 export하지 않는다.

### 준비 완료 제품 기준

다음 조건을 모두 만족해야 Ready Product다.

Ready 판정 전 baseline은 Proposal이며, User 승인 후 Approved Operational Baseline Handoff가 되어 새로운 작업 주체에게 전달된다.

1. Product의 정확한 Repository 위치가 확정되어 있음
2. Factory와 분리된 독립 Repository임
3. iOS 및 Android Flutter 기본 구조와 Flutter 기본 dependency가 준비되어 있음
4. 정적 분석, 기본 테스트, Android APK build와 iOS Simulator build가 통과함
5. Product-local `README.md`가 정체성, 목적, 현재 상태를 설명함
6. Product-local `AGENTS.md`가 권한, 역할, Agreement, 변경, 검증 및 Git 규칙을 설명함
7. 승인된 baseline handoff가 새로운 작업 주체에게 전달 가능한 상태이며, 작업 주체는 이를 사용해 Factory를 다시 읽지 않고 Product를 이해할 수 있음
8. Product-local 문서와 handoff metadata가 실제 Git 상태 비교와 첫 Agreement 제안에 충분함
9. 첫 Agreement에 필수 다섯 항목이 포함되어 있음
10. Bootstrap 중 Product Implementation이 시작되지 않음
11. Factory Repository가 Bootstrap으로 인해 변경되지 않음
12. 예상하지 못한 파일, 민감정보 또는 Repository 충돌이 없음
13. Git 상태와 미커밋 Bootstrap 산출물이 승인된 baseline handoff에 명확하게 기록되고 실제 상태와 일치함
14. User가 최종 Ready 상태와 baseline을 승인할 수 있도록 Evidence가 제공됨

Commit은 준비 완료 제품의 필수 조건으로 자동 간주하지 않는다. 준비 완료 제품 산출물이 미커밋 상태라면 승인된 운영 기준선 인계가 예상 Git 상태를 식별해야 한다. Commit과 push에는 별도의 사용자 요청이 필요하다.

## Template과 도구 사슬 흐름

아래 기존 Template 중심 흐름은 현재 Executable Flutter V1 실행 경로가 아니다. 별도로 검증·승인되기 전에는 V1 기능으로 주장하지 않는다.

단방향 진행만 한다.

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

### 초기화

#### 입력

- Factory 진입 요청

#### 출력

- 초기화된 Factory 컨텍스트

### Template 선택

#### 입력

- 초기화된 Factory 컨텍스트

#### 출력

- 선택된 템플릿

### 프로젝트 생성

#### 입력

- 선택된 템플릿

#### 출력

- 생성된 프로젝트

### Manifest 적용

#### 입력

- 생성된 프로젝트
- Factory Manifest

#### 출력

- Manifest가 적용된 프로젝트

### 도구 사슬 실행

#### 입력

- Manifest가 적용된 프로젝트

#### 출력

- Toolchain 실행 결과

### 검증

#### 입력

- Toolchain 실행 결과

#### 출력

- 검증 결과

### 파이프라인 결과

#### 입력

- 검증 결과

#### 출력

- 파이프라인 결과

Pipeline result만으로 Ready Product 기준을 충족한 것은 아니다.
