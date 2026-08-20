# Template 명세

> Factory Template 최소 사양  

## 상태

비활성 이전 초안

## 목적

- 비활성 legacy 경로에서 Template를 식별하고 위치를 결정하던 초안 계약을 기록한다
- Template Locator와 Project Generator가 공유할 최소 기준을 제공한다

이 문서는 현재 Executable Flutter V1 계약이나 실행 경로가 아니다. 현재 Authority는 `Docs/ARCHITECTURE.md`다.

## 범위

이 문서는 Template의 식별, Manifest 표현, 저장 위치, Locator 계약, Generator와의 관계만 정의한다.

## 비목표

- Template Locator 구현
- Template 복사
- 파일 생성
- Flutter CLI 실행
- 변수 치환
- Project Generator 구현
- Plugin 또는 Toolchain 실행

## Template 정의

Template는 Factory가 프로젝트 생성을 시작할 때 기준으로 삼는 재사용 가능한 파일 시스템 디렉터리다.

Template는 코드나 파일을 직접 생성하는 실행 단위가 아니다. Template는 위치를 가진 입력 자산이며, 실제 복사와 생성은 이후 Generator 단계가 담당한다.

## Template 식별

Factory는 Template를 `id`와 `path`의 조합으로 식별한다.

### `id`

- 사람이 읽을 수 있는 안정적인 식별자다
- 로그, 보고, 문서, UI에서 Template를 지칭할 때 사용한다
- 파일 시스템 위치를 직접 의미하지 않는다

### `path`

- Repository Root 기준 상대 경로다
- Template Locator가 실제 위치를 찾기 위한 입력이다
- `templates/` 아래의 디렉터리를 가리켜야 한다

### 이유

`id`만 사용하면 파일 시스템 위치를 찾기 위한 별도 registry가 필요하다.

`path`만 사용하면 보고나 사용자 선택 화면에서 Template를 안정적으로 지칭하기 어렵다.

따라서 Manifest는 사람이 이해할 수 있는 `id`와 Locator가 사용할 수 있는 `path`를 함께 가진다.

## Manifest 구조

`factory.yaml`은 최상위 `template` 항목으로 기본 Template를 선언한다.

```yaml
template:
  id: flutter_basic_app
  path: templates/flutter_basic_app
```

### 필드

#### `template.id`

- 타입: `String`
- 필수 여부: 필수
- 의미: Factory가 사용할 Template의 안정적인 식별자

#### `template.path`

- 타입: `String`
- 필수 여부: 필수
- 의미: Repository Root 기준 Template 디렉터리 상대 경로

## Template 위치 규칙

Template는 Repository 내부의 `templates/` 디렉터리 아래에 저장한다.

```text
.
└── templates/
    └── <template-id>/
```

### 경로 규칙

- `template.path`는 Repository Root 기준 상대 경로여야 한다
- `template.path`는 `templates/`로 시작해야 한다
- `template.path`는 Template 디렉터리를 가리켜야 한다
- 절대 경로는 Manifest에 기록하지 않는다
- `..`를 사용해 Repository Root 밖을 가리키지 않는다

## 탐색기 계약

Template Locator는 Manifest에서 얻은 Template 경로를 파일 시스템에서 사용할 수 있는 경로로 해석한다.

### 입력

```dart
String templatePath
```

- 값 출처: `FactoryManifest.template.path`
- 형식: Repository Root 기준 상대 경로
- 예: `templates/flutter_basic_app`

### 출력

```dart
String locatedTemplatePath
```

- 의미: 파일 시스템에서 사용할 수 있는 Template 디렉터리 경로
- 이후 Generator의 입력으로 전달된다

### 책임 경계

Locator는 경로를 해석하고 Template 위치를 반환하는 역할만 수행한다.

Locator는 Template 내용을 읽거나 복사하지 않는다.

## 생성기와의 관계

Generator는 Locator가 반환한 Template 위치를 입력으로 받는다.

Generator는 해당 위치를 기준으로 프로젝트 생성에 필요한 파일 복사, 렌더링, 변수 치환, 출력 디렉터리 생성을 수행할 수 있다.

이 문서는 Generator가 어떤 파일을 어떻게 복사하거나 변환하는지는 정의하지 않는다. Generator는 Template의 위치를 직접 추정하지 않고 Locator 결과를 사용해야 한다.

## 향후 작업

- `FactoryManifest`에 `template` 구조 반영
- `factory.yaml`에 기본 Template 선언 추가
- `TemplateLocator` 계약 구현
- 파일 시스템 기반 Locator 구현
- Project Generator 계약 정의
