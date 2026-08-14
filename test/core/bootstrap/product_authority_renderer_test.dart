import 'package:ai_flutter_app_factory/core/bootstrap/product_authority_renderer.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/repository_mode.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/validated_bootstrap_request.dart';
import 'package:test/test.dart';

void main() {
  const renderer = ProductAuthorityRenderer();

  test('renders complete Korean-first Product-local authority', () {
    final documents = renderer.render(
      _request(
        name: 'Inventory Companion',
        purpose: 'Track household inventory.',
        scope: 'Clarify the first inventory workflow.',
      ),
    );

    expect(documents.readme, contains('Inventory Companion'));
    expect(documents.readme, contains('Track household inventory.'));
    expect(
      documents.readme,
      contains('Clarify the first inventory workflow.'),
    );
    expect(documents.readme, contains('Repository-local 시작점'));
    expect(
      documents.readme,
      contains('Automated technical validation has passed'),
    );
    expect(documents.readme, contains('User Ready approval is pending'));
    expect(documents.readme, contains('First Agreement approval is pending'));
    expect(documents.readme, contains('`AGENTS.md`'));
    expect(documents.readme, isNot(contains('/Users/')));

    const sections = [
      'Repository Identity and Boundary',
      'User Authority',
      'Permanent Roles and Change Permissions',
      'Agreement Rule',
      'Execution Profile Lock and Deviation Gate',
      'Standard Work Loop',
      'Scope and Change Rules',
      'Verification Policy',
      'Git Policy',
      'Reporting Requirements',
      'Product Context Maintenance',
    ];
    for (final section in sections) {
      expect(documents.agents, contains(section), reason: section);
    }
    for (final field in [
      'Goal',
      'Included Scope',
      'Excluded Scope',
      'Acceptance Criteria',
      'Verification',
    ]) {
      expect(documents.agents, contains(field), reason: field);
    }
    expect(documents.agents, contains('final approver'));
    expect(documents.agents, contains('outside the Product root'));
    expect(documents.agents, contains('external read-only reference'));
    expect(
      documents.agents,
      contains(
        'Design Role is activated only when an Agreement contains UI/UX or visual-design scope',
      ),
    );
    expect(
      documents.agents,
      contains('prepares the design direction and implementation handoff'),
    );
    expect(documents.agents, contains('does not modify production code'));
    expect(
        documents.agents, contains('does not reinterpret an approved design'));
    expect(documents.agents, contains('QA verdict separated'));
    expect(
      documents.agents,
      contains('User approval applies only to the last presented consolidated'),
    );
    expect(
      documents.agents,
      contains('compare the Approved Execution Profile with Planned Actual'),
    );
    expect(
      documents.agents,
      contains('different Agent Instance or separate fresh context'),
    );
    expect(
      documents.agents,
      contains('Do not continue with Main alone'),
    );
    expect(documents.agents, contains('`Environment Blocked`'));
    expect(
        documents.agents, contains('do not continue through service restart'));
    expect(documents.agents, contains('Repair does not reset'));
    expect(documents.agents, contains('`Approved vs Actual` comparison'));
    expect(documents.agents, contains('Commit and push only'));
    expect(documents.agents, contains('Approved Operational Baseline Handoff'));
    expect(documents.agents, contains('check for drift'));
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

  test('renders the bilingual Standard Work Loop as five mirrored steps', () {
    final documents = renderer.render(
      _request(
        name: 'Workflow Product',
        purpose: 'Validate the work loop.',
        scope: 'Prepare the first Agreement.',
      ),
    );
    final loop = documents.agents
        .split('## 표준 작업 순환 / Standard Work Loop')
        .last
        .split('## 범위와 변경 규칙 / Scope and Change Rules')
        .first;

    expect(
      RegExp(r'^\d+\. ', multiLine: true).allMatches(loop),
      hasLength(5),
    );
    expect(
      RegExp(
        r'^\d+\. [^\n]+\n {3}(?!\d+\. )[^\n]+$',
        multiLine: true,
      ).allMatches(loop),
      hasLength(5),
    );
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
      '## 실행 프로필 고정 및 편차 중단 / Execution Profile Lock and Deviation Gate',
    );
    final loopStart = documents.agents.indexOf(
      '## 표준 작업 순환 / Standard Work Loop',
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
    expect(documents.readme, contains('## Product 목적 / Product Purpose'));
    expect(
      documents.agents,
      contains(
        '## Repository 정체성과 경계 / Repository Identity and Boundary',
      ),
    );
    expect(documents.agents, contains('## Agreement 규칙 / Agreement Rule'));
    expect(
      documents.agents,
      contains('## Product Context 유지 / Product Context Maintenance'),
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
