# Template Specification

> Factory Template 최소 사양  
> Minimum specification for Factory Templates

## Status

Inactive Legacy Draft

## Purpose

- 비활성 legacy 경로에서 Template를 식별하고 위치를 결정하던 초안 계약을 기록한다
- Record the draft contract that identified and located Templates in the inactive legacy path
- Template Locator와 Project Generator가 공유할 최소 기준을 제공한다
- Provide the minimum shared rules for Template Locator and Project Generator

이 문서는 현재 Executable Flutter V1 계약이나 실행 경로가 아니다. 현재 Authority는 `Docs/ARCHITECTURE.md`다.

This document is not the current Executable Flutter V1 contract or execution path. The current authority is `Docs/ARCHITECTURE.md`.

## Scope

이 문서는 Template의 식별, Manifest 표현, 저장 위치, Locator 계약, Generator와의 관계만 정의한다.

This document defines only Template identity, Manifest representation, storage location, Locator contract, and the relationship with Generator.

## Non-Goals

- Template Locator 구현
- Template Locator implementation
- Template 복사
- Template copying
- 파일 생성
- File generation
- Flutter CLI 실행
- Flutter CLI execution
- 변수 치환
- Variable substitution
- Project Generator 구현
- Project Generator implementation
- Plugin 또는 Toolchain 실행
- Plugin or Toolchain execution

## Template Definition

Template는 Factory가 프로젝트 생성을 시작할 때 기준으로 삼는 재사용 가능한 파일 시스템 디렉터리다.

A Template is a reusable file-system directory used by the Factory as the starting point for project generation.

Template는 코드나 파일을 직접 생성하는 실행 단위가 아니다. Template는 위치를 가진 입력 자산이며, 실제 복사와 생성은 이후 Generator 단계가 담당한다.

A Template is not an execution unit that creates code or files by itself. It is an input asset with a location, while copying and generation belong to a later Generator step.

## Template Identification

Factory는 Template를 `id`와 `path`의 조합으로 식별한다.

The Factory identifies a Template with both `id` and `path`.

### `id`

- 사람이 읽을 수 있는 안정적인 식별자다
- Human-readable stable identifier
- 로그, 보고, 문서, UI에서 Template를 지칭할 때 사용한다
- Used to refer to a Template in reports, documents, and UI
- 파일 시스템 위치를 직접 의미하지 않는다
- Does not directly mean a file-system location

### `path`

- Repository Root 기준 상대 경로다
- Repository-root-relative path
- Template Locator가 실제 위치를 찾기 위한 입력이다
- Input used by Template Locator to locate the actual position
- `templates/` 아래의 디렉터리를 가리켜야 한다
- Must point to a directory under `templates/`

### Rationale

`id`만 사용하면 파일 시스템 위치를 찾기 위한 별도 registry가 필요하다.

Using only `id` would require a separate registry to resolve file-system locations.

`path`만 사용하면 보고나 사용자 선택 화면에서 Template를 안정적으로 지칭하기 어렵다.

Using only `path` makes it harder to refer to Templates stably in reports or user-facing selection.

따라서 Manifest는 사람이 이해할 수 있는 `id`와 Locator가 사용할 수 있는 `path`를 함께 가진다.

Therefore the Manifest keeps both a human-readable `id` and a Locator-ready `path`.

## Manifest Structure

`factory.yaml`은 최상위 `template` 항목으로 기본 Template를 선언한다.

`factory.yaml` declares the default Template using a top-level `template` entry.

```yaml
template:
  id: flutter_basic_app
  path: templates/flutter_basic_app
```

### Fields

#### `template.id`

- 타입: `String`
- Type: `String`
- 필수 여부: 필수
- Required: yes
- 의미: Factory가 사용할 Template의 안정적인 식별자
- Meaning: stable identifier of the Template used by the Factory

#### `template.path`

- 타입: `String`
- Type: `String`
- 필수 여부: 필수
- Required: yes
- 의미: Repository Root 기준 Template 디렉터리 상대 경로
- Meaning: repository-root-relative path to the Template directory

## Template Location Rules

Template는 Repository 내부의 `templates/` 디렉터리 아래에 저장한다.

Templates are stored inside the repository under the `templates/` directory.

```text
.
└── templates/
    └── <template-id>/
```

### Path Rules

- `template.path`는 Repository Root 기준 상대 경로여야 한다
- `template.path` must be relative to the Repository Root
- `template.path`는 `templates/`로 시작해야 한다
- `template.path` must start with `templates/`
- `template.path`는 Template 디렉터리를 가리켜야 한다
- `template.path` must point to a Template directory
- 절대 경로는 Manifest에 기록하지 않는다
- Absolute paths are not written in the Manifest
- `..`를 사용해 Repository Root 밖을 가리키지 않는다
- `..` must not be used to point outside the Repository Root

## Locator Contract

Template Locator는 Manifest에서 얻은 Template 경로를 파일 시스템에서 사용할 수 있는 경로로 해석한다.

Template Locator resolves the Template path from the Manifest into a file-system path usable by later pipeline steps.

### Input

```dart
String templatePath
```

- 값 출처: `FactoryManifest.template.path`
- Source: `FactoryManifest.template.path`
- 형식: Repository Root 기준 상대 경로
- Format: repository-root-relative path
- 예: `templates/flutter_basic_app`
- Example: `templates/flutter_basic_app`

### Output

```dart
String locatedTemplatePath
```

- 의미: 파일 시스템에서 사용할 수 있는 Template 디렉터리 경로
- Meaning: file-system path to the Template directory
- 이후 Generator의 입력으로 전달된다
- Passed to the Generator as input

### Responsibility Boundary

Locator는 경로를 해석하고 Template 위치를 반환하는 역할만 수행한다.

The Locator only resolves the path and returns the Template location.

Locator는 Template 내용을 읽거나 복사하지 않는다.

The Locator does not read or copy Template contents.

## Relationship With Generator

Generator는 Locator가 반환한 Template 위치를 입력으로 받는다.

The Generator receives the Template location returned by the Locator.

Generator는 해당 위치를 기준으로 프로젝트 생성에 필요한 파일 복사, 렌더링, 변수 치환, 출력 디렉터리 생성을 수행할 수 있다.

The Generator may use that location to copy files, render files, substitute variables, and create output directories.

이 문서는 Generator가 어떤 파일을 어떻게 복사하거나 변환하는지는 정의하지 않는다. Generator는 Template의 위치를 직접 추정하지 않고 Locator 결과를 사용해야 한다.

This document does not define how the Generator copies or transforms files. The Generator must use the Locator result instead of guessing the Template location.

## Future Work

- `FactoryManifest`에 `template` 구조 반영
- Reflect `template` structure in `FactoryManifest`
- `factory.yaml`에 기본 Template 선언 추가
- Add the default Template declaration to `factory.yaml`
- `TemplateLocator` 계약 구현
- Implement the `TemplateLocator` contract
- 파일 시스템 기반 Locator 구현
- Implement a file-system-based Locator
- Project Generator 계약 정의
- Define the Project Generator contract
