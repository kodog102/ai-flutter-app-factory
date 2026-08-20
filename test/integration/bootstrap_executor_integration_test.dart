import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_executor.dart'
    show FileSystemBootstrapExecutor;
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight.dart'
    show FileSystemBootstrapPreflight;
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
        final runtime = FlutterAppFactoryRuntime(
          factoryRoot: fixture.factory,
        );
        final ready = await runtime.inspect(
          _request(outputPath: targetPath),
        ) as BootstrapPreflightReady;

        final result = await runtime.execute(ready);

        expect(result, isA<BootstrapExecutionPrepared>(),
            reason: _describe(result));
        final completed = result as BootstrapExecutionPrepared;
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
        expect(
          await File(path.join(targetPath, 'README.md')).readAsString(),
          allOf(
            contains('Automated technical validation has passed'),
            contains('User Ready approval is pending'),
            contains('First Agreement approval is pending'),
          ),
        );
        expect(await File(path.join(targetPath, 'AGENTS.md')).exists(), isTrue);
        expect(
            await Directory(path.join(targetPath, 'Docs')).exists(), isFalse);
        expect(
          await File(path.join(targetPath, 'Agreement.md')).exists(),
          isFalse,
        );
        expect(
          await File(path.join(targetPath, 'Handoff.md')).exists(),
          isFalse,
        );
        expect(completed.automatedTechnicalValidationStatus, 'Passed');
        expect(completed.userReadyApprovalStatus, 'Pending');
        expect(completed.firstAgreementApprovalStatus, 'Pending');
        expect(completed.firstAgreementProposal.approvalStatus,
            'Proposed — User approval required');
        expect(completed.baselineHandoffProposal.proposalStatus, 'Proposed');
        expect(
          completed.baselineHandoffProposal.technicalValidationStatus,
          'Passed',
        );
        expect(
          completed.baselineHandoffProposal.userApprovalStatus,
          'Pending',
        );
        expect(
          completed.technicalValidationEvidence.completedCommands
              .map((command) => command.arguments),
          [
            ['pub', 'get'],
            ['analyze'],
            ['test'],
            ['build', 'apk'],
            ['build', 'ios', '--simulator'],
          ],
        );
        expect(
          completed.technicalValidationEvidence.completedCommands
              .every((command) => command.succeeded),
          isTrue,
        );
        expect(
          completed
              .technicalValidationEvidence.factoryRepositoryUnchangedStatus,
          'Confirmed',
        );
        expect(
          completed.baselineHandoffProposal.gitStatusEntries,
          await _gitStatusEntries(Directory(targetPath)),
        );
        expect(
          await File(
            path.join(
              targetPath,
              'build',
              'app',
              'outputs',
              'flutter-apk',
              'app-release.apk',
            ),
          ).exists(),
          isTrue,
        );
        expect(
          await Directory(
            path.join(
              targetPath,
              'build',
              'ios',
              'iphonesimulator',
              'Runner.app',
            ),
          ).exists(),
          isTrue,
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

        final runtime = FlutterAppFactoryRuntime(
          factoryRoot: fixture.factory,
        );
        final ready = await runtime.inspect(
          _request(
            outputPath: target.path,
            repositoryMode: 'existingEmptyRepository',
            initialBranchName: null,
            repositoryPolicy: 'preserve observed Repository policy',
          ),
        ) as BootstrapPreflightReady;

        final result = await runtime.execute(ready);

        expect(result, isA<BootstrapExecutionPrepared>(),
            reason: _describe(result));
        final completed = result as BootstrapExecutionPrepared;
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
        expect(
          await File(path.join(target.path, 'README.md')).readAsString(),
          contains('Automated technical validation has passed'),
        );
        expect(
            await File(path.join(target.path, 'AGENTS.md')).exists(), isTrue);
        expect(
          completed.baselineHandoffProposal.gitStatusEntries,
          await _gitStatusEntries(target),
        );
        expect(completed.baselineHandoffProposal.branch, 'preserved');
        expect(completed.baselineHandoffProposal.headAvailable, isFalse);
        expect(completed.baselineHandoffProposal.remotePresent, isFalse);
        expect(completed.automatedTechnicalValidationStatus, 'Passed');
        expect(completed.userReadyApprovalStatus, 'Pending');
        expect(completed.firstAgreementApprovalStatus, 'Pending');
        expect(
          completed.technicalValidationEvidence.completedCommands,
          hasLength(5),
        );
        expect(
          await File(
            path.join(
              target.path,
              'build',
              'app',
              'outputs',
              'flutter-apk',
              'app-release.apk',
            ),
          ).exists(),
          isTrue,
        );
        expect(
          await Directory(
            path.join(
              target.path,
              'build',
              'ios',
              'iphonesimulator',
              'Runner.app',
            ),
          ).exists(),
          isTrue,
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
    timeout: const Timeout(Duration(minutes: 8)),
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

        expect(result, isA<BootstrapExecutionPrepared>(),
            reason: _describe(result));
        final completed = result as BootstrapExecutionPrepared;
        final statusAfter = await _gitOutput(target, ['status', '--short']);
        expect(statusAfter, contains(statusBefore.trim()));
        expect(await _gitOutput(target, ['rev-parse', 'HEAD']), headBefore);
        expect(await File(path.join(target.path, 'pubspec.yaml')).exists(),
            isTrue);
        expect(
            await File(path.join(target.path, 'AGENTS.md')).exists(), isTrue);
        expect(completed.headExists, isTrue);
        expect(completed.hasRemotes, isTrue);
        expect(
          completed.baselineHandoffProposal.gitStatusEntries,
          await _gitStatusEntries(target),
        );
        expect(
          completed.baselineHandoffProposal.headIdentity,
          (await _gitOutput(target, ['rev-parse', 'HEAD'])).trim(),
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

  test(
    'cross-domain Products receive isolated authority and proposals',
    () async {
      final factoryStatusBefore = await _factoryStatus();
      final fixture = await _fixture();
      try {
        final cases = [
          (
            directory: 'garden_product',
            name: 'Garden Planner',
            purpose: 'Plan seasonal garden work.',
            scope: 'Clarify the first planting outcome.',
            project: 'garden_planner',
          ),
          (
            directory: 'reading_product',
            name: 'Reading Log',
            purpose: 'Record personal reading progress.',
            scope: 'Clarify the first reading-log outcome.',
            project: 'reading_log',
          ),
        ];
        final rendered = <String>[];
        for (final product in cases) {
          final targetPath = path.join(fixture.root.path, product.directory);
          final runtime = FlutterAppFactoryRuntime(
            factoryRoot: fixture.factory,
          );
          final ready = await runtime.inspect(
            _request(
              outputPath: targetPath,
              productDisplayName: product.name,
              productPurpose: product.purpose,
              initialScope: product.scope,
              flutterProjectName: product.project,
            ),
          ) as BootstrapPreflightReady;
          final result =
              await runtime.execute(ready) as BootstrapExecutionPrepared;
          final authority =
              '${await File(path.join(targetPath, 'README.md')).readAsString()}\n'
              '${await File(path.join(targetPath, 'AGENTS.md')).readAsString()}';
          rendered.add(authority);
          expect(authority, contains(product.name));
          expect(authority, contains(product.purpose));
          expect(authority, contains(product.scope));
          expect(result.firstAgreementProposal.goal, product.scope);
        }
        expect(rendered[0], isNot(contains(cases[1].name)));
        expect(rendered[1], isNot(contains(cases[0].name)));
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
  await _runGit(factory, ['init', '--initial-branch=factory-main', '.']);
  return _IntegrationFixture(root, factory);
}

BootstrapRequest _request({
  required String outputPath,
  String repositoryMode = 'newRepository',
  String? initialBranchName = 'bootstrap-main',
  String? repositoryPolicy,
  String productDisplayName = 'Disposable Bootstrap Validation',
  String productPurpose = 'Validate the executable Bootstrap contract.',
  String initialScope = 'Prepare and inspect a disposable neutral scaffold.',
  String flutterProjectName = 'factory_bootstrap_validation',
}) {
  return BootstrapRequest(
    productDisplayName: productDisplayName,
    productPurpose: productPurpose,
    initialProductScopeOrFirstIntendedOutcome: initialScope,
    exactOutputPath: outputPath,
    repositoryMode: repositoryMode,
    initialBranchName: initialBranchName,
    repositoryPolicy: repositoryPolicy,
    flutterProjectName: flutterProjectName,
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
  await _runGit(
    target,
    ['remote', 'add', 'origin', 'https://example.invalid/product.git'],
  );
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

Future<List<String>> _gitStatusEntries(Directory repository) async {
  return (await _gitOutput(repository, ['status', '--short']))
      .split('\n')
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
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
    BootstrapExecutionPrepared _ => 'Prepared',
  };
}

final class _IntegrationFixture {
  const _IntegrationFixture(this.root, this.factory);

  final Directory root;
  final Directory factory;
}
