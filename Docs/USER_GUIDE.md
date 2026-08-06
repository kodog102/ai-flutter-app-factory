# USER_GUIDE.md

> 비개발자가 AI Flutter App Factory로 샘플 Flutter 앱을 시작하는 순서 안내
> A step-by-step guide for non-developers starting a sample Flutter app with the AI Flutter App Factory

Status: **사용 가능 — Flutter V1 / Ready for Use — Flutter V1**

## 이 문서의 목표 / Goal

이 문서는 코드를 직접 작성하지 않는 사용자가 Product 정보를 준비하고, 작업 도구에 Factory 실행을 요청하고, 결과를 승인한 뒤 작은 샘플 앱을 실행하는 과정을 안내한다.

This guide helps a non-developer prepare Product information, request Factory execution through a work tool, approve the results, and run a small sample app without writing code directly.

이 문서의 예시는 **장보기 목록 앱**이다. 사용자는 항목을 추가하고, 구매 완료로 표시하고, 삭제할 수 있다.

The example is a **shopping list app** where a user can add items, mark them as purchased, and delete them.

> 이 문서는 쉬운 사용 순서를 설명한다. 입력·중단·Repository 안전 규칙이 충돌하면 `Docs/ARCHITECTURE.md`와 `Docs/SETUP.md`가 우선한다.
>
> This guide explains the user-friendly workflow. If an input, stop, or Repository safety rule conflicts with this guide, `Docs/ARCHITECTURE.md` and `Docs/SETUP.md` take precedence.

## 먼저 알아둘 점 / Before You Start

Factory V1.1은 `product_request.yaml` 하나와 한 명령을 제공한다. 이 명령은 기존 Dart 공개 Runtime을 호출하며 버튼형 독립 앱이나 AI Product Loop는 아니다. 사용자는 Factory Repository를 읽고 명령을 실행할 수 있는 **코드 작업 도구**에 파일과 실행 요청을 전달할 수 있다.

Factory V1.1 provides one `product_request.yaml` and one command. The command invokes the existing public Dart Runtime and is not a standalone button-based app or an AI Product Loop. The User may give the file and execution request to a **code-capable work tool** that can access and run the Factory Repository.

V1.2.1은 Product Loop Guard를 직접 Dart 코드로 연결하지 않아도 되는 한 명령 진입점을 제공한다. 다만 User 승인과 실제 Product 구현을 건너뛸 수 없으므로 같은 명령을 기준선 `capture`와 구현 후 `validate` 두 단계로 사용한다.

V1.2.1 provides one command entry point without requiring direct Dart integration with the Product Loop Guard. The same command is used in separate baseline `capture` and post-implementation `validate` phases because User approval and actual Product implementation cannot be skipped.

작업 도구의 제품명은 중요하지 않다. 다음 조건만 만족하면 된다.

The work tool does not need to be a specific product. It only needs to:

- Factory와 Product 경로를 읽고 쓸 수 있다
- Access the Factory and Product paths
- Dart, Flutter와 Git 명령을 실행할 수 있다
- Run Dart, Flutter, and Git commands
- 사용자 승인 전에 구현·커밋·push하지 않는다
- Avoid implementation, commit, and push before User approval
- Factory의 공개 실행 창구를 사용할 수 있다
- Use the Factory's public execution boundary

Factory가 처음 준비하는 것은 완성 앱이 아니라 **검증된 Flutter Product 시작점**이다. 실제 샘플 기능은 첫 Agreement를 승인한 다음 구현한다.

The Factory first prepares a **verified Flutter Product starting point**, not a finished app. The sample features are implemented only after the first Agreement is approved.

## 전체 순서 / Workflow at a Glance

```text
1. 환경 확인
2. 만들 앱과 첫 범위 결정
3. 열 개 입력 작성
4. Factory 사전 검사와 실행 요청
5. Prepared 결과 검토
6. Ready 상태와 기준선 승인
7. 첫 Agreement 승인
8. Design → Implementation → QA
9. Simulator에서 샘플 앱 확인
10. User 승인 후 commit
```

```text
1. Check the environment
2. Choose the app and first scope
3. Complete the ten inputs
4. Request Factory inspection and execution
5. Review the Prepared result
6. Approve the Ready state and baseline
7. Approve the first Agreement
8. Run Design → Implementation → QA
9. Verify the sample app in a Simulator
10. Commit after User approval
```

## 1. 환경 준비 확인 / Check the Environment

작업 도구에 아래 내용을 확인해 달라고 요청한다. 직접 Terminal 명령을 입력할 필요는 없다.

Ask the work tool to verify the following. The User does not need to type terminal commands directly.

- Factory Repository가 clean 상태인가
- Is the Factory Repository clean?
- Git을 사용할 수 있는가
- Is Git available?
- Flutter와 Dart를 사용할 수 있는가
- Are Flutter and Dart available?
- Xcode와 iOS Simulator를 사용할 수 있는가
- Are Xcode and the iOS Simulator available?
- Android SDK와 Android build toolchain을 사용할 수 있는가
- Are the Android SDK and build toolchain available?
- 새 Product를 만들 정확한 절대 경로가 안전한가
- Is the exact absolute Product output path safe?

복사해서 사용할 요청:

Copyable request:

```text
Factory 실행 환경을 읽기 전용으로 확인해 주세요.

Factory Root:
/Users/사용자이름/Documents/경로/ai-flutter-app-factory

확인할 것:
- Factory Git 상태
- Git 사용 가능 여부
- Flutter 및 Dart 버전
- Xcode와 iOS Simulator 사용 가능 여부
- Android SDK와 Android build 사용 가능 여부
- Factory 문서가 요구하는 V1 환경 충족 여부

시스템 설정, 파일, Repository를 변경하지 마세요.
문제가 있으면 해결하지 말고 필요한 사용자 조치만 알려주세요.
```

환경이 확인되지 않으면 Bootstrap을 진행하지 않는다.

Do not continue Bootstrap when the required environment cannot be verified.

## 2. 샘플 앱 범위 결정 / Choose the Sample App Scope

첫 앱은 작게 시작한다. 한 번의 작업으로 로그인, 결제, 서버, 알림까지 모두 만들려고 하지 않는다.

Start small. Do not attempt login, payments, backend services, and notifications in one task.

샘플 장보기 목록의 권장 첫 범위:

Recommended first scope for the sample shopping list:

### 포함 / Included

- 한 화면에 장보기 항목 목록 표시
- Show shopping items on one screen
- 새 항목 추가
- Add a new item
- 구매 완료 상태 전환
- Toggle purchased status
- 항목 삭제
- Delete an item
- 기기에 간단히 저장하고 재실행 후 복원
- Store items locally and restore them after restart
- 기본 Widget 및 저장 동작 테스트
- Basic widget and persistence tests

### 제외 / Excluded

- 로그인과 회원가입
- Login and account creation
- 서버와 계정 동기화
- Backend or account synchronization
- 결제
- Payments
- 가족 공유
- Family sharing
- 알림
- Notifications
- 앱스토어 배포
- App Store or Play Store release

## 3. 열 개 입력 작성 / Complete the Ten Inputs

처음에는 `newRepository` 사용을 권장한다. 기존 빈 Git Repository를 반드시 보존해야 할 때만 `existingEmptyRepository`를 선택한다.

Use `newRepository` for the first sample. Choose `existingEmptyRepository` only when an existing empty Git Repository must be preserved.

| 번호 | 입력 | 장보기 샘플 값 |
|---|---|---|
| 1 | Product Display Name | `My Shopping List` |
| 2 | Product Purpose | `장보기 항목을 간단히 기록하고 구매 상태를 관리한다.` |
| 3 | Initial Product Scope or First Intended Outcome | `추가, 완료 전환, 삭제와 로컬 복원이 가능한 한 화면 앱을 준비한다.` |
| 4 | Exact Output Path | `/Users/사용자이름/Documents/My Apps/my-shopping-list` |
| 5 | Repository Mode | `newRepository` |
| 6 | Initial Branch Name or Repository Policy | `main` |
| 7 | Flutter Project Name | `my_shopping_list` |
| 8 | Organization Identifier | `com.example` |
| 9 | Requested Technology | `flutter` |
| 10 | Target Platforms | `ios`, `android` |

영문 입력표:

English input summary:

```text
Product Display Name: My Shopping List
Product Purpose: Keep a simple shopping list and manage purchase status.
Initial Product Scope or First Intended Outcome:
Prepare a one-screen app with add, toggle, delete, and local restore behavior.
Exact Output Path: /Users/your-name/Documents/My Apps/my-shopping-list
Repository Mode: newRepository
Initial Branch Name: main
Repository Policy: null
Flutter Project Name: my_shopping_list
Organization Identifier: com.example
Requested Technology: flutter
Target Platforms: ios, android
```

### 이름 작성 규칙 / Naming Rules

- `Product Display Name`: 사람이 보는 이름이므로 공백을 사용할 수 있다
- `Product Display Name`: human-readable and may contain spaces
- `Flutter Project Name`: 소문자, 숫자와 `_`를 사용하는 Dart 식별자 형태
- `Flutter Project Name`: a lowercase Dart identifier using letters, numbers, and `_`
- `Organization Identifier`: 보유한 도메인이 없다면 샘플에서만 `com.example` 사용
- `Organization Identifier`: use `com.example` only for a sample when no owned domain is available
- `Exact Output Path`: 반드시 절대 경로를 사용하며 Factory 내부 경로를 지정하지 않는다
- `Exact Output Path`: use an absolute path and never place the Product inside the Factory

## 4. Factory 실행 요청 / Request Factory Execution

열 개 입력을 다음 `product_request.yaml`에 작성한다. 이 파일은 Factory와 Product output 밖에 두며 symlink가 아닌 128 KiB 이하의 UTF-8 regular file이어야 한다.

Write the ten inputs into the following `product_request.yaml`. Keep it outside the Factory and Product output as a regular, non-symlink UTF-8 file no larger than 128 KiB.

```yaml
schemaVersion: 1
requestId: shopping-sample-001

bootstrap:
  productDisplayName: My Shopping List
  productPurpose: 장보기 항목을 간단히 기록하고 구매 상태를 관리한다.
  initialProductScopeOrFirstIntendedOutcome: 추가, 완료 전환, 삭제와 로컬 복원이 가능한 한 화면 앱을 준비한다.
  exactOutputPath: /Users/사용자이름/Documents/My Apps/my-shopping-list
  repositoryMode: newRepository
  initialBranchName: main
  repositoryPolicy: null
  flutterProjectName: my_shopping_list
  organizationIdentifier: com.example
  requestedTechnology: flutter
  targetPlatforms:
    - ios
    - android
```

### 기존 빈 Repository 입력 / Existing Empty Repository Input

기존의 빈 Git Repository를 보존해야 할 때는 아래 조건을 모두 만족해야 한다.

When an existing empty Git Repository must be preserved, all conditions below must be satisfied.

- Product 경로가 이미 존재하며 일반 디렉터리다.
- The Product path already exists and is a regular directory.
- Product 경로가 직접 소유한 실제 `.git` 디렉터리가 있다.
- The Product path has its own real `.git` directory.
- 아직 commit이 없고 Product root에는 `.git` 외 항목이 없다.
- There are no commits yet and the Product root contains nothing except `.git`.
- `initialBranchName`은 `null`이고 `repositoryPolicy`는 비어 있지 않은 설명문이다.
- `initialBranchName` is `null`, and `repositoryPolicy` is a non-blank descriptive statement.

다음 블록을 복사한 뒤 Product 정보와 경로만 바꾼다. `preserve existing Repository policy`는 설명서가 권장하는 표준 입력값이며 Runtime은 다른 비어 있지 않은 정책 설명도 허용한다.

Copy the block below and change only the Product information and path. `preserve existing Repository policy` is the guide's canonical input; the Runtime also accepts another non-blank policy description.

```yaml
schemaVersion: 1
requestId: existing-shopping-sample-001

bootstrap:
  productDisplayName: My Shopping List
  productPurpose: 장보기 항목을 간단히 기록하고 구매 상태를 관리한다.
  initialProductScopeOrFirstIntendedOutcome: 기존 빈 Repository에 Flutter 기반과 Product 운영 문서를 준비한다.
  exactOutputPath: /Users/사용자이름/Documents/My Apps/my-shopping-list
  repositoryMode: existingEmptyRepository
  initialBranchName: null
  repositoryPolicy: preserve existing Repository policy
  flutterProjectName: my_shopping_list
  organizationIdentifier: com.example
  requestedTechnology: flutter
  targetPlatforms:
    - ios
    - android
```

`requestId`는 선택 사항이며 승인, credential 또는 Product authority가 아니다. 요청 파일에 비밀정보를 넣지 않는다.

`requestId` is optional and is not an approval, credential, or Product authority. Do not place secrets in the request file.

Factory Repository root에서 직접 실행하거나 작업 도구에 다음 한 명령을 그대로 실행하도록 요청한다.

Run this one command from the Factory Repository root, or ask the work tool to run it exactly.

```text
dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml
```

명령은 `stdout`에 JSON 한 문서, `stderr`에 한국어 우선 요약을 출력한다. JSON과 요약을 모두 보존해 사용자에게 제시하되, 명령 완료 후 Product 기능 구현을 시작하지 않는다.

The command writes one JSON document to `stdout` and a Korean-first summary to `stderr`. Preserve and present both results to the User, and do not begin Product feature implementation after the command completes.

## 5. 실행 결과 이해 / Understand the Result

| 결과 | 뜻 | 사용자가 할 일 |
|---|---|---|
| `BootstrapPreflightStopped` | 입력 또는 경로가 안전하지 않아 실행 전 중단 | 중단 이유를 읽고 입력만 수정한 뒤 다시 요청 |
| `BootstrapExecutionPrepared` | Flutter 시작 구조와 기술 검증이 준비됨 | Evidence와 제안을 검토하고 승인 여부 결정 |
| `BootstrapExecutionStopped` | 실행 중 안전하게 중단되거나 복구됨 | 확인된 사실과 미수행 항목 검토 |
| `BootstrapExecutionPartialFailure` | 자동 정리의 안전성을 보장할 수 없음 | 표시된 경로를 이동·삭제하지 말고 별도 검사 요청 |

V1.1 command exit code는 다음처럼 해석한다.

Interpret V1.1 command exit codes as follows.

| Exit | 뜻 | 사용자가 할 일 |
|---|---|---|
| `0` | `Prepared` | Evidence와 proposal을 검토하고 Ready 승인 여부 결정 |
| `2` | request/schema/preflight 중단 | 구조화된 오류만 확인하고 입력 수정 여부 결정 |
| `3` | 안전한 execution stop 또는 복구 | 중단·복구 Evidence 검토 |
| `4` | `PartialFailure` | 보고된 경로를 변경하지 말고 별도 안전 검사 요청 |

`64`는 help/usage 결과이며 `70`은 예상하지 못한 command-layer failure다.

`64` is a help/usage result, and `70` is an unexpected command-layer failure.

```text
Prepared ≠ Ready ≠ Approved ≠ Released
```

`Prepared`는 Factory 자동 검증이 끝났다는 뜻일 뿐이다. 사용자의 Ready 승인과 첫 Agreement 승인은 별도로 필요하다.

`Prepared` means only that automated Factory preparation and verification finished. User approval of Ready and the first Agreement is still required.

## 6. Ready 상태와 기준선 승인 / Approve Ready and the Baseline

Prepared 보고서에서 다음을 확인한다.

Review the following in the Prepared report.

- Product 경로가 요청한 경로와 같은가
- Does the Product path match the requested path?
- iOS와 Android 구조가 생성됐는가
- Were the iOS and Android structures generated?
- dependency 준비, analyze, test와 두 platform build가 통과했는가
- Did dependency preparation, analysis, tests, and both platform builds pass?
- Product `README.md`와 `AGENTS.md`가 존재하는가
- Do Product-local `README.md` and `AGENTS.md` exist?
- 예상하지 못한 파일이나 Git 변경이 없는가
- Are there no unexpected files or Git changes?
- Baseline Handoff Proposal이 실제 상태와 일치하는가
- Does the Baseline Handoff Proposal match the actual state?

모두 맞을 때 사용할 승인 문장:

Approval text when everything matches:

```text
제시된 Product 경로, 기술 검증 Evidence와 Baseline Handoff Proposal을 확인했다.
현재 Product의 Ready 상태와 제안된 운영 기준선을 승인한다.

아직 Product 기능 구현을 시작하지 마라.
먼저 First Agreement Proposal을 사용자가 이해할 수 있는 말로 다시 제시하라.
Goal, Included Scope, Excluded Scope, Acceptance Criteria, Verification을 빠짐없이 포함하라.
commit과 push는 별도 승인 전까지 수행하지 마라.
```

내용이 다르면 승인하지 말고 차이만 수정 요청한다.

Do not approve when the reported state differs; request correction of only the mismatch.

## 7. 첫 Agreement 승인 / Approve the First Agreement

Agreement는 법률 계약이 아니라 **이번에 할 작은 작업의 범위 합의**다.

An Agreement is not a legal contract. It is a **small, explicit scope agreement for the next task**.

반드시 다음 다섯 항목이 있어야 한다.

It must contain these five fields.

1. `Goal` — 이번 작업이 이루려는 결과
2. `Included Scope` — 이번에 만드는 것
3. `Excluded Scope` — 이번에 만들지 않는 것
4. `Acceptance Criteria` — 완료로 인정할 구체 조건
5. `Verification` — 테스트와 사용자 확인 방법

장보기 샘플의 승인 예시:

Example approval for the shopping list sample:

```text
First Agreement를 다음 조건으로 승인한다.

Goal:
장보기 항목을 추가하고 구매 완료 상태를 바꾸고 삭제할 수 있는 한 화면 앱을 만든다.

Included Scope:
- 항목 목록
- 항목 추가
- 구매 완료 전환
- 삭제 확인
- 로컬 저장과 재실행 복원
- 필요한 Widget 및 저장 테스트

Excluded Scope:
- 로그인
- 서버 동기화
- 공유
- 알림
- 결제
- 앱스토어 배포

Acceptance Criteria:
- 빈 상태에서 항목을 추가할 수 있다.
- 항목의 구매 상태를 변경할 수 있다.
- 확인 후 항목을 삭제할 수 있다.
- 앱을 다시 실행해도 항목이 복원된다.
- 좁은 화면에서 overflow가 없다.
- analyze, test, iOS Simulator build와 Android APK build가 통과한다.

Verification:
- 자동 테스트
- 독립 QA
- iOS Simulator 또는 Android Emulator 화면 확인

승인된 범위만 구현하라.
UI 작업이 있으므로 Design Role을 먼저 활성화하라.
Implementation과 독립 QA를 분리하라.
QA가 PASS이면 결과와 화면을 보고하고 commit은 하지 마라.
```

## 8. Product 개발 루프 실행 / Run the Product Development Loop

Agreement 구현 전에 작업 도구에 V1.2.1 기준선 Capture를 요청한다. 요청 파일과 빈 Evidence 디렉터리는 Factory와 Product 밖에 둔다.

Before Agreement implementation, ask the work tool to run V1.2.1 baseline Capture. Keep the request file and empty Evidence directory outside the Factory and Product.

Capture 전에 다음 네 가지를 반드시 확인한다.

Confirm all four requirements before Capture.

1. 요청 파일 이름은 정확히 `product_loop_request.yaml`이다.
   The request filename is exactly `product_loop_request.yaml`.
2. Evidence 디렉터리는 명령 실행 전에 이미 존재한다.
   The Evidence directory already exists before the command runs.
3. Evidence 디렉터리는 비어 있으며 symlink가 아니다.
   The Evidence directory is empty and is not a symlink.
4. 요청 파일과 Evidence 디렉터리는 Factory와 Product Repository 밖에 있다.
   The request file and Evidence directory are outside both the Factory and Product Repositories.

```yaml
schemaVersion: 1
productRoot: /Users/사용자이름/Documents/제품경로/example_product
buildPolicy: both
evidenceDirectory: /Users/사용자이름/Documents/factory-evidence/agreement-001
```

작업 도구에 전달할 요청:

Copyable request for the work tool:

```text
Factory Root에서 아래 Product Loop 기준선 Capture를 실행해 주세요.

dart run ai_flutter_app_factory:factory_product_loop \
  --request /절대경로/product_loop_request.yaml \
  --phase capture

Product와 Factory를 수정하지 마세요.
결과의 baseline 경로, SHA-256, Git 상태와 승인 대기 상태를 보고하세요.
commit과 push는 하지 마세요.
```

User는 기준선 파일과 SHA-256을 검토해 승인한다. 그 뒤 아래 역할 흐름으로 Agreement를 구현한다.

The User reviews and approves the baseline file and SHA-256. The Agreement is then implemented through the role flow below.

UI가 포함된 장보기 샘플은 다음 순서를 따른다.

The UI-based shopping list sample follows this sequence.

```text
User Agreement 승인
    ↓
Design Role: 화면과 상태, 문구, 완료 기준 제안
    ↓
Orchestrator Role: 구현 계약 확정
    ↓
Implementation Role: 승인 범위 구현과 테스트
    ↓
Independent QA Role: 요구사항, 화면, 테스트와 diff 검증
    ↓
필요할 때만 제한된 Repair
    ↓
User 최종 승인
```

Design Role과 Implementation Role은 특정 서비스 이름이 아니라 책임을 뜻한다. 작업 도구가 바뀌어도 순서는 유지한다.

Design and Implementation Roles describe responsibilities, not specific service names. The sequence remains the same when the work tool changes.

구현과 자체 검증이 끝나면 승인했던 SHA-256으로 Validate를 요청한다.

After implementation and self-verification, request Validate using the approved SHA-256.

```text
Factory Root에서 아래 Product Loop 후보 검증을 실행해 주세요.

dart run ai_flutter_app_factory:factory_product_loop \
  --request /절대경로/product_loop_request.yaml \
  --phase validate \
  --approved-baseline-sha256 <내가 승인한 SHA-256>

구조화된 Evidence와 Flutter Health Gate 결과를 보고하세요.
기술 검증 성공을 QA PASS 또는 User 승인으로 해석하지 마세요.
독립 QA를 수행하고 commit과 push는 하지 마세요.
```

## 9. 샘플 앱 실행 확인 / Verify the Sample App

QA가 PASS이면 작업 도구에 Simulator 실행과 화면 확인을 요청한다.

After QA passes, ask the work tool to run the Product in a Simulator and verify the screen.

```text
승인된 Product를 iOS Simulator에서 실행해 주세요.

확인할 것:
- 앱이 오류 없이 시작되는가
- 빈 상태가 이해하기 쉬운가
- 항목 추가가 가능한가
- 구매 완료 상태가 보이는가
- 삭제 확인이 작동하는가
- 앱 재실행 후 항목이 복원되는가
- 좁은 화면에서 잘리지 않는가

화면 캡처와 확인 결과를 보고하세요.
코드를 추가로 수정하지 마세요.
commit과 push는 하지 마세요.
```

Android Emulator도 확인하려면 별도 요청으로 같은 시나리오를 반복한다.

Repeat the same scenario in an Android Emulator when Android visual verification is desired.

## 10. 최종 승인과 Commit / Final Approval and Commit

다음을 모두 확인한 뒤에만 commit을 요청한다.

Request a commit only after confirming all of the following.

- Agreement 범위만 변경됨
- Only the Agreement scope changed
- Design 결과와 실제 화면이 일치함
- The implementation matches the approved design
- QA가 PASS임
- QA passed
- 분석, 테스트와 필요한 build가 통과함
- Analysis, tests, and required builds passed
- 예상하지 못한 파일이 없음
- No unexpected files exist
- 민감정보가 없음
- No sensitive information exists

```text
최종 구현과 독립 QA 결과를 승인한다.
승인된 변경 파일만 stage하고 전체 검증을 다시 실행하라.
검증이 모두 통과하면 작업 내용을 정확히 설명하는 한 개의 commit을 생성하라.
push, amend, rebase, tag는 수행하지 마라.
commit hash, 메시지, 파일 목록과 최종 Git 상태를 보고하라.
```

## 문제 해결 / Troubleshooting

### Preflight에서 중단됨

입력값을 임의로 바꾸지 말고 `reasons`에서 지목한 필드만 수정한다. 경로가 위험하다는 결과가 나오면 다른 절대 경로를 사용한다.

Change only the field identified by `reasons`. Use a different absolute path when the current path is unsafe.

### Existing Empty Repository가 거절됨

처음 사용하는 사용자는 `newRepository`를 선택하는 것이 안전하다. Existing mode는 직접 `.git`을 가진 독립 Repository이며 `.git` 외 항목이 없는 경우에만 사용한다. 요청에는 `initialBranchName: null`과 비어 있지 않은 `repositoryPolicy`가 필요하다. 위의 **기존 빈 Repository 입력** 예제를 그대로 복사해 다시 시도한다.

First-time Users should prefer `newRepository`. Existing mode requires an independent Repository with its own `.git` and no other root entries. The request needs `initialBranchName: null` and a non-blank `repositoryPolicy`. Retry by copying the **Existing Empty Repository Input** example above.

### PartialFailure가 반환됨

보고된 target 또는 staging 경로를 직접 삭제하거나 덮어쓰지 않는다. 작업 도구에 읽기 전용 검사를 요청하고, 소유권과 외부 변경이 확인될 때까지 기다린다.

Do not delete or overwrite reported target or staging paths. Request read-only inspection and wait until ownership and external changes are understood.

### iOS 또는 Android build가 실패함

Product 코드를 먼저 수정하지 않는다. 실패가 환경 문제인지 Product 문제인지 분리해서 보고하도록 요청한다. 로그인, 라이선스, SDK 설치 또는 관리자 권한이 필요하면 사용자가 별도로 승인한다.

Do not modify Product code first. Ask the work tool to separate environment failures from Product failures. The User separately approves actions requiring login, licensing, SDK installation, or administrator access.

### 결과가 너무 큰 기능 범위를 제안함

첫 Agreement를 더 작게 줄인다. 한 화면과 한 가지 사용자 흐름을 우선하고 나머지는 Excluded Scope로 옮긴다.

Reduce the first Agreement. Prioritize one screen and one user flow, and move the rest to Excluded Scope.

## 완료 체크리스트 / Completion Checklist

샘플 앱 시작이 완료됐다고 판단하려면 다음을 모두 확인한다.

Confirm all items before considering the sample app start complete.

- [ ] 열 개 입력이 명확하다
- [ ] The ten inputs are explicit
- [ ] Preflight가 Ready를 반환했다
- [ ] Preflight returned Ready
- [ ] Execution이 Prepared를 반환했다
- [ ] Execution returned Prepared
- [ ] 기술 검증이 모두 통과했다
- [ ] All technical validation passed
- [ ] Product-local README와 AGENTS가 있다
- [ ] Product-local README and AGENTS exist
- [ ] User가 Ready 상태와 기준선을 승인했다
- [ ] The User approved Ready and the baseline
- [ ] User가 첫 Agreement를 승인했다
- [ ] The User approved the first Agreement
- [ ] Design, Implementation과 독립 QA가 완료됐다
- [ ] Design, Implementation, and independent QA completed
- [ ] Simulator에서 샘플 흐름을 확인했다
- [ ] The sample flow was verified in a Simulator
- [ ] User 승인 후 commit했다
- [ ] The change was committed after User approval
- [ ] Push와 Release는 별도 승인으로 남아 있다
- [ ] Push and Release remain separate approvals

## V1 범위 / V1 Boundaries

Factory V1이 제공하는 것:

Factory V1 provides:

- iOS와 Android Flutter 시작 구조
- Flutter starting structure for iOS and Android
- 독립 Product Repository 경계
- Independent Product Repository boundary
- Product-local 운영 문서와 첫 Agreement 제안
- Product-local operating documents and first Agreement proposal
- 기본 dependency, analyze, test와 두 platform build 검증
- Default dependency, analysis, tests, and both platform build validation
- 안전한 중단과 구조화된 Evidence
- Safe stops and structured evidence
- `product_request.yaml`과 한 명령을 사용하는 V1.1 Bootstrap
- V1.1 Bootstrap using one `product_request.yaml` and one command
- 승인 SHA-256을 사용하는 V1.2.1 Product Loop Capture·Validate 명령
- V1.2.1 Product Loop Capture and Validate commands using an approved SHA-256

Factory V1이 자동으로 제공하지 않는 것:

Factory V1 does not automatically provide:

- 완성된 Product 기능
- Finished Product features
- 로그인, backend, 결제와 배포
- Login, backend, payments, or distribution
- User를 대신한 Ready·Agreement·Release 승인
- Ready, Agreement, or Release approval on behalf of the User
- 자동 commit, push 또는 tag
- Automatic commit, push, or tag
- 버튼형 독립 실행 앱, Product 구현·승인 자동화 또는 Provider Adapter
- A standalone button-based app, automated Product implementation or approval, or a Provider Adapter

## 용어 / Glossary

| 용어 | 쉬운 뜻 |
|---|---|
| Factory | 새 Flutter Product의 안전한 시작점을 준비하는 시스템 |
| Product Repository | 실제 앱 코드와 Product 문서를 소유하는 독립 작업 공간 |
| Bootstrap | Product Repository와 Flutter 시작 구조를 준비하는 과정 |
| 공개 실행 창구 | 작업 도구가 Factory 기능을 사용하는 공식 Dart API |
| Preflight | 파일을 바꾸기 전에 입력과 경로의 안전성을 확인하는 단계 |
| Prepared | 자동 준비와 기술 검증이 끝났지만 User 승인은 아직인 상태 |
| Ready | User가 Product 시작 상태와 기준선을 승인한 상태 |
| Agreement | 다음 작은 작업의 목표, 범위와 완료 조건에 대한 합의 |
| Baseline | 다음 작업이 예상 상태인지 비교하기 위한 승인된 기준선 |
| Independent QA | 구현한 역할과 분리된 관점에서 결과를 검증하는 단계 |
| PartialFailure | 자동 정리를 계속하면 위험할 수 있어 User 검사가 필요한 상태 |

## 권한 문서 / Authoritative References

- `AGENTS.md` — 역할과 User 승인 권한 / Roles and User approval authority
- `Docs/ARCHITECTURE.md` — Bootstrap 계약과 안전 경계 / Bootstrap contract and safety boundaries
- `Docs/SETUP.md` — 실행 환경과 정확한 입력 / Environment and exact inputs
- `Docs/ROADMAP.md` — Factory 진행 상태 / Factory progress
