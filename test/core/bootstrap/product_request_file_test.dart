import 'dart:convert';
import 'dart:io';

import 'package:ai_flutter_app_factory/core/bootstrap/product_request_file.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixtureRoot;
  late Directory factoryRoot;
  late Directory intakeRoot;
  late ProductRequestFileReader reader;

  setUp(() async {
    fixtureRoot =
        await Directory.systemTemp.createTemp('product_request_file_');
    factoryRoot = await Directory(
      path.join(fixtureRoot.path, 'factory'),
    ).create();
    intakeRoot = await Directory(
      path.join(fixtureRoot.path, 'intake'),
    ).create();
    reader = ProductRequestFileReader(factoryRoot: factoryRoot);
  });

  tearDown(() async {
    if (await fixtureRoot.exists()) {
      await fixtureRoot.delete(recursive: true);
    }
  });

  test('accepts a valid New Repository request and preserves bytes', () async {
    final outputPath = path.join(fixtureRoot.path, 'new_product');
    final file = await _writeRequest(
      intakeRoot,
      _requestYaml(outputPath: outputPath),
    );
    final original = await file.readAsBytes();

    final result = await reader.read(file.path) as ProductRequestFileReady;

    expect(result.requestId, 'sample-001');
    expect(result.request.repositoryMode, 'newRepository');
    expect(result.request.initialBranchName, 'main');
    expect(result.request.repositoryPolicy, isNull);
    expect(result.request.targetPlatforms, ['ios', 'android']);
    expect(result.originalBytes, original);
    expect(result.requestSha256, hasLength(64));
  });

  test('accepts a valid Existing Empty Repository request', () async {
    final file = await _writeRequest(
      intakeRoot,
      _requestYaml(
        outputPath: path.join(fixtureRoot.path, 'existing_product'),
        repositoryMode: 'existingEmptyRepository',
        initialBranchName: 'null',
        repositoryPolicy: 'preserve existing Repository policy',
      ),
    );

    final result = await reader.read(file.path) as ProductRequestFileReady;

    expect(result.request.repositoryMode, 'existingEmptyRepository');
    expect(result.request.initialBranchName, isNull);
    expect(
      result.request.repositoryPolicy,
      'preserve existing Repository policy',
    );
  });

  test('rejects missing and unsupported schema versions', () async {
    final output = path.join(fixtureRoot.path, 'product');
    for (final caseData in <(String, ProductRequestIssueCode)>[
      (
        _requestYaml(outputPath: output).replaceFirst('schemaVersion: 1\n', ''),
        ProductRequestIssueCode.missingKey,
      ),
      (
        _requestYaml(outputPath: output)
            .replaceFirst('schemaVersion: 1', 'schemaVersion: 2'),
        ProductRequestIssueCode.unsupportedSchemaVersion,
      ),
    ]) {
      final file = await _writeRequest(intakeRoot, caseData.$1);
      await _expectStopped(reader, file.path, caseData.$2);
    }
  });

  test('rejects unknown root and bootstrap keys without echoing them',
      () async {
    final output = path.join(fixtureRoot.path, 'product');
    for (final source in [
      '${_requestYaml(outputPath: output)}credential: do-not-echo\n',
      _requestYaml(outputPath: output).replaceFirst(
        '  productDisplayName:',
        '  apiSecret: do-not-echo\n  productDisplayName:',
      ),
    ]) {
      final file = await _writeRequest(intakeRoot, source);
      final stopped = await reader.read(file.path) as ProductRequestFileStopped;
      expect(stopped.issues.single.code, ProductRequestIssueCode.unknownKey);
      expect(stopped.issues.single.message, isNot(contains('do-not-echo')));
    }
  });

  test('rejects duplicate keys and malformed YAML', () async {
    final output = path.join(fixtureRoot.path, 'product');
    final duplicate = _requestYaml(outputPath: output).replaceFirst(
      '  productPurpose:',
      '  productDisplayName: Duplicate\n  productPurpose:',
    );
    final malformed = 'schemaVersion: 1\nbootstrap: [\n';

    await _expectStopped(
      reader,
      (await _writeRequest(intakeRoot, duplicate)).path,
      ProductRequestIssueCode.malformedYaml,
    );
    await _expectStopped(
      reader,
      (await _writeRequest(intakeRoot, malformed)).path,
      ProductRequestIssueCode.prohibitedYamlFeature,
    );
  });

  test('rejects blank required text and unsupported nesting', () async {
    final output = path.join(fixtureRoot.path, 'product');
    final blank = _requestYaml(outputPath: output).replaceFirst(
      '  productPurpose: Validate a Product workflow.',
      '  productPurpose: "   "',
    );
    final nested = _requestYaml(outputPath: output).replaceFirst(
      '  productPurpose: Validate a Product workflow.',
      '  productPurpose:\n    nested: value',
    );

    await _expectStopped(
      reader,
      (await _writeRequest(intakeRoot, blank)).path,
      ProductRequestIssueCode.blankValue,
    );
    await _expectStopped(
      reader,
      (await _writeRequest(intakeRoot, nested)).path,
      ProductRequestIssueCode.invalidType,
    );
  });

  test('rejects multi-document, anchor, alias, tag, and merge-key YAML',
      () async {
    final output = path.join(fixtureRoot.path, 'product');
    final base = _requestYaml(outputPath: output);
    final cases = [
      '$base---\nschemaVersion: 1\n',
      base.replaceFirst('Example Product', '&product Example Product'),
      base.replaceFirst(
        'Validate a Product workflow.',
        '*product',
      ),
      base.replaceFirst('Example Product', '!custom Example Product'),
      base.replaceFirst(
        '  productDisplayName:',
        '  <<: {productDisplayName: Example Product}\n  productDisplayName:',
      ),
    ];

    for (final source in cases) {
      await _expectStopped(
        reader,
        (await _writeRequest(intakeRoot, source)).path,
        ProductRequestIssueCode.prohibitedYamlFeature,
      );
    }
  });

  test('rejects invalid UTF-8 and oversized input before parsing', () async {
    final invalidUtf8 =
        File(path.join(intakeRoot.path, 'product_request.yaml'));
    await invalidUtf8.writeAsBytes([0xff, 0xfe, 0xfd]);
    await _expectStopped(
      reader,
      invalidUtf8.path,
      ProductRequestIssueCode.invalidUtf8,
    );

    await invalidUtf8.writeAsBytes(
      List<int>.filled(productRequestMaximumBytes + 1, 0x61),
    );
    await _expectStopped(
      reader,
      invalidUtf8.path,
      ProductRequestIssueCode.fileTooLarge,
    );
  });

  test('rejects relative paths and request files inside Factory', () async {
    await _expectStopped(
      reader,
      'product_request.yaml',
      ProductRequestIssueCode.pathMustBeAbsolute,
    );
    final insideFactory = await _writeRequest(
      factoryRoot,
      _requestYaml(outputPath: path.join(fixtureRoot.path, 'product')),
    );
    await _expectStopped(
      reader,
      insideFactory.path,
      ProductRequestIssueCode.fileInsideFactory,
    );
  });

  test('rejects a request file inside its Product output root', () async {
    final productRoot = await Directory(
      path.join(fixtureRoot.path, 'product'),
    ).create();
    final file = await _writeRequest(
      productRoot,
      _requestYaml(outputPath: productRoot.path),
    );

    await _expectStopped(
      reader,
      file.path,
      ProductRequestIssueCode.fileInsideProductOutput,
    );
  });

  test('rejects a symbolic-link request file', () async {
    final realFile = File(path.join(intakeRoot.path, 'real_request.yaml'));
    await realFile.writeAsString(
      _requestYaml(outputPath: path.join(fixtureRoot.path, 'product')),
    );
    final linkedPath = path.join(intakeRoot.path, 'product_request.yaml');
    await Link(linkedPath).create(realFile.path);

    await _expectStopped(
      reader,
      linkedPath,
      ProductRequestIssueCode.fileMustNotBeSymlink,
    );
  });

  test('accepts only safe opaque request IDs', () async {
    final output = path.join(fixtureRoot.path, 'product');
    final valid = await _writeRequest(
      intakeRoot,
      _requestYaml(outputPath: output, requestId: 'run_01.alpha-beta'),
    );
    expect(
      (await reader.read(valid.path) as ProductRequestFileReady).requestId,
      'run_01.alpha-beta',
    );

    final invalid = await _writeRequest(
      intakeRoot,
      _requestYaml(outputPath: output, requestId: 'secret=value'),
    );
    await _expectStopped(
      reader,
      invalid.path,
      ProductRequestIssueCode.invalidRequestId,
    );

    final nullValue = await _writeRequest(
      intakeRoot,
      _requestYaml(outputPath: output, requestId: 'null'),
    );
    await _expectStopped(
      reader,
      nullValue.path,
      ProductRequestIssueCode.invalidType,
    );
  });

  test('rejects secret-like content before Runtime delegation', () async {
    final output = path.join(fixtureRoot.path, 'product');
    final source = _requestYaml(outputPath: output).replaceFirst(
      'Validate a Product workflow.',
      'apiKey=do-not-store-this-value',
    );
    final file = await _writeRequest(intakeRoot, source);

    final stopped = await reader.read(file.path) as ProductRequestFileStopped;

    expect(
      stopped.issues.single.code,
      ProductRequestIssueCode.secretLikeContent,
    );
    expect(stopped.issues.single.message, isNot(contains('do-not-store')));
  });

  test('computes standard SHA-256 request evidence', () {
    expect(
      sha256HexForRequestBytes(utf8.encode('abc')),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}

Future<File> _writeRequest(Directory directory, String source) async {
  final file = File(path.join(directory.path, 'product_request.yaml'));
  await file.writeAsString(source);
  return file;
}

Future<void> _expectStopped(
  ProductRequestFileReader reader,
  String requestPath,
  ProductRequestIssueCode code,
) async {
  final stopped = await reader.read(requestPath) as ProductRequestFileStopped;
  expect(stopped.issues, isNotEmpty);
  expect(stopped.issues.first.code, code);
}

String _requestYaml({
  required String outputPath,
  String repositoryMode = 'newRepository',
  String initialBranchName = 'main',
  String repositoryPolicy = 'null',
  String requestId = 'sample-001',
}) {
  return '''schemaVersion: 1
requestId: $requestId

bootstrap:
  productDisplayName: Example Product
  productPurpose: Validate a Product workflow.
  initialProductScopeOrFirstIntendedOutcome: Prepare the first approved workflow.
  exactOutputPath: $outputPath
  repositoryMode: $repositoryMode
  initialBranchName: $initialBranchName
  repositoryPolicy: $repositoryPolicy
  flutterProjectName: example_product
  organizationIdentifier: com.example
  requestedTechnology: flutter
  targetPlatforms:
    - ios
    - android
''';
}
