import 'dart:convert';
import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';
import 'package:ai_flutter_app_factory/core/product_loop/factory_product_loop_command.dart';
import 'package:ai_flutter_app_factory/core/product_loop/product_loop_snapshot_codec.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixture;
  late Directory factoryRoot;
  late Directory productRoot;
  late Directory intakeRoot;
  late Directory evidenceRoot;
  late File requestFile;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('product_loop_command_');
    factoryRoot = await Directory(path.join(fixture.path, 'factory')).create();
    productRoot = await Directory(path.join(fixture.path, 'product')).create();
    productRoot = Directory(
      path.normalize(await productRoot.resolveSymbolicLinks()),
    );
    intakeRoot = await Directory(path.join(fixture.path, 'intake')).create();
    evidenceRoot =
        await Directory(path.join(fixture.path, 'evidence')).create();
    requestFile = await _writeRequest(
      intakeRoot,
      productRoot,
      evidenceRoot,
    );
  });

  tearDown(() async {
    await fixture.delete(recursive: true);
  });

  test('help and malformed arguments preserve Pending approvals', () async {
    for (final arguments in <List<String>>[
      const ['--help'],
      const [],
      const ['--request', '/tmp/request', '--phase', 'validate'],
    ]) {
      final result = await FactoryProductLoopCommand(
        factoryRoot: factoryRoot,
      ).run(arguments);
      expect(result.exitCode, 64);
      final report = jsonDecode(result.stdoutJson) as Map<String, dynamic>;
      expect(report['approvalStatuses']['qaStatus'], 'NotProposed');
      expect(report['approvalStatuses']['userApprovalStatus'], 'Pending');
      expect(report['approvalStatuses']['commitStatus'], 'NotPerformed');
    }
  });

  test('capture writes immutable baseline and proposal report', () async {
    var captureCalls = 0;
    final result = await FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async {
        captureCalls++;
        return ProductLoopBaselineProposal(snapshot: _snapshot(productRoot));
      },
      validate: (ready) async => throw StateError('not called'),
    ).run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);

    expect(result.exitCode, 0);
    expect(captureCalls, 1);
    final report = jsonDecode(result.stdoutJson) as Map<String, dynamic>;
    expect(report['outcomeState'], 'baselineProposed');
    expect(report['baseline']['status'], 'Proposed');
    expect(report['baseline']['userApprovalStatus'], 'Pending');
    expect(report['baseline']['sha256'], hasLength(64));
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopBaselineFilename),
      ).exists(),
      isTrue,
    );
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopCaptureReportFilename),
      ).exists(),
      isTrue,
    );
    expect(result.stderrText, contains('User 승인 또는 Product 구현 완료'));
  });

  test('capture refuses to overwrite an existing artifact', () async {
    final baseline = File(
      path.join(evidenceRoot.path, productLoopBaselineFilename),
    );
    await baseline.writeAsString('existing');
    var captureCalled = false;

    final result = await FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async {
        captureCalled = true;
        return ProductLoopBaselineProposal(snapshot: _snapshot(productRoot));
      },
      validate: (ready) async => throw StateError('not called'),
    ).run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);

    expect(result.exitCode, 2);
    expect(captureCalled, isFalse);
    expect(await baseline.readAsString(), 'existing');
    expect(
        jsonDecode(result.stdoutJson)['outcomeState'], 'artifactPathStopped');
  });

  test('capture rechecks request and Evidence ownership before writing',
      () async {
    final external = File(path.join(evidenceRoot.path, 'external.txt'));
    final result = await FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async {
        await external.writeAsString('external');
        return ProductLoopBaselineProposal(snapshot: _snapshot(productRoot));
      },
      validate: (ready) async => throw StateError('not called'),
    ).run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);

    expect(result.exitCode, 2);
    expect(await external.readAsString(), 'external');
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopBaselineFilename),
      ).exists(),
      isFalse,
    );
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopCaptureReportFilename),
      ).exists(),
      isFalse,
    );
    expect(
      jsonDecode(result.stdoutJson)['failure']['code'],
      'evidenceDirectoryOwnershipMismatch',
    );
  });

  test('capture stops when the request changes during inspection', () async {
    final result = await FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async {
        await requestFile
            .writeAsString('${await requestFile.readAsString()}# changed\n');
        return ProductLoopBaselineProposal(snapshot: _snapshot(productRoot));
      },
      validate: (ready) async => throw StateError('not called'),
    ).run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);

    expect(result.exitCode, 2);
    expect(
      jsonDecode(result.stdoutJson)['failure']['code'],
      'requestChangedDuringOperation',
    );
    expect(evidenceRoot.listSync(), isEmpty);
  });

  test('validate requires the exact approved hash and never auto-approves',
      () async {
    ProductLoopGuardReady? received;
    final command = FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async =>
          ProductLoopBaselineProposal(snapshot: _snapshot(productRoot)),
      validate: (ready) async {
        received = ready;
        return ProductLoopCandidateValidated(
          candidate: _snapshot(productRoot),
          commandsCompleted: const [],
          buildPolicy: ready.buildPolicy,
        );
      },
    );
    final captured = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);
    final approvedHash =
        jsonDecode(captured.stdoutJson)['baseline']['sha256'] as String;

    final wrongHash = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      List.filled(64, 'f').join(),
    ]);
    expect(wrongHash.exitCode, 2);
    expect(received, isNull);

    final validated = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      approvedHash,
    ]);

    expect(validated.exitCode, 0);
    expect(received?.buildPolicy, ProductLoopBuildPolicy.both);
    final report = jsonDecode(validated.stdoutJson) as Map<String, dynamic>;
    expect(report['outcomeState'], 'candidateValidated');
    expect(report['validation']['technicalValidationStatus'], 'Passed');
    expect(report['validation']['qaStatus'], 'Pending');
    expect(report['approvalStatuses']['qaStatus'], 'Pending');
    expect(report['validation']['userApprovalStatus'], 'Pending');
    expect(report['validation']['commitStatus'], 'NotPerformed');
    expect(
      report['approvedBaselineEvidence']['callerDeclaredUserApproval'],
      isTrue,
    );
  });

  test('validate rejects a request changed after baseline capture', () async {
    var validateCalled = false;
    final command = FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async =>
          ProductLoopBaselineProposal(snapshot: _snapshot(productRoot)),
      validate: (ready) async {
        validateCalled = true;
        return ProductLoopCandidateValidated(
          candidate: _snapshot(productRoot),
          commandsCompleted: const [],
          buildPolicy: ready.buildPolicy,
        );
      },
    );
    final captured = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);
    final approvedHash =
        jsonDecode(captured.stdoutJson)['baseline']['sha256'] as String;
    await requestFile.writeAsString('''schemaVersion: 1
productRoot: ${productRoot.path}
buildPolicy: ios
evidenceDirectory: ${evidenceRoot.path}
''');

    final result = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      approvedHash,
    ]);

    expect(result.exitCode, 2);
    expect(validateCalled, isFalse);
    expect(
      jsonDecode(result.stdoutJson)['failure']['code'],
      'baselineRequestMismatch',
    );
  });

  test('validate stops for an unexpected Evidence directory entry', () async {
    var validateCalled = false;
    final command = FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async =>
          ProductLoopBaselineProposal(snapshot: _snapshot(productRoot)),
      validate: (ready) async {
        validateCalled = true;
        return ProductLoopCandidateValidated(
          candidate: _snapshot(productRoot),
          commandsCompleted: const [],
          buildPolicy: ready.buildPolicy,
        );
      },
    );
    final captured = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);
    final approvedHash =
        jsonDecode(captured.stdoutJson)['baseline']['sha256'] as String;
    final external = File(path.join(evidenceRoot.path, 'external.txt'));
    await external.writeAsString('external');

    final result = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      approvedHash,
    ]);

    expect(result.exitCode, 2);
    expect(validateCalled, isFalse);
    expect(await external.readAsString(), 'external');
    expect(
      jsonDecode(result.stdoutJson)['failure']['code'],
      'evidenceDirectoryOwnershipMismatch',
    );
  });

  test('validate rechecks Evidence ownership after Health Gate execution',
      () async {
    final external = File(path.join(evidenceRoot.path, 'external.txt'));
    final command = FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async =>
          ProductLoopBaselineProposal(snapshot: _snapshot(productRoot)),
      validate: (ready) async {
        await external.writeAsString('external');
        return ProductLoopCandidateValidated(
          candidate: _snapshot(productRoot),
          commandsCompleted: const [],
          buildPolicy: ready.buildPolicy,
        );
      },
    );
    final captured = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);
    final approvedHash =
        jsonDecode(captured.stdoutJson)['baseline']['sha256'] as String;

    final result = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      approvedHash,
    ]);

    expect(result.exitCode, 2);
    expect(await external.readAsString(), 'external');
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopValidationReportFilename),
      ).exists(),
      isFalse,
    );
    expect(
      jsonDecode(result.stdoutJson)['failure']['code'],
      'evidenceDirectoryOwnershipMismatch',
    );
  });

  test('validate stops when the approved baseline changes during execution',
      () async {
    late File baselineFile;
    final command = FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async =>
          ProductLoopBaselineProposal(snapshot: _snapshot(productRoot)),
      validate: (ready) async {
        await baselineFile.writeAsString(
          '${await baselineFile.readAsString()} ',
        );
        return ProductLoopCandidateValidated(
          candidate: _snapshot(productRoot),
          commandsCompleted: const [],
          buildPolicy: ready.buildPolicy,
        );
      },
    );
    final captured = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);
    final approvedHash =
        jsonDecode(captured.stdoutJson)['baseline']['sha256'] as String;
    baselineFile = File(
      path.join(evidenceRoot.path, productLoopBaselineFilename),
    );

    final result = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      approvedHash,
    ]);

    expect(result.exitCode, 2);
    expect(
      jsonDecode(result.stdoutJson)['failure']['code'],
      'baselineChangedDuringValidation',
    );
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopValidationReportFilename),
      ).exists(),
      isFalse,
    );
  });

  test('validate stops when the request changes during Health Gate execution',
      () async {
    final command = FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async =>
          ProductLoopBaselineProposal(snapshot: _snapshot(productRoot)),
      validate: (ready) async {
        await requestFile.writeAsString(
          '${await requestFile.readAsString()}# changed\n',
        );
        return ProductLoopCandidateValidated(
          candidate: _snapshot(productRoot),
          commandsCompleted: const [],
          buildPolicy: ready.buildPolicy,
        );
      },
    );
    final captured = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);
    final approvedHash =
        jsonDecode(captured.stdoutJson)['baseline']['sha256'] as String;

    final result = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      approvedHash,
    ]);

    expect(result.exitCode, 2);
    expect(
      jsonDecode(result.stdoutJson)['failure']['code'],
      'requestChangedDuringOperation',
    );
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopValidationReportFilename),
      ).exists(),
      isFalse,
    );
  });

  test('validation stop is persisted without proposing QA PASS', () async {
    final command = FactoryProductLoopCommand(
      factoryRoot: factoryRoot,
      capture: (root) async =>
          ProductLoopBaselineProposal(snapshot: _snapshot(productRoot)),
      validate: (ready) async => ProductLoopValidationStopped(
        category: ProductLoopStopCategory.healthGateFailed,
        stage: ProductLoopStage.healthGate,
        evidence: const ['flutter analyze failed'],
        notPerformed: const ['flutter test'],
        commandsCompleted: const [],
      ),
    );
    final captured = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'capture',
    ]);
    final approvedHash =
        jsonDecode(captured.stdoutJson)['baseline']['sha256'] as String;

    final result = await command.run([
      '--request',
      requestFile.path,
      '--phase',
      'validate',
      '--approved-baseline-sha256',
      approvedHash,
    ]);

    expect(result.exitCode, 3);
    final report = jsonDecode(result.stdoutJson) as Map<String, dynamic>;
    expect(report['outcomeState'], 'validationStopped');
    expect(report['validation']['qaStatus'], 'NotProposed');
    expect(report['approvalStatuses']['qaStatus'], 'NotProposed');
    expect(report['validation']['commitStatus'], 'NotPerformed');
    expect(
      await File(
        path.join(evidenceRoot.path, productLoopValidationReportFilename),
      ).exists(),
      isTrue,
    );
  });
}

Future<File> _writeRequest(
  Directory intakeRoot,
  Directory productRoot,
  Directory evidenceRoot,
) async {
  final file = File(
    path.join(intakeRoot.path, 'product_loop_request.yaml'),
  );
  await file.writeAsString('''schemaVersion: 1
productRoot: ${productRoot.path}
buildPolicy: both
evidenceDirectory: ${evidenceRoot.path}
''');
  return file;
}

ProductLoopRepositorySnapshot _snapshot(Directory productRoot) {
  return ProductLoopRepositorySnapshot(
    productRoot: productRoot.path,
    gitTopLevel: productRoot.path,
    branch: 'main',
    headIdentity: 'abc123',
    gitStatusEntries: const [],
    contentManifest: const {
      'worktree:README.md': 'readme',
      'worktree:AGENTS.md': 'agents',
    },
  );
}
