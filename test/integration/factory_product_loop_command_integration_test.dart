import 'dart:convert';
import 'dart:io';

import 'package:ai_flutter_app_factory/core/product_loop/factory_product_loop_command.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

final _runIntegration =
    Platform.environment['AI_FLUTTER_FACTORY_RUN_INTEGRATION'] == '1';

void main() {
  test(
    'captures and validates a disposable Flutter Product through the command',
    () async {
      final factoryRoot = Directory.current.absolute;
      final factoryStatusBefore = await _gitOutput(factoryRoot, [
        'status',
        '--short',
        '--untracked-files=all',
      ]);
      final fixture = await Directory.systemTemp.createTemp(
        'factory_product_loop_command_integration_',
      );
      final productRoot = Directory(path.join(fixture.path, 'product'));
      final intakeRoot = await Directory(
        path.join(fixture.path, 'intake'),
      ).create();
      final evidenceRoot = await Directory(
        path.join(fixture.path, 'evidence'),
      ).create();
      try {
        final create = await Process.run(
          'flutter',
          [
            'create',
            '--platforms=ios,android',
            '--project-name=factory_product_loop_sample',
            '--org=com.example',
            productRoot.path,
          ],
          workingDirectory: fixture.path,
          runInShell: false,
        );
        expect(create.exitCode, 0, reason: create.stderr.toString());
        await File(
          path.join(productRoot.path, 'AGENTS.md'),
        ).writeAsString('Product-local operating authority.\n');
        await _ensureCommittedRepository(productRoot);
        final requestFile = File(
          path.join(intakeRoot.path, 'product_loop_request.yaml'),
        );
        await requestFile.writeAsString('''schemaVersion: 1
productRoot: ${productRoot.path}
buildPolicy: none
evidenceDirectory: ${evidenceRoot.path}
''');
        final command = FactoryProductLoopCommand(factoryRoot: factoryRoot);

        final capture = await command.run([
          '--request',
          requestFile.path,
          '--phase',
          'capture',
        ]);
        expect(capture.exitCode, 0, reason: capture.stderrText);
        final captureReport =
            jsonDecode(capture.stdoutJson) as Map<String, dynamic>;
        final approvedSha256 = captureReport['baseline']['sha256'] as String;
        expect(captureReport['baseline']['userApprovalStatus'], 'Pending');

        final validate = await command.run([
          '--request',
          requestFile.path,
          '--phase',
          'validate',
          '--approved-baseline-sha256',
          approvedSha256,
        ]);
        expect(
          validate.exitCode,
          0,
          reason: '${validate.stderrText}\n${validate.stdoutJson}',
        );
        final validationReport =
            jsonDecode(validate.stdoutJson) as Map<String, dynamic>;
        expect(validationReport['outcomeState'], 'candidateValidated');
        expect(
          validationReport['validation']['technicalValidationStatus'],
          'Passed',
        );
        expect(validationReport['validation']['qaStatus'], 'Pending');
        expect(
          validationReport['validation']['userApprovalStatus'],
          'Pending',
        );
        expect(
          validationReport['validation']['commitStatus'],
          'NotPerformed',
        );
        expect(
          validationReport['validation']['commandsCompleted'].map(
            (dynamic command) =>
                '${command['executable']} ${(command['arguments'] as List<dynamic>).join(' ')}',
          ),
          [
            'dart format --output=none --set-exit-if-changed lib test',
            'flutter analyze',
            'flutter test',
          ],
        );
        expect(
          await _gitOutput(productRoot, [
            'status',
            '--short',
            '--untracked-files=all',
          ]),
          isEmpty,
        );
        expect(
          await _gitOutput(factoryRoot, [
            'status',
            '--short',
            '--untracked-files=all',
          ]),
          factoryStatusBefore,
        );
      } finally {
        await fixture.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with AI_FLUTTER_FACTORY_RUN_INTEGRATION=1.',
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _ensureCommittedRepository(Directory root) async {
  await _git(root, ['init', '-b', 'main']);
  await _git(root, ['config', 'user.email', 'factory@example.invalid']);
  await _git(root, ['config', 'user.name', 'Factory Integration']);
  await _git(root, ['add', '.']);
  await _git(root, ['commit', '-m', 'Product baseline']);
}

Future<void> _git(Directory root, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: root.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
}

Future<String> _gitOutput(Directory root, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: root.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout.toString().trim();
}
