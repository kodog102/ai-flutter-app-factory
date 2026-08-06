# AI Flutter App Factory

## Overview

이 저장소는 새로운 Flutter 모바일 Product Repository가 일관된 운영 규칙과 실행 가능한 시작 구조를 갖고 즉시 첫 작업을 시작할 수 있도록 준비하는 Factory다.

This repository is a Factory that prepares a new Flutter mobile Product Repository with consistent operating rules and an executable starting structure so that it can begin its first task immediately.

## Mission

Flutter 모바일 Product Repository가 자체 문서, 명확한 책임 경계, 검증된 기본 구조를 갖춘 운영·실행 가능한 시작 상태가 되도록 한다.

Prepare a Flutter mobile Product Repository for an operational and executable start through its own documents, clear responsibility boundaries, and a verified base structure.

Factory V1은 iOS와 Android를 지원한다. Flutter Web, Flutter Desktop, 비 Flutter 기술 스택은 V1 범위가 아니다.

Factory V1 supports iOS and Android. Flutter Web, Flutter Desktop, and non-Flutter technology stacks are outside the V1 scope.

Factory는 특정 Product 분야에 종속되지 않으며, 역할과 계약 및 생성 결과는 특정 실행 환경에 종속되지 않는다.

The Factory is not tied to a specific Product domain, and its roles, contracts, and generated results are not tied to a specific execution environment.

## Ready Outcome

Product Repository만으로 첫 Agreement를 시작할 수 있는 상태

A state where the first Agreement can begin from the Product Repository alone

## Operating Principle

빠른 생성 + 작은 승인 + 빠른 개선

Fast Creation + Small Agreements + Rapid Iteration

## Bootstrap Entry

Executable V1 Bootstrap을 시작하려면 Product 정보, Repository 정보, Flutter project identifier, organization identifier, 요청 기술과 대상 플랫폼을 명시해야 한다.

Starting Executable V1 Bootstrap requires explicit Product information, Repository information, a Flutter project identifier, an organization identifier, the requested technology, and target platforms.

Operational Bootstrap과 Executable Flutter Bootstrap의 전체 입력, 출력, 순서, 중단 조건, Ready Product 기준은 [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md)가 단일 권한을 가진다.

[Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md) is the single authority for the inputs, outputs, sequence, stop conditions, and Ready Product criteria of Operational Bootstrap and Executable Flutter Bootstrap.

비개발자가 샘플 앱을 순서대로 준비하려면 [Docs/USER_GUIDE.md](Docs/USER_GUIDE.md)를 먼저 따른다.

Non-developers can follow [Docs/USER_GUIDE.md](Docs/USER_GUIDE.md) to prepare a sample app step by step.

### V1.1 One-run Bootstrap

V1.1은 Factory 밖의 `product_request.yaml` 하나를 기존 Runtime 입력으로 안전하게 변환하고 한 명령으로 검증된 Flutter Product 시작점을 준비한다.

V1.1 safely adapts one `product_request.yaml` outside the Factory into the existing Runtime inputs and prepares a verified Flutter Product starting point with one command.

```text
dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml
```

요청 파일 위치와 schema는 [Docs/SETUP.md](Docs/SETUP.md), 비개발자 실행·승인 순서는 [Docs/USER_GUIDE.md](Docs/USER_GUIDE.md)를 따른다. V1.1은 Product 기능을 구현하지 않으며 V1.2 Product Loop Guard를 포함하지 않는다.

Follow [Docs/SETUP.md](Docs/SETUP.md) for the request-file location and schema, and [Docs/USER_GUIDE.md](Docs/USER_GUIDE.md) for the non-developer execution and approval flow. V1.1 does not implement Product features and does not include the V1.2 Product Loop Guard.

### V1.2 Product Loop Guard Runtime

Product Loop는 Product Repository에서 작은 Agreement 하나를 안전하게 완료하는 반복 작업 단위다. 자율적으로 Product를 개발하는 AI 기능이 아니라, 승인된 시작 상태와 구현 후 검증 대상을 고정해 예상 밖 변경이 다음 단계로 넘어가지 못하게 하는 운영 흐름이다.

A Product Loop is a repeatable unit of work for safely completing one small Agreement inside a Product Repository. It is not an autonomous AI Product-development feature. It is an operating flow that fixes the approved starting state and the post-implementation validation candidate so unexpected changes cannot proceed to the next stage.

```text
Product 기준선 제안
→ User 기준선 승인
→ 작은 Agreement 구현
→ QA candidate 캡처
→ Flutter Health Gate
→ 독립 QA
→ User 결과 승인
→ 선택적 commit
```

```text
Product baseline proposal
→ User baseline approval
→ Small Agreement implementation
→ QA candidate capture
→ Flutter Health Gate
→ Independent QA
→ User result approval
→ Optional commit
```

V1.2 Runtime foundation은 승인된 Product 기준선을 검사하고, QA candidate를 고정한 뒤 Flutter format, analyze, test와 선택된 Android/iOS build를 실행한다.

The V1.2 Runtime foundation verifies an expected Product baseline, freezes the QA candidate, and then runs Flutter format, analyze, tests, and selected Android/iOS builds.

Product Context 의미 검토, QA 판정과 User 승인은 자동화하지 않는다. Provider, Agent Adapter, orchestration과 V1.2 CLI는 현재 범위가 아니다.

It does not automate semantic Product Context review, the QA verdict, or User approval. Provider integration, an Agent Adapter, orchestration, and a V1.2 CLI are outside the current scope.

Ready Product는 새로운 작업 주체가 Factory를 다시 읽지 않고 Product Repository만으로 첫 Agreement를 제안할 수 있는 상태다.

A Ready Product is a state in which a new work participant can propose the first Agreement from the Product Repository alone without rereading the Factory.

### Active Runtime

```text
BootstrapRequest
    ↓
FlutterAppFactoryRuntime.inspect
    ↓
BootstrapPreflightReady
    ↓
FlutterAppFactoryRuntime.execute
    ↓
BootstrapExecutionPrepared | BootstrapExecutionStopped | BootstrapExecutionPartialFailure
```

```text
ProductLoopGuardRuntime.captureBaseline
    ↓
ProductLoopBaselineProposal
    ↓
ProductLoopGuardRuntime.inspect
    ↓
ProductLoopGuardReady
    ↓
ProductLoopGuardRuntime.validate
    ↓
ProductLoopCandidateValidated | ProductLoopValidationStopped
```

외부 consumer는 package-root API 하나만 import한다.

External consumers import only the package-root API.

```dart
import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';

Future<void> main() async {
  final runtime = FlutterAppFactoryRuntime(
    factoryRoot: Directory('/exact/factory/path'),
  );
  final request = BootstrapRequest(
    productDisplayName: 'Example Product',
    productPurpose: 'Validate the public Factory runtime.',
    initialProductScopeOrFirstIntendedOutcome:
        'Prepare the first Product Agreement.',
    exactOutputPath: '/exact/product/path',
    repositoryMode: RepositoryMode.newRepository.name,
    initialBranchName: 'main',
    repositoryPolicy: null,
    flutterProjectName: 'example_product',
    organizationIdentifier: 'com.example',
    requestedTechnology: 'flutter',
    targetPlatforms: const ['ios', 'android'],
  );

  final preflight = await runtime.inspect(request);
  if (preflight case BootstrapPreflightReady ready) {
    final result = await runtime.execute(ready);
    print(result.runtimeType);
  }
}
```

Executable Flutter V1은 `lib/core/bootstrap/` runtime을 package-root 공개 실행 창구로 조정한다. Template/Generator pipeline은 active V1 경로가 아니며, `factory.yaml`과 `factory_manifest.json`은 inactive legacy metadata다. CLI는 V1 기능이 아니다.

Executable Flutter V1 coordinates the `lib/core/bootstrap/` runtime through the package-root public execution entry point. The Template/Generator pipeline is not the active V1 path, and `factory.yaml` and `factory_manifest.json` are inactive legacy metadata. A CLI is not a V1 capability.

## Role Model

- Roles are stable.
- Providers are replaceable.
- Factory 검증은 테스트 Product 완성보다 우선한다.
- Factory validation takes priority over completing a test Product.

## Repository Structure

```text
.
├── AGENTS.md
├── README.md
├── factory.yaml                         # inactive legacy metadata
├── factory_manifest.json                # inactive legacy metadata
├── lib/
│   ├── ai_flutter_app_factory.dart       # active public V1 API
│   └── core/
│       ├── bootstrap/                    # active V1 runtime
│       ├── product_loop/                 # V1.2 Product Loop Guard runtime
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

## Getting Started

비개발자 Product 시작:

Non-developer Product start:

1. `Docs/USER_GUIDE.md`
2. Product 입력 작성과 Bootstrap 요청 / Complete the Product inputs and request Bootstrap

Factory 검토와 개발:

Factory review and development:

1. `README.md`
2. `AGENTS.md`
3. `Docs/VISION.md`
4. `Docs/ARCHITECTURE.md`

## Foundation Documents

- `AGENTS.md` — AI Agent의 역할과 책임 / Roles and responsibilities of AI agents
- `Docs/VISION.md` — Factory의 존재 목적과 설계 원칙 / Factory purpose and design principles
- `Docs/ARCHITECTURE.md` — Factory의 전체 구조 / Overall Factory structure
- `Docs/ROADMAP.md` — 작업 순서와 단계별 완료 조건 / Work sequence and phase completion criteria

## Development Status

현재 상태: **Flutter V1 Ready — Release Pending**

Current status: **Flutter V1 Ready — Release Pending**

V1.2 Product Loop Guard Runtime foundation: **Completed — User Approved**

실제 Flutter Product에서 자동 Health Gate와 독립 QA가 통과했으며, 실기기 사용은 User가 제공한 수동 검증 Evidence로 승인됐다. Release는 계속 별도 User 결정을 기다린다.

The automated Health Gate and independent QA passed on an actual Flutter Product, and physical-device use was approved from User-provided manual verification Evidence. Release continues to await a separate User decision.

## License

`LICENSE` 파일을 참고한다.

See the `LICENSE` file.
