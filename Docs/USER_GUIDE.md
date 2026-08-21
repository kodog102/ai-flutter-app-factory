# 사용설명서

> 비개발자가 AI Flutter App Factory로 샘플 Flutter 앱을 시작하는 순서 안내

상태: **사용 가능 — Flutter Factory V1.2 Consumer Ready**

## 이 문서의 목표

이 문서는 코드를 직접 작성하지 않는 사용자가 Product 정보를 준비하고, 작업 도구에 Factory 실행을 요청하고, 결과를 승인한 뒤 작은 샘플 앱을 실행하는 과정을 안내한다.

이 문서의 예시는 **장보기 목록 앱**이다. 사용자는 항목을 추가하고, 구매 완료로 표시하고, 삭제할 수 있다.

> 이 문서는 쉬운 사용 순서를 설명한다. 입력·중단·Repository 안전 규칙이 충돌하면 `Docs/ARCHITECTURE.md`와 `Docs/SETUP.md`가 우선한다.

## 먼저 알아둘 점

Factory V1.1은 `product_request.yaml` 하나와 한 명령을 제공한다. 이 명령은 기존 Dart 공개 Runtime을 호출하며 버튼형 독립 앱이나 AI Product Loop는 아니다. 사용자는 Factory Repository를 읽고 명령을 실행할 수 있는 **코드 작업 도구**에 파일과 실행 요청을 전달할 수 있다.

V1.2.1은 Product Loop Guard를 직접 Dart 코드로 연결하지 않아도 되는 한 명령 진입점을 제공한다. 다만 User 승인과 실제 Product 구현을 건너뛸 수 없으므로 같은 명령을 기준선 `capture`와 구현 후 `validate` 두 단계로 사용한다.

작업 도구의 제품명은 중요하지 않다. 다음 조건만 만족하면 된다.

- Factory와 Product 경로를 읽고 쓸 수 있다.
- Dart, Flutter와 Git 명령을 실행할 수 있다.
- 사용자 승인 전에 구현·커밋·push하지 않는다.
- Factory의 공개 실행 창구를 사용할 수 있다.

Factory가 처음 준비하는 것은 완성 앱이 아니라 **검증된 Flutter Product 시작점**이다. 실제 샘플 기능은 첫 Agreement를 승인한 다음 구현한다.

## 전체 순서

```text
1. 환경 확인
2. 만들 앱과 첫 범위 결정
3. 열 개 입력 작성
4. Factory 사전 검사와 실행 요청
5. Prepared 결과 검토
6. Ready 상태와 기준선 승인
7. 첫 Agreement와 위험도·역할·검증 범위 승인
8. 필요한 역할 활성화 → 필요한 검증
9. 필요할 때 Simulator에서 샘플 앱 확인
10. User 승인 후 commit
```

## 1. 환경 준비 확인

작업 도구에 아래 내용을 확인해 달라고 요청한다. 직접 Terminal 명령을 입력할 필요는 없다.

- Factory Repository가 clean 상태인가
- Git을 사용할 수 있는가
- Flutter와 Dart를 사용할 수 있는가
- Xcode와 iOS Simulator를 사용할 수 있는가
- Android SDK와 Android build toolchain을 사용할 수 있는가
- 새 Product를 만들 정확한 절대 경로가 안전한가

복사해서 사용할 요청:

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

## 2. 샘플 앱 범위 결정

첫 앱은 작게 시작한다. 한 번의 작업으로 로그인, 결제, 서버, 알림까지 모두 만들려고 하지 않는다.

샘플 장보기 목록의 권장 첫 범위:

### 포함

- 한 화면에 장보기 항목 목록 표시
- 새 항목 추가
- 구매 완료 상태 전환
- 항목 삭제
- 기기에 간단히 저장하고 재실행 후 복원
- 기본 Widget 및 저장 동작 테스트

### 제외

- 로그인과 회원가입
- 서버와 계정 동기화
- 결제
- 가족 공유
- 알림
- 앱스토어 배포

## 3. 열 개 입력 작성

처음에는 `newRepository` 사용을 권장한다. 기존 빈 Git Repository를 반드시 보존해야 할 때만 `existingEmptyRepository`를 선택한다.

| 번호 | 입력 | 장보기 샘플 값 |
|---|---|---|
| 1 | Product 표시 이름 | `My Shopping List` |
| 2 | Product 목적 | `장보기 항목을 간단히 기록하고 구매 상태를 관리한다.` |
| 3 | 초기 Product 범위 또는 첫 결과 | `추가, 완료 전환, 삭제와 로컬 복원이 가능한 한 화면 앱을 준비한다.` |
| 4 | 정확한 출력 경로 | `/Users/사용자이름/Documents/My Apps/my-shopping-list` |
| 5 | Repository 모드 | `newRepository` |
| 6 | 초기 branch 이름 또는 Repository 정책 | `main` |
| 7 | Flutter project 이름 | `my_shopping_list` |
| 8 | Organization 식별자 | `com.example` |
| 9 | 요청 기술 | `flutter` |
| 10 | 대상 플랫폼 | `ios`, `android` |

### 이름 작성 규칙

- Product 표시 이름은 사람이 보는 이름이므로 공백을 사용할 수 있다.
- Flutter project 이름은 소문자, 숫자와 `_`를 사용하는 Dart 식별자 형태다.
- 보유한 도메인이 없다면 샘플의 Organization 식별자에만 `com.example`을 사용한다.
- 출력 경로는 반드시 절대 경로를 사용하며 Factory 내부를 지정하지 않는다.

## 4. 팩토리 실행 요청

열 개 입력을 다음 `product_request.yaml`에 작성한다. 이 파일은 Factory와 Product 출력 경로 밖에 두며 symlink가 아닌 128 KiB 이하의 UTF-8 일반 파일이어야 한다.

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

### 기존 빈 저장소 입력

기존의 빈 Git Repository를 보존해야 할 때는 아래 조건을 모두 만족해야 한다.

- Product 경로가 이미 존재하며 일반 디렉터리다.
- Product 경로가 직접 소유한 실제 `.git` 디렉터리가 있다.
- 아직 commit이 없고 Product root에는 `.git` 외 항목이 없다.
- `initialBranchName`은 `null`이고 `repositoryPolicy`는 비어 있지 않은 설명문이다.

다음 블록을 복사한 뒤 Product 정보와 경로만 바꾼다. `preserve existing Repository policy`는 설명서가 권장하는 표준 입력값이며 Runtime은 다른 비어 있지 않은 정책 설명도 허용한다.

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

Factory Repository root에서 직접 실행하거나 작업 도구에 다음 한 명령을 그대로 실행하도록 요청한다.

```text
dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml
```

명령은 `stdout`에 JSON 한 문서, `stderr`에 한국어 우선 요약을 출력한다. JSON과 요약을 모두 보존해 사용자에게 제시하되, 명령 완료 후 Product 기능 구현을 시작하지 않는다.

## 5. 실행 결과 이해

| 결과 | 뜻 | 사용자가 할 일 |
|---|---|---|
| `BootstrapPreflightStopped` | 입력 또는 경로가 안전하지 않아 실행 전 중단 | 중단 이유를 읽고 입력만 수정한 뒤 다시 요청 |
| `BootstrapExecutionPrepared` | Flutter 시작 구조와 기술 검증이 준비됨 | Evidence와 제안을 검토하고 승인 여부 결정 |
| `BootstrapExecutionStopped` | 실행 중 안전하게 중단되거나 복구됨 | 확인된 사실과 미수행 항목 검토 |
| `BootstrapExecutionPartialFailure` | 자동 정리의 안전성을 보장할 수 없음 | 표시된 경로를 이동·삭제하지 말고 별도 검사 요청 |

V1.1 명령의 종료 코드는 다음처럼 해석한다.

| 종료 코드 | 뜻 | 사용자가 할 일 |
|---|---|---|
| `0` | `Prepared` | Evidence와 proposal을 검토하고 Ready 승인 여부 결정 |
| `2` | 요청·schema·preflight 중단 | 구조화된 오류만 확인하고 입력 수정 여부 결정 |
| `3` | 안전한 실행 중단 또는 복구 | 중단·복구 Evidence 검토 |
| `4` | `PartialFailure` | 보고된 경로를 변경하지 말고 별도 안전 검사 요청 |

`64`는 도움말·사용법 결과이며 `70`은 예상하지 못한 명령 계층 오류다.

```text
Prepared ≠ Ready ≠ Approved ≠ Released
```

`Prepared`는 Factory 자동 검증이 끝났다는 뜻일 뿐이다. 사용자의 Ready 승인과 첫 Agreement 승인은 별도로 필요하다.

## 6. 준비 완료 상태와 기준선 승인

Prepared 보고서에서 다음을 확인한다.

- Product 경로가 요청한 경로와 같은가
- iOS와 Android 구조가 생성됐는가
- dependency 준비, analyze, test와 두 platform build가 통과했는가
- Product `README.md`와 `AGENTS.md`가 존재하는가
- 예상하지 못한 파일이나 Git 변경이 없는가
- Baseline Handoff Proposal이 실제 상태와 일치하는가

모두 맞을 때 사용할 승인 문장:

```text
제시된 Product 경로, 기술 검증 Evidence와 Baseline Handoff Proposal을 확인했다.
현재 Product의 Ready 상태와 제안된 운영 기준선을 승인한다.

아직 Product 기능 구현을 시작하지 마라.
먼저 First Agreement Proposal을 사용자가 이해할 수 있는 말로 다시 제시하라.
Goal, Included Scope, Excluded Scope, Acceptance Criteria, Verification을 빠짐없이 포함하라.
commit과 push는 별도 승인 전까지 수행하지 마라.
```

내용이 다르면 승인하지 말고 차이만 수정 요청한다.

## 7. 첫 작업 합의 승인

Agreement는 법률 계약이 아니라 **이번에 할 작은 작업의 범위 합의**다.

반드시 다음 다섯 항목이 있어야 한다.

1. `Goal` — 이번 작업이 이루려는 결과
2. `Included Scope` — 이번에 만드는 것
3. `Excluded Scope` — 이번에 만들지 않는 것
4. `Acceptance Criteria` — 완료로 인정할 구체 조건
5. `Verification` — 테스트와 사용자 확인 방법

Agreement를 승인하기 전에 작업 도구가 위험도를 함께 제안하게 한다.

| 위험도 | 대표 작업 | 기본 역할과 검증 |
|---|---|---|
| Low | 문구·색상·작은 문서, 소스 변경 없는 빌드 파일 생성 | Main 1개, 독립 QA 생략, 관련 검증만 |
| Medium | 일반 기능, 여러 파일의 사용자 흐름·상태 변경 | Implementation, 독립 QA 1회, UI 결정이 있을 때만 Design |
| High | migration, 네이티브 경계, 알림, 보안, 실제 배포 | Architecture, Implementation, 독립 QA, 필요한 경우 Design |

빌드 파일을 만드는 것과 실제 업로드·배포·출시는 다르다. 소스와 dependency를 바꾸지 않고 기존 검증 코드로 산출물만 만들면 기본적으로 Low다. Simulator나 환경 오류가 발생해도 위험도를 올리지 않고 최초 시도 1회와 원인이 명확할 때 재시도 1회까지만 수행한다.

Agreement 또는 실행 계획을 수정했다면, 승인 전에 작업 도구가 **최신 통합 Agreement와 Execution Profile 전체**를 다시 제시해야 한다. 이전 제안이나 일부 수정 메시지에 대한 승인은 사용할 수 없다. 통합본에는 Risk Level, 이유, 역할, Agent Instances와 역할 매핑, Context Pack, Direct Approval Actions, Direct Executor, Verification Ladder, QA·Repair 한도, 환경 시도·재시도·시간 예산과 Stop Conditions가 포함되어야 한다.

Direct Approval Action은 사용자의 명시적 승인을 직접 확인할 수 있는 실행 주체만 수행할 수 있는 작업이다. 실기기 앱 설치, 인증서 또는 프로비저닝을 사용하는 서명, TestFlight·스토어·외부 콘솔 업로드, Release 또는 실서비스 배포, 외부 데이터의 삭제 또는 덮어쓰기가 여기에 해당한다. Agreement에는 그런 작업과 Direct Executor를 적고, 없으면 `None`으로 표시하게 한다. Direct Executor는 기본적으로 Main 또는 사용자 승인 메시지를 직접 볼 수 있는 다른 실행 주체다. 하위 실행 주체는 준비·진단·구현·QA를 할 수 있지만 그 승인 메시지를 직접 볼 수 없다면 이 작업을 실행하면 안 된다. Main도 사용자의 명시적 승인 전에는 실행할 수 없다.

승인 가시성이 불명확하거나 실제 Direct Executor가 승인된 내용과 다르면, 실행하지 말고 역할과 인스턴스 대응 관계 및 이유를 포함한 프로필 편차를 다시 제시하게 한다.

승인 직전에는 작업 도구가 Approved Execution Profile과 Planned Actual Execution을 비교해야 한다. 필수 역할, 독립 QA, Agent Instances, Context Pack, Direct Approval Actions, Direct Executor, 검증, QA·Repair·환경 예산 또는 중단 조건이 다르면 구현을 시작하지 말고 Profile Delta와 이유를 다시 제시하게 한다. Medium 또는 High의 Independent QA는 구현과 다른 실행 주체 또는 분리된 새 문맥이어야 하며, 이를 만들 수 없으면 Main 단독 실행을 허용하지 않는다.

복사해서 사용할 위험도 제안 요청:

```text
이번 Agreement를 구현하기 전에 작업 위험도를 Low, Medium, High 중 하나로 분류해 주세요.

함께 제시할 것:
- Risk Level과 구체적인 이유
- Activated Roles, Agent Instances, Role / Instance Mapping과 Capability Tier
- 변경에 필요한 파일만 담은 Context Pack
- Direct Approval Actions와 Direct Executor (`None` 가능)
- V0부터 V5 중 필요한 최소 검증 단계
- QA Count, Repair Limit과 생략할 QA, 전체 테스트, 플랫폼 빌드의 이유
- 환경 검증의 최초 시도·재시도·시간 한도
- Stop Conditions

빌드 산출물 생성과 실제 배포를 구분하세요.
환경 실패를 이유로 Risk Level을 높이지 마세요.
User가 요청하지 않은 README나 다른 문서를 수정하지 마세요.
수정 요청이 있었다면 최신 통합 Agreement와 Execution Profile을 다시 제시한 뒤에만 승인을 받으세요.
Approved Execution Profile과 Planned Actual Execution이 다르면 구현하지 말고 Profile Delta 승인을 기다리세요.
```

장보기 샘플의 승인 예시:

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
이 작업은 여러 파일의 UI 흐름을 변경하므로 Medium으로 분류하라.
UI 작업이 있으므로 Design Role을 먼저 활성화하라.
Implementation과 독립 QA를 분리하라.
QA가 PASS이면 결과와 화면을 보고하고 commit은 하지 마라.
```

실행 중에는 승인되지 않은 역할·QA·검증·Repair·환경 복구나 우회를 추가하거나 대체할 수 없다. Simulator 또는 Emulator는 최초 시도 1회와 원인이 명확한 재시도 1회만 허용하며, 복구를 포함한 문제 해결은 기본 10–15분 안에서 중단한다. 예산이 소진되면 서비스 재시작, 초기화, 다른 기기 또는 다른 도구 우회 대신 `Environment Blocked`와 남은 수동 확인을 보고하게 한다.

## 8. 제품 개발 루프 실행

Agreement 구현 전에 작업 도구에 V1.2.1 기준선 Capture를 요청한다. 요청 파일과 빈 Evidence 디렉터리는 Factory와 Product 밖에 둔다.

Capture 전에 다음 네 가지를 반드시 확인한다.

1. 요청 파일 이름은 정확히 `product_loop_request.yaml`이다.
2. Evidence 디렉터리는 명령 실행 전에 이미 존재한다.
3. Evidence 디렉터리는 비어 있으며 symlink가 아니다.
4. 요청 파일과 Evidence 디렉터리는 Factory와 Product Repository 밖에 있다.

```yaml
schemaVersion: 1
productRoot: /Users/사용자이름/Documents/제품경로/example_product
buildPolicy: both
evidenceDirectory: /Users/사용자이름/Documents/factory-evidence/agreement-001
```

작업 도구에 전달할 요청:

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

UI가 포함된 장보기 샘플은 다음 순서를 따른다.

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

구현과 자체 검증이 끝나면 승인했던 SHA-256으로 Validate를 요청한다.

```text
Factory Root에서 아래 Product Loop 후보 검증을 실행해 주세요.

dart run ai_flutter_app_factory:factory_product_loop \
  --request /절대경로/product_loop_request.yaml \
  --phase validate \
  --approved-baseline-sha256 <내가 승인한 SHA-256>

구조화된 Evidence와 Flutter Health Gate 결과를 보고하세요.
기술 검증 성공을 QA PASS 또는 User 승인으로 해석하지 마세요.
승인된 Risk Level에 따라 필요한 경우에만 독립 QA를 수행하세요.
Low 작업에는 독립 QA를 자동으로 추가하지 마세요.
commit과 push는 하지 마세요.
```

## 9. 샘플 앱 실행 확인

Agreement의 Acceptance Criteria를 자동 테스트나 build만으로 증명할 수 없을 때 Simulator 실행과 화면 확인을 요청한다. Low 작업이나 이미 같은 기준선에서 검증한 산출물 생성에는 Simulator를 자동으로 추가하지 않는다.

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

Android Emulator도 실제 플랫폼 차이를 확인해야 할 때만 별도 요청으로 같은 시나리오를 반복한다. Simulator나 Emulator가 실패하면 최초 시도 1회와 원인이 명확할 때의 재시도 1회까지만 허용하고, 기본 10–15분 안에 환경 차단으로 보고한다.

Repair가 필요하면 원래 Execution Profile을 다시 초기화하지 않는다. Required Defect, Allowed Files, Focused Verification, QA Recheck Scope와 Additional Attempt Budget만 Profile Delta로 제시하고 승인받는다.

## 10. 최종 승인과 커밋

다음을 모두 확인한 뒤에만 commit을 요청한다.

- Agreement 범위만 변경됨
- Design이 활성화됐다면 결과와 실제 화면이 일치함
- Medium 또는 High라면 QA가 PASS임
- 분석, 테스트와 필요한 build가 통과함
- 예상하지 못한 파일이 없음
- 민감정보가 없음
- Approved-vs-Actual 비교에서 승인되지 않은 편차가 없음

최종 결과에는 아래 비교를 포함하게 한다. 승인되지 않은 편차가 있으면 기술 검증이 통과했어도 Adaptive Policy Safety는 FAIL이다.

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

```text
최종 구현과 승인된 Risk Level에 따른 검증 결과를 승인한다.
승인된 변경 파일만 stage하고 Risk Level에 승인된 필수 검증만 다시 실행하라.
검증이 모두 통과하면 작업 내용을 정확히 설명하는 한 개의 commit을 생성하라.
push, amend, rebase, tag는 수행하지 마라.
commit hash, 메시지, 파일 목록과 최종 Git 상태를 보고하라.
```

## 문제 해결

### 사전 점검에서 중단됨

입력값을 임의로 바꾸지 말고 `reasons`에서 지목한 필드만 수정한다. 경로가 위험하다는 결과가 나오면 다른 절대 경로를 사용한다.

### 기존 빈 저장소가 거절됨

처음 사용하는 사용자는 `newRepository`를 선택하는 것이 안전하다. Existing mode는 직접 `.git`을 가진 독립 Repository이며 `.git` 외 항목이 없는 경우에만 사용한다. 요청에는 `initialBranchName: null`과 비어 있지 않은 `repositoryPolicy`가 필요하다. 위의 **기존 빈 Repository 입력** 예제를 그대로 복사해 다시 시도한다.

### 부분 실패가 반환됨

보고된 target 또는 staging 경로를 직접 삭제하거나 덮어쓰지 않는다. 작업 도구에 읽기 전용 검사를 요청하고, 소유권과 외부 변경이 확인될 때까지 기다린다.

### iOS 또는 Android 빌드가 실패함

Product 코드를 먼저 수정하지 않는다. 실패가 환경 문제인지 Product 문제인지 분리해서 보고하도록 요청한다. 로그인, 라이선스, SDK 설치 또는 관리자 권한이 필요하면 사용자가 별도로 승인한다.

### 결과가 너무 큰 기능 범위를 제안함

첫 Agreement를 더 작게 줄인다. 한 화면과 한 가지 사용자 흐름을 우선하고 나머지는 Excluded Scope로 옮긴다.

## 완료 체크리스트

샘플 앱 시작이 완료됐다고 판단하려면 다음을 모두 확인한다.

- [ ] 열 개 입력이 명확하다.
- [ ] Preflight가 Ready를 반환했다.
- [ ] Execution이 Prepared를 반환했다.
- [ ] 기술 검증이 모두 통과했다.
- [ ] Product-local README와 AGENTS가 있다.
- [ ] User가 Ready 상태와 기준선을 승인했다.
- [ ] User가 첫 Agreement를 승인했다.
- [ ] Risk Level과 필요한 역할·검증 범위를 승인했다.
- [ ] 활성화된 역할과 필요한 QA가 완료됐다.
- [ ] 필요한 경우에만 Simulator에서 샘플 흐름을 확인했다.
- [ ] User 승인 후 commit했다.
- [ ] Push와 Release는 별도 승인으로 남아 있다.

## V1 범위

Factory V1이 제공하는 것:

- iOS와 Android Flutter 시작 구조
- 독립 Product Repository 경계
- Product-local 운영 문서와 첫 Agreement 제안
- 기본 dependency, analyze, test와 두 platform build 검증
- 안전한 중단과 구조화된 Evidence
- `product_request.yaml`과 한 명령을 사용하는 V1.1 Bootstrap
- 승인 SHA-256을 사용하는 V1.2.1 Product Loop Capture·Validate 명령

Factory V1이 자동으로 제공하지 않는 것:

- 완성된 Product 기능
- 로그인, backend, 결제와 배포
- User를 대신한 Ready·Agreement·Release 승인
- 자동 commit, push 또는 tag
- 버튼형 독립 실행 앱, Product 구현·승인 자동화 또는 Provider Adapter

## 용어

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

## 기존 제품 권한 확인

기존 Product Repository의 `AGENTS.md`가 현재 Factory 권한 계약과 일치하는지 확인할 때는 `ProductAuthorityAuditor`를 사용한다. 감사 결과가 준수 보고이면 누락된 항목이 없는지 확인하고, 편차가 있으면 해당 목록을 다음 Agreement의 입력으로 사용한다.

구조화된 중단 결과가 나오면 Product 경계, Git top-level과 `AGENTS.md` 파일 상태를 먼저 확인한다. 중단 상태를 준수로 간주하거나 문서를 자동 수정하지 않는다. 감사 자체는 Product 파일과 Git 상태를 바꾸지 않는다.

## 실행 프로필 확인

실행 전에 완전한 실행 프로필 제안과 SHA-256을 함께 확인한다. 역할, 실행 주체, 독립 QA, 변경 허용 파일, 보호 대상, 직접 승인 작업, 검증 단계와 재시도 예산이 Agreement와 일치할 때만 해당 해시를 승인한다.

실행 주체는 승인된 해시와 계획 실행을 `ExecutionProfileValidator`로 비교한다. 일치 결과는 해시와 계획이 같다는 의미일 뿐 사용자 승인이나 Product 변경 권한을 새로 만들지 않는다. 중단 결과가 나오면 표시된 필드 편차를 수정한 통합 Agreement와 실행 프로필을 다시 제시하고 새 승인을 기다린다.

작업을 마치기 전에는 실제 역할, QA·수정 횟수와 환경 사용량을 승인 예산과 다시 비교한다. 환경 재시도가 있었다면 각 재시도의 명확한 실패 원인과 확인 증거도 함께 기록한다. 편차가 있거나 재시도 증거가 없으면 기술 검증이 성공했더라도 완료나 승인을 제안하지 않는다.

## 권한 문서

- `AGENTS.md` — 역할과 User 승인 권한
- `Docs/ARCHITECTURE.md` — Bootstrap 계약과 안전 경계
- `Docs/SETUP.md` — 실행 환경과 정확한 입력
- `Docs/ROADMAP.md` — Factory 진행 상태
