import '../product_authority/product_authority_contract.dart';
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

## 제품 정체성

- Product 이름: $name

## 제품 목적

> $purpose

이 문장은 Product가 해결하려는 목적의 현재 기준이다.

## 초기 범위 또는 첫 번째 의도된 결과

> $scope

## 현재 Bootstrap 상태

- Flutter 모바일 iOS 및 Android 시작 구조가 준비되었다.
- Product 기능 구현은 아직 시작되지 않았다.
- 자동 기술 검증은 통과했다.
- User의 Ready 승인은 대기 중이다.
- 첫 Agreement 승인은 대기 중이다.
- 첫 구현 전 User가 첫 Agreement를 승인해야 한다.

## 저장소 내부 시작점

작업을 시작하기 전에 이 Repository의 `AGENTS.md`를 읽고 현재 Git 상태를 승인된 baseline handoff와 비교한다.

''';
  }

  String _agents({
    required String name,
    required String purpose,
    required String scope,
  }) {
    return '''# AGENTS.md

${ProductAuthorityContract.versionLine}

> $name Product Repository의 운영 권한

## 저장소 정체성과 경계

- 이 Repository는 $name Product와 그 내부 작업만 소유한다.
- Product 목적: $purpose
- 초기 범위: $scope
- Product root 밖의 파일은 수정하지 않는다.
- Factory는 외부의 읽기 전용 참고 대상이며 Product 작업에서 수정하지 않는다.

## 사용자 권한

- User는 Product 방향, 범위, Agreement, 구현 결과, QA 판정과 Ready 상태의 최종 승인자다.
- 최종 결정을 역할 또는 실행 도구가 대신하지 않는다.

## 상시 역할과 변경 권한

- Architecture Role은 Product context와 운영 Authority를 유지하고 구현 범위를 제안한다.
- Design Role은 Agreement에 UI/UX 또는 시각적 설계 범위가 있을 때만 활성화하며, 승인에 필요한 디자인 방향과 구현 handoff를 준비한다.
- Design Role은 production code를 수정하거나 Architecture를 결정하지 않으며 User의 최종 Product 결정을 대신하지 않는다.
- Implementation Role은 승인된 Agreement 범위 안에서만 Product root를 변경한다.
- Implementation Role은 승인된 디자인 방향을 임의로 재해석하지 않는다.
- QA Role은 구현과 분리된 관점에서 검증하고 최종 품질 판정을 내리며 구현 파일을 수정하지 않는다.
- 역할은 책임을 나타내며 runtime 도구는 교체 가능하다.

## Agreement 규칙

구현 전에 User가 다음 다섯 항목을 포함한 작은 Agreement를 승인해야 한다.

- 목표
- 포함 범위
- 제외 범위
- 인수 기준
- 검증

Agreement 단계에서 Direct Approval Actions와 Direct Executor를 명시하며, 그런 작업이 없으면 `None`으로 표시한다.

Direct Approval Action은 User의 명시적 승인을 직접 확인할 수 있는 실행 주체만 수행할 수 있는 작업이다. 실기기 앱 설치, 인증서 또는 프로비저닝을 사용하는 서명, TestFlight·스토어·외부 콘솔 업로드, Release 또는 실서비스 배포, 외부 데이터의 삭제 또는 덮어쓰기가 이에 해당한다.

Direct Executor는 기본적으로 Main 또는 User 승인 메시지를 직접 볼 수 있는 다른 실행 주체다. User의 명시적 승인 없이는 Main을 포함한 어떤 실행 주체도 Direct Approval Action을 수행할 수 없다. 하위 실행 주체는 준비, 진단, 구현 또는 QA를 수행할 수 있지만 승인 메시지를 직접 확인할 수 없으면 Direct Approval Action을 수행하지 않는다.

승인 가시성이 불명확하거나 실제 Direct Executor가 승인된 실행 프로필과 다르면 해당 작업 전에 중단한다. 실행하지 않은 상태에서 Role / Instance Mapping, 차이와 이유를 포함한 Profile Delta를 User에게 제시하고 승인을 기다린다.

## 실행 프로필 고정 및 편차 중단

- Agreement 또는 Execution Profile에 수정 요청이 있으면 구현 전에 최신 통합본을 다시 제시하고 User 승인을 기다린다.
- User 승인은 마지막으로 제시된 통합 Agreement와 Execution Profile에만 적용한다.
- 통합본에는 Risk Level, Risk Reasons, Activated Roles, Agent Instances, Role / Instance Mapping, Capability Tier, Context Pack, Direct Approval Actions, Direct Executor, Verification Ladder, QA Count, Repair Limit, Environment Attempts / Retries / Time Budget와 Stop Conditions를 포함한다.
- 구현 전에 Approved Execution Profile과 Planned Actual Execution을 비교한다.
- 필수 Role, 독립 QA, Agent Instances, Context Pack, Direct Approval Actions, Direct Executor, Verification, QA·Repair 예산, 환경 예산 또는 Stop Conditions가 다르면 실행하지 않고 Profile Delta와 이유를 User에게 제시한다.
- Medium·High의 Independent QA는 Implementation과 다른 Agent Instance 또는 분리된 새 문맥에서 수행하며 Main 자기 검토로 대체하지 않는다.
- 필요한 독립 실행 주체를 만들 수 없으면 Main 단독으로 계속하지 않는다.
- 실행 중 승인되지 않은 Role, QA, 검증, Repair, 환경 복구 또는 우회를 추가·제거·대체하지 않는다.
- 환경 시도는 최초 1회와 원인이 명확한 재시도 1회, Simulator 또는 Emulator 문제 해결은 기본 10–15분으로 제한한다. 예산 소진 후에는 `Environment Blocked`와 남은 수동 확인만 보고한다.
- 예산 소진 후 서비스 재시작, Simulator 초기화, 다른 기기 또는 다른 도구 우회로 계속하지 않는다.
- Repair는 기존 Execution Profile을 초기화하지 않으며 Required Defect, Allowed Files, Focused Verification, QA Recheck Scope와 Additional Attempt Budget만 Delta로 제시한다.

## 수행 역량 등급

- 수행 역량 등급은 작업 위험도, 판단 난도, 검증 난도와 비용 효율을 기준으로 정한다.
- 낮은 위험 작업은 요구사항을 충분히 충족하는 낮은 등급에서 시작할 수 있다.
- 검증 실패, 반복되는 문맥·범위 이탈 또는 해소되지 않은 안전·권한 모호성이 증거로 확인될 때만 등급을 높인다.
- 등급을 높일 때는 실행 프로필에 근거와 줄어드는 구체적인 위험을 기록한다.
- 토큰 사용량이나 비용 자체를 성능 지표로 사용하지 않는다.
- 정책 실험이나 학습 목적의 실행은 직접 승인 작업을 수행할 수 없다.

## 표준 작업 순환

1. Product context와 실제 Git 상태를 pre-flight에서 확인한다.
2. 작은 Agreement를 제안하고 User 승인을 기다린다.
3. 승인된 범위만 구현하고 필요한 검증을 수행한다.
4. Implementation과 분리된 QA 판정을 받는다.
5. User가 결과와 다음 작업을 최종 승인한다.

## 범위와 변경 규칙

- 범위 확장이 필요하면 작업을 중단하고 User 결정을 요청한다.
- 불필요한 문서, 추상화 또는 dependency를 만들지 않는다.
- 이미 요구사항을 충족하는 산출물은 수정하지 않는다.

## 검증 정책

- Agreement의 Acceptance Criteria와 Verification을 변경 결과에 직접 대조한다.
- Implementation과 최종 QA 판정은 분리한다.
- 수행하지 못한 검증과 수동 확인 항목을 명시한다.

## Git 정책

- 작업 전 실제 Git 상태를 알려진 Approved Operational Baseline Handoff와 비교한다.
- baseline과 다른 변경이 있으면 수정 전에 중단한다.
- commit과 push는 User가 명시적으로 요청한 경우에만 수행한다.

## 보고 요구사항

- 결과, 변경 파일, 검증, 미수행 작업과 남은 질문을 보고한다.
- 최종 보고에는 Risk Level, Roles, Agent Instances, Role / Instance Mapping, Context Pack, Direct Approval Actions, Direct Executor, QA Count, Repair Count, Verification Level, Environment Attempts, Environment Retries, Environment Time와 Deviations를 포함한 `Approved vs Actual` 비교를 포함한다.
- 승인되지 않은 편차가 있으면 기술 결과가 PASS여도 Adaptive Policy Safety는 FAIL이다.
- 승인되지 않은 상태를 Ready 또는 Approved로 표현하지 않는다.

## 문서 언어

- 사람이 읽는 설명 문서와 제품 권한 문서는 한글로 작성한다.
- 같은 내용을 영어로 반복하거나 영어 전용 설명 절을 만들지 않는다.
- 코드 식별자, 공개 API 이름, 파일 경로, 명령, 구성 키와 실행 리터럴은 원문을 유지할 수 있다.
- 작업 후 모호했던 지시, 효과적이었던 검증과 다음 문맥 묶음 개선점을 기존 보고에 짧게 남긴다.
- 학습 기록만을 위한 새 영구 문서는 만들지 않는다.

## 제품 문맥 유지

- pre-flight에서 README, AGENTS, 승인된 baseline과 실제 상태 사이의 drift를 확인한다.
- 승인된 장기 지식은 기존 Product SSOT에 최소한으로 반영한다.
- 일시적인 Agreement나 handoff를 자동으로 영구 문서화하지 않는다.
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
