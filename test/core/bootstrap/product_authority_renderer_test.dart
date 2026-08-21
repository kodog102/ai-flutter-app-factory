import 'package:ai_flutter_app_factory/core/bootstrap/product_authority_renderer.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/repository_mode.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/validated_bootstrap_request.dart';
import 'package:ai_flutter_app_factory/core/product_authority/product_authority_contract.dart';
import 'package:test/test.dart';

void main() {
  const renderer = ProductAuthorityRenderer();

  test('renders complete Korean-only Product-local authority', () {
    final documents = renderer.render(
      _request(
        name: '재고 도우미',
        purpose: '가정용 재고를 추적한다.',
        scope: '첫 재고 작업 흐름을 명확히 한다.',
      ),
    );

    expect(documents.readme, contains('재고 도우미'));
    expect(documents.readme, contains('가정용 재고를 추적한다.'));
    expect(
      documents.readme,
      contains('첫 재고 작업 흐름을 명확히 한다.'),
    );
    expect(documents.readme, contains('저장소 내부 시작점'));
    expect(
      documents.readme,
      contains('자동 기술 검증은 통과했다'),
    );
    expect(documents.readme, contains('User의 Ready 승인은 대기 중이다'));
    expect(documents.readme, contains('첫 Agreement 승인은 대기 중이다'));
    expect(documents.readme, contains('`AGENTS.md`'));
    expect(documents.readme, isNot(contains('/Users/')));

    const sections = [
      '저장소 정체성과 경계',
      '사용자 권한',
      '상시 역할과 변경 권한',
      'Agreement 규칙',
      '실행 프로필 고정 및 편차 중단',
      '수행 역량 등급',
      '표준 작업 순환',
      '범위와 변경 규칙',
      '검증 정책',
      'Git 정책',
      '보고 요구사항',
      '문서 언어',
      '제품 문맥 유지',
    ];
    for (final section in sections) {
      expect(documents.agents, contains(section), reason: section);
    }
    for (final field in [
      '목표',
      '포함 범위',
      '제외 범위',
      '인수 기준',
      '검증',
    ]) {
      expect(documents.agents, contains(field), reason: field);
    }
    expect(documents.agents, contains('최종 승인자'));
    expect(documents.agents, contains('Product root 밖의 파일'));
    expect(documents.agents, contains('외부의 읽기 전용 참고 대상'));
    expect(
      documents.agents,
      contains(
        'Design Role은 Agreement에 UI/UX 또는 시각적 설계 범위가 있을 때만 활성화',
      ),
    );
    expect(
      documents.agents,
      contains('디자인 방향과 구현 handoff를 준비'),
    );
    expect(documents.agents, contains('production code를 수정하거나'));
    expect(documents.agents, contains('승인된 디자인 방향을 임의로 재해석하지'));
    expect(documents.agents, contains('구현과 분리된 관점에서 검증'));
    expect(
      documents.agents,
      contains('마지막으로 제시된 통합 Agreement와 Execution Profile에만 적용'),
    );
    expect(
      documents.agents,
      contains('Approved Execution Profile과 Planned Actual Execution을 비교'),
    );
    expect(documents.agents, contains('Direct Approval Actions'));
    expect(documents.agents, contains('Direct Executor'));
    expect(
      documents.agents,
      contains('실기기 앱 설치'),
    );
    expect(
      documents.agents,
      contains('User의 명시적 승인을 직접 확인할 수 있는'),
    );
    expect(
      documents.agents,
      contains('Main을 포함한 어떤 실행 주체도 Direct Approval Action을 수행할 수 없다'),
    );
    expect(
      documents.agents,
      contains('승인 가시성이 불명확하거나'),
    );
    expect(
      documents.agents,
      contains('다른 Agent Instance 또는 분리된 새 문맥'),
    );
    expect(
      documents.agents,
      contains('Main 단독으로 계속하지 않는다'),
    );
    expect(documents.agents, contains('`Environment Blocked`'));
    expect(documents.agents, contains('서비스 재시작, Simulator 초기화'));
    expect(documents.agents, contains('Repair는 기존 Execution Profile을 초기화하지'));
    expect(documents.agents, contains('`Approved vs Actual` 비교'));
    expect(documents.agents, contains('commit과 push는 User가 명시적으로 요청'));
    expect(documents.agents, contains('Approved Operational Baseline Handoff'));
    expect(documents.agents, contains('실제 상태 사이의 drift를 확인'));
    expect(documents.agents, contains('토큰 사용량이나 비용 자체를 성능 지표로 사용하지 않는다'));
    expect(
      documents.agents,
      contains(ProductAuthorityContract.versionLine),
    );
    expect(documents.agents, isNot(contains('Operating authority for')));
    expect(documents.agents, isNot(contains('Standard Work Loop')));
    for (final runtimeName in [
      'OpenAI',
      'Codex',
      'Claude',
      'VS Code',
      'Android Studio',
      'Figma',
      'Sketch',
    ]) {
      expect(
        '${documents.readme}${documents.agents}',
        isNot(contains(runtimeName)),
        reason: runtimeName,
      );
    }
  });

  test('neutralizes Markdown, code-fence, and raw HTML injection', () {
    final documents = renderer.render(
      _request(
        name: 'Name\n# Inject ``` <script>',
        purpose: 'Purpose\r\n## Escape\n```dart\n<div>unsafe</div>',
        scope: 'Scope\n# Hidden\n</blockquote>',
      ),
    );
    final combined = '${documents.readme}\n${documents.agents}';

    expect(combined, contains('Inject'));
    expect(combined, contains('Escape'));
    expect(combined, contains('Hidden'));
    expect(combined, isNot(contains('\n# Inject')));
    expect(combined, isNot(contains('\n## Escape')));
    expect(combined, isNot(contains('```')));
    expect(combined, isNot(contains('<script>')));
    expect(combined, isNot(contains('<div>')));
    expect(combined, isNot(contains('</blockquote>')));
    expect(combined, contains('&lt;script&gt;'));
  });

  test('renders the Korean-only Standard Work Loop as five steps', () {
    final documents = renderer.render(
      _request(
        name: '작업 흐름 제품',
        purpose: '작업 순환을 검증한다.',
        scope: '첫 Agreement를 준비한다.',
      ),
    );
    final loop =
        documents.agents.split('## 표준 작업 순환').last.split('## 범위와 변경 규칙').first;

    expect(
      RegExp(r'^\d+\. ', multiLine: true).allMatches(loop),
      hasLength(5),
    );
    expect(RegExp(r'^ {3}[A-Za-z]', multiLine: true).hasMatch(loop), isFalse);
  });

  test('renders execution profile lock before the unchanged five-step loop',
      () {
    final documents = renderer.render(
      _request(
        name: 'Profile Product',
        purpose: 'Validate execution-profile authority.',
        scope: 'Preserve the approved operating contract.',
      ),
    );

    final profileStart = documents.agents.indexOf(
      '## 실행 프로필 고정 및 편차 중단',
    );
    final loopStart = documents.agents.indexOf(
      '## 표준 작업 순환',
    );
    expect(profileStart, greaterThanOrEqualTo(0));
    expect(loopStart, greaterThan(profileStart));

    for (final requiredField in [
      'Risk Reasons',
      'Role / Instance Mapping',
      'Capability Tier',
      'QA Count',
      'Repair Limit',
      'Stop Conditions',
      'Profile Delta',
      'Direct Approval Actions',
      'Direct Executor',
      'Environment Attempts / Retries / Time Budget',
    ]) {
      expect(documents.agents, contains(requiredField), reason: requiredField);
    }
  });

  test('renders README and AGENTS without trailing whitespace or tabs', () {
    final documents = renderer.render(
      _request(
        name: 'Whitespace Product',
        purpose: 'Verify rendered document whitespace.',
        scope: 'Preserve the five-step work loop structure.',
      ),
    );

    for (final document in [documents.readme, documents.agents]) {
      for (final line in document.split('\n')) {
        expect(line, isNot(matches(RegExp(r'[ \t]+$'))));
      }
    }
  });

  test('does not render English-only explanatory lines', () {
    final documents = renderer.render(
      _request(
        name: '한글 제품',
        purpose: '한글 목적을 설명한다.',
        scope: '한글 범위를 설명한다.',
      ),
    );

    for (final document in [documents.readme, documents.agents]) {
      for (final line in document.split('\n')) {
        final hasEnglishWord = RegExp(r'[A-Za-z]{3}').hasMatch(line);
        final hasKorean = RegExp(r'[가-힣]').hasMatch(line);
        if (hasEnglishWord && !hasKorean) {
          expect(line, equals('# AGENTS.md'));
        }
      }
    }
  });

  test('renders a Markdown-sensitive Product name as safe plain text', () {
    final documents = renderer.render(
      _request(
        name: 'Tick`Slash\\ [Box] <script>alert</script>\n# Inject',
        purpose: 'Preserve the required README structure.',
        scope: 'Preserve the required AGENTS structure.',
      ),
    );
    final combined = '${documents.readme}\n${documents.agents}';
    const escapedName =
        r'Tick\`Slash\\ \[Box\] &lt;script&gt;alert&lt;/script&gt; / \# Inject';

    expect(combined, contains(escapedName));
    expect(combined, isNot(contains('`Tick')));
    expect(combined, isNot(contains('<script>')));
    expect(combined, isNot(contains('\n# Inject')));
    expect(combined, isNot(contains('```')));
    expect(documents.readme, contains('## 제품 목적'));
    expect(
      documents.agents,
      contains(
        '## 저장소 정체성과 경계',
      ),
    );
    expect(documents.agents, contains('## Agreement 규칙'));
    expect(
      documents.agents,
      contains('## 제품 문맥 유지'),
    );
  });

  test('renders different Product inputs without cross-Product leakage', () {
    final alpha = renderer.render(
      _request(
        name: 'Alpha Product',
        purpose: 'Alpha purpose.',
        scope: 'Alpha scope.',
      ),
    );
    final beta = renderer.render(
      _request(
        name: 'Beta Product',
        purpose: 'Beta purpose.',
        scope: 'Beta scope.',
      ),
    );

    expect('${alpha.readme}${alpha.agents}', isNot(contains('Beta')));
    expect('${beta.readme}${beta.agents}', isNot(contains('Alpha')));
    expect(alpha.agents.replaceAll('Alpha', 'Product'),
        beta.agents.replaceAll('Beta', 'Product'));
  });
}

ValidatedBootstrapRequest _request({
  required String name,
  required String purpose,
  required String scope,
}) {
  return ValidatedBootstrapRequest(
    productDisplayName: name,
    productPurpose: purpose,
    initialProductScopeOrFirstIntendedOutcome: scope,
    exactOutputPath: '/portable/product',
    repositoryMode: RepositoryMode.newRepository,
    initialBranchName: 'main',
    repositoryPolicy: null,
    flutterProjectName: 'product',
    organizationIdentifier: 'com.example',
    requestedTechnology: 'flutter',
    targetPlatforms: const ['ios', 'android'],
  );
}
