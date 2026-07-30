# DESIGN.md

> Factory와 Product의 디자인 권한 경계
> Design authority boundary between the Factory and Product

## Factory V1 Design Surface

Factory V1에는 별도 사용자 인터페이스나 시각 디자인 시스템이 없다.

Factory V1 has no separate user interface or visual design system.

Flutter scaffold는 기술적 Bootstrap 산출물이며 Product 디자인 결정이 아니다.

The Flutter scaffold is a technical Bootstrap output, not a Product design decision.

## Product Design Ownership

- Product UI/UX, 화면, 디자인 시스템과 시각 기준은 Product Repository가 소유한다
- The Product Repository owns Product UI/UX, screens, the design system, and visual standards
- Product 디자인은 승인된 Product-local Agreement와 Design Role 결과에 근거한다
- Product design is based on an approved Product-local Agreement and Design Role output
- Factory는 Product 분야나 기능을 근거로 디자인을 임의로 생성하지 않는다
- The Factory does not infer or create design from a Product domain or feature

## Boundary

Product 디자인이 첫 작업에 필요하면 Product Repository의 기존 Authority를 갱신하거나 실제로 필요한 Authority만 추가한다. Factory 디자인 문서를 Product에 복사하지 않는다.

When Product design is required for the first task, update existing Product Repository authority or add only the authority that is actually needed. Do not copy the Factory design document into the Product.
