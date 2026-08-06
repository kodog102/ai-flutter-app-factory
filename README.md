# AI Flutter App Factory

## 개요

이 저장소는 새로운 Flutter 모바일 Product Repository가 일관된 운영 규칙과 실행 가능한 시작 구조를 갖고 즉시 첫 작업을 시작할 수 있도록 준비하는 Factory다.

## 목표

Flutter 모바일 Product Repository가 자체 문서, 명확한 책임 경계, 검증된 기본 구조를 갖춘 운영·실행 가능한 시작 상태가 되도록 한다.

Factory V1은 iOS와 Android를 지원한다. Flutter Web, Flutter Desktop, 비 Flutter 기술 스택은 V1 범위가 아니다.

Factory는 특정 Product 분야에 종속되지 않으며, 역할과 계약 및 생성 결과는 특정 실행 환경에 종속되지 않는다.

## 준비 완료 상태

Product Repository만으로 첫 Agreement를 시작할 수 있는 상태

## 운영 원칙

빠른 생성 + 작은 승인 + 빠른 개선

## Bootstrap 시작 입력

Executable V1 Bootstrap을 시작하려면 Product 정보, Repository 정보, Flutter project identifier, organization identifier, 요청 기술과 대상 플랫폼을 명시해야 한다.

Operational Bootstrap과 Executable Flutter Bootstrap의 전체 입력, 출력, 순서, 중단 조건, Ready Product 기준은 [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md)가 단일 권한을 가진다.

비개발자가 샘플 앱을 순서대로 준비하려면 [Docs/USER_GUIDE.md](Docs/USER_GUIDE.md)를 먼저 따른다.

### V1.1 한 번 실행 Bootstrap

V1.1은 Factory 밖의 `product_request.yaml` 하나를 기존 Runtime 입력으로 안전하게 변환하고 한 명령으로 검증된 Flutter Product 시작점을 준비한다.

```text
dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml
```

요청 파일 위치와 schema는 [Docs/SETUP.md](Docs/SETUP.md), 비개발자 실행·승인 순서는 [Docs/USER_GUIDE.md](Docs/USER_GUIDE.md)를 따른다. V1.1은 Product 기능을 구현하지 않으며 V1.2 Product Loop Guard를 포함하지 않는다.

### V1.2 Product Loop Guard Runtime

Product Loop는 Product Repository에서 작은 Agreement 하나를 안전하게 완료하는 반복 작업 단위다. 자율적으로 Product를 개발하는 AI 기능이 아니라, 승인된 시작 상태와 구현 후 검증 대상을 고정해 예상 밖 변경이 다음 단계로 넘어가지 못하게 하는 운영 흐름이다.

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

V1.2 Runtime foundation은 승인된 Product 기준선을 검사하고, QA candidate를 고정한 뒤 Flutter format, analyze, test와 선택된 Android/iOS build를 실행한다.

Product Context 의미 검토, QA 판정과 User 승인은 자동화하지 않는다. Provider, Agent Adapter와 orchestration은 현재 범위가 아니다.

### V1.2.1 Product Loop 명령

V1.2.1은 기존 Runtime을 하나의 명령 진입점으로 제공한다. User 승인과 외부 구현 경계를 보존하기 위해 같은 명령을 `capture`와 `validate` 두 단계로 실행한다.

```text
dart run ai_flutter_app_factory:factory_product_loop \
  --request /absolute/intake/product_loop_request.yaml \
  --phase capture
```

Capture가 출력한 SHA-256을 User가 승인하고 Product Agreement 구현이 끝난 뒤 다음 검증을 실행한다.

```text
dart run ai_flutter_app_factory:factory_product_loop \
  --request /absolute/intake/product_loop_request.yaml \
  --phase validate \
  --approved-baseline-sha256 <USER_APPROVED_HASH>
```

이 명령은 QA PASS, User 승인 또는 Git 작업을 자동 수행하지 않는다. 요청 schema와 Evidence 경계는 [Docs/SETUP.md](Docs/SETUP.md)를 따른다.

Ready Product는 새로운 작업 주체가 Factory를 다시 읽지 않고 Product Repository만으로 첫 Agreement를 제안할 수 있는 상태다.

### 활성 Runtime

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

```text
factory_product_loop --phase capture
    ↓
Product Loop 기준선 JSON + SHA-256
    ↓
User 기준선 승인 + 외부 구현
    ↓
factory_product_loop --phase validate --approved-baseline-sha256 <HASH>
    ↓
QA candidate Evidence | 구조화된 중단 결과
```

외부 사용자는 package-root API 하나만 import한다.

```dart
import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';

Future<void> main() async {
  final runtime = FlutterAppFactoryRuntime(
    factoryRoot: Directory('/exact/factory/path'),
  );
  final request = BootstrapRequest(
    productDisplayName: '예제 Product',
    productPurpose: '공개 Factory Runtime을 검증한다.',
    initialProductScopeOrFirstIntendedOutcome:
        '첫 번째 Product Agreement를 준비한다.',
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

Executable Flutter V1은 `lib/core/bootstrap/`과 `lib/core/product_loop/` Runtime을 package-root 공개 API와 좁은 명령 진입점으로 조정한다. Template/Generator pipeline은 활성 V1 경로가 아니며, `factory.yaml`과 `factory_manifest.json`은 비활성 legacy metadata다. 범용 CLI 또는 orchestration은 V1 기능이 아니다.

## 역할 원칙

- 역할은 고정한다.
- 실행 도구와 Provider는 교체할 수 있다.
- Factory 검증은 테스트 Product 완성보다 우선한다.

## 저장소 구조

```text
.
├── AGENTS.md
├── README.md
├── bin/
│   ├── factory_bootstrap.dart            # 활성 V1.1 명령 진입점
│   └── factory_product_loop.dart         # 활성 V1.2.1 명령 진입점
├── factory.yaml                          # 비활성 legacy metadata
├── factory_manifest.json                 # 비활성 legacy metadata
├── lib/
│   ├── ai_flutter_app_factory.dart       # 활성 공개 V1 API
│   └── core/
│       ├── bootstrap/                    # 활성 V1 Runtime
│       ├── product_loop/                 # V1.2 Product Loop Guard Runtime
│       ├── factory/                      # 비활성 legacy source
│       ├── generator/                    # 비활성 legacy source
│       └── template/                     # 비활성 legacy source
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

## 시작 순서

비개발자 Product 시작:

1. `Docs/USER_GUIDE.md`
2. Product 입력 작성과 Bootstrap 요청

Factory 검토와 개발:

1. `README.md`
2. `AGENTS.md`
3. `Docs/VISION.md`
4. `Docs/ARCHITECTURE.md`

## 기반 문서

- `AGENTS.md` — AI Agent의 역할과 책임
- `Docs/VISION.md` — Factory의 존재 목적과 설계 원칙
- `Docs/ARCHITECTURE.md` — Factory의 전체 구조
- `Docs/ROADMAP.md` — 작업 순서와 단계별 완료 조건

## 개발 상태

현재 상태: **Flutter Factory V1.2 Consumer Ready — Release Pending**

V1.2 Product Loop Guard Runtime foundation: **완료 — User 승인**

V1.2.1 Product Loop Operator Command: **완료 — User 승인**

V1.2 Consumer Readiness Validation: **완료 — User 승인**

새 Repository, 기존 빈 Repository와 잘못된 Evidence 경계 복구를 새 작업 주체가 공개 사용설명서만으로 검증했고 독립 QA를 통과했다. 실제 Flutter Product의 자동 Health Gate와 User가 제공한 실기기 검증 Evidence도 유지된다. Release는 계속 별도 User 결정을 기다린다.

## 라이선스

`LICENSE` 파일을 참고한다.
