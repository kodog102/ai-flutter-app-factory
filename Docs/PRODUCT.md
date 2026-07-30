# PRODUCT.md

> Factory의 사용자 가치와 V1 범위의 단일 권한
> Single authority for Factory user value and V1 scope

## Product

**AI Flutter App Factory V1**

## User

- 새로운 Flutter 모바일 Product Repository를 안전하고 일관된 상태로 준비해야 하는 User
- A User who needs to prepare a new Flutter mobile Product Repository safely and consistently
- Factory를 다시 읽지 않고 Product Repository에서 첫 Agreement를 시작해야 하는 새로운 작업 주체
- A new work participant who must begin the first Agreement in the Product Repository without rereading the Factory

## Problem

새 Product Repository를 시작할 때 Repository 경계, 운영 Authority, Flutter 기본 구조와 검증 기준을 매번 다시 결정하면 누락과 불일치가 발생한다.

Re-deciding the Repository boundary, operating authority, Flutter base structure, and verification criteria for every new Product Repository creates omissions and inconsistencies.

## Core Value

승인된 표준 입력으로 독립 Flutter 모바일 Product Repository를 준비하고, Product-local 정보와 검증 Evidence만으로 다음 작업을 시작할 수 있게 한다.

Prepare an independent Flutter mobile Product Repository from approved standard inputs so that the next task can begin using only Product-local information and verification Evidence.

## V1 Inputs and Result

V1은 명시적인 Product, Repository, Flutter 식별자, 기술 및 대상 플랫폼 입력을 받는다. 전체 입력 계약은 `Docs/ARCHITECTURE.md`가 소유한다.

V1 accepts explicit Product, Repository, Flutter identifier, technology, and target-platform inputs. `Docs/ARCHITECTURE.md` owns the complete input contract.

결과는 독립 Repository, iOS 및 Android Flutter 기본 구조, Product-local Authority, 필수 검증 Evidence와 User 승인 전 proposal이다.

The result is an independent Repository, an iOS and Android Flutter base structure, Product-local authority, required verification Evidence, and proposals that precede User approval.

## V1 Included Scope

- Flutter/Dart 기반 iOS 및 Android Product
- Flutter/Dart-based iOS and Android Products
- New Repository와 Existing Empty Repository mode
- New Repository and Existing Empty Repository modes
- Flutter 기본 dependency와 기본 scaffold
- Default Flutter dependencies and base scaffold
- Product-local `README.md`와 `AGENTS.md`
- Product-local `README.md` and `AGENTS.md`
- Ready 검증과 실행 결과 보고
- Ready verification and runtime reporting

## V1 Excluded Scope

- Flutter Web, Flutter Desktop 및 비 Flutter 기술 스택
- Flutter Web, Flutter Desktop, and non-Flutter technology stacks
- Product 기능, 데이터 모델, UI, backend, 인증 및 외부 서비스 결정
- Product feature, data model, UI, backend, authentication, and external-service decisions
- Product별 package 자동 선택
- Automatic selection of Product-specific packages
- Factory Template, CLI 또는 orchestration을 V1 필수 조건으로 만드는 것
- Making a Factory Template, CLI, or orchestration a V1 requirement
- Product 기능 구현, 출시, remote 설정, commit 또는 push
- Product feature implementation, release, remote setup, commit, or push

## Success Criteria

1. 승인된 입력으로 독립 Flutter 모바일 Product Repository를 안전하게 준비할 수 있다.
2. iOS와 Android 기본 구조가 존재하고 필수 기술 검증을 통과한다.
3. Product-local Authority와 실행 보고만으로 첫 Agreement와 baseline 승인을 제안할 수 있다.
4. 특정 Product 분야나 실행 환경이 바뀌어도 Factory의 역할과 계약이 바뀌지 않는다.
5. 미지원 또는 불충분한 요청은 추측 없이 명확한 중단 결과가 된다.

1. Approved inputs can safely prepare an independent Flutter mobile Product Repository.
2. The iOS and Android base structure exists and passes the required technical verification.
3. Product-local authority and runtime reports are sufficient to propose the first Agreement and baseline approval.
4. Factory roles and contracts remain unchanged when the Product domain or execution environment changes.
5. Unsupported or insufficient requests produce an explicit stop result without guessing.
