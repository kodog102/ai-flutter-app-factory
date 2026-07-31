import 'dart:io';

import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_execution_result.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_execution_stop_reason.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_executor.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight_result.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_request.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

final _runIntegration =
    Platform.environment['RUN_FACTORY_BOOTSTRAP_INTEGRATION'] == 'true';

void main() {
  test(
    'disposable New Repository receives an executable empty scaffold',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final targetPath = path.join(fixture.root.path, 'new_product');
        final preflight = FileSystemBootstrapPreflight(
          factoryRoot: fixture.factory,
        );
        final ready = await preflight.inspect(
          _request(outputPath: targetPath),
        ) as BootstrapPreflightReady;

        final result = await FileSystemBootstrapExecutor(
          factoryRoot: fixture.factory,
          preflight: preflight,
        ).execute(ready);

        expect(result, isA<BootstrapExecutionReady>(),
            reason: _describe(result));
        final completed = result as BootstrapExecutionReady;
        expect(completed.branch, 'bootstrap-main');
        expect(completed.headExists, isFalse);
        expect(completed.hasRemotes, isFalse);
        expect(
          await Directory(path.join(targetPath, 'android')).exists(),
          isTrue,
        );
        expect(await Directory(path.join(targetPath, 'ios')).exists(), isTrue);
        expect(
          await File(
            path.join(targetPath, 'test', 'bootstrap_smoke_test.dart'),
          ).exists(),
          isTrue,
        );
        expect(
          await File(path.join(targetPath, 'lib', 'main.dart')).readAsString(),
          isNot(contains('incrementCounter')),
        );
        await _expectSmokeTestPasses(targetPath);
        expect(_ownedStaging(fixture.root), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.root.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'disposable Existing Repository preserves Git policy and adds scaffold',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final target = await Directory(
          path.join(fixture.root.path, 'existing_product'),
        ).create();
        final init = await Process.run(
          'git',
          ['init', '--initial-branch=preserved', '.'],
          workingDirectory: target.path,
          runInShell: false,
        );
        expect(init.exitCode, 0, reason: init.stderr.toString());
        final headBefore = await File(
          path.join(target.path, '.git', 'HEAD'),
        ).readAsString();
        final configBefore = await File(
          path.join(target.path, '.git', 'config'),
        ).readAsString();

        final preflight = FileSystemBootstrapPreflight(
          factoryRoot: fixture.factory,
        );
        final ready = await preflight.inspect(
          _request(
            outputPath: target.path,
            repositoryMode: 'existingEmptyRepository',
            initialBranchName: null,
            repositoryPolicy: 'preserve observed Repository policy',
          ),
        ) as BootstrapPreflightReady;

        final result = await FileSystemBootstrapExecutor(
          factoryRoot: fixture.factory,
          preflight: preflight,
        ).execute(ready);

        expect(result, isA<BootstrapExecutionReady>(),
            reason: _describe(result));
        final completed = result as BootstrapExecutionReady;
        expect(completed.branch, 'preserved');
        expect(completed.headExists, isFalse);
        expect(completed.hasRemotes, isFalse);
        expect(
          await File(path.join(target.path, '.git', 'HEAD')).readAsString(),
          headBefore,
        );
        expect(
          await File(path.join(target.path, '.git', 'config')).readAsString(),
          configBefore,
        );
        expect(
          completed.commandsCompleted.any(
            (command) =>
                command.executable == 'git' &&
                command.arguments.firstOrNull == 'init',
          ),
          isFalse,
        );
        await _expectSmokeTestPasses(target.path);
        expect(_ownedStaging(fixture.root), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.root.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'tracked scaffold path stops before Existing Repository mutation',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final target = await _repositoryWithStagedDeletion(
          fixture.root,
          'tracked_collision',
          'README.md',
        );
        final statusBefore = await _gitOutput(target, ['status', '--short']);
        final headBefore = await _gitOutput(target, ['rev-parse', 'HEAD']);
        final configBefore =
            await File(path.join(target.path, '.git', 'config')).readAsBytes();
        final indexBefore =
            await File(path.join(target.path, '.git', 'index')).readAsBytes();
        final preflight = FileSystemBootstrapPreflight(
          factoryRoot: fixture.factory,
        );
        final ready = await preflight.inspect(
          _request(
            outputPath: target.path,
            repositoryMode: 'existingEmptyRepository',
            initialBranchName: null,
            repositoryPolicy: 'preserve observed Repository policy',
          ),
        ) as BootstrapPreflightReady;

        final result = await FileSystemBootstrapExecutor(
          factoryRoot: fixture.factory,
          preflight: preflight,
        ).execute(ready);

        final stopped = result as BootstrapExecutionStopped;
        expect(
          stopped.category,
          BootstrapExecutionStopCategory.trackedPathConflict,
        );
        expect(stopped.evidence.join('\n'), contains('README.md'));
        expect(await File(path.join(target.path, 'pubspec.yaml')).exists(),
            isFalse);
        expect(await _gitOutput(target, ['status', '--short']), statusBefore);
        expect(await _gitOutput(target, ['rev-parse', 'HEAD']), headBefore);
        expect(
          await File(path.join(target.path, '.git', 'config')).readAsBytes(),
          configBefore,
        );
        expect(
          await File(path.join(target.path, '.git', 'index')).readAsBytes(),
          indexBefore,
        );
        expect(_ownedStaging(fixture.root), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.root.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'non-conflicting staged deletion preserves status and receives scaffold',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final target = await _repositoryWithStagedDeletion(
          fixture.root,
          'non_conflicting_history',
          'legacy.txt',
        );
        final statusBefore = await _gitOutput(target, ['status', '--short']);
        final headBefore = await _gitOutput(target, ['rev-parse', 'HEAD']);
        final preflight = FileSystemBootstrapPreflight(
          factoryRoot: fixture.factory,
        );
        final ready = await preflight.inspect(
          _request(
            outputPath: target.path,
            repositoryMode: 'existingEmptyRepository',
            initialBranchName: null,
            repositoryPolicy: 'preserve observed Repository policy',
          ),
        ) as BootstrapPreflightReady;

        final result = await FileSystemBootstrapExecutor(
          factoryRoot: fixture.factory,
          preflight: preflight,
        ).execute(ready);

        expect(result, isA<BootstrapExecutionReady>(),
            reason: _describe(result));
        final statusAfter = await _gitOutput(target, ['status', '--short']);
        expect(statusAfter, contains(statusBefore.trim()));
        expect(await _gitOutput(target, ['rev-parse', 'HEAD']), headBefore);
        expect(await File(path.join(target.path, 'pubspec.yaml')).exists(),
            isTrue);
        await _expectSmokeTestPasses(target.path);
        expect(_ownedStaging(fixture.root), isEmpty);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.root.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'Existing rollback preserves an external staging entry',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final target = await Directory(
          path.join(fixture.root.path, 'existing_rollback'),
        ).create();
        await _runGit(
          target,
          ['init', '--initial-branch=preserved', '.'],
        );
        final headBefore =
            await File(path.join(target.path, '.git', 'HEAD')).readAsString();
        final configBefore =
            await File(path.join(target.path, '.git', 'config')).readAsString();
        final statusBefore = await _gitOutput(target, ['status', '--short']);
        final preflight = FileSystemBootstrapPreflight(
          factoryRoot: fixture.factory,
        );
        final ready = await preflight.inspect(
          _request(
            outputPath: target.path,
            repositoryMode: 'existingEmptyRepository',
            initialBranchName: null,
            repositoryPolicy: 'preserve observed Repository policy',
          ),
        ) as BootstrapPreflightReady;

        final result = await FileSystemBootstrapExecutor(
          factoryRoot: fixture.factory,
          preflight: preflight,
          executionHook: (
            stage, {
            required stagingPath,
            required finalTargetPath,
          }) async {
            final conflict = Directory(path.join(finalTargetPath, 'lib'));
            if (stage == BootstrapExecutionStage.installation) {
              await conflict.create();
            }
            if (stage == BootstrapExecutionStage.rollback) {
              if (await conflict.exists()) {
                await conflict.delete();
              }
              await File(path.join(stagingPath, 'external.txt'))
                  .writeAsString('external');
            }
          },
        ).execute(ready);

        final partial = result as BootstrapExecutionPartialFailure;
        expect(
          partial.category,
          BootstrapExecutionStopCategory.ownershipMismatch,
        );
        expect(partial.stagingPath, isNotNull);
        expect(
          await File(path.join(partial.stagingPath!, 'external.txt')).exists(),
          isTrue,
        );
        expect(partial.expectedManifest, isNot(contains('external.txt')));
        expect(partial.actualManifest, contains('external.txt'));
        expect(partial.ownershipDifferences, contains('added:external.txt'));
        expect(partial.gitMetadataAffected, isFalse);
        expect(
          await File(path.join(target.path, '.git', 'HEAD')).readAsString(),
          headBefore,
        );
        expect(
          await File(path.join(target.path, '.git', 'config')).readAsString(),
          configBefore,
        );
        expect(await _gitOutput(target, ['status', '--short']), statusBefore);
        expect(
          target
              .listSync(followLinks: false)
              .map((entry) => path.basename(entry.path)),
          ['.git'],
        );
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.root.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'New non-Git ownership mismatch preserves target and reports no Git impact',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final targetPath = path.join(fixture.root.path, 'new_mismatch');
        final preflight = FileSystemBootstrapPreflight(
          factoryRoot: fixture.factory,
        );
        final ready = await preflight.inspect(
          _request(outputPath: targetPath),
        ) as BootstrapPreflightReady;

        final result = await FileSystemBootstrapExecutor(
          factoryRoot: fixture.factory,
          preflight: preflight,
          executionHook: (
            stage, {
            required stagingPath,
            required finalTargetPath,
          }) async {
            if (stage == BootstrapExecutionStage.finalVerification) {
              await File(path.join(finalTargetPath, 'README.md'))
                  .writeAsString('external change');
            }
          },
        ).execute(ready);

        final partial = result as BootstrapExecutionPartialFailure;
        expect(
          partial.category,
          BootstrapExecutionStopCategory.ownershipMismatch,
        );
        expect(partial.gitMetadataAffected, isFalse);
        expect(partial.ownershipDifferences, contains('changed:README.md'));
        expect(await Directory(targetPath).exists(), isTrue);
        expect(
          await File(path.join(targetPath, 'README.md')).readAsString(),
          'external change',
        );
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.root.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'New post-manifest hook failure preserves external staging content',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final targetPath = path.join(
          fixture.root.path,
          'new_guarded_cleanup',
        );
        final preflight = FileSystemBootstrapPreflight(
          factoryRoot: fixture.factory,
        );
        final ready = await preflight.inspect(
          _request(outputPath: targetPath),
        ) as BootstrapPreflightReady;

        final result = await FileSystemBootstrapExecutor(
          factoryRoot: fixture.factory,
          preflight: preflight,
          executionHook: (
            stage, {
            required stagingPath,
            required finalTargetPath,
          }) async {
            if (stage == BootstrapExecutionStage.installation) {
              await File(path.join(stagingPath, 'external.txt'))
                  .writeAsString('external');
              throw StateError('integration guarded-cleanup failure');
            }
          },
        ).execute(ready);

        final partial = result as BootstrapExecutionPartialFailure;
        expect(
          partial.category,
          BootstrapExecutionStopCategory.ownershipMismatch,
        );
        expect(partial.stagingPath, isNotNull);
        expect(
          await File(path.join(partial.stagingPath!, 'external.txt')).exists(),
          isTrue,
        );
        expect(partial.ownershipDifferences, contains('added:external.txt'));
        expect(partial.gitMetadataAffected, isFalse);
        expect(await Directory(targetPath).exists(), isFalse);
        expect(await _factoryStatus(), factoryStatusBefore);
      } finally {
        await fixture.root.delete(recursive: true);
      }
    },
    skip: _runIntegration
        ? false
        : 'Run with RUN_FACTORY_BOOTSTRAP_INTEGRATION=true.',
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<_IntegrationFixture> _fixture() async {
  final created = await Directory.systemTemp.createTemp(
    'factory_bootstrap_integration_',
  );
  final root = Directory(await created.resolveSymbolicLinks());
  final factory = await Directory(path.join(root.path, 'factory')).create();
  return _IntegrationFixture(root, factory);
}

BootstrapRequest _request({
  required String outputPath,
  String repositoryMode = 'newRepository',
  String? initialBranchName = 'bootstrap-main',
  String? repositoryPolicy,
}) {
  return BootstrapRequest(
    productDisplayName: 'Disposable Bootstrap Validation',
    productPurpose: 'Validate the executable Bootstrap contract.',
    initialProductScopeOrFirstIntendedOutcome:
        'Prepare and inspect a disposable neutral scaffold.',
    exactOutputPath: outputPath,
    repositoryMode: repositoryMode,
    initialBranchName: initialBranchName,
    repositoryPolicy: repositoryPolicy,
    flutterProjectName: 'factory_bootstrap_validation',
    organizationIdentifier: 'com.example',
    requestedTechnology: 'flutter',
    targetPlatforms: const ['ios', 'android'],
  );
}

Future<void> _expectSmokeTestPasses(String productPath) async {
  final result = await Process.run(
    'flutter',
    ['test', 'test/bootstrap_smoke_test.dart'],
    workingDirectory: productPath,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
}

Future<Directory> _repositoryWithStagedDeletion(
  Directory root,
  String name,
  String relativePath,
) async {
  final target = await Directory(path.join(root.path, name)).create();
  await _runGit(target, ['init', '--initial-branch=preserved', '.']);
  await _runGit(target, ['config', 'user.name', 'Factory Integration']);
  await _runGit(
    target,
    ['config', 'user.email', 'factory-integration@example.invalid'],
  );
  final tracked = File(path.join(target.path, relativePath));
  await tracked.parent.create(recursive: true);
  await tracked.writeAsString('baseline\n');
  await _runGit(target, ['add', relativePath]);
  await _runGit(target, ['commit', '-m', 'integration baseline']);
  await tracked.delete();
  await _runGit(target, ['add', '-u']);
  return target;
}

Future<void> _runGit(Directory repository, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: repository.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
}

Future<String> _gitOutput(
  Directory repository,
  List<String> arguments,
) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: repository.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout.toString();
}

Future<String> _factoryStatus() async {
  final result = await Process.run(
    'git',
    ['status', '--porcelain=v1'],
    workingDirectory: Directory.current.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout.toString();
}

List<String> _ownedStaging(Directory root) {
  return root
      .listSync(followLinks: false)
      .map((entry) => path.basename(entry.path))
      .where((name) => name.contains('.factory-bootstrap-'))
      .toList();
}

String _describe(BootstrapExecutionResult result) {
  return switch (result) {
    BootstrapExecutionStopped stopped =>
      '${stopped.category.name}/${stopped.stage.name}: '
          '${stopped.validationFailure ?? stopped.failedCommand?.stderr}',
    BootstrapExecutionPartialFailure partial =>
      '${partial.category.name}/${partial.stage.name}: ${partial.failure}',
    BootstrapExecutionReady _ => 'Ready',
  };
}

final class _IntegrationFixture {
  const _IntegrationFixture(this.root, this.factory);

  final Directory root;
  final Directory factory;
}
