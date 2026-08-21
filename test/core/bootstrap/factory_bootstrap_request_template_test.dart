import 'dart:io';

import 'package:ai_flutter_app_factory/core/bootstrap/factory_bootstrap_request_template.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('renders all V1 inputs as a non-executable Korean request example', () {
    const renderer = FactoryBootstrapRequestTemplate();

    final result = renderer.render();

    for (final key in [
      'productDisplayName',
      'productPurpose',
      'initialProductScopeOrFirstIntendedOutcome',
      'exactOutputPath',
      'repositoryMode',
      'initialBranchName',
      'repositoryPolicy',
      'flutterProjectName',
      'organizationIdentifier',
      'requestedTechnology',
      'targetPlatforms',
    ]) {
      expect(result, contains('$key:'));
    }
    expect(result, contains('반드시'));
    expect(result, contains('existingEmptyRepository'));
    expect(result, isNot(contains('\t')));
    expect(
      result.split('\n').where((line) => line.endsWith(' ')),
      isEmpty,
    );
  });

  test('rendering the request example creates no file', () async {
    final root = await Directory.systemTemp.createTemp('request_template_');

    try {
      const FactoryBootstrapRequestTemplate().render();

      expect(
        await File(path.join(root.path, 'product_request.yaml')).exists(),
        isFalse,
      );
      expect(await root.list().toList(), isEmpty);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
