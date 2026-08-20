# SETUP.md

> Factory 개발, 실행과 생성 결과 검증을 위한 환경 경계

## 원칙

- 실행 전에 현재 환경과 Repository 상태를 확인한다
- 특정 IDE를 필수 조건으로 만들지 않는다
- 이미 정상인 도구나 시스템 설정을 불필요하게 변경하지 않는다
- 로그인, 라이선스, 관리자 권한 또는 서명 관련 조치는 User 승인이 필요할 수 있다
- 인증정보나 비밀정보를 Repository에 기록하지 않는다

## 팩토리 개발 환경

Factory source를 검토하고 구현하려면 Repository가 요구하는 Dart 환경과 dependency를 사용할 수 있어야 한다.

Factory 구현 검증은 해당 Agreement에서 승인된 분석과 테스트 범위만 수행한다.

## 팩토리 실행 전제 조건

Executable V1을 실행하기 전에 다음 상태를 확인한다.

- Git을 사용할 수 있음
- 공식 Flutter toolchain과 iOS 및 Android platform toolchain을 사용할 수 있음
- 승인된 V1 입력과 안전한 output path가 제공됨
- 필요한 파일 시스템 권한이 있음

필수 환경을 확인할 수 없으면 Bootstrap을 진행하지 않는다. 상세 중단 조건은 `Docs/ARCHITECTURE.md`가 소유한다.

## 필수 제품 입력

Executable V1 요청은 다음 열 개의 개념 입력을 모두 제공한다.

1. Product 표시 이름
2. Product 목적
3. 초기 Product 범위 또는 첫 번째 의도된 결과
4. 정확한 출력 경로
5. Repository 모드
6. 초기 branch 이름 또는 Repository 정책
7. Flutter project 식별자
8. Organization 식별자
9. 요청 기술
10. 대상 플랫폼

정확한 accepted token은 다음과 같다.

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

## V1.1 제품 요청 파일

V1.1 요청 파일 이름은 `product_request.yaml`이며 `--request`에 명시적 절대 경로를 전달한다. 파일은 Factory root와 Product output root 밖의 regular UTF-8 파일이어야 하고 symlink일 수 없으며 최대 크기는 128 KiB다.

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

## V1.1 한 번 실행 명령

Factory Repository root에서 다음 한 명령을 실행한다.

```text
dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml
```

`stdout`은 정확히 하나의 versioned JSON 문서만 출력하고 `stderr`는 한국어 우선 요약과 다음 User 결정을 출력한다.

| 종료 코드 | 의미 |
|---|---|
| `0` | `BootstrapExecutionPrepared`; Ready 또는 Approved가 아님 |
| `2` | request parse/schema 또는 preflight 중단 |
| `3` | 안전한 execution stop 또는 복구 |
| `4` | `BootstrapExecutionPartialFailure`; User 검사 필요 |
| `64` | `--help` 또는 command usage 결과 |
| `70` | 예상하지 못한 command-layer failure |

parse, schema 또는 preflight가 중단되면 Product execution을 시작하지 않는다. 명령은 commit, remote, push, tag, publication 또는 release를 수행하지 않는다.

## V1.2.1 제품 루프 요청 파일

Product Loop 요청 파일 이름은 `product_loop_request.yaml`이며 Factory와 Product Repository 밖의 regular UTF-8 파일이어야 한다. Evidence 디렉터리도 두 Repository 밖에 미리 존재해야 하며 symlink일 수 없다. Capture 시작 시 Evidence 디렉터리는 비어 있어야 한다.

```yaml
schemaVersion: 1
productRoot: /absolute/products/example_product
buildPolicy: both
evidenceDirectory: /absolute/evidence/agreement-001
```

`buildPolicy`는 `none`, `android`, `ios`, `both` 중 하나다. 알 수 없는 key, 누락·blank·잘못된 type, 지원하지 않는 YAML 기능, 상대 경로와 secret-like 내용은 거절한다. 명령은 기존 Evidence 파일을 덮어쓰지 않는다.

## V1.2.1 제품 루프 명령

Factory Repository root에서 먼저 기준선을 캡처한다.

```text
dart run ai_flutter_app_factory:factory_product_loop --request /absolute/intake/product_loop_request.yaml --phase capture
```

성공 시 Evidence 디렉터리에 다음 파일을 생성한다.

```text
product_loop_baseline.json
product_loop_capture_report.json
```

User가 출력된 baseline SHA-256을 승인하고 외부 Agreement 구현이 끝난 뒤 같은 요청 파일과 승인 hash로 검증한다.

```text
dart run ai_flutter_app_factory:factory_product_loop --request /absolute/intake/product_loop_request.yaml --phase validate --approved-baseline-sha256 <USER_APPROVED_HASH>
```

Validate는 Evidence 디렉터리에 Capture가 생성한 두 파일만 있을 때 `product_loop_validation_report.json`을 생성한다. Capture 이후 또는 검증 실행 중 요청 파일, build policy, Product root 또는 baseline 파일이 바뀌거나 알 수 없는 Evidence 항목이 나타나면 결과를 쓰기 전에 중단한다.

| 종료 코드 | 의미 |
|---|---|
| `0` | baseline proposal 또는 기술 검증 candidate 준비 |
| `2` | 요청, 승인 hash 또는 artifact 검증 중단 |
| `3` | Runtime baseline 또는 candidate 검증 중단 |
| `4` | Evidence 저장 부분 실패로 User 검사 필요 |
| `64` | `--help` 또는 command usage 결과 |
| `70` | 예상하지 못한 command-layer failure |

Exit `0`은 QA PASS, User 승인, commit, push 또는 release를 의미하지 않는다.

## 공개 API 실행

외부 consumer는 package-root library만 사용한다.

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

## V1.2 제품 루프 보호 공개 실행 환경

Product Loop Guard는 Bootstrap 이후 별도 Product Repository에서 사용한다. 먼저 기준선 Proposal을 capture하고 User가 승인한 동일 기준선을 `inspect`한 뒤, 승인된 Product 구현이 끝났을 때 `validate`를 실행한다.

```dart
final loop = ProductLoopGuardRuntime(
  factoryRoot: Directory('/exact/factory/path'),
);
final proposal = await loop.captureBaseline(
  Directory('/exact/product/path'),
);
if (proposal case ProductLoopBaselineProposal baseline) {
  final inspected = await loop.inspect(
    ProductLoopGuardRequest(
      expectedBaseline: baseline.snapshot,
      buildPolicy: ProductLoopBuildPolicy.both,
    ),
  );
  if (inspected case ProductLoopGuardReady ready) {
    // User가 승인한 Product 구현은 Factory 밖에서 수행한다.
    // Perform User-approved Product implementation outside the Factory.
    final validation = await loop.validate(ready);
    print(validation.runtimeType);
  }
}
```

`ProductLoopCandidateValidated`는 기술 검증 통과를 의미하지만 QA PASS, Product Context 승인, User 승인 또는 commit을 의미하지 않는다. `ProductLoopValidationStopped`가 반환되면 Evidence를 확인하고 기존 QA candidate를 사용하지 않는다.

## 결과 처리와 승인 경계

- `BootstrapPreflightStopped`: 입력 또는 Target 검증이 실패했으며 execution을 시작하지 않음
- `BootstrapExecutionPrepared`: Bootstrap 산출물과 기술 Evidence가 준비됐지만 Ready 또는 Approved가 아님
- `BootstrapExecutionStopped`: 안전한 중단 또는 복구가 확인됨
- `BootstrapExecutionPartialFailure`: 자동 정리를 계속할 수 없어 User 검사가 필요한 경로와 Evidence를 반환함

Prepared 이후 순서는 Baseline Handoff Proposal 제시 → User의 Ready 상태와 baseline 승인 → 첫 Agreement 승인 → Product Implementation 시작이다.

## 생성 제품 검증 환경

생성된 Product는 Flutter 기본 dependency 준비, 정적 분석, 기본 테스트, Android APK build와 iOS Simulator build를 수행할 수 있는 환경에서 검증한다.

필수 검증을 환경 또는 toolchain 문제로 수행할 수 없으면 Ready로 판정하지 않고 확인된 상태와 필요한 User 조치를 보고한다.

## 책임 경계

- Factory 환경 준비는 Factory source와 runtime 검증을 지원한다
- Factory 실행 환경은 Bootstrap을 수행한다
- 생성된 Product의 검증 환경은 Bootstrap 결과만 검증하며 Product 기능을 결정하지 않는다
