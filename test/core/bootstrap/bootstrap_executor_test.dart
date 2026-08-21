import 'dart:convert';
import 'dart:io';

import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_execution_result.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_execution_stop_reason.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_executor.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight_result.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_process_runner.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_request.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixtureRoot;
  late Directory factoryRoot;
  late FileSystemBootstrapPreflight preflight;

  setUp(() async {
    final created = await Directory.systemTemp.createTemp(
      'factory_bootstrap_executor_',
    );
    fixtureRoot = Directory(await created.resolveSymbolicLinks());
    factoryRoot = await Directory(
      path.join(fixtureRoot.path, 'factory'),
    ).create();
    await _runGit(factoryRoot, ['init', '--initial-branch=factory-main', '.']);
    preflight = FileSystemBootstrapPreflight(
      factoryRoot: factoryRoot,
      gitInspector: _FixtureGitInspector(),
    );
  });

  tearDown(() async {
    if (await fixtureRoot.exists()) {
      await fixtureRoot.delete(recursive: true);
    }
  });

  Future<BootstrapPreflightReady> newReady([String? outputPath]) async {
    final result = await preflight.inspect(
      _request(
        outputPath: outputPath ?? path.join(fixtureRoot.path, 'product'),
      ),
    );
    return result as BootstrapPreflightReady;
  }

  Future<BootstrapPreflightReady> existingReady(Directory target) async {
    final result = await preflight.inspect(
      _request(
        outputPath: target.path,
        repositoryMode: 'existingEmptyRepository',
        initialBranchName: null,
        repositoryPolicy: 'preserve existing policy',
      ),
    );
    return result as BootstrapPreflightReady;
  }

  FileSystemBootstrapExecutor executor({
    required BootstrapProcessRunner runner,
    BootstrapPreflight? selectedPreflight,
    BootstrapExecutionHook? hook,
    BootstrapInspectionHook? inspectionHook,
  }) {
    return FileSystemBootstrapExecutor(
      factoryRoot: factoryRoot,
      preflight: selectedPreflight ?? preflight,
      processRunner: runner,
      executionHook: hook,
      inspectionHook: inspectionHook,
    );
  }

  group('entry, revalidation, and toolchain', () {
    test('accepts only BootstrapPreflightReady at the type boundary', () {
      final BootstrapExecutor contract = executor(
        runner: _FakeProcessRunner(),
      );
      final Future<BootstrapExecutionResult> Function(BootstrapPreflightReady)
          execute = contract.execute;

      expect(
        execute,
        isA<
            Future<BootstrapExecutionResult> Function(
                BootstrapPreflightReady)>(),
      );
    });

    test('stops before toolchain or mutation when revalidation changes',
        () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner();
      final result = await executor(
        runner: runner,
        selectedPreflight: _FixedPreflight(
          BootstrapPreflightStopped(
            reasons: const [],
            notPerformed: const [],
          ),
        ),
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(stopped.category, BootstrapExecutionStopCategory.preflightChanged);
      expect(stopped.stage, BootstrapExecutionStage.preflightRevalidation);
      expect(runner.invocations, isEmpty);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('stops when revalidation returns a different Ready result', () async {
      final ready = await newReady();
      final differentReady = await newReady(
        path.join(fixtureRoot.path, 'different_product'),
      );
      final runner = _FakeProcessRunner();

      final result = await executor(
        runner: runner,
        selectedPreflight: _FixedPreflight(differentReady),
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(stopped.category, BootstrapExecutionStopCategory.preflightChanged);
      expect(stopped.stage, BootstrapExecutionStage.preflightRevalidation);
      expect(runner.invocations, isEmpty);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('stops when Git is unavailable', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(unavailableGit: true);

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.gitToolUnavailable,
      );
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('stops when Flutter is unavailable', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(unavailableFlutter: true);

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.flutterToolUnavailable,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('stops when Flutter create options are unsupported', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(createHelp: '--empty --platforms');

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.flutterCreateUnsupported,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });
  });

  group('New Repository mode', () {
    test('installs a neutral scaffold on the requested branch', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner();
      final factoryBefore = _snapshot(factoryRoot.path);

      final result = await executor(runner: runner).execute(ready);

      final completed = result as BootstrapExecutionPrepared;
      expect(completed.branch, 'main');
      expect(completed.headExists, isFalse);
      expect(completed.hasRemotes, isFalse);
      expect(completed.generatedPlatforms, {'ios', 'android'});
      expect(completed.rollbackRequired, isFalse);
      expect(completed.automatedTechnicalValidationStatus, 'Passed');
      expect(completed.userReadyApprovalStatus, 'Pending');
      expect(completed.firstAgreementApprovalStatus, 'Pending');
      expect(
        completed.productAuthorityEvidence.generatedPaths,
        ['README.md', 'AGENTS.md'],
      );
      expect(
          completed.productAuthorityEvidence.factoryReferenceRequired, isFalse);
      expect(completed.firstAgreementProposal.approvalStatus,
          'Proposed — User approval required');
      expect(completed.baselineHandoffProposal.proposalStatus, 'Proposed');
      expect(completed.baselineHandoffProposal.technicalValidationStatus,
          'Passed');
      expect(completed.baselineHandoffProposal.userApprovalStatus, 'Pending');
      expect(
        completed.baselineHandoffProposal.generatedProductAuthorityPaths,
        ['README.md', 'AGENTS.md'],
      );
      expect(
        await File(
          path.join(ready.normalizedOutputPath, 'README.md'),
        ).readAsString(),
        allOf(
          contains('Factory Validation App'),
          contains('Validate executable Bootstrap.'),
          contains('Prepare a neutral Flutter scaffold.'),
          contains('Product 기능 구현은 아직 시작되지 않았다'),
          contains('자동 기술 검증은 통과했다'),
          contains('User의 Ready 승인은 대기 중이다'),
          contains('첫 Agreement 승인은 대기 중이다'),
        ),
      );
      expect(
        await File(
          path.join(ready.normalizedOutputPath, 'AGENTS.md'),
        ).readAsString(),
        allOf(
          contains('저장소 정체성과 경계'),
          contains('Agreement 규칙'),
          contains('Approved Operational Baseline Handoff'),
        ),
      );
      expect(
        await File(
          path.join(ready.normalizedOutputPath, 'Agreement.md'),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          path.join(ready.normalizedOutputPath, 'Handoff.md'),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          path.join(
            ready.normalizedOutputPath,
            'test',
            'bootstrap_smoke_test.dart',
          ),
        ).readAsString(),
        allOf(
          contains("package:factory_validation_app/main.dart"),
          contains('const MainApp()'),
          contains('find.byType(MaterialApp)'),
          isNot(contains('Hello World!')),
        ),
      );
      expect(
        runner.invocations
            .singleWhere(
              (call) =>
                  call.arguments.firstOrNull == 'create' &&
                  call.arguments.contains('--empty'),
            )
            .arguments,
        [
          'create',
          '--empty',
          '--platforms=ios,android',
          '--project-name=factory_validation_app',
          '--org=com.example',
          '--no-pub',
          '.',
        ],
      );
      final validationInvocations = runner.invocations
          .where(
            (call) =>
                call.executable == 'flutter' &&
                const [
                  'pub get',
                  'analyze',
                  'test',
                  'build apk',
                  'build ios --simulator',
                ].contains(call.arguments.join(' ')),
          )
          .toList(growable: false);
      expect(
        validationInvocations.map((call) => call.arguments),
        [
          ['pub', 'get'],
          ['analyze'],
          ['test'],
          ['build', 'apk'],
          ['build', 'ios', '--simulator'],
        ],
      );
      expect(
        validationInvocations.map((call) => call.workingDirectory).toSet(),
        hasLength(1),
      );
      expect(
        path.basename(validationInvocations.first.workingDirectory),
        contains('.factory-bootstrap-'),
      );
      expect(
        completed.technicalValidationEvidence.completedCommands,
        hasLength(5),
      );
      expect(
        completed.technicalValidationEvidence.factoryRepositoryUnchangedStatus,
        'Confirmed',
      );
      expect(_ownedStaging(fixtureRoot), isEmpty);
      expect(_snapshot(factoryRoot.path), factoryBefore);
    });

    test('rolls back staging when scaffold generation fails', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(failFlutterCreate: true);

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.flutterScaffoldFailed,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('preserves external staging content added before ownership capture',
        () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.stagingCreation) {
            await File(path.join(stagingPath, 'external.txt'))
                .writeAsString('external');
            throw StateError('injected pre-ownership mutation');
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
        await File(path.join(partial.stagingPath!, 'external.txt'))
            .readAsString(),
        'external',
      );
      expect(partial.expectedManifest, isNot(contains('external.txt')));
      expect(partial.actualManifest, contains('external.txt'));
      expect(partial.ownershipDifferences, contains('added:external.txt'));
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('rejects content injected during the initial staging snapshot',
        () async {
      final ready = await newReady();
      var injected = false;

      final result = await executor(
        runner: _FakeProcessRunner(),
        inspectionHook: (operation, inspectionPath) async {
          if (!injected &&
              operation == 'directoryList' &&
              path.basename(inspectionPath).contains('.factory-bootstrap-')) {
            injected = true;
            await File(path.join(inspectionPath, 'external.txt'))
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
        await File(path.join(partial.stagingPath!, 'external.txt'))
            .readAsString(),
        'external',
      );
      expect(partial.expectedManifest.keys, ['.']);
      expect(partial.actualManifest, contains('external.txt'));
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('preserves staging changed by a failed scaffold process', () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(
          failFlutterCreate: true,
          writeExternalOnFailedCreate: true,
        ),
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
        partial.category,
        BootstrapExecutionStopCategory.ownershipMismatch,
      );
      expect(partial.stagingPath, isNotNull);
      expect(
        await File(path.join(partial.stagingPath!, 'external.txt'))
            .readAsString(),
        'external',
      );
      expect(partial.ownershipDifferences, contains('added:external.txt'));
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('rolls back staging when pub get fails', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(failPubGet: true);

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.dependencyPreparationFailed,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('preserves staging changed by a failed validation process', () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(
          failPubGet: true,
          writeExternalOnFailedPubGet: true,
        ),
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
        partial.category,
        BootstrapExecutionStopCategory.ownershipMismatch,
      );
      expect(partial.stagingPath, isNotNull);
      expect(
        await File(path.join(partial.stagingPath!, 'external.txt'))
            .readAsString(),
        'external',
      );
      expect(partial.ownershipDifferences, contains('added:external.txt'));
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('rolls back staging when git init fails', () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(failGitInit: true),
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(
        stopped.category,
        BootstrapExecutionStopCategory.repositoryInitializationFailed,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('stops when staging does not confirm the requested branch', () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(wrongStagingBranch: true),
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(
        stopped.category,
        BootstrapExecutionStopCategory.branchInitializationFailed,
      );
      expect(stopped.stage, BootstrapExecutionStage.branchInitialization);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('detects a final target race before install', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner();

      final result = await executor(
        runner: runner,
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.targetRevalidation) {
            await Directory(finalTargetPath).create();
          }
        },
      ).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.targetChangedBeforeInstall,
      );
      expect(_ownedStaging(fixtureRoot), isEmpty);
      expect(await Directory(ready.normalizedOutputPath).exists(), isTrue);
    });

    test('preserves an external symlink target that appears before install',
        () async {
      final ready = await newReady();
      final external = await Directory(
        path.join(fixtureRoot.path, 'external_target'),
      ).create();
      final marker = File(path.join(external.path, 'marker.txt'));
      await marker.writeAsString('external');

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.targetRevalidation) {
            await Link(finalTargetPath).create(external.path);
          }
        },
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(
        stopped.category,
        BootstrapExecutionStopCategory.targetChangedBeforeInstall,
      );
      expect(
        await FileSystemEntity.type(
          ready.normalizedOutputPath,
          followLinks: false,
        ),
        FileSystemEntityType.link,
      );
      expect(await marker.readAsString(), 'external');
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('does not leave a target when final verification fails', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(wrongFinalBranch: true);

      final result = await executor(runner: runner).execute(ready);

      expect(result, isA<BootstrapExecutionStopped>());
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('keeps target for inspection when staging changes after capture',
        () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.ownershipVerification) {
            await File(path.join(stagingPath, 'concurrent.txt'))
                .writeAsString('external');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.actualManifest, contains('concurrent.txt'));
      expect(partial.expectedManifest, isNot(contains('concurrent.txt')));
      expect(partial.ownershipDifferences, contains('added:concurrent.txt'));
      expect(partial.gitMetadataAffected, isFalse);
      expect(partial.pathsRequiringUserInspection,
          contains(ready.normalizedOutputPath));
      expect(await Directory(ready.normalizedOutputPath).exists(), isTrue);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test(
        'preserves an external staging entry when ownership hook adds it and fails',
        () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.ownershipVerification) {
            await File(path.join(stagingPath, 'external.txt'))
                .writeAsString('external');
            throw StateError('injected ownership hook failure');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.stagingPath, isNotNull);
      expect(
        await File(path.join(partial.stagingPath!, 'external.txt')).exists(),
        isTrue,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(partial.expectedManifest, isNot(contains('external.txt')));
      expect(partial.expectedManifest, contains('README.md'));
      expect(partial.expectedManifest, contains('AGENTS.md'));
      expect(partial.actualManifest, contains('external.txt'));
      expect(partial.ownershipDifferences, contains('added:external.txt'));
      expect(
        partial.pathsRequiringUserInspection,
        contains(partial.stagingPath),
      );
      expect(partial.gitMetadataAffected, isFalse);
    });

    test(
        'preserves an external staging entry when installation hook adds it and fails',
        () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.installation) {
            await File(path.join(stagingPath, 'external.txt'))
                .writeAsString('external');
            throw StateError('injected installation hook failure');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.stagingPath, isNotNull);
      expect(
        await File(path.join(partial.stagingPath!, 'external.txt')).exists(),
        isTrue,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(partial.ownershipDifferences, contains('added:external.txt'));
      expect(partial.gitMetadataAffected, isFalse);
    });

    test('cleans exact staging after an ownership hook failure', () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.ownershipVerification) {
            throw StateError('injected exact-manifest hook failure');
          }
        },
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(stopped.category, BootstrapExecutionStopCategory.installFailed);
      expect(stopped.targetUnchangedOrRestored, isTrue);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('preserves an external target created immediately before rename',
        () async {
      final ready = await newReady();
      final marker = File(
        path.join(ready.normalizedOutputPath, 'external.txt'),
      );

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.installation) {
            await marker.parent.create();
            await marker.writeAsString('external target');
          }
        },
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(stopped.category, BootstrapExecutionStopCategory.installFailed);
      expect(stopped.targetUnchangedOrRestored, isFalse);
      expect(await marker.readAsString(), 'external target');
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('preserves staging when guarded cleanup inspection fails', () async {
      final ready = await newReady();
      var cleanupStarted = false;

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.ownershipVerification) {
            cleanupStarted = true;
            throw StateError('trigger guarded cleanup');
          }
        },
        inspectionHook: (operation, inspectionPath) async {
          if (cleanupStarted &&
              operation == 'directoryList' &&
              path.basename(inspectionPath).contains(
                    '.factory-bootstrap-',
                  )) {
            throw FileSystemException(
              'injected guarded cleanup inspection failure',
              inspectionPath,
            );
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.failure, contains('Failed operation: directoryList'));
      expect(partial.stagingPath, isNotNull);
      expect(await Directory(partial.stagingPath!).exists(), isTrue);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(partial.gitMetadataAffected, isTrue);
    });

    test('detects missing modified and symlinked final manifest entries',
        () async {
      for (final mutation in ['missing', 'modified', 'symlink']) {
        final ready = await newReady(
          path.join(fixtureRoot.path, 'product_$mutation'),
        );
        final result = await executor(
          runner: _FakeProcessRunner(),
          hook: (stage,
              {required stagingPath, required finalTargetPath}) async {
            if (stage != BootstrapExecutionStage.finalVerification) {
              return;
            }
            final readme = File(path.join(finalTargetPath, 'README.md'));
            if (mutation == 'missing') {
              await readme.delete();
            } else if (mutation == 'modified') {
              await readme.writeAsString('concurrent');
            } else {
              await readme.delete();
              await Link(readme.path).create('pubspec.yaml');
            }
          },
        ).execute(ready);

        final partial = result as BootstrapExecutionPartialFailure;
        expect(
          partial.category,
          BootstrapExecutionStopCategory.ownershipMismatch,
          reason: mutation,
        );
        expect(
          partial.ownershipDifferences,
          contains(
            mutation == 'missing' ? 'deleted:README.md' : 'changed:README.md',
          ),
          reason: mutation,
        );
        expect(partial.gitMetadataAffected, isFalse, reason: mutation);
        expect(await Directory(ready.normalizedOutputPath).exists(), isTrue);
      }
    });

    test('derives Git metadata impact from exact manifest differences',
        () async {
      final cases = <String, bool>{
        'readme': false,
        'lib_deleted': false,
        'git_head': true,
        'git_entry_deleted': true,
        'git_symlink': true,
        'snapshot_unavailable': true,
      };

      for (final entry in cases.entries) {
        final ready = await newReady(
          path.join(fixtureRoot.path, 'impact_${entry.key}'),
        );
        final result = await executor(
          runner: _FakeProcessRunner(),
          hook: (stage,
              {required stagingPath, required finalTargetPath}) async {
            if (stage != BootstrapExecutionStage.finalVerification) {
              return;
            }
            switch (entry.key) {
              case 'readme':
                await File(path.join(finalTargetPath, 'README.md'))
                    .writeAsString('changed');
              case 'lib_deleted':
                await File(path.join(finalTargetPath, 'lib', 'main.dart'))
                    .delete();
              case 'git_head':
                await File(path.join(finalTargetPath, '.git', 'HEAD'))
                    .writeAsString('ref: refs/heads/changed\n');
              case 'git_entry_deleted':
                await File(path.join(finalTargetPath, '.git', 'config'))
                    .delete();
              case 'git_symlink':
                final git = Directory(path.join(finalTargetPath, '.git'));
                final movedGit =
                    await git.rename(path.join(finalTargetPath, '.git-owned'));
                await Link(git.path).create(path.basename(movedGit.path));
              case 'snapshot_unavailable':
                await Directory(finalTargetPath).delete(recursive: true);
            }
          },
        ).execute(ready);

        final partial = result as BootstrapExecutionPartialFailure;
        expect(
          partial.category,
          BootstrapExecutionStopCategory.ownershipMismatch,
          reason: entry.key,
        );
        expect(
          partial.gitMetadataAffected,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test(
        'derives non-Git impact from a Product-file change after final verification fails',
        () async {
      final ready = await newReady();
      var mutated = false;

      final result = await executor(
        runner: _FakeProcessRunner(wrongFinalBranch: true),
        inspectionHook: (operation, inspectionPath) async {
          final finalGitPath = path.join(ready.normalizedOutputPath, '.git');
          if (!mutated &&
              operation == 'directoryList' &&
              path.equals(inspectionPath, finalGitPath)) {
            mutated = true;
            await File(
              path.join(ready.normalizedOutputPath, 'README.md'),
            ).writeAsString('changed after final verification started');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.gitMetadataAffected, isFalse);
      expect(partial.ownershipDifferences, contains('changed:README.md'));
      expect(await Directory(ready.normalizedOutputPath).exists(), isTrue);
    });

    test('derives Git impact from a .git/HEAD change after final failure',
        () async {
      final ready = await newReady();
      var mutated = false;

      final result = await executor(
        runner: _FakeProcessRunner(wrongFinalBranch: true),
        inspectionHook: (operation, inspectionPath) async {
          final finalGitPath = path.join(ready.normalizedOutputPath, '.git');
          if (!mutated &&
              operation == 'directoryList' &&
              path.equals(inspectionPath, finalGitPath)) {
            mutated = true;
            await File(path.join(finalGitPath, 'HEAD'))
                .writeAsString('ref: refs/heads/changed\n');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.gitMetadataAffected, isTrue);
      expect(partial.ownershipDifferences, contains('changed:.git/HEAD'));
      expect(await Directory(ready.normalizedOutputPath).exists(), isTrue);
    });

    test('preserves target when its post-failure snapshot cannot be inspected',
        () async {
      final ready = await newReady();
      var targetListings = 0;

      final result = await executor(
        runner: _FakeProcessRunner(wrongFinalBranch: true),
        inspectionHook: (operation, inspectionPath) async {
          if (operation == 'directoryList' &&
              path.equals(inspectionPath, ready.normalizedOutputPath) &&
              ++targetListings == 2) {
            throw FileSystemException(
              'injected target snapshot failure',
              inspectionPath,
            );
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.gitMetadataAffected, isTrue);
      expect(partial.failure, contains('directoryList'));
      expect(partial.failure, contains(ready.normalizedOutputPath));
      expect(await Directory(ready.normalizedOutputPath).exists(), isTrue);
    });

    test('rejects non-neutral or unsupported generated scaffold content',
        () async {
      final cases = <String, _FakeProcessRunner>{
        'counter sample': _FakeProcessRunner(counterSample: true),
        'unsupported platform': _FakeProcessRunner(
          unsupportedPlatform: true,
        ),
        'Product-specific dependency': _FakeProcessRunner(
          productDependency: true,
        ),
        'missing flutter_test': _FakeProcessRunner(
          omitFlutterTest: true,
        ),
      };

      for (final entry in cases.entries) {
        final ready = await newReady();
        final result = await executor(runner: entry.value).execute(ready);

        expect(
          result,
          isA<BootstrapExecutionStopped>(),
          reason: entry.key,
        );
        expect(
          (result as BootstrapExecutionStopped).category,
          BootstrapExecutionStopCategory.scaffoldVerificationFailed,
          reason: entry.key,
        );
        expect(
          await Directory(ready.normalizedOutputPath).exists(),
          isFalse,
          reason: entry.key,
        );
        expect(_ownedStaging(fixtureRoot), isEmpty, reason: entry.key);
      }
    });
  });

  group('automated technical validation', () {
    final failureCases = <({
      String name,
      _FakeProcessRunner Function() runner,
      BootstrapExecutionStopCategory category,
      List<String> failedArguments,
    })>[
      (
        name: 'static analysis',
        runner: () => _FakeProcessRunner(failAnalyze: true),
        category: BootstrapExecutionStopCategory.staticAnalysisFailed,
        failedArguments: ['analyze'],
      ),
      (
        name: 'default tests',
        runner: () => _FakeProcessRunner(failDefaultTests: true),
        category: BootstrapExecutionStopCategory.defaultTestsFailed,
        failedArguments: ['test'],
      ),
      (
        name: 'Android APK build',
        runner: () => _FakeProcessRunner(failAndroidBuild: true),
        category: BootstrapExecutionStopCategory.androidApkBuildFailed,
        failedArguments: ['build', 'apk'],
      ),
      (
        name: 'iOS Simulator build',
        runner: () => _FakeProcessRunner(failIosBuild: true),
        category: BootstrapExecutionStopCategory.iosSimulatorBuildFailed,
        failedArguments: ['build', 'ios', '--simulator'],
      ),
    ];

    for (final failureCase in failureCases) {
      test('${failureCase.name} failure stops before New installation',
          () async {
        final ready = await newReady(
          path.join(
            fixtureRoot.path,
            'validation_${failureCase.name.replaceAll(' ', '_')}',
          ),
        );
        final runner = failureCase.runner();

        final result = await executor(runner: runner).execute(ready);

        final stopped = result as BootstrapExecutionStopped;
        expect(stopped.category, failureCase.category);
        expect(stopped.failedCommand?.arguments, failureCase.failedArguments);
        expect(
          stopped.confirmedFacts.join('\n'),
          contains('Completed validation steps:'),
        );
        expect(
          stopped.evidence.join('\n'),
          allOf(
            contains('Failed executable: flutter'),
            contains('Working directory:'),
            contains('Exit code:'),
          ),
        );
        expect(
          stopped.notPerformed,
          contains('Final Product installation was not performed.'),
        );
        expect(stopped.targetUnchangedOrRestored, isTrue);
        expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
        expect(_ownedStaging(fixtureRoot), isEmpty);
        final failedIndex = runner.invocations.indexWhere(
          (call) =>
              call.arguments.join('\u0000') ==
              failureCase.failedArguments.join('\u0000'),
        );
        expect(failedIndex, greaterThanOrEqualTo(0));
        expect(
          runner.invocations.skip(failedIndex + 1).where(
                (call) =>
                    call.executable == 'flutter' &&
                    const [
                      'analyze',
                      'test',
                      'build apk',
                      'build ios --simulator',
                    ].contains(call.arguments.join(' ')),
              ),
          isEmpty,
        );
      });
    }

    test('reports a validation process start failure structurally', () async {
      final ready = await newReady();
      final result = await executor(
        runner: _FakeProcessRunner(validationProcessStartFailure: true),
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(
        stopped.category,
        BootstrapExecutionStopCategory.validationProcessStartFailed,
      );
      expect(stopped.stage, BootstrapExecutionStage.staticAnalysis);
      expect(stopped.failedCommand?.didStart, isFalse);
      expect(stopped.failedCommand?.exitCode, isNull);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('preserves unknown staging content after validation failure',
        () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(failAnalyze: true),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.ownershipVerification) {
            await File(
              path.join(stagingPath, 'external-after-validation.txt'),
            ).writeAsString('external');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.stage, BootstrapExecutionStage.staticAnalysis);
      expect(partial.stagingPath, isNotNull);
      expect(await Directory(partial.stagingPath!).exists(), isTrue);
      expect(
        await File(
          path.join(partial.stagingPath!, 'external-after-validation.txt'),
        ).readAsString(),
        'external',
      );
      final preservedReadme = await File(
        path.join(partial.stagingPath!, 'README.md'),
      ).readAsString();
      expect(
        preservedReadme,
        isNot(contains('자동 기술 검증은 통과했다')),
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('preserves staging and blocks Prepared when Factory changes',
        () async {
      final ready = await newReady();
      var changed = false;

      final result = await executor(
        runner: _FakeProcessRunner(useSystemGit: true),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.factoryBaselineVerification &&
              !changed) {
            changed = true;
            await File(
              path.join(factoryRoot.path, 'unexpected-factory-change.txt'),
            ).writeAsString('changed');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
        partial.category,
        BootstrapExecutionStopCategory.factoryRepositoryChanged,
      );
      expect(
        partial.stage,
        BootstrapExecutionStage.factoryBaselineVerification,
      );
      expect(partial.stagingPath, isNotNull);
      expect(await Directory(partial.stagingPath!).exists(), isTrue);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });
  });

  group('Product authority write safety', () {
    test('rejects README symlink and preserves its external target', () async {
      final ready = await newReady();
      final external = File(path.join(fixtureRoot.path, 'external_readme.txt'));
      await external.writeAsString('external');

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.smokeTestGeneration) {
            final readme = File(path.join(stagingPath, 'README.md'));
            await readme.delete();
            await Link(readme.path).create(external.path);
          }
        },
      ).execute(ready);

      expect(result, isA<BootstrapExecutionStopped>());
      expect(await external.readAsString(), 'external');
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('rejects README with a non-file type', () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.smokeTestGeneration) {
            final readme = File(path.join(stagingPath, 'README.md'));
            await readme.delete();
            await Directory(readme.path).create();
          }
        },
      ).execute(ready);

      expect(result, isA<BootstrapExecutionStopped>());
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('rejects pre-existing AGENTS file directory and symlink', () async {
      for (final type in ['file', 'directory', 'symlink']) {
        final ready = await newReady(
          path.join(fixtureRoot.path, 'agents_$type'),
        );
        final external = File(
          path.join(fixtureRoot.path, 'agents_external_$type.txt'),
        );
        await external.writeAsString('external');

        final result = await executor(
          runner: _FakeProcessRunner(),
          hook: (stage,
              {required stagingPath, required finalTargetPath}) async {
            if (stage != BootstrapExecutionStage.smokeTestGeneration) {
              return;
            }
            final agentsPath = path.join(stagingPath, 'AGENTS.md');
            if (type == 'file') {
              await File(agentsPath).writeAsString('unexpected');
            } else if (type == 'directory') {
              await Directory(agentsPath).create();
            } else {
              await Link(agentsPath).create(external.path);
            }
          },
        ).execute(ready);

        expect(result, isA<BootstrapExecutionStopped>(), reason: type);
        expect(await external.readAsString(), 'external', reason: type);
        expect(
          await Directory(ready.normalizedOutputPath).exists(),
          isFalse,
          reason: type,
        );
        expect(_ownedStaging(fixtureRoot), isEmpty, reason: type);
      }
    });

    test('leaves Product target unchanged when authority write fails',
        () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        inspectionHook: (operation, inspectionPath) async {
          if (operation == 'entityType' &&
              path.basename(inspectionPath) ==
                  '.README.md.factory-authority.backup') {
            await Directory(
              path.join(
                path.dirname(inspectionPath),
                '.README.md.factory-authority.tmp',
              ),
            ).create();
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
        partial.category,
        BootstrapExecutionStopCategory.ownershipMismatch,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(partial.stagingPath, isNotNull);
      expect(
        await Directory(
          path.join(
            partial.stagingPath!,
            '.README.md.factory-authority.tmp',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        partial.ownershipDifferences,
        contains('added:.README.md.factory-authority.tmp'),
      );
    });
  });

  group('smoke test generation', () {
    test('does not overwrite a generated smoke test path', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(precreateSmokeTest: true);

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.smokeTestConflict,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('reports smoke test filesystem generation failure safely', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(blockTestDirectory: true);

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.smokeTestGenerationFailed,
      );
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('rejects a scaffold without the MainApp contract', () async {
      final ready = await newReady();
      final runner = _FakeProcessRunner(missingMainApp: true);

      final result = await executor(runner: runner).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.smokeTestUnsupported,
      );
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });
  });

  group('Existing Empty Repository mode', () {
    test('installs without git init and preserves Git metadata', () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
        branch: 'stable',
      );
      final gitBefore = _snapshot(path.join(target.path, '.git'));
      final ready = await existingReady(target);
      final runner = _FakeProcessRunner();

      final result = await executor(runner: runner).execute(ready);

      final completed = result as BootstrapExecutionPrepared;
      expect(completed.branch, 'stable');
      expect(completed.headExists, isFalse);
      expect(completed.hasRemotes, isFalse);
      expect(_snapshot(path.join(target.path, '.git')), gitBefore);
      expect(
        runner.invocations.where(
          (call) => call.executable == 'git' && call.arguments.first == 'init',
        ),
        isEmpty,
      );
      expect(
        await File(
          path.join(target.path, 'test', 'bootstrap_smoke_test.dart'),
        ).exists(),
        isTrue,
      );
      expect(await File(path.join(target.path, 'README.md')).exists(), isTrue);
      expect(await File(path.join(target.path, 'AGENTS.md')).exists(), isTrue);
      expect(
        completed.baselineHandoffProposal.generatedProductAuthorityPaths,
        ['README.md', 'AGENTS.md'],
      );
      expect(completed.baselineHandoffProposal.branch, 'stable');
      expect(completed.baselineHandoffProposal.proposalStatus, 'Proposed');
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('scaffold failure leaves the Existing Repository unchanged', () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final before = _snapshot(target.path);
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(failFlutterCreate: true),
      ).execute(ready);

      expect(result, isA<BootstrapExecutionStopped>());
      expect(_snapshot(target.path), before);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('pub get failure leaves the Existing Repository unchanged', () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final before = _snapshot(target.path);
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(failPubGet: true),
      ).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.dependencyPreparationFailed,
      );
      expect(_snapshot(target.path), before);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('validation failure leaves Existing files and Git state unchanged',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_validation_failure',
      );
      final before = _snapshot(target.path);
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(failAndroidBuild: true),
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(
        stopped.category,
        BootstrapExecutionStopCategory.androidApkBuildFailed,
      );
      expect(stopped.targetUnchangedOrRestored, isTrue);
      expect(_snapshot(target.path), before);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('smoke failure leaves the Existing Repository unchanged', () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final before = _snapshot(target.path);
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(precreateSmokeTest: true),
      ).execute(ready);

      expect(
        (result as BootstrapExecutionStopped).category,
        BootstrapExecutionStopCategory.smokeTestConflict,
      );
      expect(_snapshot(target.path), before);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('preserves real branch, HEAD, remote, status, index, and config',
        () async {
      final target = await _realRepositoryWithHistory(
        fixtureRoot,
        'existing_product',
      );
      final ready = await existingReady(target);
      final branchBefore = await _gitOutput(target, [
        'symbolic-ref',
        '--short',
        'HEAD',
      ]);
      final headBefore = await _gitOutput(target, ['rev-parse', 'HEAD']);
      final remotesBefore = await _gitOutput(target, ['remote', '-v']);
      final statusBefore = await _gitOutput(target, ['status', '--short']);
      final gitBefore = _snapshot(path.join(target.path, '.git'));
      final configBefore =
          await File(path.join(target.path, '.git', 'config')).readAsBytes();
      final indexBefore =
          await File(path.join(target.path, '.git', 'index')).readAsBytes();
      final runner = _FakeProcessRunner(useSystemGit: true);

      final result = await executor(runner: runner).execute(ready);

      final completed = result as BootstrapExecutionPrepared;
      expect(completed.branch, branchBefore.trim());
      expect(completed.headExists, isTrue);
      expect(completed.hasRemotes, isTrue);
      expect(await _gitOutput(target, ['rev-parse', 'HEAD']), headBefore);
      expect(await _gitOutput(target, ['remote', '-v']), remotesBefore);
      final statusAfter = await _gitOutput(target, ['status', '--short']);
      expect(statusAfter, contains(statusBefore.trim()));
      final baselineStatusLines = const LineSplitter()
          .convert(statusBefore)
          .where((line) => line.isNotEmpty)
          .toSet();
      expect(
        const LineSplitter()
            .convert(statusAfter)
            .where((line) => line.isNotEmpty)
            .where((line) => !baselineStatusLines.contains(line)),
        everyElement(startsWith('?? ')),
      );
      expect(
        await File(path.join(target.path, '.git', 'config')).readAsBytes(),
        configBefore,
      );
      expect(
        await File(path.join(target.path, '.git', 'index')).readAsBytes(),
        indexBefore,
      );
      expect(_snapshot(path.join(target.path, '.git')), gitBefore);
      expect(
        runner.invocations.where(
          (call) => call.executable == 'git' && call.arguments.first == 'init',
        ),
        isEmpty,
      );
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('reports PartialFailure when an external root entry remains',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final gitBefore = _snapshot(path.join(target.path, '.git'));
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.installation) {
            await Directory(path.join(finalTargetPath, 'lib')).create();
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.rollbackFailed, contains(target.path));
      expect(_snapshot(path.join(target.path, '.git')), gitBefore);
      expect(await Directory(path.join(target.path, 'lib')).exists(), isTrue);
      expect(
          await File(path.join(target.path, '.gitignore')).exists(), isFalse);
      expect(
          await Directory(path.join(target.path, 'android')).exists(), isFalse);
      expect(_ownedStaging(fixtureRoot), isNotEmpty);
    });

    test('stops before install when the Existing root becomes a symlink',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_install_symlink',
      );
      final displacedPath = '${target.path}-displaced';
      final external = await Directory(
        path.join(fixtureRoot.path, 'external_install_target'),
      ).create();
      final marker = File(path.join(external.path, 'marker.txt'));
      await marker.writeAsString('external');
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.installation) {
            await Directory(finalTargetPath).rename(displacedPath);
            await Link(finalTargetPath).create(external.path);
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
        partial.category,
        BootstrapExecutionStopCategory.ownershipMismatch,
      );
      expect(partial.stage, BootstrapExecutionStage.installation);
      expect(await marker.readAsString(), 'external');
      expect(await Directory(displacedPath).exists(), isTrue);
      expect(
        await FileSystemEntity.type(target.path, followLinks: false),
        FileSystemEntityType.link,
      );
      expect(partial.stagingPath, isNotNull);
    });

    test('preserves staging when it changes before Product installation',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final productBefore = _snapshot(target.path);
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.installation) {
            await File(path.join(stagingPath, 'external.txt'))
                .writeAsString('external');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.stagingPath, isNotNull);
      expect(
        await File(path.join(partial.stagingPath!, 'external.txt')).exists(),
        isTrue,
      );
      expect(partial.expectedManifest, isNot(contains('external.txt')));
      expect(partial.actualManifest, contains('external.txt'));
      expect(partial.ownershipDifferences, contains('added:external.txt'));
      expect(
          partial.pathsRequiringUserInspection, contains(partial.stagingPath));
      expect(partial.gitMetadataAffected, isFalse);
      expect(_snapshot(target.path), productBefore);
    });

    test('preserves unknown staging content after Product rollback', () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final productBefore = _snapshot(target.path);
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
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
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.stagingPath, isNotNull);
      expect(
        await File(path.join(partial.stagingPath!, 'external.txt')).exists(),
        isTrue,
      );
      expect(partial.expectedManifest, isNot(contains('external.txt')));
      expect(partial.actualManifest, contains('external.txt'));
      expect(partial.ownershipDifferences, contains('added:external.txt'));
      expect(
          partial.pathsRequiringUserInspection, contains(partial.stagingPath));
      expect(partial.gitMetadataAffected, isFalse);
      expect(_snapshot(target.path), productBefore);
      expect(result, isNot(isA<BootstrapExecutionStopped>()));
    });

    test('stops rollback when the Existing root becomes a symlink', () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_rollback_symlink',
      );
      final displacedPath = '${target.path}-displaced';
      final external = await Directory(
        path.join(fixtureRoot.path, 'external_rollback_target'),
      ).create();
      final marker = File(path.join(external.path, 'marker.txt'));
      await marker.writeAsString('external');
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.finalVerification) {
            throw StateError('trigger rollback root replacement');
          }
          if (stage == BootstrapExecutionStage.rollback) {
            await Directory(finalTargetPath).rename(displacedPath);
            await Link(finalTargetPath).create(external.path);
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
        partial.category,
        BootstrapExecutionStopCategory.ownershipMismatch,
      );
      expect(partial.stage, BootstrapExecutionStage.rollback);
      expect(await marker.readAsString(), 'external');
      expect(await Directory(displacedPath).exists(), isTrue);
      expect(
        await FileSystemEntity.type(target.path, followLinks: false),
        FileSystemEntityType.link,
      );
      expect(partial.stagingPath, isNotNull);
    });

    test('preserves staging changed immediately before rollback cleanup',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_cleanup_race',
      );
      final ready = await existingReady(target);
      var rollbackStarted = false;
      String? rollbackStagingPath;
      var stagingLists = 0;

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.finalVerification) {
            throw StateError('trigger guarded rollback cleanup');
          }
          if (stage == BootstrapExecutionStage.rollback) {
            rollbackStarted = true;
            rollbackStagingPath = stagingPath;
          }
        },
        inspectionHook: (operation, inspectionPath) async {
          if (rollbackStarted &&
              rollbackStagingPath != null &&
              operation == 'directoryList' &&
              path.equals(inspectionPath, rollbackStagingPath!)) {
            stagingLists += 1;
            if (stagingLists == 2) {
              await File(path.join(inspectionPath, 'external.txt'))
                  .writeAsString('external');
            }
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
        await File(path.join(partial.stagingPath!, 'external.txt'))
            .readAsString(),
        'external',
      );
      expect(partial.ownershipDifferences, contains('added:external.txt'));
    });

    test('returns Stopped only after complete rollback restoration', () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final before = _snapshot(target.path);
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          final conflict = Directory(path.join(finalTargetPath, 'lib'));
          if (stage == BootstrapExecutionStage.installation) {
            await conflict.create();
          }
          if (stage == BootstrapExecutionStage.rollback &&
              await conflict.exists()) {
            await conflict.delete();
          }
        },
      ).execute(ready);

      final stopped = result as BootstrapExecutionStopped;
      expect(stopped.category, BootstrapExecutionStopCategory.installFailed);
      expect(stopped.targetUnchangedOrRestored, isTrue);
      expect(_snapshot(target.path), before);
      expect(_ownedStaging(fixtureRoot), isEmpty);
    });

    test('detects concurrent root, generated-path, and file mutations',
        () async {
      for (final mutation in ['root', 'inside', 'modified']) {
        final target = await _existingRepository(
          fixtureRoot,
          'existing_$mutation',
        );
        final ready = await existingReady(target);

        final result = await executor(
          runner: _FakeProcessRunner(),
          hook: (stage,
              {required stagingPath, required finalTargetPath}) async {
            if (stage != BootstrapExecutionStage.finalVerification) {
              return;
            }
            if (mutation == 'root') {
              await File(path.join(finalTargetPath, 'external.txt'))
                  .writeAsString('external');
            } else if (mutation == 'inside') {
              await File(path.join(finalTargetPath, 'lib', 'external.dart'))
                  .writeAsString('external');
            } else {
              await File(path.join(finalTargetPath, 'pubspec.yaml'))
                  .writeAsString('changed');
            }
          },
        ).execute(ready);

        expect(
          result,
          isA<BootstrapExecutionPartialFailure>(),
          reason: mutation,
        );
        final partial = result as BootstrapExecutionPartialFailure;
        expect(partial.pathsRequiringUserInspection, contains(target.path));
        if (mutation == 'root') {
          expect(
            await File(path.join(target.path, 'external.txt')).exists(),
            isTrue,
          );
        }
      }
    });

    test('stops before mutation for tracked root and nested path collisions',
        () async {
      for (final trackedPath in [
        'README.md',
        'AGENTS.md',
        'lib/legacy.dart',
      ]) {
        final target = await _realRepositoryWithTrackedDeletion(
          fixtureRoot,
          'tracked_${trackedPath.replaceAll('/', '_')}',
          trackedPath,
        );
        final ready = await existingReady(target);
        final before = _snapshot(target.path);
        final statusBefore = await _gitOutput(target, ['status', '--short']);

        final result = await executor(
          runner: _FakeProcessRunner(useSystemGit: true),
        ).execute(ready);

        expect(result, isA<BootstrapExecutionStopped>(), reason: trackedPath);
        final stopped = result as BootstrapExecutionStopped;
        expect(
          stopped.category,
          BootstrapExecutionStopCategory.trackedPathConflict,
          reason: trackedPath,
        );
        expect(
          stopped.evidence.join('\n'),
          contains(trackedPath),
          reason: trackedPath,
        );
        expect(_snapshot(target.path), before);
        expect(
          await _gitOutput(target, ['status', '--short']),
          statusBefore,
        );
        expect(_ownedStaging(fixtureRoot), isEmpty);
      }
    });

    test('reports PartialFailure when safe rollback cannot be proven',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_product',
      );
      final ready = await existingReady(target);

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.installation) {
            await Directory(path.join(finalTargetPath, 'lib')).create();
          }
          if (stage == BootstrapExecutionStage.rollback) {
            throw StateError('simulated concurrent rollback mutation');
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(
          partial.category, BootstrapExecutionStopCategory.ownershipMismatch);
      expect(partial.rollbackFailed, isNotEmpty);
      expect(partial.pathsRequiringUserInspection, contains(target.path));
      expect(
        () => partial.createdOrMovedEntries.add('unexpected'),
        throwsUnsupportedError,
      );
      expect(
        () => partial.rollbackSucceeded.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => partial.rollbackFailed.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => partial.pathsRequiringUserInspection.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => partial.cleanupNotPerformed.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => partial.commandsCompleted.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => partial.expectedManifest['bad'] = 'bad',
        throwsUnsupportedError,
      );
      expect(
        () => partial.actualManifest.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => partial.ownershipDifferences.add('bad'),
        throwsUnsupportedError,
      );
    });
  });

  group('filesystem inspection containment', () {
    test('contains a directory-list failure before Product mutation', () async {
      final ready = await newReady();

      final result = await executor(
        runner: _FakeProcessRunner(),
        inspectionHook: (operation, inspectionPath) async {
          if (operation == 'directoryList' &&
              path.basename(inspectionPath).contains(
                    '.factory-bootstrap-',
                  )) {
            throw FileSystemException(
              'injected directory listing failure',
              inspectionPath,
            );
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.failure, contains('Failed operation: directoryList'));
      expect(partial.failure, contains('Product mutation started: false'));
      expect(partial.stagingPath, isNotNull);
      expect(await Directory(partial.stagingPath!).exists(), isTrue);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('contains a file-read failure during New final verification',
        () async {
      final ready = await newReady();
      final readmePath = path.join(ready.normalizedOutputPath, 'README.md');

      final result = await executor(
        runner: _FakeProcessRunner(),
        inspectionHook: (operation, inspectionPath) async {
          if (operation == 'fileRead' &&
              path.equals(inspectionPath, readmePath)) {
            throw FileSystemException(
              'injected file read failure',
              inspectionPath,
            );
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.failure, contains('Failed operation: fileRead'));
      expect(partial.failure, contains('Product mutation started: true'));
      expect(partial.pathsRequiringUserInspection, contains(readmePath));
      expect(await Directory(ready.normalizedOutputPath).exists(), isTrue);
    });

    test('contains a link-target failure and preserves unknown staging',
        () async {
      final ready = await newReady();
      String? linkPath;

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.stagingCreation) {
            linkPath = path.join(stagingPath, 'ownership-link');
            await Link(linkPath!).create('README.md');
          }
        },
        inspectionHook: (operation, inspectionPath) async {
          if (operation == 'linkTarget' &&
              linkPath != null &&
              path.equals(inspectionPath, linkPath!)) {
            throw FileSystemException(
              'injected link target failure',
              inspectionPath,
            );
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.failure, contains('Failed operation: linkTarget'));
      expect(partial.failure, contains('Product mutation started: false'));
      expect(partial.stagingPath, isNotNull);
      expect(await Link(linkPath!).exists(), isTrue);
      expect(await Directory(ready.normalizedOutputPath).exists(), isFalse);
    });

    test('contains an entity-type failure during Existing pre-install',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_inspection_preinstall',
      );
      final before = _snapshot(target.path);
      final ready = await existingReady(target);
      var installationStarted = false;

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          if (stage == BootstrapExecutionStage.installation) {
            installationStarted = true;
          }
        },
        inspectionHook: (operation, inspectionPath) async {
          if (installationStarted &&
              operation == 'entityType' &&
              path.basename(inspectionPath).contains(
                    '.factory-bootstrap-',
                  )) {
            throw FileSystemException(
              'injected entity type failure',
              inspectionPath,
            );
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.failure, contains('Failed operation: entityType'));
      expect(partial.failure, contains('Product mutation started: false'));
      expect(partial.gitMetadataAffected, isFalse);
      expect(partial.stagingPath, isNotNull);
      expect(await Directory(partial.stagingPath!).exists(), isTrue);
      expect(_snapshot(target.path), before);
    });

    test('contains a directory-list failure during Existing rollback',
        () async {
      final target = await _existingRepository(
        fixtureRoot,
        'existing_inspection_rollback',
      );
      final ready = await existingReady(target);
      var rollbackStarted = false;

      final result = await executor(
        runner: _FakeProcessRunner(),
        hook: (stage, {required stagingPath, required finalTargetPath}) async {
          final conflict = Directory(path.join(finalTargetPath, 'lib'));
          if (stage == BootstrapExecutionStage.installation) {
            await conflict.create();
          }
          if (stage == BootstrapExecutionStage.rollback) {
            rollbackStarted = true;
            if (await conflict.exists()) {
              await conflict.delete();
            }
          }
        },
        inspectionHook: (operation, inspectionPath) async {
          if (rollbackStarted &&
              operation == 'directoryList' &&
              path.basename(inspectionPath).contains(
                    '.factory-bootstrap-',
                  )) {
            throw FileSystemException(
              'injected rollback listing failure',
              inspectionPath,
            );
          }
        },
      ).execute(ready);

      final partial = result as BootstrapExecutionPartialFailure;
      expect(partial.stage, BootstrapExecutionStage.rollback);
      expect(partial.failure, contains('Failed operation: directoryList'));
      expect(partial.failure, contains('Product mutation started: true'));
      expect(partial.stagingPath, isNotNull);
      expect(await Directory(partial.stagingPath!).exists(), isTrue);
    });
  });

  group('structured result evidence', () {
    test('exposes immutable Prepared collections and stable command evidence',
        () async {
      final ready = await newReady();
      final result = await executor(
        runner: _FakeProcessRunner(),
      ).execute(ready) as BootstrapExecutionPrepared;

      expect(
        () => result.createdRootEntries.add('unexpected'),
        throwsUnsupportedError,
      );
      expect(
        () => result.generatedPlatforms.add('web'),
        throwsUnsupportedError,
      );
      expect(
        () => result.productAuthorityEvidence.generatedPaths.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => result.firstAgreementProposal.openQuestions.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => result.baselineHandoffProposal.gitStatusEntries.clear(),
        throwsUnsupportedError,
      );
      expect(result.automatedTechnicalValidationStatus, 'Passed');
      expect(result.userReadyApprovalStatus, 'Pending');
      expect(result.firstAgreementApprovalStatus, 'Pending');
      expect(
        result.technicalValidationEvidence.completedCommands,
        hasLength(5),
      );
      expect(
        () => result.technicalValidationEvidence.completedCommands.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => result.technicalValidationEvidence.factoryStatusEntries
            .add('approved'),
        throwsUnsupportedError,
      );
      expect(
        () => result.commandsCompleted.add(
          BootstrapProcessResult(
            executable: 'bad',
            arguments: const [],
            workingDirectory: fixtureRoot.path,
            exitCode: 0,
            stdout: '',
            stderr: '',
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        result.commandsCompleted,
        contains(
          isA<BootstrapProcessResult>().having(
            (command) => command.arguments,
            'arguments',
            containsAllInOrder(['create', '--empty']),
          ),
        ),
      );
    });

    test('exposes immutable Stop evidence', () async {
      final ready = await newReady();
      final result = await executor(
        runner: _FakeProcessRunner(unavailableGit: true),
      ).execute(ready) as BootstrapExecutionStopped;

      expect(() => result.evidence.add('bad'), throwsUnsupportedError);
      expect(() => result.notPerformed.clear(), throwsUnsupportedError);
      expect(result.category.name, 'gitToolUnavailable');
    });
  });
}

BootstrapRequest _request({
  required String outputPath,
  String repositoryMode = 'newRepository',
  String? initialBranchName = 'main',
  String? repositoryPolicy,
}) {
  return BootstrapRequest(
    productDisplayName: 'Factory Validation App',
    productPurpose: 'Validate executable Bootstrap.',
    initialProductScopeOrFirstIntendedOutcome:
        'Prepare a neutral Flutter scaffold.',
    exactOutputPath: outputPath,
    repositoryMode: repositoryMode,
    initialBranchName: initialBranchName,
    repositoryPolicy: repositoryPolicy,
    flutterProjectName: 'factory_validation_app',
    organizationIdentifier: 'com.example',
    requestedTechnology: 'flutter',
    targetPlatforms: const ['ios', 'android'],
  );
}

List<String> _ownedStaging(Directory root) {
  return root
      .listSync(followLinks: false)
      .map((entry) => path.basename(entry.path))
      .where((name) => name.contains('.factory-bootstrap-'))
      .toList();
}

Future<Directory> _existingRepository(
  Directory root,
  String name, {
  String branch = 'main',
}) async {
  final target = await Directory(path.join(root.path, name)).create();
  final git = await Directory(path.join(target.path, '.git')).create();
  await File(path.join(git.path, 'HEAD')).writeAsString(
    'ref: refs/heads/$branch\n',
  );
  await File(path.join(git.path, 'config')).writeAsString(
    '[core]\n\trepositoryformatversion = 0\n',
  );
  return target;
}

Future<Directory> _realRepositoryWithHistory(
  Directory root,
  String name,
) async {
  final target = await Directory(path.join(root.path, name)).create();
  await _runGit(target, ['init', '--initial-branch=preserved', '.']);
  await _runGit(target, ['config', 'user.name', 'Factory Test']);
  await _runGit(target, ['config', 'user.email', 'factory@example.invalid']);
  final tracked = File(path.join(target.path, 'tracked.txt'));
  await tracked.writeAsString('baseline\n');
  await _runGit(target, ['add', 'tracked.txt']);
  await _runGit(target, ['commit', '-m', 'test baseline']);
  await _runGit(
    target,
    ['remote', 'add', 'origin', 'https://example.invalid/repository.git'],
  );
  await tracked.delete();
  await _runGit(target, ['add', '-u']);
  return target;
}

Future<Directory> _realRepositoryWithTrackedDeletion(
  Directory root,
  String name,
  String trackedPath,
) async {
  final target = await Directory(path.join(root.path, name)).create();
  await _runGit(target, ['init', '--initial-branch=preserved', '.']);
  await _runGit(target, ['config', 'user.name', 'Factory Test']);
  await _runGit(target, ['config', 'user.email', 'factory@example.invalid']);
  final tracked = File(path.join(target.path, trackedPath));
  await tracked.parent.create(recursive: true);
  await tracked.writeAsString('baseline\n');
  await _runGit(target, ['add', trackedPath]);
  await _runGit(target, ['commit', '-m', 'tracked collision baseline']);
  await tracked.delete();
  var parent = tracked.parent;
  while (
      !path.equals(parent.path, target.path) && await parent.list().isEmpty) {
    await parent.delete();
    parent = parent.parent;
  }
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
  expect(
    result.exitCode,
    0,
    reason: 'git ${arguments.join(' ')} failed: ${result.stderr}',
  );
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
  expect(
    result.exitCode,
    0,
    reason: 'git ${arguments.join(' ')} failed: ${result.stderr}',
  );
  return result.stdout.toString();
}

Map<String, String> _snapshot(String rootPath) {
  final root = Directory(rootPath);
  final result = <String, String>{};
  if (!root.existsSync()) {
    return result;
  }
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    final relative = path.relative(entity.path, from: rootPath);
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    result[relative] = switch (type) {
      FileSystemEntityType.file =>
        'file:${base64Encode(File(entity.path).readAsBytesSync())}',
      FileSystemEntityType.directory => 'directory',
      FileSystemEntityType.link => 'link:${Link(entity.path).targetSync()}',
      _ => type.toString(),
    };
  }
  return result;
}

final class _FixedPreflight implements BootstrapPreflight {
  const _FixedPreflight(this.result);

  final BootstrapPreflightResult result;

  @override
  Future<BootstrapPreflightResult> inspect(BootstrapRequest request) async {
    return result;
  }
}

final class _FixtureGitInspector implements GitRepositoryInspector {
  @override
  Future<GitRepositoryInspection> inspect(String targetPath) async {
    return GitRepositoryInspection(
      status: GitRepositoryInspectionStatus.valid,
      topLevelPath: path.normalize(targetPath),
    );
  }
}

final class _Invocation {
  _Invocation(
    this.executable,
    List<String> arguments,
    this.workingDirectory,
  ) : arguments = List<String>.unmodifiable(arguments);

  final String executable;
  final List<String> arguments;
  final String workingDirectory;
}

final class _FakeProcessRunner implements BootstrapProcessRunner {
  _FakeProcessRunner({
    this.unavailableGit = false,
    this.unavailableFlutter = false,
    this.createHelp = '--empty --platforms --project-name --org --no-pub',
    this.failFlutterCreate = false,
    this.writeExternalOnFailedCreate = false,
    this.failPubGet = false,
    this.writeExternalOnFailedPubGet = false,
    this.failAnalyze = false,
    this.failDefaultTests = false,
    this.failAndroidBuild = false,
    this.failIosBuild = false,
    this.validationProcessStartFailure = false,
    this.failGitInit = false,
    this.precreateSmokeTest = false,
    this.blockTestDirectory = false,
    this.missingMainApp = false,
    this.wrongFinalBranch = false,
    this.wrongStagingBranch = false,
    this.counterSample = false,
    this.unsupportedPlatform = false,
    this.productDependency = false,
    this.omitFlutterTest = false,
    this.useSystemGit = false,
  });

  final bool unavailableGit;
  final bool unavailableFlutter;
  final String createHelp;
  final bool failFlutterCreate;
  final bool writeExternalOnFailedCreate;
  final bool failPubGet;
  final bool writeExternalOnFailedPubGet;
  final bool failAnalyze;
  final bool failDefaultTests;
  final bool failAndroidBuild;
  final bool failIosBuild;
  final bool validationProcessStartFailure;
  final bool failGitInit;
  final bool precreateSmokeTest;
  final bool blockTestDirectory;
  final bool missingMainApp;
  final bool wrongFinalBranch;
  final bool wrongStagingBranch;
  final bool counterSample;
  final bool unsupportedPlatform;
  final bool productDependency;
  final bool omitFlutterTest;
  final bool useSystemGit;
  final List<_Invocation> invocations = [];

  @override
  Future<BootstrapProcessResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    invocations.add(_Invocation(executable, arguments, workingDirectory));

    if (executable == 'git') {
      if (useSystemGit) {
        return const SystemBootstrapProcessRunner().run(
          executable,
          arguments,
          workingDirectory: workingDirectory,
        );
      }
      if (arguments.length == 1 && arguments.single == '--version') {
        return unavailableGit
            ? _result(
                executable,
                arguments,
                workingDirectory,
                didStart: false,
                exitCode: null,
                stderr: 'git unavailable',
              )
            : _result(
                executable,
                arguments,
                workingDirectory,
                stdout: 'git version 2.50.1\n',
              );
      }
      if (arguments.first == 'init') {
        if (failGitInit) {
          return _result(
            executable,
            arguments,
            workingDirectory,
            exitCode: 1,
            stderr: 'git init failed',
          );
        }
        final branchArgument = arguments.singleWhere(
          (argument) => argument.startsWith('--initial-branch='),
        );
        final branch = branchArgument.substring(
          '--initial-branch='.length,
        );
        final git =
            await Directory(path.join(workingDirectory, '.git')).create();
        await File(path.join(git.path, 'HEAD')).writeAsString(
          'ref: refs/heads/$branch\n',
        );
        await File(path.join(git.path, 'config')).writeAsString(
          '[core]\n\trepositoryformatversion = 0\n',
        );
        return _result(executable, arguments, workingDirectory);
      }
      return _gitInspection(executable, arguments, workingDirectory);
    }

    if (executable == 'flutter') {
      if (arguments.length == 1 && arguments.single == '--version') {
        return unavailableFlutter
            ? _result(
                executable,
                arguments,
                workingDirectory,
                didStart: false,
                exitCode: null,
                stderr: 'flutter unavailable',
              )
            : _result(
                executable,
                arguments,
                workingDirectory,
                stdout: 'Flutter 3.44.8\n',
              );
      }
      if (arguments.length == 2 &&
          arguments[0] == 'create' &&
          arguments[1] == '--help') {
        return _result(
          executable,
          arguments,
          workingDirectory,
          stdout: createHelp,
        );
      }
      if (arguments.first == 'create') {
        if (failFlutterCreate) {
          if (writeExternalOnFailedCreate) {
            await File(path.join(workingDirectory, 'external.txt'))
                .writeAsString('external');
          }
          return _result(
            executable,
            arguments,
            workingDirectory,
            exitCode: 1,
            stderr: 'create failed',
          );
        }
        final projectName = arguments
            .singleWhere((argument) => argument.startsWith('--project-name='))
            .substring('--project-name='.length);
        await _writeNeutralScaffold(
          Directory(workingDirectory),
          projectName,
          precreateSmokeTest: precreateSmokeTest,
          blockTestDirectory: blockTestDirectory,
          missingMainApp: missingMainApp,
          counterSample: counterSample,
          unsupportedPlatform: unsupportedPlatform,
          productDependency: productDependency,
          omitFlutterTest: omitFlutterTest,
        );
        return _result(executable, arguments, workingDirectory);
      }
      if (arguments.length == 2 &&
          arguments[0] == 'pub' &&
          arguments[1] == 'get') {
        if (failPubGet && writeExternalOnFailedPubGet) {
          await File(path.join(workingDirectory, 'external.txt'))
              .writeAsString('external');
        }
        return _result(
          executable,
          arguments,
          workingDirectory,
          exitCode: failPubGet ? 1 : 0,
          stderr: failPubGet ? 'pub get failed' : '',
        );
      }
      if (arguments.length == 1 && arguments.single == 'analyze') {
        return _result(
          executable,
          arguments,
          workingDirectory,
          didStart: !validationProcessStartFailure,
          exitCode: validationProcessStartFailure
              ? null
              : failAnalyze
                  ? 1
                  : 0,
          stderr: failAnalyze ? 'analysis failed' : '',
        );
      }
      if (arguments.length == 1 && arguments.single == 'test') {
        return _result(
          executable,
          arguments,
          workingDirectory,
          exitCode: failDefaultTests ? 1 : 0,
          stderr: failDefaultTests ? 'tests failed' : '',
        );
      }
      if (arguments case ['build', 'apk']) {
        return _result(
          executable,
          arguments,
          workingDirectory,
          exitCode: failAndroidBuild ? 1 : 0,
          stderr: failAndroidBuild ? 'Android build failed' : '',
        );
      }
      if (arguments case ['build', 'ios', '--simulator']) {
        return _result(
          executable,
          arguments,
          workingDirectory,
          exitCode: failIosBuild ? 1 : 0,
          stderr: failIosBuild ? 'iOS Simulator build failed' : '',
        );
      }
    }

    return _result(
      executable,
      arguments,
      workingDirectory,
      exitCode: 1,
      stderr: 'unexpected command',
    );
  }

  Future<BootstrapProcessResult> _gitInspection(
    String executable,
    List<String> arguments,
    String workingDirectory,
  ) async {
    final gitDirectory = Directory(path.join(workingDirectory, '.git'));
    if (!await gitDirectory.exists()) {
      return _result(
        executable,
        arguments,
        workingDirectory,
        exitCode: 128,
        stderr: 'not a git repository',
      );
    }

    if (arguments case ['rev-parse', '--show-toplevel']) {
      return _result(
        executable,
        arguments,
        workingDirectory,
        stdout: '${path.normalize(workingDirectory)}\n',
      );
    }
    if (arguments case ['symbolic-ref', '--quiet', '--short', 'HEAD']) {
      final head = await File(
        path.join(gitDirectory.path, 'HEAD'),
      ).readAsString();
      var branch = head.trim().split('/').last;
      final isFinalNewTarget =
          !path.basename(workingDirectory).contains('.factory-bootstrap-') &&
              path.basename(workingDirectory) == 'product';
      final isStaging =
          path.basename(workingDirectory).contains('.factory-bootstrap-');
      if (wrongFinalBranch && isFinalNewTarget) {
        branch = 'wrong';
      }
      if (wrongStagingBranch && isStaging) {
        branch = 'wrong';
      }
      return _result(
        executable,
        arguments,
        workingDirectory,
        stdout: '$branch\n',
      );
    }
    if (arguments case ['rev-parse', '--verify', 'HEAD']) {
      return _result(
        executable,
        arguments,
        workingDirectory,
        exitCode: 1,
        stderr: 'unborn branch',
      );
    }
    if (arguments case ['remote']) {
      return _result(executable, arguments, workingDirectory);
    }
    if (arguments case ['status', '--short']) {
      return _result(executable, arguments, workingDirectory);
    }
    if (arguments case ['ls-files', '-z']) {
      return _result(executable, arguments, workingDirectory);
    }
    return _result(
      executable,
      arguments,
      workingDirectory,
      exitCode: 1,
      stderr: 'unsupported git inspection',
    );
  }

  BootstrapProcessResult _result(
    String executable,
    List<String> arguments,
    String workingDirectory, {
    int? exitCode = 0,
    String stdout = '',
    String stderr = '',
    bool didStart = true,
  }) {
    return BootstrapProcessResult(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
      didStart: didStart,
    );
  }
}

Future<void> _writeNeutralScaffold(
  Directory root,
  String projectName, {
  required bool precreateSmokeTest,
  required bool blockTestDirectory,
  required bool missingMainApp,
  required bool counterSample,
  required bool unsupportedPlatform,
  required bool productDependency,
  required bool omitFlutterTest,
}) async {
  await Directory(path.join(root.path, 'lib')).create();
  await Directory(path.join(root.path, 'android')).create();
  await Directory(path.join(root.path, 'ios')).create();
  await File(path.join(root.path, 'README.md')).writeAsString(
    '# $projectName\n',
  );
  await File(path.join(root.path, '.gitignore')).writeAsString('.dart_tool/\n');
  await File(path.join(root.path, 'pubspec.yaml')).writeAsString('''
name: $projectName
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
${omitFlutterTest ? '' : '''  flutter_test:
    sdk: flutter
'''}  flutter_lints: ^6.0.0
${productDependency ? '''  product_package: ^1.0.0
''' : ''}
''');
  await File(path.join(root.path, 'lib', 'main.dart')).writeAsString(
    missingMainApp
        ? 'void main() {}\n'
        : '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold());
  }
}
${counterSample ? 'void incrementCounter() {}' : ''}
''',
  );
  if (unsupportedPlatform) {
    await Directory(path.join(root.path, 'web')).create();
  }
  if (blockTestDirectory) {
    await File(path.join(root.path, 'test')).writeAsString('blocked');
  } else if (precreateSmokeTest) {
    final testDirectory = await Directory(
      path.join(root.path, 'test'),
    ).create();
    await File(
      path.join(testDirectory.path, 'bootstrap_smoke_test.dart'),
    ).writeAsString('existing');
  }
}
