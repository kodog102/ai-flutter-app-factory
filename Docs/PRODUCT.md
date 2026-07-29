# PRODUCT.md

> 제품 목표, 사용자 가치, 범위의 단일 권한  
> Single authority for product goals, user value, and scope

## 제품명 / Product Name

임시 이름: **Subscription Tracker**

Temporary name: **Subscription Tracker**

## 제품 한 문장 / Product in One Sentence

정기 구독과 결제 예정일을 간단히 관리하고 월간 고정 지출을 한눈에 파악하는 앱.

A simple app for managing recurring subscriptions, upcoming billing dates, and monthly fixed expenses at a glance.

## 문제 / Problem

### 한국어

사용자는 여러 구독 서비스의 결제일과 금액을 기억하기 어렵다. 기존 금융 앱은 정보가 많고, 일반 할 일 앱은 반복 결제와 월간 비용을 이해하기 어렵다.

### English

Users struggle to remember billing dates and amounts across multiple subscriptions. Finance apps are often too broad, while general task apps do not model recurring payments and monthly fixed costs well.

## 핵심 사용자 / Primary User

- 3개 이상의 유료 구독을 사용하는 개인
- 결제일을 놓치거나 사용하지 않는 구독을 방치하는 사람
- 복잡한 가계부보다 가벼운 도구를 원하는 사람

## 핵심 가치 / Core Value

- 무엇이 언제 결제되는지 즉시 알 수 있다.
- 매월 고정적으로 나가는 금액을 쉽게 파악한다.
- 필요 없는 구독을 발견하고 정리할 수 있다.

## MVP 범위 / MVP Scope

### 포함 / Included

- 구독 추가, 수정, 삭제
- 이름, 금액, 통화, 결제 주기, 다음 결제일
- 활성/비활성 상태
- 예정 결제 목록
- 월간 예상 구독 비용 요약
- 카테고리 또는 간단한 아이콘 선택
- 로컬 저장
- 라이트 모드 우선
- iOS와 Android 실행 가능

### 제외 / Excluded

- 실제 결제 처리
- 은행 또는 카드 자동 연동
- 영수증 OCR
- 가족 공유
- 계정과 서버 동기화
- 웹 앱
- 복잡한 통계
- 다중 예산
- 앱 내부 유료 구독

## 성공 기준 / Success Criteria

1. 처음 실행한 사용자가 1분 안에 첫 구독을 추가할 수 있다.
2. 홈 화면에서 다음 결제와 월간 예상 비용을 즉시 이해할 수 있다.
3. iOS와 Android에서 같은 핵심 흐름이 동작한다.
4. Design Role 결과와 구현 화면 사이에 큰 구조적 차이가 없다.
5. Architecture Role의 추가 대화 없이 Implementation Role이 문서만 읽고 다음 기능을 진행할 수 있다.

## 제품 원칙 / Product Principles

- 지금 필요한 정보만 보여준다.
- 입력은 짧고 예측 가능해야 한다.
- 재무 앱처럼 무겁게 보이지 않는다.
- 사용자를 불안하게 만들지 않는다.
- 자동화되지 않은 데이터는 자동화된 것처럼 표현하지 않는다.
