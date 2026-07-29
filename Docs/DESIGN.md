# DESIGN.md

> Stitch를 위한 디자인 브리프이자 Flutter 구현 시각 기준  
> Design brief for Stitch and visual authority for Flutter implementation

## 디자인 역할 / Design Ownership

- Stitch가 UI/UX와 디자인 시스템의 시각적 권한을 가진다.
- Cursor는 Stitch 결과를 Flutter로 충실히 구현한다.
- Cursor가 디자인을 임의로 개선하거나 재해석하지 않는다.
- 접근성, 플랫폼 제약, 구현 불가능성으로 변경이 필요하면 먼저 차이를 보고한다.

## 제품 인상 / Product Impression

### 한국어

차분하고 현대적이며 가벼운 개인 금융 도구. 은행 앱처럼 복잡하거나 경고 중심으로 보이지 않는다. 사용자가 구독 상태를 빠르게 이해하고 정리할 수 있어야 한다.

### English

A calm, modern, lightweight personal finance tool. It should not feel like a dense banking app or an alarm-heavy expense warning system. Users should quickly understand and organize their subscriptions.

## 시각 방향 / Visual Direction

- 넉넉한 여백
- 명확한 정보 계층
- 카드 남용 금지
- 부드러운 표면과 절제된 강조
- 숫자는 읽기 쉽고 안정적으로 표시
- 결제 임박 상태는 명확하되 불안감을 과장하지 않음
- 장식보다 정보 구조 우선

## 필수 화면 / Required Screens

1. 첫 실행 빈 상태
2. 홈 대시보드
3. 구독 추가
4. 구독 상세
5. 구독 수정
6. 전체 구독 목록
7. 비활성 구독 상태
8. 오류 또는 입력 검증 상태

## 홈 화면 필수 정보 / Home Requirements

- 이번 달 예상 구독 비용
- 가장 가까운 다음 결제
- 예정 결제 목록
- 구독 추가 주요 CTA
- 전체 구독으로 이동하는 진입점

## Stitch 산출물 요구 / Stitch Deliverables

Stitch는 다음을 제공해야 한다.

- 모바일 화면 전체 흐름
- 핵심 화면의 빈 상태, 기본 상태, 데이터가 많은 상태
- Typography scale
- Color roles
- Spacing rules
- Radius and surface rules
- Button, field, list row, summary component
- 상태별 interaction notes
- iOS/Android 공통 구현이 가능한 구조

## 구현 전달 규칙 / Handoff Rules

Cursor는 Stitch 결과를 받을 때 다음을 정리한다.

- 화면 목록
- 재사용 컴포넌트
- 디자인 토큰
- 이미지와 아이콘 자산
- interaction
- 반응형 또는 작은 화면 고려
- Stitch에서 불명확한 부분

불명확한 항목은 임의 구현보다 질문 또는 명시적 가정을 우선한다.
