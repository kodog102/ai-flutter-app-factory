# 제품

> Factory의 사용자 가치와 V1 범위의 단일 권한

## 제품

**AI Flutter App Factory V1**

## 사용자

- 새로운 Flutter 모바일 Product Repository를 안전하고 일관된 상태로 준비해야 하는 User
- Factory를 다시 읽지 않고 Product Repository에서 첫 Agreement를 시작해야 하는 새로운 작업 주체

## 문제

새 Product Repository를 시작할 때 Repository 경계, 운영 Authority, Flutter 기본 구조와 검증 기준을 매번 다시 결정하면 누락과 불일치가 발생한다.

## 핵심 가치

승인된 표준 입력으로 독립 Flutter 모바일 Product Repository를 준비하고, Product-local 정보와 검증 Evidence만으로 다음 작업을 시작할 수 있게 한다.

## V1 입력과 결과

V1은 명시적인 Product, Repository, Flutter 식별자, 기술 및 대상 플랫폼 입력을 받는다. 전체 입력 계약은 `Docs/ARCHITECTURE.md`가 소유한다.

결과는 독립 Repository, iOS 및 Android Flutter 기본 구조, Product-local Authority, 필수 검증 Evidence와 User 승인 전 proposal이다.

## V1 포함 범위

- Flutter/Dart 기반 iOS 및 Android Product
- New Repository와 Existing Empty Repository mode
- Flutter 기본 dependency와 기본 scaffold
- Product-local `README.md`와 `AGENTS.md`
- Ready 검증과 실행 결과 보고

## V1 제외 범위

- Flutter Web, Flutter Desktop 및 비 Flutter 기술 스택
- Product 기능, 데이터 모델, UI, backend, 인증 및 외부 서비스 결정
- Product별 package 자동 선택
- Factory Template, CLI 또는 orchestration을 V1 필수 조건으로 만드는 것
- Product 기능 구현, 출시, remote 설정, commit 또는 push

## 성공 기준

1. 승인된 입력으로 독립 Flutter 모바일 Product Repository를 안전하게 준비할 수 있다.
2. iOS와 Android 기본 구조가 존재하고 필수 기술 검증을 통과한다.
3. Product-local Authority와 실행 보고만으로 첫 Agreement와 baseline 승인을 제안할 수 있다.
4. 특정 Product 분야나 실행 환경이 바뀌어도 Factory의 역할과 계약이 바뀌지 않는다.
5. 미지원 또는 불충분한 요청은 추측 없이 명확한 중단 결과가 된다.
