import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('public runtime safely returns a structured preflight stop', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'factory_public_api_',
    );
    final factoryRoot = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
      {'README.md': 'Factory\n'},
    );
    final targetPath = path.join(fixture.path, 'product');

    try {
      final runtime = FlutterAppFactoryRuntime(factoryRoot: factoryRoot);
      final request = BootstrapRequest(
        productDisplayName: 'Public API Validation',
        productPurpose: null,
        initialProductScopeOrFirstIntendedOutcome:
            'Validate the public preflight boundary.',
        exactOutputPath: targetPath,
        repositoryMode: RepositoryMode.newRepository.name,
        initialBranchName: 'main',
        repositoryPolicy: null,
        flutterProjectName: 'public_api_validation',
        organizationIdentifier: 'com.example',
        requestedTechnology: 'flutter',
        targetPlatforms: const ['ios', 'android'],
      );

      final result = await runtime.inspect(request);

      expect(result, isA<BootstrapPreflightStopped>());
      final stopped = result as BootstrapPreflightStopped;
      expect(
        stopped.reasons,
        contains(
          isA<BootstrapStopReason>()
              .having(
                (reason) => reason.category,
                'category',
                BootstrapStopCategory.missingInput,
              )
              .having(
                (reason) => reason.fieldOrFact,
                'field',
                'productPurpose',
              ),
        ),
      );
      expect(await Directory(targetPath).exists(), isFalse);
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('public Product Loop runtime captures a baseline proposal', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'factory_product_loop_public_api_',
    );
    final factoryRoot = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
      {'README.md': 'factory\n'},
    );
    final productRoot = await _gitRepository(
      Directory(path.join(fixture.path, 'product')),
      {
        'README.md': 'product\n',
        'AGENTS.md': 'authority\n',
        'lib/main.dart': 'void main() {}\n',
        'test/app_test.dart': 'void main() {}\n',
      },
    );

    try {
      final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);

      final result = await runtime.captureBaseline(productRoot);

      expect(result, isA<ProductLoopBaselineProposal>());
      final proposal = result as ProductLoopBaselineProposal;
      expect(
        proposal.snapshot.productRoot,
        path.normalize(await productRoot.resolveSymbolicLinks()),
      );
      expect(proposal.snapshot.isClean, isTrue);
      expect(proposal.proposalStatus, 'Proposed');
      expect(proposal.userApprovalStatus, 'Pending');
    } finally {
      await fixture.delete(recursive: true);
    }
  });

  test('public Product Authority auditor returns structured drift', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'factory_product_authority_public_api_',
    );
    final factoryRoot = await _gitRepository(
      Directory(path.join(fixture.path, 'factory')),
      {'README.md': 'Factory\n'},
    );
    final productRoot = await _gitRepository(
      Directory(path.join(fixture.path, 'product')),
      {
        'README.md': '제품\n',
        'AGENTS.md': '# AGENTS.md\n',
      },
    );

    try {
      final result = await ProductAuthorityAuditor(
        factoryRoot: factoryRoot,
      ).audit(productRoot);

      expect(result, isA<ProductAuthorityAuditReport>());
      final report = result as ProductAuthorityAuditReport;
      expect(report.isCompliant, isFalse);
      expect(
        report.expectedContractVersion,
        ProductAuthorityContract.currentVersion,
      );
      expect(
        report.drifts,
        contains(
          isA<ProductAuthorityDrift>().having(
            (drift) => drift.category,
            'category',
            ProductAuthorityDriftCategory.missingContractVersion,
          ),
        ),
      );
    } finally {
      await fixture.delete(recursive: true);
    }
  });
}

Future<Directory> _gitRepository(
  Directory root,
  Map<String, String> files,
) async {
  await root.create(recursive: true);
  for (final entry in files.entries) {
    final file = File(path.join(root.path, entry.key));
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
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
  return Directory(path.normalize(root.path));
}
