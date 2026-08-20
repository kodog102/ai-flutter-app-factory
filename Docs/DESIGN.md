# 디자인

> Factory와 Product의 디자인 권한 경계

## 팩토리 V1 디자인 범위

Factory V1에는 별도 사용자 인터페이스나 시각 디자인 시스템이 없다.

Flutter scaffold는 기술적 Bootstrap 산출물이며 Product 디자인 결정이 아니다.

## 제품 디자인 소유권

- Product UI/UX, 화면, 디자인 시스템과 시각 기준은 Product Repository가 소유한다
- Product 디자인은 승인된 Product-local Agreement와 Design Role 결과에 근거한다
- Factory는 Product 분야나 기능을 근거로 디자인을 임의로 생성하지 않는다

## 경계

Product 디자인이 첫 작업에 필요하면 Product Repository의 기존 Authority를 갱신하거나 실제로 필요한 Authority만 추가한다. Factory 디자인 문서를 Product에 복사하지 않는다.
