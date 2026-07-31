import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('public runtime safely returns a structured preflight stop', () async {
    final fixture = await Directory.systemTemp.createTemp(
      'factory_public_api_',
    );
    final factoryRoot = await Directory(
      path.join(fixture.path, 'factory'),
    ).create();
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
}
