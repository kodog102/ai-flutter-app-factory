# VISION.md

> Factory의 존재 목적과 설계 원칙  

## 사명

- 새로운 Flutter 모바일 Product Repository가 일관된 운영 규칙과 검증된 기본 구조를 갖춘 운영·실행 가능한 시작 상태가 되도록 준비한다

## 비전

- Product Repository가 자체 문서와 검증된 Flutter 모바일 구조만으로 첫 Agreement를 시작할 수 있는 상태를 반복 가능하게 만든다
- Flutter 모바일 범위에서 특정 Product 분야에 종속되지 않는 Factory 기반을 유지한다
- 역할, 계약, 생성 결과를 특정 실행 도구와 분리한다

## 핵심 원칙

### 단일 기준 정보원

- 각 주제는 하나의 권한 문서만 가진다

### 결정 우선

- 되돌리기 어려운 방향은 구현 전에 결정한다

### AI 협업

- AI는 역할이 분리된 상태로 협력한다

### 작고 검토 가능한 변경

- 변경은 작고 검토 가능해야 한다

### 재사용 가능한 기반

- Factory는 다음 제품에도 재사용 가능해야 한다

### Flutter 모바일 V1 경계

- Factory V1은 Flutter/Dart 기반 iOS 및 Android Product를 지원한다
- Flutter Web, Flutter Desktop, 비 Flutter 기술 스택을 V1 지원 범위로 주장하지 않는다

### 팩토리 중심 검증

- Factory가 중심 Product다
- 테스트 Product는 Factory 가설을 검증하기 위한 실험 수단이다
- Product 완성도는 Factory의 성공 기준이 아니다
- 충분한 증거가 확보되면 테스트 Product를 완성하지 않고 Product 실험을 중단할 수 있다
- 한 Product의 결과를 자동으로 Core Standard로 승격하지 않는다
- 검증된 학습만 기존 Factory SSOT에 최소 반영한다

## 비목표

- 특정 제품의 비전을 대신하지 않는다
- Product 기능, 데이터 모델, UI, backend, 인증 또는 외부 서비스를 임의로 결정하지 않는다
- 완성된 범용 앱 프레임워크를 제공하지 않는다
- 비 Flutter 기술 스택을 위한 범용 Factory를 제공하지 않는다
- 자동으로 제품을 출시하지 않는다
- 서버, 결제, 계정 인프라를 기본 포함하지 않는다
- 모든 결정을 자동화하지 않는다
