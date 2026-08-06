import 'dart:io';

import 'package:ai_flutter_app_factory/core/product_loop/product_loop_request_file.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixture;
  late Directory factoryRoot;
  late Directory productRoot;
  late Directory intakeRoot;
  late Directory evidenceRoot;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('product_loop_request_');
    factoryRoot = await Directory(path.join(fixture.path, 'factory')).create();
    productRoot = await Directory(path.join(fixture.path, 'product')).create();
    intakeRoot = await Directory(path.join(fixture.path, 'intake')).create();
    evidenceRoot =
        await Directory(path.join(fixture.path, 'evidence')).create();
  });

  tearDown(() async {
    await fixture.delete(recursive: true);
  });

  test('reads the strict Product Loop request schema', () async {
    final file = await _writeRequest(
      intakeRoot,
      productRoot: productRoot.path,
      evidenceRoot: evidenceRoot.path,
    );

    final result = await ProductLoopRequestFileReader(
      factoryRoot: factoryRoot,
    ).read(file.path);

    expect(result, isA<ProductLoopRequestFileReady>());
    final ready = result as ProductLoopRequestFileReady;
    expect(ready.request.productRoot, productRoot.path);
    expect(ready.request.buildPolicy.name, 'both');
    expect(ready.request.evidenceDirectory, evidenceRoot.path);
    expect(ready.requestSha256, hasLength(64));
  });

  test('rejects missing unknown and invalid values', () async {
    for (final source in [
      'schemaVersion: 1\nproductRoot: ${productRoot.path}\n',
      '''schemaVersion: 1
productRoot: ${productRoot.path}
buildPolicy: both
evidenceDirectory: ${evidenceRoot.path}
extra: false
''',
      '''schemaVersion: 1
productRoot: ${productRoot.path}
buildPolicy: web
evidenceDirectory: ${evidenceRoot.path}
''',
    ]) {
      final file = File(
        path.join(intakeRoot.path, 'product_loop_request.yaml'),
      );
      await file.writeAsString(source);
      final result = await ProductLoopRequestFileReader(
        factoryRoot: factoryRoot,
      ).read(file.path);
      expect(result, isA<ProductLoopRequestFileStopped>());
    }
  });

  test('requires request and evidence paths outside both Repositories',
      () async {
    final unsafeEvidence = await Directory(
      path.join(productRoot.path, 'evidence'),
    ).create();
    final file = await _writeRequest(
      intakeRoot,
      productRoot: productRoot.path,
      evidenceRoot: unsafeEvidence.path,
    );

    final result = await ProductLoopRequestFileReader(
      factoryRoot: factoryRoot,
    ).read(file.path);

    expect(result, isA<ProductLoopRequestFileStopped>());
    expect(
      (result as ProductLoopRequestFileStopped).issues.single.code,
      ProductLoopRequestIssueCode.repositoryBoundaryConflict,
    );
  });

  test('rejects a symlink evidence directory', () async {
    final link = Link(path.join(fixture.path, 'evidence_link'));
    await link.create(evidenceRoot.path);
    final file = await _writeRequest(
      intakeRoot,
      productRoot: productRoot.path,
      evidenceRoot: link.path,
    );

    final result = await ProductLoopRequestFileReader(
      factoryRoot: factoryRoot,
    ).read(file.path);

    expect(result, isA<ProductLoopRequestFileStopped>());
    expect(
      (result as ProductLoopRequestFileStopped).issues.single.code,
      ProductLoopRequestIssueCode.evidenceDirectoryMustNotBeSymlink,
    );
  });

  test('rejects secret-like request content', () async {
    final file = File(
      path.join(intakeRoot.path, 'product_loop_request.yaml'),
    );
    await file.writeAsString('''schemaVersion: 1
productRoot: ${productRoot.path}
buildPolicy: both
evidenceDirectory: ${evidenceRoot.path}
# ${'ghp_'}abcdefghijklmnopqrstuvwxyz1234567890
''');

    final result = await ProductLoopRequestFileReader(
      factoryRoot: factoryRoot,
    ).read(file.path);

    expect(result, isA<ProductLoopRequestFileStopped>());
    expect(
      (result as ProductLoopRequestFileStopped).issues.single.code,
      ProductLoopRequestIssueCode.secretLikeContent,
    );
  });
}

Future<File> _writeRequest(
  Directory intakeRoot, {
  required String productRoot,
  required String evidenceRoot,
}) async {
  final file = File(
    path.join(intakeRoot.path, 'product_loop_request.yaml'),
  );
  await file.writeAsString('''schemaVersion: 1
productRoot: $productRoot
buildPolicy: both
evidenceDirectory: $evidenceRoot
''');
  return file;
}
