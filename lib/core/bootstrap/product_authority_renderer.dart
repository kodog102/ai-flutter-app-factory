import 'validated_bootstrap_request.dart';

final class ProductAuthorityDocuments {
  const ProductAuthorityDocuments({
    required this.readme,
    required this.agents,
  });

  final String readme;
  final String agents;
}

final class ProductAuthorityRenderer {
  const ProductAuthorityRenderer();

  ProductAuthorityDocuments render(ValidatedBootstrapRequest request) {
    final name = _safeMarkdown(request.productDisplayName);
    final purpose = _safeMarkdown(request.productPurpose);
    final scope =
        _safeMarkdown(request.initialProductScopeOrFirstIntendedOutcome);
    return ProductAuthorityDocuments(
      readme: _readme(name: name, purpose: purpose, scope: scope),
      agents: _agents(name: name, purpose: purpose, scope: scope),
    );
  }

  String _readme({
    required String name,
    required String purpose,
    required String scope,
  }) {
    return '''# $name

## Product 정체성 / Product Identity

- Product 이름: $name
- Product name: $name

## Product 목적 / Product Purpose

> $purpose

이 문장은 Product가 해결하려는 목적의 현재 기준이다.

This statement is the current authority for the Product purpose.

## 초기 범위 또는 첫 번째 의도된 결과 / Initial Scope or First Intended Outcome

> $scope

## 현재 Bootstrap 상태 / Current Bootstrap Status

- Flutter 모바일 iOS 및 Android 시작 구조가 준비되었다.
- A Flutter mobile iOS and Android starting structure has been prepared.
- Product 기능 구현은 아직 시작되지 않았다.
- Product feature implementation has not started.
- 자동 기술 검증은 통과했다.
- Automated technical validation has passed.
- User의 Ready 승인은 대기 중이다.
- User Ready approval is pending.
- 첫 Agreement 승인은 대기 중이다.
- First Agreement approval is pending.
- 첫 구현 전 User가 첫 Agreement를 승인해야 한다.
- The User must approve the first Agreement before implementation.

## Repository-local 시작점 / Repository-local Starting Point

작업을 시작하기 전에 이 Repository의 `AGENTS.md`를 읽고 현재 Git 상태를 승인된 baseline handoff와 비교한다.

Before starting work, read this Repository's `AGENTS.md` and compare the current Git state with the approved baseline handoff.
''';
  }

  String _agents({
    required String name,
    required String purpose,
    required String scope,
  }) {
    return '''# AGENTS.md

> $name Product Repository의 운영 권한
>
> Operating authority for the $name Product Repository

## Repository 정체성과 경계 / Repository Identity and Boundary

- 이 Repository는 $name Product와 그 내부 작업만 소유한다.
- This Repository owns only the $name Product and its internal work.
- Product 목적: $purpose
- Product purpose: $purpose
- 초기 범위: $scope
- Initial scope: $scope
- Product root 밖의 파일은 수정하지 않는다.
- Do not modify files outside the Product root.
- Factory는 외부의 읽기 전용 참고 대상이며 Product 작업에서 수정하지 않는다.
- The Factory is an external read-only reference and must not be modified during Product work.

## User 권한 / User Authority

- User는 Product 방향, 범위, Agreement, 구현 결과, QA 판정과 Ready 상태의 최종 승인자다.
- The User is the final approver of Product direction, scope, Agreements, implementation results, QA verdicts, and Ready state.
- 최종 결정을 역할 또는 실행 도구가 대신하지 않는다.
- No role or runtime tool may replace the User's final decision.

## 상시 역할과 변경 권한 / Permanent Roles and Change Permissions

- Architecture Role은 Product context와 운영 Authority를 유지하고 구현 범위를 제안한다.
- The Architecture Role maintains Product context and operating authority and proposes implementation boundaries.
- Design Role은 Agreement에 UI/UX 또는 시각적 설계 범위가 있을 때만 활성화하며, 승인에 필요한 디자인 방향과 구현 handoff를 준비한다.
- The Design Role is activated only when an Agreement contains UI/UX or visual-design scope and prepares the design direction and implementation handoff required for approval.
- Design Role은 production code를 수정하거나 Architecture를 결정하지 않으며 User의 최종 Product 결정을 대신하지 않는다.
- The Design Role does not modify production code, decide architecture, or replace the User's final Product decision.
- Implementation Role은 승인된 Agreement 범위 안에서만 Product root를 변경한다.
- The Implementation Role changes the Product root only within an approved Agreement.
- Implementation Role은 승인된 디자인 방향을 임의로 재해석하지 않는다.
- The Implementation Role does not reinterpret an approved design direction.
- QA Role은 구현과 분리된 관점에서 검증하고 최종 품질 판정을 내리며 구현 파일을 수정하지 않는다.
- The QA Role verifies independently from implementation, gives the quality verdict, and does not modify implementation files.
- 역할은 책임을 나타내며 runtime 도구는 교체 가능하다.
- Roles express responsibility; runtime tools are replaceable.

## Agreement 규칙 / Agreement Rule

구현 전에 User가 다음 다섯 항목을 포함한 작은 Agreement를 승인해야 한다.

Before implementation, the User must approve a small Agreement containing:

- Goal
- Included Scope
- Excluded Scope
- Acceptance Criteria
- Verification

## 표준 작업 순환 / Standard Work Loop

1. Product context와 실제 Git 상태를 pre-flight에서 확인한다.
   Check Product context and the actual Git state during pre-flight.
2. 작은 Agreement를 제안하고 User 승인을 기다린다.
   Propose a small Agreement and wait for User approval.
3. 승인된 범위만 구현하고 필요한 검증을 수행한다.
   Implement only the approved scope and perform required verification.
4. Implementation과 분리된 QA 판정을 받는다.
   Obtain a QA verdict separated from implementation.
5. User가 결과와 다음 작업을 최종 승인한다.
   The User gives final approval to the result and next work.

## 범위와 변경 규칙 / Scope and Change Rules

- 범위 확장이 필요하면 작업을 중단하고 User 결정을 요청한다.
- Stop and request a User decision when scope expansion is required.
- 불필요한 문서, 추상화 또는 dependency를 만들지 않는다.
- Do not create unnecessary documents, abstractions, or dependencies.
- 이미 요구사항을 충족하는 산출물은 수정하지 않는다.
- Do not modify artifacts that already satisfy the requirements.

## 검증 정책 / Verification Policy

- Agreement의 Acceptance Criteria와 Verification을 변경 결과에 직접 대조한다.
- Compare changes directly with the Agreement's Acceptance Criteria and Verification.
- Implementation과 최종 QA 판정은 분리한다.
- Keep implementation separate from the final QA verdict.
- 수행하지 못한 검증과 수동 확인 항목을 명시한다.
- State any verification not performed and any manual checks required.

## Git 정책 / Git Policy

- 작업 전 실제 Git 상태를 알려진 Approved Operational Baseline Handoff와 비교한다.
- Before work, compare the actual Git state with the known Approved Operational Baseline Handoff.
- baseline과 다른 변경이 있으면 수정 전에 중단한다.
- Stop before modification when the state differs from the baseline.
- commit과 push는 User가 명시적으로 요청한 경우에만 수행한다.
- Commit and push only when explicitly requested by the User.

## 보고 요구사항 / Reporting Requirements

- 결과, 변경 파일, 검증, 미수행 작업과 남은 질문을 보고한다.
- Report the outcome, changed files, verification, unperformed work, and remaining questions.
- 승인되지 않은 상태를 Ready 또는 Approved로 표현하지 않는다.
- Do not describe an unapproved state as Ready or Approved.

## Product Context 유지 / Product Context Maintenance

- pre-flight에서 README, AGENTS, 승인된 baseline과 실제 상태 사이의 drift를 확인한다.
- During pre-flight, check for drift among README, AGENTS, the approved baseline, and actual state.
- 승인된 장기 지식은 기존 Product SSOT에 최소한으로 반영한다.
- Incorporate approved long-term knowledge minimally into existing Product SSOT.
- 일시적인 Agreement나 handoff를 자동으로 영구 문서화하지 않는다.
- Do not automatically turn temporary Agreements or handoffs into permanent documents.
''';
  }

  String _safeMarkdown(String input) {
    final normalized =
        input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    final singleLine = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' / ');
    final htmlSafe = singleLine
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final buffer = StringBuffer();
    const syntax = r'\`*_{}[]()#!|';
    for (final rune in htmlSafe.runes) {
      final character = String.fromCharCode(rune);
      if (syntax.contains(character)) {
        buffer.write(r'\');
      }
      buffer.write(character);
    }
    return buffer.toString();
  }
}
