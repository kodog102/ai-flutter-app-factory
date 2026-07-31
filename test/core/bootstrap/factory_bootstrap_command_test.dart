import 'dart:convert';
import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/factory_bootstrap_command.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixtureRoot;
  late Directory factoryRoot;
  late Directory intakeRoot;
  late String outputPath;

  setUp(() async {
    fixtureRoot = await Directory.systemTemp.createTemp(
      'factory_bootstrap_command_',
    );
    factoryRoot = await Directory(
      path.join(fixtureRoot.path, 'factory'),
    ).create();
    intakeRoot = await Directory(
      path.join(fixtureRoot.path, 'intake'),
    ).create();
    outputPath = path.join(fixtureRoot.path, 'product');
  });

  tearDown(() async {
    if (await fixtureRoot.exists()) {
      await fixtureRoot.delete(recursive: true);
    }
  });

  test('--help is supported without using Prepared exit code zero', () async {
    final result = await FactoryBootstrapCommand(
      factoryRoot: factoryRoot,
    ).run(['--help']);

    expect(result.exitCode, 64);
    final report = jsonDecode(result.stdoutJson) as Map<String, dynamic>;
    expect(report['outcomeState'], 'help');
    expect(report['approvalStatuses']['readyApprovalStatus'], 'Pending');
    expect(report['approvalStatuses']['agreementApprovalStatus'], 'Pending');
    _expectHumanSummary(result.stderrText);
  });

  test('missing request and unknown arguments return usage exit 64', () async {
    for (final arguments in <List<String>>[
      const [],
      const ['--request'],
      const ['--unknown', '/tmp/value'],
      const ['--request', '/tmp/value', '--extra'],
    ]) {
      final result = await FactoryBootstrapCommand(
        factoryRoot: factoryRoot,
      ).run(arguments);
      expect(result.exitCode, 64, reason: arguments.toString());
      final report = jsonDecode(result.stdoutJson) as Map<String, dynamic>;
      expect(report['outcomeState'], 'usageError');
      expect(report['approvalStatuses']['readyApprovalStatus'], 'Pending');
      expect(report['approvalStatuses']['agreementApprovalStatus'], 'Pending');
      _expectHumanSummary(result.stderrText);
    }
  });

  test('parse failure exits 2 and never calls Runtime', () async {
    final file = File(path.join(intakeRoot.path, 'product_request.yaml'));
    await file.writeAsString('schemaVersion: 1\nbootstrap: [\n');
    var inspectCalled = false;

    final result = await FactoryBootstrapCommand(
      factoryRoot: factoryRoot,
      inspect: (request) async {
        inspectCalled = true;
        return _ready(request, outputPath);
      },
      execute: (ready) async => _prepared(ready.validatedRequest),
    ).run(['--request', file.path]);

    expect(result.exitCode, 2);
    expect(inspectCalled, isFalse);
    expect(await Directory(outputPath).exists(), isFalse);
    expect(jsonDecode(result.stdoutJson)['outcomeState'], 'requestStopped');
    _expectHumanSummary(result.stderrText);
  });

  test('preflight stop exits 2 and never calls execute', () async {
    final file = await _writeValidRequest(intakeRoot, outputPath);
    var executeCalled = false;

    final result = await FactoryBootstrapCommand(
      factoryRoot: factoryRoot,
      inspect: (request) async => BootstrapPreflightStopped(
        reasons: const [
          BootstrapStopReason(
            category: BootstrapStopCategory.unsafeOutputPath,
            fieldOrFact: 'exactOutputPath',
            description: 'The output path is unsafe.',
          ),
        ],
        notPerformed: const ['No Product mutation was performed.'],
      ),
      execute: (ready) async {
        executeCalled = true;
        return _prepared(ready.validatedRequest);
      },
    ).run(['--request', file.path]);

    expect(result.exitCode, 2);
    expect(executeCalled, isFalse);
    expect(jsonDecode(result.stdoutJson)['outcomeState'], 'preflightStopped');
    _expectHumanSummary(result.stderrText);
  });

  test('execution safe stop exits 3', () async {
    final file = await _writeValidRequest(intakeRoot, outputPath);
    final result = await _commandWithExecution(
      factoryRoot,
      file,
      outputPath,
      BootstrapExecutionStopped(
        category: BootstrapExecutionStopCategory.flutterToolUnavailable,
        stage: BootstrapExecutionStage.toolchainValidation,
        confirmedFacts: const ['No Product mutation was started.'],
        targetUnchangedOrRestored: true,
        evidence: const ['Toolchain validation stopped.'],
        notPerformed: const ['Product installation was not performed.'],
        commandsCompleted: const [],
      ),
    );

    expect(result.exitCode, 3);
    expect(jsonDecode(result.stdoutJson)['outcomeState'], 'executionStopped');
    _expectHumanSummary(result.stderrText);
  });

  test('partial failure exits 4 and requires User inspection', () async {
    final file = await _writeValidRequest(intakeRoot, outputPath);
    final result = await _commandWithExecution(
      factoryRoot,
      file,
      outputPath,
      BootstrapExecutionPartialFailure(
        category: BootstrapExecutionStopCategory.rollbackFailed,
        stage: BootstrapExecutionStage.rollback,
        finalTargetPath: outputPath,
        stagingPath: '$outputPath.staging',
        createdOrMovedEntries: const ['README.md'],
        rollbackSucceeded: const [],
        rollbackFailed: const ['README.md'],
        gitMetadataAffected: false,
        pathsRequiringUserInspection: [outputPath],
        cleanupNotPerformed: const ['No unsafe cleanup was attempted.'],
        commandsCompleted: const [],
      ),
    );

    expect(result.exitCode, 4);
    expect(jsonDecode(result.stdoutJson)['outcomeState'], 'partialFailure');
    expect(result.stderrText, contains('User 검사가 필요'));
    _expectHumanSummary(result.stderrText);
  });

  test('unexpected command-layer failure exits 70 without raw error', () async {
    final file = await _writeValidRequest(intakeRoot, outputPath);
    final result = await FactoryBootstrapCommand(
      factoryRoot: factoryRoot,
      inspect: (request) async => throw StateError('token=do-not-echo'),
      execute: (ready) async => _prepared(ready.validatedRequest),
    ).run(['--request', file.path]);

    expect(result.exitCode, 70);
    expect(result.stdoutJson, isNot(contains('do-not-echo')));
    expect(
      jsonDecode(result.stdoutJson)['outcomeState'],
      'unexpectedCommandFailure',
    );
    _expectHumanSummary(result.stderrText);
  });

  test('Prepared exits 0 with one JSON document and Pending approvals',
      () async {
    final file = await _writeValidRequest(intakeRoot, outputPath);
    final progress = <String>[];
    final result = await FactoryBootstrapCommand(
      factoryRoot: factoryRoot,
      inspect: (request) async => _ready(request, outputPath),
      execute: (ready) async => _prepared(ready.validatedRequest),
      progress: progress.add,
    ).run(['--request', file.path]);

    expect(result.exitCode, 0);
    final decoded = jsonDecode(result.stdoutJson) as Map<String, dynamic>;
    expect(decoded['outcomeState'], 'prepared');
    expect(decoded['execution']['status'], 'prepared');
    expect(decoded['approvalStatuses']['readyApprovalStatus'], 'Pending');
    expect(decoded['approvalStatuses']['agreementApprovalStatus'], 'Pending');
    expect(
      decoded['execution']['firstAgreementProposal']['approvalStatus'],
      'Pending',
    );
    expect(
      decoded['execution']['baselineHandoffProposal']['userApprovalStatus'],
      'Pending',
    );
    expect(
        () => jsonDecode('${result.stdoutJson}\nnoise'), throwsFormatException);
    for (final forbiddenClaim in [
      '"Ready"',
      '"Approved"',
      '"Committed"',
      '"Pushed"',
      '"Released"',
      '"Published"',
    ]) {
      expect(result.stdoutJson, isNot(contains(forbiddenClaim)));
    }
    expect(result.stderrText, contains('Prepared는 Ready 또는 Approved가 아닙니다'));
    expect(progress, [
      '요청 파일을 안전하게 검사하고 있습니다.',
      '요청 Schema 검증을 통과해 Runtime 사전 검사를 시작합니다.',
      '사전 검사를 통과해 Operational Bootstrap을 실행합니다.',
    ]);
    _expectHumanSummary(result.stderrText);
  });
}

Future<FactoryBootstrapCommandResult> _commandWithExecution(
  Directory factoryRoot,
  File requestFile,
  String outputPath,
  BootstrapExecutionResult execution,
) {
  return FactoryBootstrapCommand(
    factoryRoot: factoryRoot,
    inspect: (request) async => _ready(request, outputPath),
    execute: (ready) async => execution,
  ).run(['--request', requestFile.path]);
}

BootstrapPreflightReady _ready(BootstrapRequest request, String outputPath) {
  return BootstrapPreflightReady(
    validatedRequest: _validated(outputPath),
    normalizedOutputPath: outputPath,
    inspection: BootstrapTargetInspection(
      inspectedPath: outputPath,
      normalizedPath: outputPath,
      targetExists: false,
      repositoryMode: RepositoryMode.newRepository,
      nearestExistingParent: path.dirname(outputPath),
      hasIndependentGitDirectory: false,
      targetEntries: const [],
    ),
  );
}

ValidatedBootstrapRequest _validated(String outputPath) {
  return ValidatedBootstrapRequest(
    productDisplayName: 'Example Product',
    productPurpose: 'Validate a Product workflow.',
    initialProductScopeOrFirstIntendedOutcome:
        'Prepare the first approved workflow.',
    exactOutputPath: outputPath,
    repositoryMode: RepositoryMode.newRepository,
    initialBranchName: 'main',
    repositoryPolicy: null,
    flutterProjectName: 'example_product',
    organizationIdentifier: 'com.example',
    requestedTechnology: 'flutter',
    targetPlatforms: const ['ios', 'android'],
  );
}

BootstrapExecutionPrepared _prepared(ValidatedBootstrapRequest request) {
  final baseline = BaselineHandoffProposal(
    repositoryIdentity: request.exactOutputPath,
    branch: 'main',
    headAvailable: false,
    headIdentity: null,
    remotePresent: false,
    gitStatusEntries: const ['?? README.md', '?? AGENTS.md'],
    generatedProductAuthorityPaths: const ['README.md', 'AGENTS.md'],
    generatedRootEntries: const ['README.md', 'AGENTS.md', 'lib'],
  );
  return BootstrapExecutionPrepared(
    validatedRequest: request,
    finalProductPath: request.exactOutputPath,
    repositoryMode: request.repositoryMode,
    gitTopLevel: request.exactOutputPath,
    branch: 'main',
    headExists: false,
    hasRemotes: false,
    generatedPlatforms: const {'ios', 'android'},
    dependencyPreparationSucceeded: true,
    createdRootEntries: const ['README.md', 'AGENTS.md', 'lib'],
    commandsCompleted: const [],
    rollbackRequired: false,
    environmentNote: 'No environment changes requested.',
    productAuthorityEvidence: ProductAuthorityEvidence(
      generatedPaths: const ['README.md', 'AGENTS.md'],
      productLocalStartingPoint: 'AGENTS.md',
      factoryReferenceRequired: false,
    ),
    technicalValidationEvidence: BootstrapTechnicalValidationEvidence.passed(
      completedCommands: const [],
      factoryRoot: '/portable/factory',
      factoryBranch: 'main',
      factoryHeadIdentity: 'abc123',
      factoryStatusEntries: const [],
    ),
    firstAgreementProposal:
        FirstAgreementProposal.fromValidatedRequest(request),
    baselineHandoffProposal: baseline,
  );
}

Future<File> _writeValidRequest(
  Directory intakeRoot,
  String outputPath,
) async {
  final file = File(path.join(intakeRoot.path, 'product_request.yaml'));
  await file.writeAsString('''schemaVersion: 1
requestId: command-001

bootstrap:
  productDisplayName: Example Product
  productPurpose: Validate a Product workflow.
  initialProductScopeOrFirstIntendedOutcome: Prepare the first approved workflow.
  exactOutputPath: $outputPath
  repositoryMode: newRepository
  initialBranchName: main
  repositoryPolicy: null
  flutterProjectName: example_product
  organizationIdentifier: com.example
  requestedTechnology: flutter
  targetPlatforms:
    - ios
    - android
''');
  return file;
}

void _expectHumanSummary(String stderrText) {
  expect(stderrText.trim(), isNotEmpty);
  expect(stderrText, matches(RegExp(r'^[가-힣]')));
  expect(stderrText, contains('다음 사용자 결정'));
}
