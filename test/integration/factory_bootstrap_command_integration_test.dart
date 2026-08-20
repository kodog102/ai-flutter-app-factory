import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

final _runIntegration =
    Platform.environment['RUN_FACTORY_BOOTSTRAP_INTEGRATION'] == 'true';

void main() {
  test(
    'one command prepares a disposable New Repository Product',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _temporaryFixture(
        'factory_bootstrap_command_new_',
      );
      try {
        final intake = await Directory(
          path.join(fixture.path, 'intake'),
        ).create();
        final targetPath = path.join(fixture.path, 'new_product');
        final request = await _writeRequest(
          intake,
          _requestYaml(outputPath: targetPath),
        );

        final command = await _runCommand(request);

        expect(
          command.exitCode,
          0,
          reason: '${command.stderr}\n${command.stdout}',
        );
        final report = _jsonReport(command);
        expect(report['outcomeState'], 'prepared');
        expect(report['approvalStatuses']['readyApprovalStatus'], 'Pending');
        expect(
          report['approvalStatuses']['agreementApprovalStatus'],
          'Pending',
        );
        expect(report['execution']['firstAgreementProposal'], isNotNull);
        expect(report['execution']['baselineHandoffProposal'], isNotNull);
        expect(report['execution']['technicalValidationEvidence'], isNotNull);
        expect(
          await File(path.join(targetPath, 'README.md')).exists(),
          isTrue,
        );
        expect(
          await File(path.join(targetPath, 'AGENTS.md')).exists(),
          isTrue,
        );
        expect(await Directory(path.join(targetPath, 'ios')).exists(), isTrue);
        expect(
          await Directory(path.join(targetPath, 'android')).exists(),
          isTrue,
        );
        expect(_ownedStaging(fixture), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'one command preserves an Existing Empty Repository policy',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _temporaryFixture(
        'factory_bootstrap_command_existing_',
      );
      try {
        final intake = await Directory(
          path.join(fixture.path, 'intake'),
        ).create();
        final target = await Directory(
          path.join(fixture.path, 'existing_product'),
        ).create();
        final gitInit = await Process.run(
          'git',
          ['init', '--initial-branch=preserved', '.'],
          workingDirectory: target.path,
          runInShell: false,
        );
        expect(gitInit.exitCode, 0, reason: gitInit.stderr.toString());
        final headBefore = await File(
          path.join(target.path, '.git', 'HEAD'),
        ).readAsString();
        final configBefore = await File(
          path.join(target.path, '.git', 'config'),
        ).readAsString();
        final request = await _writeRequest(
          intake,
          _requestYaml(
            outputPath: target.path,
            repositoryMode: 'existingEmptyRepository',
            initialBranchName: 'null',
            repositoryPolicy: 'preserve existing Repository policy',
          ),
        );

        final command = await _runCommand(request);

        expect(
          command.exitCode,
          0,
          reason: '${command.stderr}\n${command.stdout}',
        );
        final report = _jsonReport(command);
        expect(report['outcomeState'], 'prepared');
        expect(report['execution']['product']['branch'], 'preserved');
        expect(
          await File(path.join(target.path, '.git', 'HEAD')).readAsString(),
          headBefore,
        );
        expect(
          await File(path.join(target.path, '.git', 'config')).readAsString(),
          configBefore,
        );
        expect(
            await File(path.join(target.path, 'README.md')).exists(), isTrue);
        expect(
            await File(path.join(target.path, 'AGENTS.md')).exists(), isTrue);
        expect(_ownedStaging(fixture), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'malformed request creates no Product through the command',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _temporaryFixture(
        'factory_bootstrap_command_malformed_',
      );
      try {
        final targetPath = path.join(fixture.path, 'product');
        final request = await _writeRequest(
          fixture,
          'schemaVersion: 1\nbootstrap: [\n',
        );

        final command = await _runCommand(request);

        expect(command.exitCode, 2);
        expect(_jsonReport(command)['outcomeState'], 'requestStopped');
        expect(await Directory(targetPath).exists(), isFalse);
        expect(_ownedStaging(fixture), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
  );

  test(
    'invalid Existing branch-only request stops before Product mutation',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _temporaryFixture(
        'factory_bootstrap_command_invalid_existing_',
      );
      try {
        final targetPath = path.join(fixture.path, 'product');
        final request = await _writeRequest(
          fixture,
          _requestYaml(
            outputPath: targetPath,
            repositoryMode: 'existingEmptyRepository',
            initialBranchName: 'main',
            repositoryPolicy: 'null',
          ),
        );

        final command = await _runCommand(request);

        expect(command.exitCode, 2);
        final report = _jsonReport(command);
        expect(report['outcomeState'], 'preflightStopped');
        expect(
          report['preflight']['reasons'].any(
            (dynamic reason) =>
                reason['category'] == 'invalidBranchOrRepositoryPolicy',
          ),
          isTrue,
        );
        expect(await Directory(targetPath).exists(), isFalse);
        expect(_ownedStaging(fixture), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
  );
}

Future<ProcessResult> _runCommand(File request) {
  return Process.run(
    Platform.resolvedExecutable,
    [
      'run',
      'ai_flutter_app_factory:factory_bootstrap',
      '--request',
      request.path,
    ],
    workingDirectory: Directory.current.path,
    runInShell: false,
  );
}

Future<Directory> _temporaryFixture(String prefix) async {
  final created = await Directory.systemTemp.createTemp(prefix);
  return Directory(await created.resolveSymbolicLinks());
}

Map<String, dynamic> _jsonReport(ProcessResult result) {
  final stdoutText = result.stdout.toString().trim();
  final decoded = jsonDecode(stdoutText) as Map<String, dynamic>;
  expect(() => jsonDecode('$stdoutText\nnoise'), throwsFormatException);
  expect(result.stderr.toString(), contains('다음 사용자 결정'));
  return decoded;
}

Future<File> _writeRequest(Directory directory, String source) async {
  final file = File(path.join(directory.path, 'product_request.yaml'));
  await file.writeAsString(source);
  return file;
}

String _requestYaml({
  required String outputPath,
  String repositoryMode = 'newRepository',
  String initialBranchName = 'bootstrap-main',
  String repositoryPolicy = 'null',
}) {
  return '''schemaVersion: 1
requestId: integration-001

bootstrap:
  productDisplayName: Command Validation Product
  productPurpose: Validate one-run Product Bootstrap.
  initialProductScopeOrFirstIntendedOutcome: Prepare a verified Flutter starting point.
  exactOutputPath: $outputPath
  repositoryMode: $repositoryMode
  initialBranchName: $initialBranchName
  repositoryPolicy: $repositoryPolicy
  flutterProjectName: command_validation_product
  organizationIdentifier: com.example
  requestedTechnology: flutter
  targetPlatforms:
    - ios
    - android
''';
}

Future<List<String>> _factoryStatus() async {
  final result = await Process.run(
    'git',
    ['status', '--porcelain=v1'],
    workingDirectory: Directory.current.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return const LineSplitter()
      .convert(result.stdout.toString())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

List<String> _ownedStaging(Directory root) {
  return root
      .listSync(followLinks: false)
      .map((entity) => path.basename(entity.path))
      .where((name) => name.contains('.factory-bootstrap-'))
      .toList(growable: false);
}
