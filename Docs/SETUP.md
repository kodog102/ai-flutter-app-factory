# SETUP.md

> Factory 개발, 실행과 생성 결과 검증을 위한 환경 경계
> Environment boundaries for Factory development, execution, and generated-result verification

## Principles

- 실행 전에 현재 환경과 Repository 상태를 확인한다
- Inspect the current environment and Repository state before execution
- 특정 IDE를 필수 조건으로 만들지 않는다
- Do not make a specific IDE a requirement
- 이미 정상인 도구나 시스템 설정을 불필요하게 변경하지 않는다
- Do not unnecessarily change working tools or system settings
- 로그인, 라이선스, 관리자 권한 또는 서명 관련 조치는 User 승인이 필요할 수 있다
- Login, licensing, administrator privileges, or signing-related actions may require User approval
- 인증정보나 비밀정보를 Repository에 기록하지 않는다
- Do not record credentials or secrets in a Repository

## Factory Development Environment

Factory source를 검토하고 구현하려면 Repository가 요구하는 Dart 환경과 dependency를 사용할 수 있어야 한다.

Reviewing and implementing Factory source requires access to the Dart environment and dependencies required by the Repository.

Factory 구현 검증은 해당 Agreement에서 승인된 분석과 테스트 범위만 수행한다.

Factory implementation verification performs only the analysis and test scope approved by the relevant Agreement.

## Factory Execution Prerequisites

Executable V1을 실행하기 전에 다음 상태를 확인한다.

Confirm the following before running Executable V1.

- Git을 사용할 수 있음
- Git is available
- 공식 Flutter toolchain과 iOS 및 Android platform toolchain을 사용할 수 있음
- The official Flutter toolchain and iOS and Android platform toolchains are available
- 승인된 V1 입력과 안전한 output path가 제공됨
- Approved V1 inputs and a safe output path are provided
- 필요한 파일 시스템 권한이 있음
- Required file-system permissions are available

필수 환경을 확인할 수 없으면 Bootstrap을 진행하지 않는다. 상세 중단 조건은 `Docs/ARCHITECTURE.md`가 소유한다.

Do not continue Bootstrap when a required environment cannot be verified. `Docs/ARCHITECTURE.md` owns the detailed stop conditions.

## Required Product Inputs

Executable V1 요청은 다음 열 개의 개념 입력을 모두 제공한다.

An Executable V1 request provides all ten conceptual inputs below.

1. Product Display Name / Product 표시 이름
2. Product Purpose / Product 목적
3. Initial Product Scope or First Intended Outcome / 초기 Product 범위 또는 첫 번째 의도된 결과
4. Exact Output Path / 정확한 출력 경로
5. Repository Mode / Repository 모드
6. Initial Branch Name or Repository Policy / 초기 branch 이름 또는 Repository 정책
7. Flutter Project Name / Flutter project 식별자
8. Organization Identifier / Organization 식별자
9. Requested Technology / 요청 기술
10. Target Platforms / 대상 플랫폼

정확한 accepted token은 다음과 같다.

The exact accepted tokens are:

```text
repositoryMode:
- newRepository
- existingEmptyRepository

requestedTechnology:
- flutter

targetPlatforms:
- ios
- android
```

`newRepository`는 `initialBranchName`을 요구하고 `repositoryPolicy`는 `null`이어야 한다. `existingEmptyRepository`는 기존 독립 Repository 정책을 보존하기 위한 `repositoryPolicy`를 요구하고 `initialBranchName`은 `null`이어야 한다.

`newRepository` requires `initialBranchName` and uses `null` for `repositoryPolicy`. `existingEmptyRepository` requires `repositoryPolicy` to preserve the existing independent Repository policy and uses `null` for `initialBranchName`.

## V1.1 Product Request File

V1.1 요청 파일 이름은 `product_request.yaml`이며 `--request`에 명시적 절대 경로를 전달한다. 파일은 Factory root와 Product output root 밖의 regular UTF-8 파일이어야 하고 symlink일 수 없으며 최대 크기는 128 KiB다.

The V1.1 request filename is `product_request.yaml`, supplied to `--request` through an explicit absolute path. It must be a regular UTF-8 file outside both the Factory root and Product output root, must not be a symlink, and is limited to 128 KiB.

```yaml
schemaVersion: 1
requestId: sample-001

bootstrap:
  productDisplayName: Example Product
  productPurpose: Validate a Product workflow.
  initialProductScopeOrFirstIntendedOutcome: Prepare the first approved workflow.
  exactOutputPath: /absolute/products/example_product
  repositoryMode: newRepository
  initialBranchName: main
  repositoryPolicy: null
  flutterProjectName: example_product
  organizationIdentifier: com.example
  requestedTechnology: flutter
  targetPlatforms:
    - ios
    - android
```

`requestId`만 선택 사항이다. 알 수 없는 key, 중복 key, 누락·blank·잘못된 type, 여러 YAML document, anchor, alias, tag, merge key와 지원하지 않는 중첩은 Runtime 실행 전에 거절한다. `~`, 환경 변수, shell expression 또는 상대 경로를 확장하지 않는다. 요청 파일에 credential이나 secret을 기록하지 않는다.

Only `requestId` is optional. Unknown or duplicate keys, missing, blank, or wrongly typed values, multiple YAML documents, anchors, aliases, tags, merge keys, and unsupported nesting are rejected before Runtime execution. The command does not expand `~`, environment variables, shell expressions, or relative paths. Do not record credentials or secrets in the request file.

## V1.1 One-run Command

Factory Repository root에서 다음 한 명령을 실행한다.

Run this one command from the Factory Repository root.

```text
dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml
```

`stdout`은 정확히 하나의 versioned JSON 문서만 출력하고 `stderr`는 한국어 우선 요약과 다음 User 결정을 출력한다.

`stdout` contains exactly one versioned JSON document. `stderr` contains a Korean-first summary and the next User decision.

| Exit | 의미 / Meaning |
|---|---|
| `0` | `BootstrapExecutionPrepared`; Ready 또는 Approved가 아님 / not Ready or Approved |
| `2` | request parse/schema 또는 preflight 중단 / request parse/schema or preflight stop |
| `3` | 안전한 execution stop 또는 복구 / safe execution stop or restoration |
| `4` | `BootstrapExecutionPartialFailure`; User 검사 필요 / User inspection required |
| `64` | `--help` 또는 command usage 결과 / `--help` or command usage result |
| `70` | 예상하지 못한 command-layer failure / unexpected command-layer failure |

parse, schema 또는 preflight가 중단되면 Product execution을 시작하지 않는다. 명령은 commit, remote, push, tag, publication 또는 release를 수행하지 않는다.

The command does not begin Product execution after a parse, schema, or preflight stop. It does not commit, add a remote, push, tag, publish, or release.

## Public API Execution

외부 consumer는 package-root library만 사용한다.

External consumers use only the package-root library.

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
  } else if (preflight case BootstrapPreflightStopped stopped) {
    print(stopped.reasons.map((reason) => reason.description).join('\n'));
  }
}
```

실행 순서는 `BootstrapRequest` → `inspect` → `BootstrapPreflightReady` → `execute`다. `BootstrapPreflightStopped`는 Product mutation 전에 구조화된 중단 근거를 반환한다.

The execution sequence is `BootstrapRequest` → `inspect` → `BootstrapPreflightReady` → `execute`. `BootstrapPreflightStopped` returns structured stop evidence before Product mutation.

## Result Handling and Approval Boundary

- `BootstrapPreflightStopped`: 입력 또는 Target 검증이 실패했으며 execution을 시작하지 않음
- `BootstrapPreflightStopped`: input or Target validation failed and execution did not begin
- `BootstrapExecutionPrepared`: Bootstrap 산출물과 기술 Evidence가 준비됐지만 Ready 또는 Approved가 아님
- `BootstrapExecutionPrepared`: Bootstrap outputs and technical Evidence are prepared, but the Product is not Ready or Approved
- `BootstrapExecutionStopped`: 안전한 중단 또는 복구가 확인됨
- `BootstrapExecutionStopped`: a safe stop or restoration was confirmed
- `BootstrapExecutionPartialFailure`: 자동 정리를 계속할 수 없어 User 검사가 필요한 경로와 Evidence를 반환함
- `BootstrapExecutionPartialFailure`: automatic cleanup could not safely continue, so paths and Evidence requiring User inspection are returned

Prepared 이후 순서는 Baseline Handoff Proposal 제시 → User의 Ready 상태와 baseline 승인 → 첫 Agreement 승인 → Product Implementation 시작이다.

After Prepared, the order is presentation of the Baseline Handoff Proposal → User approval of the Ready state and baseline → approval of the first Agreement → start of Product Implementation.

## Generated Product Verification Environment

생성된 Product는 Flutter 기본 dependency 준비, 정적 분석, 기본 테스트, Android APK build와 iOS Simulator build를 수행할 수 있는 환경에서 검증한다.

Verify the generated Product in an environment that can prepare default Flutter dependencies, run static analysis and default tests, and build an Android APK and an iOS Simulator target.

필수 검증을 환경 또는 toolchain 문제로 수행할 수 없으면 Ready로 판정하지 않고 확인된 상태와 필요한 User 조치를 보고한다.

When an environment or toolchain issue prevents required verification, do not judge the Product as Ready; report the confirmed state and required User action.

## Responsibility Boundary

- Factory 환경 준비는 Factory source와 runtime 검증을 지원한다
- Factory environment preparation supports Factory source and runtime verification
- Factory 실행 환경은 Bootstrap을 수행한다
- The Factory execution environment performs Bootstrap
- 생성된 Product의 검증 환경은 Bootstrap 결과만 검증하며 Product 기능을 결정하지 않는다
- The generated Product verification environment verifies only the Bootstrap result and does not decide Product features
