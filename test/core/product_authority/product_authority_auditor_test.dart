import 'dart:io';

import 'package:ai_flutter_app_factory/core/product_authority/product_authority_audit_result.dart';
import 'package:ai_flutter_app_factory/core/product_authority/product_authority_auditor.dart';
import 'package:ai_flutter_app_factory/core/product_authority/product_authority_contract.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('returns a compliant report without changing Product state', () async {
    final fixture = await Directory.systemTemp.createTemp('authority_audit_');
    final factory = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
    );
    final product = await _gitRepository(
      Directory(path.join(fixture.path, 'product')),
      agents: _compliantAuthority(),
    );
    final agents = File(path.join(product.path, 'AGENTS.md'));
    final bytesBefore = await agents.readAsBytes();
    final statusBefore = await _gitStatus(product);

    try {
      final result = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(product);

      expect(result, isA<ProductAuthorityAuditReport>());
      final report = result as ProductAuthorityAuditReport;
      expect(report.isCompliant, isTrue);
      expect(
        report.detectedContractVersion,
        ProductAuthorityContract.currentVersion,
      );
      expect(report.drifts, isEmpty);
      expect(
        report.requirements.every((requirement) => requirement.satisfied),
        isTrue,
      );
      expect(await agents.readAsBytes(), bytesBefore);
      expect(await _gitStatus(product), statusBefore);
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('reports contract and required-item drift structurally', () async {
    final fixture = await Directory.systemTemp.createTemp('authority_drift_');
    final factory = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
    );
    final product = await _gitRepository(
      Directory(path.join(fixture.path, 'product')),
      agents: '''# AGENTS.md

권한 계약 버전: 0

## 저장소 정체성과 경계
''',
    );

    try {
      final result = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(product);

      expect(result, isA<ProductAuthorityAuditReport>());
      final report = result as ProductAuthorityAuditReport;
      expect(report.isCompliant, isFalse);
      expect(report.detectedContractVersion, '0');
      expect(
        report.drifts,
        contains(
          isA<ProductAuthorityDrift>().having(
            (drift) => drift.category,
            'category',
            ProductAuthorityDriftCategory.unsupportedContractVersion,
          ),
        ),
      );
      expect(
        report.drifts,
        contains(
          isA<ProductAuthorityDrift>()
              .having(
                (drift) => drift.category,
                'category',
                ProductAuthorityDriftCategory.missingRequiredSection,
              )
              .having(
                (drift) => drift.requirement,
                'requirement',
                '## 사용자 권한',
              ),
        ),
      );
      expect(
        report.drifts,
        contains(
          isA<ProductAuthorityDrift>()
              .having(
                (drift) => drift.category,
                'category',
                ProductAuthorityDriftCategory.missingRequiredMarker,
              )
              .having(
                (drift) => drift.requirement,
                'requirement',
                'Direct Executor',
              ),
        ),
      );
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('reports duplicate contract versions as ambiguous drift', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'authority_version_',
    );
    final factory = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
    );
    final product = await _gitRepository(
      Directory(path.join(fixture.path, 'product')),
      agents: '${_compliantAuthority()}권한 계약 버전: 0\n',
    );

    try {
      final result = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(product);

      expect(result, isA<ProductAuthorityAuditReport>());
      final report = result as ProductAuthorityAuditReport;
      expect(report.isCompliant, isFalse);
      expect(report.detectedContractVersion, isNull);
      expect(
        report.drifts,
        contains(
          isA<ProductAuthorityDrift>().having(
            (drift) => drift.category,
            'category',
            ProductAuthorityDriftCategory.ambiguousContractVersion,
          ),
        ),
      );
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('stops for missing, linked, or unreadable Product authority', () async {
    final fixture = await Directory.systemTemp.createTemp('authority_stop_');
    final factory = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
    );

    try {
      final missing = await _gitRepository(
        Directory(path.join(fixture.path, 'missing')),
      );
      final missingResult = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(missing);
      expect(
        missingResult,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.agentsMissing,
        ),
      );

      final linked = await _gitRepository(
        Directory(path.join(fixture.path, 'linked')),
      );
      final external = File(path.join(fixture.path, 'external.md'));
      await external.writeAsString(_compliantAuthority());
      await Link(path.join(linked.path, 'AGENTS.md')).create(external.path);
      final linkedResult = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(linked);
      expect(
        linkedResult,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.agentsNotRegularFile,
        ),
      );
      expect(await external.readAsString(), _compliantAuthority());

      final malformed = await _gitRepository(
        Directory(path.join(fixture.path, 'malformed')),
      );
      await File(path.join(malformed.path, 'AGENTS.md')).writeAsBytes(
        [0xff, 0xfe],
      );
      final malformedResult = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(malformed);
      expect(
        malformedResult,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.agentsReadFailed,
        ),
      );
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('stops for unsafe Repository boundaries and Git metadata', () async {
    final fixture = await Directory.systemTemp.createTemp('authority_git_');
    final factory = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
    );

    try {
      final nested = await _gitRepository(
        Directory(path.join(factory.path, 'nested_product')),
        agents: _compliantAuthority(),
      );
      final nestedResult = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(nested);
      expect(
        nestedResult,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.repositoryBoundaryConflict,
        ),
      );

      final linkedTarget = await _gitRepository(
        Directory(path.join(fixture.path, 'linked_target')),
        agents: _compliantAuthority(),
      );
      final linkedRoot = Link(path.join(fixture.path, 'linked_root'));
      await linkedRoot.create(linkedTarget.path);
      final linkedRootResult = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(Directory(linkedRoot.path));
      expect(
        linkedRootResult,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.productRootSymlink,
        ),
      );

      final linkedGit = await Directory(
        path.join(fixture.path, 'linked_git'),
      ).create();
      await Link(path.join(linkedGit.path, '.git')).create(
        path.join(linkedTarget.path, '.git'),
      );
      await File(path.join(linkedGit.path, 'AGENTS.md')).writeAsString(
        _compliantAuthority(),
      );
      final linkedGitResult = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(linkedGit);
      expect(
        linkedGitResult,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.gitMetadataUnsupported,
        ),
      );
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('stops when Factory root is not its Git top-level', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'authority_factory_',
    );
    final factory = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
    );
    final factoryChild = await Directory(
      path.join(factory.path, 'child'),
    ).create();
    final product = await _gitRepository(
      Directory(path.join(fixture.path, 'product')),
      agents: _compliantAuthority(),
    );

    try {
      final result = await ProductAuthorityAuditor(
        factoryRoot: factoryChild,
      ).audit(product);

      expect(
        result,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.factoryGitMetadataUnsupported,
        ),
      );
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('stops for a Product inside the verified Factory root', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'authority_nested_',
    );
    final factory = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
    );
    final product = await _gitRepository(
      Directory(path.join(factory.path, 'product')),
      agents: _compliantAuthority(),
    );

    try {
      final result = await ProductAuthorityAuditor(
        factoryRoot: factory,
      ).audit(product);

      expect(
        result,
        isA<ProductAuthorityAuditStopped>().having(
          (stopped) => stopped.category,
          'category',
          ProductAuthorityAuditStopCategory.repositoryBoundaryConflict,
        ),
      );
    } finally {
      await fixture.delete(recursive: true);
    }
  });
}

String _compliantAuthority() {
  return [
    '# AGENTS.md',
    ProductAuthorityContract.versionLine,
    ...ProductAuthorityContract.requiredSections,
    ...ProductAuthorityContract.requiredMarkers,
    '',
  ].join('\n');
}

Future<Directory> _gitRepository(
  Directory root, {
  String? agents,
}) async {
  await root.create(recursive: true);
  await File(path.join(root.path, 'README.md')).writeAsString('제품\n');
  if (agents != null) {
    await File(path.join(root.path, 'AGENTS.md')).writeAsString(agents);
  }
  for (final arguments in [
    ['init', '-b', 'main'],
    ['config', 'user.email', 'factory@example.invalid'],
    ['config', 'user.name', 'Factory Test'],
    ['add', '.'],
    ['commit', '-m', 'baseline'],
  ]) {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: root.path,
      runInShell: false,
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
  }
  return root;
}

Future<String> _gitStatus(Directory root) async {
  final result = await Process.run(
    'git',
    ['status', '--short', '--untracked-files=all'],
    workingDirectory: root.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout.toString();
}
