import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'bootstrap_execution_result.dart';
import 'bootstrap_execution_stop_reason.dart';
import 'bootstrap_preflight.dart';
import 'bootstrap_preflight_result.dart';
import 'bootstrap_process_runner.dart';
import 'bootstrap_request.dart';
import 'bootstrap_runtime_proposal.dart';
import 'bootstrap_technical_validation.dart';
import 'product_authority_renderer.dart';
import 'repository_mode.dart';
import 'validated_bootstrap_request.dart';

abstract interface class BootstrapExecutor {
  Future<BootstrapExecutionResult> execute(BootstrapPreflightReady ready);
}

typedef BootstrapExecutionHook = Future<void> Function(
  BootstrapExecutionStage stage, {
  required String stagingPath,
  required String finalTargetPath,
});

typedef BootstrapInspectionHook = Future<void> Function(
  String operation,
  String inspectionPath,
);

final class FileSystemBootstrapExecutor implements BootstrapExecutor {
  FileSystemBootstrapExecutor({
    required Directory factoryRoot,
    required BootstrapPreflight preflight,
    BootstrapProcessRunner processRunner = const SystemBootstrapProcessRunner(),
    this.gitExecutable = 'git',
    this.flutterExecutable = 'flutter',
    BootstrapExecutionHook? executionHook,
    BootstrapInspectionHook? inspectionHook,
    ProductAuthorityRenderer authorityRenderer =
        const ProductAuthorityRenderer(),
  })  : _factoryRoot = factoryRoot.absolute,
        _preflight = preflight,
        _processRunner = processRunner,
        _executionHook = executionHook,
        _inspectionHook = inspectionHook,
        _authorityRenderer = authorityRenderer;

  static const _environmentNote =
      'Toolchain-owned cache metadata may have been accessed or refreshed; '
      'no SDK upgrade, installation, channel, license, system configuration, '
      'or persistent environment change was requested.';

  static const _requiredProductValidations = [
    _RequiredValidation(
      label: 'Static analysis',
      arguments: ['analyze'],
      failureCategory: BootstrapExecutionStopCategory.staticAnalysisFailed,
      stage: BootstrapExecutionStage.staticAnalysis,
    ),
    _RequiredValidation(
      label: 'Default tests',
      arguments: ['test'],
      failureCategory: BootstrapExecutionStopCategory.defaultTestsFailed,
      stage: BootstrapExecutionStage.defaultTests,
    ),
    _RequiredValidation(
      label: 'Android APK build',
      arguments: ['build', 'apk'],
      failureCategory: BootstrapExecutionStopCategory.androidApkBuildFailed,
      stage: BootstrapExecutionStage.androidApkBuild,
    ),
    _RequiredValidation(
      label: 'iOS Simulator build',
      arguments: ['build', 'ios', '--simulator'],
      failureCategory: BootstrapExecutionStopCategory.iosSimulatorBuildFailed,
      stage: BootstrapExecutionStage.iosSimulatorBuild,
    ),
  ];

  final Directory _factoryRoot;
  final BootstrapPreflight _preflight;
  final BootstrapProcessRunner _processRunner;
  final BootstrapExecutionHook? _executionHook;
  final BootstrapInspectionHook? _inspectionHook;
  final ProductAuthorityRenderer _authorityRenderer;
  final String gitExecutable;
  final String flutterExecutable;

  @override
  Future<BootstrapExecutionResult> execute(
    BootstrapPreflightReady ready,
  ) async {
    try {
      return await _execute(ready);
    } on _InspectionFault catch (fault) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: ready.normalizedOutputPath,
        stagingPath: null,
        commands: const [],
        failure: fault.failure,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    } on FileSystemException catch (error) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: ready.normalizedOutputPath,
        stagingPath: null,
        commands: const [],
        failure: _inspectionFailure(
          error.path ?? ready.normalizedOutputPath,
          'executionBoundaryInspection',
          error,
        ),
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
  }

  Future<BootstrapExecutionResult> _execute(
    BootstrapPreflightReady ready,
  ) async {
    final commands = <BootstrapProcessResult>[];
    final originalRequest = _requestFrom(ready.validatedRequest);
    final revalidated = await _preflight.inspect(originalRequest);
    if (revalidated is! BootstrapPreflightReady ||
        !_sameReady(ready, revalidated)) {
      return _stopped(
        category: BootstrapExecutionStopCategory.preflightChanged,
        stage: BootstrapExecutionStage.preflightRevalidation,
        commands: commands,
        validationFailure:
            'The read-only preflight result changed before execution.',
        facts: [
          'Original target: ${ready.normalizedOutputPath}',
          'No Product mutation was started.',
        ],
        evidence: [
          'Revalidation result: ${revalidated.runtimeType}',
        ],
        notPerformed: _notPerformedFrom(
          BootstrapExecutionStage.toolchainValidation,
        ),
        targetUnchangedOrRestored: false,
      );
    }

    final toolchainFailure = await _validateToolchain(commands);
    if (toolchainFailure != null) {
      return toolchainFailure;
    }

    final factoryBaselineCapture = await _captureGitState(
      _factoryRoot.path,
      commands,
    );
    if (factoryBaselineCapture.inspectionFailure != null) {
      final failure = factoryBaselineCapture.inspectionFailure!;
      return _stopped(
        category: BootstrapExecutionStopCategory.validationEvidenceUntrusted,
        stage: BootstrapExecutionStage.factoryBaselineVerification,
        commands: commands,
        validationFailure:
            'The Factory Git baseline inspection could not be trusted.',
        facts: const ['No Product mutation was started.'],
        evidence: [
          'Inspection path: ${failure.path}',
          'Failed operation: ${failure.operation}',
          'Error type: ${failure.errorType}',
          'Safe error message: ${failure.message}',
        ],
        notPerformed: _notPerformedFrom(
          BootstrapExecutionStage.stagingCreation,
        ),
      );
    }
    if (factoryBaselineCapture.failure != null ||
        factoryBaselineCapture.state == null) {
      return _stopped(
        category: BootstrapExecutionStopCategory.validationEvidenceUntrusted,
        stage: BootstrapExecutionStage.factoryBaselineVerification,
        commands: commands,
        failedCommand: factoryBaselineCapture.failure,
        validationFailure:
            'The Factory Git baseline could not be captured read-only.',
        facts: const ['No Product mutation was started.'],
        evidence: const ['No staging directory was created.'],
        notPerformed: _notPerformedFrom(
          BootstrapExecutionStage.stagingCreation,
        ),
      );
    }
    final factoryBaseline = factoryBaselineCapture.state!;

    final targetPath = ready.normalizedOutputPath;
    _ExistingBaseline? existingBaseline;
    if (ready.confirmedRepositoryMode ==
        RepositoryMode.existingEmptyRepository) {
      final capture = await _captureGitState(targetPath, commands);
      if (capture.inspectionFailure != null) {
        return _inspectionStopped(
          stage: BootstrapExecutionStage.preflightRevalidation,
          targetPath: targetPath,
          commands: commands,
          failure: capture.inspectionFailure!,
        );
      }
      if (capture.failure != null || capture.state == null) {
        return _stopped(
          category: BootstrapExecutionStopCategory.repositoryMetadataChanged,
          stage: BootstrapExecutionStage.preflightRevalidation,
          commands: commands,
          failedCommand: capture.failure,
          validationFailure:
              'The existing Repository baseline could not be captured.',
          facts: ['Target: $targetPath'],
          evidence: const ['No staging directory was created.'],
          notPerformed: _notPerformedFrom(
            BootstrapExecutionStage.stagingCreation,
          ),
        );
      }
      final rootCapture = await _captureRootEntries(Directory(targetPath));
      if (!rootCapture.succeeded) {
        return _inspectionStopped(
          stage: BootstrapExecutionStage.preflightRevalidation,
          targetPath: targetPath,
          commands: commands,
          failure: rootCapture.inspectionFailure!,
        );
      }
      existingBaseline = _ExistingBaseline(
        git: capture.state!,
        rootEntries: rootCapture.entries,
      );
    }

    Directory staging;
    try {
      final parent = Directory(path.dirname(targetPath));
      staging = await parent.createTemp(
        '.${path.basename(targetPath)}.factory-bootstrap-',
      );
    } on FileSystemException catch (error) {
      return _stopped(
        category: BootstrapExecutionStopCategory.stagingCreationFailed,
        stage: BootstrapExecutionStage.stagingCreation,
        commands: commands,
        validationFailure: error.message,
        facts: ['Target: $targetPath'],
        evidence: const ['No staging path was successfully created.'],
        notPerformed: _notPerformedFrom(
          BootstrapExecutionStage.flutterScaffold,
        ),
      );
    }

    final stagingPath = path.normalize(staging.path);
    if (_equalsOrIsWithin(path.normalize(_factoryRoot.path), stagingPath)) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.stagingCreationFailed,
        stage: BootstrapExecutionStage.stagingCreation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure: 'Staging resolved inside the Factory Repository.',
      );
    }

    try {
      await _runHook(
        BootstrapExecutionStage.stagingCreation,
        stagingPath,
        targetPath,
      );
    } catch (error) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.filesystemMutationFailed,
        stage: BootstrapExecutionStage.stagingCreation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure: 'Staging hook failed: $error',
      );
    }

    final scaffold = await _run(
      flutterExecutable,
      [
        'create',
        '--empty',
        '--platforms=ios,android',
        '--project-name=${ready.validatedRequest.flutterProjectName}',
        '--org=${ready.validatedRequest.organizationIdentifier}',
        '--no-pub',
        '.',
      ],
      workingDirectory: stagingPath,
      commands: commands,
    );
    if (!scaffold.succeeded) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.flutterScaffoldFailed,
        stage: BootstrapExecutionStage.flutterScaffold,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        failedCommand: scaffold,
      );
    }

    final smokeFailure = await _generateSmokeTest(
      staging,
      ready.validatedRequest.flutterProjectName,
    );
    if (smokeFailure != null) {
      return _stopAfterCleanup(
        category: smokeFailure.category,
        stage: BootstrapExecutionStage.smokeTestGeneration,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure: smokeFailure.message,
      );
    }

    final completedValidationSteps = <String>[];
    final pubGet = await _run(
      flutterExecutable,
      ['pub', 'get'],
      workingDirectory: stagingPath,
      commands: commands,
    );
    if (!pubGet.succeeded) {
      return _stopAfterValidationFailure(
        ready: ready,
        category: pubGet.didStart
            ? BootstrapExecutionStopCategory.dependencyPreparationFailed
            : BootstrapExecutionStopCategory.validationProcessStartFailed,
        stage: BootstrapExecutionStage.dependencyPreparation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        failedCommand: pubGet,
        completedValidationSteps: completedValidationSteps,
        unperformedValidationSteps: const [
          'Static analysis',
          'Default tests',
          'Android APK build',
          'iOS Simulator build',
        ],
      );
    }
    completedValidationSteps.add('Flutter dependency preparation');

    String? stagingVerification;
    try {
      stagingVerification = await _verifyScaffold(
        staging,
        ready.validatedRequest.flutterProjectName,
        expectGit: false,
      );
    } on _InspectionFault catch (fault) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.scaffoldVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: fault.failure,
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    } on FileSystemException catch (error) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.scaffoldVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: _inspectionFailure(
          error.path ?? staging.path,
          'scaffoldInspection',
          error,
        ),
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    }
    if (stagingVerification != null) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.scaffoldVerificationFailed,
        stage: BootstrapExecutionStage.scaffoldVerification,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure: stagingVerification,
      );
    }

    for (final validation in _requiredProductValidations) {
      final result = await _run(
        flutterExecutable,
        validation.arguments,
        workingDirectory: stagingPath,
        commands: commands,
      );
      if (!result.succeeded) {
        final validationIndex = _requiredProductValidations.indexOf(validation);
        return _stopAfterValidationFailure(
          ready: ready,
          category: result.didStart
              ? validation.failureCategory
              : BootstrapExecutionStopCategory.validationProcessStartFailed,
          stage: validation.stage,
          commands: commands,
          staging: staging,
          targetPath: targetPath,
          failedCommand: result,
          completedValidationSteps: completedValidationSteps,
          unperformedValidationSteps: _requiredProductValidations
              .skip(validationIndex + 1)
              .map((step) => step.label)
              .toList(growable: false),
        );
      }
      completedValidationSteps.add(validation.label);
    }

    final authorityDocuments = _authorityRenderer.render(
      ready.validatedRequest,
    );
    final authorityWrite = await _writeProductAuthority(
      staging,
      authorityDocuments,
    );
    if (authorityWrite.inspectionFailure != null) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.scaffoldVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: authorityWrite.inspectionFailure!,
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    }
    if (authorityWrite.failure != null) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.filesystemMutationFailed,
        stage: BootstrapExecutionStage.scaffoldVerification,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure: authorityWrite.failure,
      );
    }

    try {
      await _runHook(
        BootstrapExecutionStage.factoryBaselineVerification,
        staging.path,
        targetPath,
      );
    } catch (error) {
      return _factoryBaselinePartial(
        category: BootstrapExecutionStopCategory.validationEvidenceUntrusted,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: 'Factory baseline verification hook failed: $error',
      );
    }
    final factoryPreInstallCapture = await _captureGitState(
      _factoryRoot.path,
      commands,
    );
    if (factoryPreInstallCapture.inspectionFailure != null ||
        factoryPreInstallCapture.failure != null ||
        factoryPreInstallCapture.state == null) {
      return _factoryBaselinePartial(
        category: BootstrapExecutionStopCategory.validationEvidenceUntrusted,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure:
            'The Factory Git state could not be trusted before Product installation.',
      );
    }
    if (!_sameGitBaseline(
      factoryBaseline,
      factoryPreInstallCapture.state!,
    )) {
      return _factoryBaselinePartial(
        category: BootstrapExecutionStopCategory.factoryRepositoryChanged,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure:
            'The Factory Repository changed during Product validation; staging was preserved.',
      );
    }

    return switch (ready.confirmedRepositoryMode) {
      RepositoryMode.newRepository => _installNew(
          ready: ready,
          originalRequest: originalRequest,
          staging: staging,
          commands: commands,
          factoryBaseline: factoryBaseline,
        ),
      RepositoryMode.existingEmptyRepository => _installExisting(
          ready: ready,
          originalRequest: originalRequest,
          staging: staging,
          commands: commands,
          baseline: existingBaseline!,
          factoryBaseline: factoryBaseline,
        ),
    };
  }

  Future<BootstrapExecutionStopped?> _validateToolchain(
    List<BootstrapProcessResult> commands,
  ) async {
    final gitVersion = await _run(
      gitExecutable,
      ['--version'],
      workingDirectory: _factoryRoot.path,
      commands: commands,
    );
    if (!gitVersion.succeeded) {
      return _stopped(
        category: BootstrapExecutionStopCategory.gitToolUnavailable,
        stage: BootstrapExecutionStage.toolchainValidation,
        commands: commands,
        failedCommand: gitVersion,
        facts: const ['Git availability was checked before Product mutation.'],
        evidence: const ['No staging directory was created.'],
        notPerformed: _notPerformedFrom(
          BootstrapExecutionStage.stagingCreation,
        ),
      );
    }

    final flutterVersion = await _run(
      flutterExecutable,
      ['--version'],
      workingDirectory: _factoryRoot.path,
      commands: commands,
    );
    if (!flutterVersion.succeeded) {
      return _stopped(
        category: BootstrapExecutionStopCategory.flutterToolUnavailable,
        stage: BootstrapExecutionStage.toolchainValidation,
        commands: commands,
        failedCommand: flutterVersion,
        facts: const [
          'Flutter availability was checked before Product mutation.',
        ],
        evidence: const ['No staging directory was created.'],
        notPerformed: _notPerformedFrom(
          BootstrapExecutionStage.stagingCreation,
        ),
      );
    }

    final createHelp = await _run(
      flutterExecutable,
      ['create', '--help'],
      workingDirectory: _factoryRoot.path,
      commands: commands,
    );
    final help = '${createHelp.stdout}\n${createHelp.stderr}';
    const requiredOptions = ['--platforms', '--project-name', '--org'];
    final supportsEmpty =
        help.contains('--empty') || help.contains('--[no-]empty');
    final supportsNoPub =
        help.contains('--no-pub') || help.contains('--[no-]pub');
    if (!createHelp.succeeded ||
        !supportsEmpty ||
        !supportsNoPub ||
        requiredOptions.any((option) => !help.contains(option))) {
      return _stopped(
        category: BootstrapExecutionStopCategory.flutterCreateUnsupported,
        stage: BootstrapExecutionStage.toolchainValidation,
        commands: commands,
        failedCommand: createHelp.succeeded ? null : createHelp,
        validationFailure:
            'Flutter create does not expose every required V1 option.',
        facts: const [
          'Required options: empty, platforms, project-name, org, no-pub.',
        ],
        evidence: const ['No staging directory was created.'],
        notPerformed: _notPerformedFrom(
          BootstrapExecutionStage.stagingCreation,
        ),
      );
    }
    return null;
  }

  Future<BootstrapExecutionResult> _installNew({
    required BootstrapPreflightReady ready,
    required BootstrapRequest originalRequest,
    required Directory staging,
    required List<BootstrapProcessResult> commands,
    required _GitState factoryBaseline,
  }) async {
    final targetPath = ready.normalizedOutputPath;
    final branch = ready.validatedRequest.initialBranchName!;
    final gitInit = await _run(
      gitExecutable,
      ['init', '--initial-branch=$branch', '.'],
      workingDirectory: staging.path,
      commands: commands,
    );
    if (!gitInit.succeeded) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.repositoryInitializationFailed,
        stage: BootstrapExecutionStage.repositoryInitialization,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        failedCommand: gitInit,
      );
    }

    final stagingGit = await _captureGitState(staging.path, commands);
    if (stagingGit.failure != null ||
        stagingGit.state == null ||
        stagingGit.state!.branch != branch) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.branchInitializationFailed,
        stage: BootstrapExecutionStage.branchInitialization,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        failedCommand: stagingGit.failure,
        validationFailure: 'The requested initial branch was not confirmed.',
      );
    }
    if (stagingGit.state!.headExists || stagingGit.state!.remotes.isNotEmpty) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.repositoryInitializationFailed,
        stage: BootstrapExecutionStage.repositoryInitialization,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure:
            'A new Bootstrap Repository must have no commit or remote.',
      );
    }

    try {
      await _runHook(
        BootstrapExecutionStage.targetRevalidation,
        staging.path,
        targetPath,
      );
    } catch (error) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.targetChangedBeforeInstall,
        stage: BootstrapExecutionStage.targetRevalidation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure: 'Target revalidation hook failed: $error',
      );
    }

    final latest = await _preflight.inspect(originalRequest);
    FileSystemEntityType currentTargetType;
    try {
      currentTargetType = await _inspectType(targetPath);
    } on _InspectionFault catch (fault) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.targetRevalidation,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: fault.failure,
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    }
    if (latest is! BootstrapPreflightReady ||
        !_sameReady(ready, latest) ||
        currentTargetType != FileSystemEntityType.notFound) {
      return _stopAfterCleanup(
        category: BootstrapExecutionStopCategory.targetChangedBeforeInstall,
        stage: BootstrapExecutionStage.targetRevalidation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        validationFailure: 'The New Repository target changed before install.',
        targetUnchangedOrRestored: false,
      );
    }

    final ownedCapture = await _captureSnapshot(
      staging.path,
      expectedType: FileSystemEntityType.directory,
    );
    if (!ownedCapture.succeeded) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.ownershipVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: ownedCapture.inspectionFailure ??
            _inspectionFailureForCapture(ownedCapture),
        productMutationStarted: false,
        gitMetadataAffected: true,
      );
    }
    final ownedManifest = ownedCapture.manifest;
    try {
      await _runHook(
        BootstrapExecutionStage.ownershipVerification,
        staging.path,
        targetPath,
      );
      await _runHook(
        BootstrapExecutionStage.installation,
        staging.path,
        targetPath,
      );
      await staging.rename(targetPath);
    } on FileSystemException catch (error) {
      return _stopNewAfterOwnedCleanup(
        category: BootstrapExecutionStopCategory.installFailed,
        stage: BootstrapExecutionStage.installation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        ownedManifest: ownedManifest,
        validationFailure: error.message,
      );
    } catch (error) {
      return _stopNewAfterOwnedCleanup(
        category: BootstrapExecutionStopCategory.installFailed,
        stage: BootstrapExecutionStage.installation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        ownedManifest: ownedManifest,
        validationFailure: '$error',
      );
    }

    try {
      await _runHook(
        BootstrapExecutionStage.finalVerification,
        staging.path,
        targetPath,
      );
    } catch (error) {
      final capturedActual = await _captureSnapshot(
        targetPath,
        expectedType: FileSystemEntityType.directory,
      );
      if (capturedActual.status == _SnapshotStatus.failure) {
        return _inspectionPartial(
          stage: BootstrapExecutionStage.finalVerification,
          targetPath: targetPath,
          stagingPath: null,
          commands: commands,
          failure: capturedActual.inspectionFailure!,
          productMutationStarted: true,
          gitMetadataAffected: true,
        );
      }
      final actualManifest = capturedActual.manifest;
      return _ownershipPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        createdOrMovedEntries: ownedManifest.keys.toList()..sort(),
        commands: commands,
        expectedManifest: ownedManifest,
        actualManifest: actualManifest,
        failure: 'Final ownership verification hook failed: $error',
        actualManifestAvailable: capturedActual.succeeded,
      );
    }

    final installedCapture = await _captureSnapshot(
      targetPath,
      expectedType: FileSystemEntityType.directory,
    );
    if (installedCapture.status == _SnapshotStatus.failure) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        commands: commands,
        failure: installedCapture.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    final installedManifest = installedCapture.manifest;
    if (!installedCapture.succeeded ||
        !_sameSnapshot(ownedManifest, installedManifest)) {
      return _ownershipPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        createdOrMovedEntries: ownedManifest.keys.toList()..sort(),
        commands: commands,
        expectedManifest: ownedManifest,
        actualManifest: installedManifest,
        failure:
            'The final New Repository differs from its captured ownership manifest.',
        actualManifestAvailable: installedCapture.succeeded,
      );
    }

    final finalCheck = await _verifyFinalNew(
      ready,
      commands,
    );
    if (finalCheck.inspectionFailure != null) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        commands: commands,
        failure: finalCheck.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    final finalFailure = finalCheck.validationFailure;
    if (finalFailure != null) {
      final currentCapture = await _captureSnapshot(
        targetPath,
        expectedType: FileSystemEntityType.directory,
      );
      if (currentCapture.status == _SnapshotStatus.failure) {
        return _inspectionPartial(
          stage: BootstrapExecutionStage.finalVerification,
          targetPath: targetPath,
          stagingPath: null,
          commands: commands,
          failure: currentCapture.inspectionFailure!,
          productMutationStarted: true,
          gitMetadataAffected: true,
        );
      }
      final currentManifest = currentCapture.manifest;
      if (!currentCapture.succeeded ||
          !_sameSnapshot(ownedManifest, currentManifest)) {
        return _ownershipPartial(
          stage: BootstrapExecutionStage.finalVerification,
          targetPath: targetPath,
          stagingPath: null,
          createdOrMovedEntries: ownedManifest.keys.toList()..sort(),
          commands: commands,
          expectedManifest: ownedManifest,
          actualManifest: currentManifest,
          failure: finalFailure,
          actualManifestAvailable: currentCapture.succeeded,
        );
      }
      if (_sameSnapshot(ownedManifest, currentManifest)) {
        try {
          await Directory(targetPath).delete(recursive: true);
          return _stopped(
            category: BootstrapExecutionStopCategory.scaffoldVerificationFailed,
            stage: BootstrapExecutionStage.finalVerification,
            commands: commands,
            validationFailure: finalFailure,
            facts: ['Final target: $targetPath'],
            evidence: const [
              'The execution-owned target matched its recorded manifest and was removed.',
            ],
            notPerformed: const ['Ready result was not returned.'],
          );
        } on FileSystemException catch (error) {
          final remainingCapture = await _captureSnapshot(
            targetPath,
            expectedType: FileSystemEntityType.directory,
          );
          if (remainingCapture.status == _SnapshotStatus.failure) {
            return _inspectionPartial(
              stage: BootstrapExecutionStage.rollback,
              targetPath: targetPath,
              stagingPath: null,
              commands: commands,
              failure: remainingCapture.inspectionFailure!,
              productMutationStarted: true,
              gitMetadataAffected: true,
            );
          }
          return _partial(
            category: BootstrapExecutionStopCategory.rollbackFailed,
            stage: BootstrapExecutionStage.rollback,
            targetPath: targetPath,
            stagingPath: null,
            createdOrMovedEntries: ownedManifest.keys.toList()..sort(),
            rollbackFailed: [targetPath],
            commands: commands,
            failure: error.message,
            gitMetadataAffected: _gitMetadataAffected(
              ownedManifest,
              remainingCapture.manifest,
              actualManifestAvailable: remainingCapture.succeeded,
            ),
            expectedManifest: ownedManifest,
            actualManifest: remainingCapture.manifest,
            ownershipDifferences: _manifestDifferences(
              ownedManifest,
              remainingCapture.manifest,
            ),
          );
        }
      }
    }

    final finalGitCapture = await _captureGitState(targetPath, commands);
    final finalGit = finalGitCapture.state;
    final readyCapture = await _captureSnapshot(
      targetPath,
      expectedType: FileSystemEntityType.directory,
    );
    if (readyCapture.status == _SnapshotStatus.failure) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        commands: commands,
        failure: readyCapture.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    final readyManifest = readyCapture.manifest;
    if (finalGitCapture.inspectionFailure != null) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        commands: commands,
        failure: finalGitCapture.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    if (finalGitCapture.failure != null ||
        finalGit == null ||
        !readyCapture.succeeded ||
        !_sameSnapshot(ownedManifest, readyManifest)) {
      return _ownershipPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        createdOrMovedEntries: ownedManifest.keys.toList()..sort(),
        commands: commands,
        expectedManifest: ownedManifest,
        actualManifest: readyManifest,
        failure:
            'The New Repository changed during final Git and ownership verification.',
        actualManifestAvailable: readyCapture.succeeded,
      );
    }
    final entriesCapture = await _captureRootEntries(Directory(targetPath));
    if (!entriesCapture.succeeded) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: null,
        commands: commands,
        failure: entriesCapture.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    final entries = entriesCapture.entries;
    return _preparedResult(
      ready: ready,
      git: finalGit,
      createdRootEntries: entries,
      commands: commands,
      factoryBaseline: factoryBaseline,
    );
  }

  Future<BootstrapExecutionResult> _installExisting({
    required BootstrapPreflightReady ready,
    required BootstrapRequest originalRequest,
    required Directory staging,
    required List<BootstrapProcessResult> commands,
    required _ExistingBaseline baseline,
    required _GitState factoryBaseline,
  }) async {
    final targetPath = ready.normalizedOutputPath;
    final authoritativeCapture = await _captureSnapshot(
      staging.path,
      expectedType: FileSystemEntityType.directory,
    );
    if (!authoritativeCapture.succeeded) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.scaffoldVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: authoritativeCapture.inspectionFailure ??
            _inspectionFailureForCapture(authoritativeCapture),
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    }
    final authoritativeManifest = authoritativeCapture.manifest;
    FileSystemEntityType generatedGitType;
    try {
      generatedGitType = await _inspectType(
        path.join(staging.path, '.git'),
      );
    } on _InspectionFault catch (fault) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.targetRevalidation,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: fault.failure,
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    }
    if (generatedGitType != FileSystemEntityType.notFound) {
      return _stopExistingAfterOwnedCleanup(
        category: BootstrapExecutionStopCategory.generatedGitMetadataConflict,
        stage: BootstrapExecutionStage.targetRevalidation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        authoritativeManifest: authoritativeManifest,
        validationFailure:
            'The generated scaffold unexpectedly contains Git metadata.',
      );
    }

    final trackedConflicts = _trackedPathConflicts(
      baseline.git.trackedPaths,
      authoritativeManifest,
    );
    if (trackedConflicts.isNotEmpty) {
      return _stopExistingAfterOwnedCleanup(
        category: BootstrapExecutionStopCategory.trackedPathConflict,
        stage: BootstrapExecutionStage.targetRevalidation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        authoritativeManifest: authoritativeManifest,
        validationFailure:
            'Generated paths intersect paths tracked by the Existing Repository.',
        facts: [
          'Existing Repository: $targetPath',
          'Tracked-path conflicts: ${trackedConflicts.join(', ')}',
        ],
        evidence: [
          for (final conflict in trackedConflicts)
            'Tracked path conflict: $conflict',
        ],
      );
    }

    try {
      await _runHook(
        BootstrapExecutionStage.targetRevalidation,
        staging.path,
        targetPath,
      );
    } catch (error) {
      return _stopExistingAfterOwnedCleanup(
        category: BootstrapExecutionStopCategory.targetChangedBeforeInstall,
        stage: BootstrapExecutionStage.targetRevalidation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        authoritativeManifest: authoritativeManifest,
        validationFailure: 'Target revalidation hook failed: $error',
        targetUnchangedOrRestored: false,
      );
    }

    final latest = await _preflight.inspect(originalRequest);
    final currentEntriesCapture =
        await _captureRootEntries(Directory(targetPath));
    if (!currentEntriesCapture.succeeded) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.targetRevalidation,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: currentEntriesCapture.inspectionFailure!,
        productMutationStarted: false,
        gitMetadataAffected: true,
      );
    }
    final currentEntries = currentEntriesCapture.entries;
    if (latest is! BootstrapPreflightReady ||
        !_sameReady(ready, latest) ||
        currentEntries.length != 1 ||
        currentEntries.single != '.git') {
      return _stopExistingAfterOwnedCleanup(
        category: BootstrapExecutionStopCategory.targetChangedBeforeInstall,
        stage: BootstrapExecutionStage.targetRevalidation,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        authoritativeManifest: authoritativeManifest,
        validationFailure:
            'The Existing Repository target changed before install.',
        targetUnchangedOrRestored: false,
      );
    }

    final generatedEntriesCapture = await _captureRootEntries(staging);
    if (!generatedEntriesCapture.succeeded) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.targetRevalidation,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: generatedEntriesCapture.inspectionFailure!,
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    }
    final generatedEntries = generatedEntriesCapture.entries;
    final entrySnapshots = <String, Map<String, String>>{};
    for (final entry in generatedEntries) {
      final entryCapture = await _captureSnapshot(
        path.join(staging.path, entry),
      );
      if (!entryCapture.succeeded) {
        return _inspectionPartial(
          stage: BootstrapExecutionStage.targetRevalidation,
          targetPath: targetPath,
          stagingPath: staging.path,
          commands: commands,
          failure: entryCapture.inspectionFailure ??
              _inspectionFailureForCapture(entryCapture),
          productMutationStarted: false,
          gitMetadataAffected: false,
        );
      }
      entrySnapshots[entry] = entryCapture.manifest;
    }

    final moved = <String>[];
    try {
      await _runHook(
        BootstrapExecutionStage.installation,
        staging.path,
        targetPath,
      );
      final preInstallCapture = await _captureSnapshot(
        staging.path,
        expectedType: FileSystemEntityType.directory,
      );
      if (preInstallCapture.status == _SnapshotStatus.failure) {
        return _inspectionPartial(
          stage: BootstrapExecutionStage.installation,
          targetPath: targetPath,
          stagingPath: staging.path,
          commands: commands,
          failure: preInstallCapture.inspectionFailure!,
          productMutationStarted: false,
          gitMetadataAffected: false,
        );
      }
      final preInstallManifest = preInstallCapture.manifest;
      if (!preInstallCapture.succeeded ||
          !_sameSnapshot(authoritativeManifest, preInstallManifest)) {
        return _ownershipPartial(
          stage: BootstrapExecutionStage.installation,
          targetPath: targetPath,
          stagingPath: staging.path,
          createdOrMovedEntries: const [],
          commands: commands,
          expectedManifest: authoritativeManifest,
          actualManifest: preInstallManifest,
          failure:
              'Staging changed after its authoritative manifest was captured; the Product was not mutated.',
          actualManifestAvailable: preInstallCapture.succeeded,
          rollbackFailed: [staging.path],
        );
      }
      for (final entry in generatedEntries) {
        final source = path.join(staging.path, entry);
        final destination = path.join(targetPath, entry);
        if (await _inspectType(destination) != FileSystemEntityType.notFound) {
          throw FileSystemException(
            'Target entry appeared during install.',
            destination,
          );
        }
        final sourceType = await _inspectType(source);
        if (sourceType == FileSystemEntityType.directory) {
          await Directory(source).rename(destination);
        } else {
          await File(source).rename(destination);
        }
        moved.add(entry);
      }
    } on _InspectionFault catch (fault) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.installation,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: fault.failure,
        productMutationStarted: moved.isNotEmpty,
        gitMetadataAffected: moved.isNotEmpty,
      );
    } catch (error) {
      return _rollbackExisting(
        targetPath: targetPath,
        staging: staging,
        moved: moved,
        snapshots: entrySnapshots,
        authoritativeManifest: authoritativeManifest,
        baseline: baseline,
        commands: commands,
        failure: '$error',
        failureCategory: BootstrapExecutionStopCategory.installFailed,
      );
    }

    try {
      await _runHook(
        BootstrapExecutionStage.finalVerification,
        staging.path,
        targetPath,
      );
    } catch (error) {
      return _rollbackExisting(
        targetPath: targetPath,
        staging: staging,
        moved: moved,
        snapshots: entrySnapshots,
        authoritativeManifest: authoritativeManifest,
        baseline: baseline,
        commands: commands,
        failure: 'Final ownership verification hook failed: $error',
        failureCategory: BootstrapExecutionStopCategory.ownershipMismatch,
      );
    }

    final finalCheck = await _verifyFinalExisting(
      ready,
      baseline,
      generatedEntries,
      entrySnapshots,
      commands,
    );
    if (finalCheck.inspectionFailure != null) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: finalCheck.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    if (finalCheck.validationFailure != null) {
      return _rollbackExisting(
        targetPath: targetPath,
        staging: staging,
        moved: moved,
        snapshots: entrySnapshots,
        authoritativeManifest: authoritativeManifest,
        baseline: baseline,
        commands: commands,
        failure: finalCheck.validationFailure!,
        failureCategory: BootstrapExecutionStopCategory.ownershipMismatch,
      );
    }

    final readyGitCapture = await _captureGitState(targetPath, commands);
    if (readyGitCapture.inspectionFailure != null) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: readyGitCapture.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    final readyGit = readyGitCapture.state;
    final readyCheck = readyGitCapture.failure != null || readyGit == null
        ? const _VerificationCapture.validation(
            'Existing Repository Git state changed before Ready.',
          )
        : await _verifyExistingOwnership(
            ready,
            baseline,
            generatedEntries,
            entrySnapshots,
            readyGit,
          );
    if (readyCheck.inspectionFailure != null) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: readyCheck.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    if (readyCheck.validationFailure != null) {
      return _rollbackExisting(
        targetPath: targetPath,
        staging: staging,
        moved: moved,
        snapshots: entrySnapshots,
        authoritativeManifest: authoritativeManifest,
        baseline: baseline,
        commands: commands,
        failure: readyCheck.validationFailure!,
        failureCategory: BootstrapExecutionStopCategory.ownershipMismatch,
      );
    }
    final verifiedGit = readyGit!;

    try {
      await staging.delete();
    } on FileSystemException catch (error) {
      return _partial(
        category: BootstrapExecutionStopCategory.rollbackFailed,
        stage: BootstrapExecutionStage.finalVerification,
        targetPath: targetPath,
        stagingPath: staging.path,
        createdOrMovedEntries: moved,
        rollbackFailed: [staging.path],
        commands: commands,
        failure: error.message,
        gitMetadataAffected: false,
      );
    }

    return _preparedResult(
      ready: ready,
      git: verifiedGit,
      createdRootEntries: moved,
      commands: commands,
      factoryBaseline: factoryBaseline,
    );
  }

  Future<BootstrapExecutionResult> _preparedResult({
    required BootstrapPreflightReady ready,
    required _GitState git,
    required List<String> createdRootEntries,
    required List<BootstrapProcessResult> commands,
    required _GitState factoryBaseline,
  }) async {
    final factoryFinalCapture = await _captureGitState(
      _factoryRoot.path,
      commands,
    );
    if (factoryFinalCapture.inspectionFailure != null ||
        factoryFinalCapture.failure != null ||
        factoryFinalCapture.state == null) {
      return _factoryBaselinePartial(
        category: BootstrapExecutionStopCategory.validationEvidenceUntrusted,
        targetPath: ready.normalizedOutputPath,
        stagingPath: null,
        commands: commands,
        failure:
            'The final Factory Git state could not be captured before returning Prepared.',
      );
    }
    final finalFactory = factoryFinalCapture.state!;
    if (!_sameGitBaseline(factoryBaseline, finalFactory)) {
      return _factoryBaselinePartial(
        category: BootstrapExecutionStopCategory.factoryRepositoryChanged,
        targetPath: ready.normalizedOutputPath,
        stagingPath: null,
        commands: commands,
        failure:
            'The Factory Repository changed before the Prepared result; the installed Product was preserved.',
      );
    }
    const authorityPaths = ['README.md', 'AGENTS.md'];
    final validationCommands =
        commands.where(_isTechnicalValidationCommand).toList(growable: false);
    return BootstrapExecutionPrepared(
      validatedRequest: ready.validatedRequest,
      finalProductPath: ready.normalizedOutputPath,
      repositoryMode: ready.confirmedRepositoryMode,
      gitTopLevel: git.topLevel,
      branch: git.branch,
      headExists: git.headExists,
      hasRemotes: git.remotes.isNotEmpty,
      generatedPlatforms: const {'ios', 'android'},
      dependencyPreparationSucceeded: true,
      createdRootEntries: createdRootEntries,
      commandsCompleted: commands,
      rollbackRequired: false,
      environmentNote: _environmentNote,
      productAuthorityEvidence: ProductAuthorityEvidence(
        generatedPaths: authorityPaths,
        productLocalStartingPoint: 'AGENTS.md',
        factoryReferenceRequired: false,
      ),
      technicalValidationEvidence: BootstrapTechnicalValidationEvidence.passed(
        completedCommands: validationCommands,
        factoryRoot: finalFactory.topLevel,
        factoryBranch: finalFactory.branch,
        factoryHeadIdentity: finalFactory.headIdentity,
        factoryStatusEntries: finalFactory.status,
      ),
      firstAgreementProposal:
          FirstAgreementProposal.fromValidatedRequest(ready.validatedRequest),
      baselineHandoffProposal: BaselineHandoffProposal(
        repositoryIdentity: ready.normalizedOutputPath,
        branch: git.branch,
        headAvailable: git.headExists,
        headIdentity: git.headIdentity,
        remotePresent: git.remotes.isNotEmpty,
        gitStatusEntries: git.status,
        generatedProductAuthorityPaths: authorityPaths,
        generatedRootEntries: createdRootEntries,
      ),
    );
  }

  Future<BootstrapExecutionResult> _rollbackExisting({
    required String targetPath,
    required Directory staging,
    required List<String> moved,
    required Map<String, Map<String, String>> snapshots,
    required Map<String, String> authoritativeManifest,
    required _ExistingBaseline baseline,
    required List<BootstrapProcessResult> commands,
    required String failure,
    required BootstrapExecutionStopCategory failureCategory,
  }) async {
    final succeeded = <String>[];
    final failed = <String>[];
    try {
      await _runHook(
        BootstrapExecutionStage.rollback,
        staging.path,
        targetPath,
      );
    } catch (_) {
      failed.addAll(moved);
    }

    if (failed.isEmpty) {
      for (final entry in moved.reversed) {
        final currentPath = path.join(targetPath, entry);
        final currentCapture = await _captureSnapshot(currentPath);
        if (currentCapture.status == _SnapshotStatus.failure) {
          return _inspectionPartial(
            stage: BootstrapExecutionStage.rollback,
            targetPath: targetPath,
            stagingPath: staging.path,
            commands: commands,
            failure: currentCapture.inspectionFailure!,
            productMutationStarted: true,
            gitMetadataAffected: true,
          );
        }
        if (!currentCapture.succeeded ||
            !_sameSnapshot(snapshots[entry]!, currentCapture.manifest)) {
          failed.add(entry);
          continue;
        }
        try {
          final stagingEntryType = await _inspectType(
            path.join(staging.path, entry),
          );
          if (stagingEntryType != FileSystemEntityType.notFound) {
            failed.add(entry);
            continue;
          }
          final type = await _inspectType(currentPath);
          if (type == FileSystemEntityType.directory) {
            await Directory(currentPath).rename(
              path.join(staging.path, entry),
            );
          } else {
            await File(currentPath).rename(path.join(staging.path, entry));
          }
          succeeded.add(entry);
        } on _InspectionFault catch (fault) {
          return _inspectionPartial(
            stage: BootstrapExecutionStage.rollback,
            targetPath: targetPath,
            stagingPath: staging.path,
            commands: commands,
            failure: fault.failure,
            productMutationStarted: true,
            gitMetadataAffected: true,
          );
        } on FileSystemException {
          failed.add(entry);
        }
      }
    }

    final actualStagingCapture = await _captureSnapshot(
      staging.path,
      expectedType: FileSystemEntityType.directory,
    );
    final gitAfter = await _captureGitState(targetPath, commands);
    if (gitAfter.inspectionFailure != null) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.rollback,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: gitAfter.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: true,
      );
    }
    final rootAfterCapture = await _captureRootEntries(Directory(targetPath));
    final gitMetadataAffected = gitAfter.state == null ||
        !_sameGitPolicy(baseline.git, gitAfter.state!);
    if (actualStagingCapture.status == _SnapshotStatus.failure) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.rollback,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: actualStagingCapture.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: gitMetadataAffected,
      );
    }
    if (!rootAfterCapture.succeeded) {
      return _inspectionPartial(
        stage: BootstrapExecutionStage.rollback,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: rootAfterCapture.inspectionFailure!,
        productMutationStarted: true,
        gitMetadataAffected: gitMetadataAffected,
      );
    }
    final actualStagingManifest = actualStagingCapture.manifest;
    final stagingOwnershipConfirmed = actualStagingCapture.succeeded &&
        _sameSnapshot(authoritativeManifest, actualStagingManifest);
    final rootAfter = rootAfterCapture.entries;
    final baselineRestored = gitAfter.state != null &&
        _sameGitBaseline(baseline.git, gitAfter.state!) &&
        _sameList(baseline.rootEntries, rootAfter);
    if (failed.isNotEmpty || !baselineRestored || !stagingOwnershipConfirmed) {
      final rollbackFailures = [
        ...failed,
        if (!baselineRestored) targetPath,
        if (!stagingOwnershipConfirmed) staging.path,
      ];
      return _partial(
        category: !stagingOwnershipConfirmed || !baselineRestored
            ? BootstrapExecutionStopCategory.ownershipMismatch
            : BootstrapExecutionStopCategory.rollbackFailed,
        stage: BootstrapExecutionStage.rollback,
        targetPath: targetPath,
        stagingPath: await staging.exists() ? staging.path : null,
        createdOrMovedEntries: moved,
        rollbackSucceeded: succeeded,
        rollbackFailed: rollbackFailures,
        commands: commands,
        failure: failure,
        gitMetadataAffected: gitMetadataAffected,
        expectedManifest: authoritativeManifest,
        actualManifest: actualStagingManifest,
        ownershipDifferences: _manifestDifferences(
          authoritativeManifest,
          actualStagingManifest,
        ),
      );
    }

    try {
      await staging.delete(recursive: true);
    } on FileSystemException catch (error) {
      final cleanupCapture = await _captureSnapshot(
        staging.path,
        expectedType: FileSystemEntityType.directory,
      );
      if (cleanupCapture.status == _SnapshotStatus.failure) {
        return _inspectionPartial(
          stage: BootstrapExecutionStage.rollback,
          targetPath: targetPath,
          stagingPath: await staging.exists() ? staging.path : null,
          commands: commands,
          failure: cleanupCapture.inspectionFailure!,
          productMutationStarted: true,
          gitMetadataAffected: true,
        );
      }
      return _partial(
        category: BootstrapExecutionStopCategory.rollbackFailed,
        stage: BootstrapExecutionStage.rollback,
        targetPath: targetPath,
        stagingPath: await staging.exists() ? staging.path : null,
        createdOrMovedEntries: moved,
        rollbackSucceeded: succeeded,
        rollbackFailed: [staging.path],
        commands: commands,
        failure: error.message,
        gitMetadataAffected: false,
        expectedManifest: authoritativeManifest,
        actualManifest: cleanupCapture.manifest,
        ownershipDifferences: _manifestDifferences(
          authoritativeManifest,
          cleanupCapture.manifest,
        ),
      );
    }

    return _stopped(
      category: failureCategory,
      stage: failureCategory == BootstrapExecutionStopCategory.installFailed
          ? BootstrapExecutionStage.installation
          : BootstrapExecutionStage.finalVerification,
      commands: commands,
      validationFailure: failure,
      facts: ['Existing Repository: $targetPath'],
      evidence: const [
        'All execution-owned entries were rolled back.',
        'The root, Git metadata, branch, HEAD, remotes, and status matched the captured baseline.',
      ],
      notPerformed: const ['Ready result was not returned.'],
    );
  }

  Future<_VerificationCapture> _verifyFinalNew(
    BootstrapPreflightReady ready,
    List<BootstrapProcessResult> commands,
  ) async {
    try {
      final scaffold = await _verifyScaffold(
        Directory(ready.normalizedOutputPath),
        ready.validatedRequest.flutterProjectName,
        expectGit: true,
      );
      if (scaffold != null) {
        return _VerificationCapture.validation(scaffold);
      }
      final capture =
          await _captureGitState(ready.normalizedOutputPath, commands);
      if (capture.inspectionFailure != null) {
        return _VerificationCapture.inspection(capture.inspectionFailure!);
      }
      final state = capture.state;
      if (capture.failure != null || state == null) {
        return const _VerificationCapture.validation(
          'Final Git state could not be inspected.',
        );
      }
      if (!path.equals(state.topLevel, ready.normalizedOutputPath) ||
          state.branch != ready.validatedRequest.initialBranchName ||
          state.headExists ||
          state.remotes.isNotEmpty) {
        return const _VerificationCapture.validation(
          'Final New Repository Git evidence does not match the contract.',
        );
      }
      return const _VerificationCapture.success();
    } on _InspectionFault catch (fault) {
      return _VerificationCapture.inspection(fault.failure);
    } on FileSystemException catch (error) {
      return _VerificationCapture.inspection(
        _inspectionFailure(
          error.path ?? ready.normalizedOutputPath,
          'finalScaffoldInspection',
          error,
        ),
      );
    }
  }

  Future<_VerificationCapture> _verifyFinalExisting(
    BootstrapPreflightReady ready,
    _ExistingBaseline baseline,
    List<String> generatedEntries,
    Map<String, Map<String, String>> entrySnapshots,
    List<BootstrapProcessResult> commands,
  ) async {
    try {
      final scaffold = await _verifyScaffold(
        Directory(ready.normalizedOutputPath),
        ready.validatedRequest.flutterProjectName,
        expectGit: true,
      );
      if (scaffold != null) {
        return _VerificationCapture.validation(scaffold);
      }
      final capture =
          await _captureGitState(ready.normalizedOutputPath, commands);
      if (capture.inspectionFailure != null) {
        return _VerificationCapture.inspection(capture.inspectionFailure!);
      }
      final state = capture.state;
      if (capture.failure != null || state == null) {
        return const _VerificationCapture.validation(
          'Existing Repository Git metadata or policy changed.',
        );
      }
      return await _verifyExistingOwnership(
        ready,
        baseline,
        generatedEntries,
        entrySnapshots,
        state,
      );
    } on _InspectionFault catch (fault) {
      return _VerificationCapture.inspection(fault.failure);
    } on FileSystemException catch (error) {
      return _VerificationCapture.inspection(
        _inspectionFailure(
          error.path ?? ready.normalizedOutputPath,
          'finalScaffoldInspection',
          error,
        ),
      );
    }
  }

  Future<_VerificationCapture> _verifyExistingOwnership(
    BootstrapPreflightReady ready,
    _ExistingBaseline baseline,
    List<String> generatedEntries,
    Map<String, Map<String, String>> entrySnapshots,
    _GitState state,
  ) async {
    if (!_sameGitPolicy(baseline.git, state) ||
        !_statusPreservesBaseline(
          baseline.git.status,
          state.status,
          generatedEntries,
        )) {
      return const _VerificationCapture.validation(
        'Existing Repository Git metadata or policy changed.',
      );
    }
    final expectedRoot = [...baseline.rootEntries, ...generatedEntries]..sort();
    final actualRootCapture =
        await _captureRootEntries(Directory(ready.normalizedOutputPath));
    if (!actualRootCapture.succeeded) {
      return _VerificationCapture.inspection(
        actualRootCapture.inspectionFailure!,
      );
    }
    if (!_sameList(expectedRoot, actualRootCapture.entries)) {
      return const _VerificationCapture.validation(
        'The final Existing Repository root differs from its ownership baseline.',
      );
    }
    for (final entry in generatedEntries) {
      final actualCapture = await _captureSnapshot(
        path.join(ready.normalizedOutputPath, entry),
      );
      if (actualCapture.status == _SnapshotStatus.failure) {
        return _VerificationCapture.inspection(
          actualCapture.inspectionFailure!,
        );
      }
      if (!actualCapture.succeeded ||
          !_sameSnapshot(entrySnapshots[entry]!, actualCapture.manifest)) {
        return _VerificationCapture.validation(
          'Generated entry changed after installation: $entry',
        );
      }
    }
    return const _VerificationCapture.success();
  }

  Future<String?> _verifyScaffold(
    Directory root,
    String projectName, {
    required bool expectGit,
  }) async {
    final requiredFiles = [
      'pubspec.yaml',
      path.join('lib', 'main.dart'),
      path.join('test', 'bootstrap_smoke_test.dart'),
      '.gitignore',
    ];
    for (final relative in requiredFiles) {
      if (await _inspectType(path.join(root.path, relative)) !=
          FileSystemEntityType.file) {
        return 'Required scaffold file is missing: $relative';
      }
    }
    for (final relative in ['android', 'ios']) {
      if (await _inspectType(path.join(root.path, relative)) !=
          FileSystemEntityType.directory) {
        return 'Required platform directory is missing: $relative';
      }
    }
    for (final unsupported in ['web', 'linux', 'macos', 'windows']) {
      if (await _inspectType(path.join(root.path, unsupported)) !=
          FileSystemEntityType.notFound) {
        return 'Unsupported platform was generated: $unsupported';
      }
    }

    final gitType = await _inspectType(path.join(root.path, '.git'));
    if (expectGit && gitType != FileSystemEntityType.directory) {
      return 'A direct .git directory is required.';
    }
    if (!expectGit && gitType != FileSystemEntityType.notFound) {
      return 'Staging unexpectedly contains Git metadata.';
    }

    final pubspecContent =
        await _readText(path.join(root.path, 'pubspec.yaml'));
    final yaml = loadYaml(pubspecContent);
    if (yaml is! YamlMap || yaml['name'] != projectName) {
      return 'pubspec package name does not match the validated project name.';
    }
    final dependencies = _yamlKeys(yaml['dependencies']);
    final devDependencies = _yamlKeys(yaml['dev_dependencies']);
    if (!dependencies.contains('flutter') ||
        !devDependencies.contains('flutter_test') ||
        !const {'flutter'}.containsAll(dependencies) ||
        !const {'flutter_test', 'flutter_lints'}.containsAll(devDependencies)) {
      return 'The scaffold contains a non-default dependency.';
    }

    final main = await _readText(path.join(root.path, 'lib', 'main.dart'));
    if (!main.contains('class MainApp') ||
        main.contains('incrementCounter') ||
        main.contains('MyHomePage')) {
      return 'The generated app is not the neutral --empty scaffold.';
    }

    final smoke = await _readText(
      path.join(root.path, 'test', 'bootstrap_smoke_test.dart'),
    );
    if (!smoke.contains("package:$projectName/main.dart") ||
        !smoke.contains('const MainApp()') ||
        !smoke.contains('find.byType(MaterialApp)') ||
        smoke.contains('Hello World!')) {
      return 'The neutral smoke test does not match its contract.';
    }

    for (final forbidden in [
      'factory.yaml',
      'factory_manifest.json',
      'Docs',
      'template',
      'generator',
    ]) {
      if (await _inspectType(path.join(root.path, forbidden)) !=
          FileSystemEntityType.notFound) {
        return 'Factory-owned content was copied into the scaffold: $forbidden';
      }
    }
    return null;
  }

  Future<_AuthorityWriteCapture> _writeProductAuthority(
    Directory staging,
    ProductAuthorityDocuments documents,
  ) async {
    final root = path.normalize(staging.path);
    final readmePath = path.join(root, 'README.md');
    final agentsPath = path.join(root, 'AGENTS.md');
    final readmeTemporary = path.join(root, '.README.md.factory-authority.tmp');
    final agentsTemporary = path.join(root, '.AGENTS.md.factory-authority.tmp');
    final readmeBackup = path.join(root, '.README.md.factory-authority.backup');
    final authorityPaths = [
      readmePath,
      agentsPath,
      readmeTemporary,
      agentsTemporary,
      readmeBackup,
    ];
    if (authorityPaths.any(
      (candidate) =>
          !path.equals(path.dirname(candidate), root) ||
          !_equalsOrIsWithin(root, candidate),
    )) {
      return const _AuthorityWriteCapture.failure(
        'Product authority paths did not remain inside the staging root.',
      );
    }

    try {
      final readmeType = await _inspectType(readmePath);
      if (readmeType != FileSystemEntityType.file) {
        return _AuthorityWriteCapture.failure(
          'Generated README.md must be a regular file, not $readmeType.',
        );
      }
      final agentsType = await _inspectType(agentsPath);
      if (agentsType != FileSystemEntityType.notFound) {
        return _AuthorityWriteCapture.failure(
          'AGENTS.md must not exist before Product authority creation; found $agentsType.',
        );
      }
      for (final temporaryPath in [
        readmeTemporary,
        agentsTemporary,
        readmeBackup,
      ]) {
        final temporaryType = await _inspectType(temporaryPath);
        if (temporaryType != FileSystemEntityType.notFound) {
          return _AuthorityWriteCapture.failure(
            'Authority transaction path already exists: ${path.basename(temporaryPath)}.',
          );
        }
      }
    } on _InspectionFault catch (fault) {
      return _AuthorityWriteCapture.inspection(fault.failure);
    }

    var readmeBackedUp = false;
    var readmeInstalled = false;
    var agentsInstalled = false;
    try {
      final readmeTempFile = await File(readmeTemporary).create(
        exclusive: true,
      );
      await readmeTempFile.writeAsString(documents.readme, flush: true);
      final agentsTempFile = await File(agentsTemporary).create(
        exclusive: true,
      );
      await agentsTempFile.writeAsString(documents.agents, flush: true);

      await File(readmePath).rename(readmeBackup);
      readmeBackedUp = true;
      await File(readmeTemporary).rename(readmePath);
      readmeInstalled = true;
      await File(agentsTemporary).rename(agentsPath);
      agentsInstalled = true;
      await File(readmeBackup).delete();
      readmeBackedUp = false;
      return const _AuthorityWriteCapture.success();
    } on FileSystemException catch (error) {
      final rollbackErrors = <String>[];
      Future<void> deleteIfFile(String filePath) async {
        try {
          if (await FileSystemEntity.type(
                filePath,
                followLinks: false,
              ) ==
              FileSystemEntityType.file) {
            await File(filePath).delete();
          }
        } on FileSystemException catch (rollbackError) {
          rollbackErrors.add(rollbackError.message);
        }
      }

      if (agentsInstalled) {
        await deleteIfFile(agentsPath);
      }
      if (readmeInstalled) {
        await deleteIfFile(readmePath);
      }
      if (readmeBackedUp) {
        try {
          await File(readmeBackup).rename(readmePath);
          readmeBackedUp = false;
        } on FileSystemException catch (rollbackError) {
          rollbackErrors.add(rollbackError.message);
        }
      }
      await deleteIfFile(readmeTemporary);
      await deleteIfFile(agentsTemporary);
      if (readmeBackedUp) {
        rollbackErrors.add('README.md backup could not be restored.');
      }
      return _AuthorityWriteCapture.failure(
        'Product authority write failed: ${error.message}'
        '${rollbackErrors.isEmpty ? '' : '; rollback incomplete: ${rollbackErrors.join('; ')}'}',
      );
    }
  }

  Future<_SmokeFailure?> _generateSmokeTest(
    Directory staging,
    String projectName,
  ) async {
    try {
      await _runHook(
        BootstrapExecutionStage.smokeTestGeneration,
        staging.path,
        '',
      );
      final mainFile = File(path.join(staging.path, 'lib', 'main.dart'));
      if (!await mainFile.exists()) {
        return const _SmokeFailure(
          BootstrapExecutionStopCategory.smokeTestUnsupported,
          'Generated lib/main.dart is missing.',
        );
      }
      final main = await mainFile.readAsString();
      if (!main.contains('class MainApp') || !main.contains('const MainApp')) {
        return const _SmokeFailure(
          BootstrapExecutionStopCategory.smokeTestUnsupported,
          'Generated lib/main.dart does not expose const MainApp.',
        );
      }

      final testDirectory = Directory(path.join(staging.path, 'test'));
      await testDirectory.create();
      final smokeFile = File(
        path.join(testDirectory.path, 'bootstrap_smoke_test.dart'),
      );
      if (await FileSystemEntity.type(
            smokeFile.path,
            followLinks: false,
          ) !=
          FileSystemEntityType.notFound) {
        return const _SmokeFailure(
          BootstrapExecutionStopCategory.smokeTestConflict,
          'The smoke test path already exists.',
        );
      }
      await smokeFile.create(exclusive: true);
      await smokeFile.writeAsString(_smokeTestSource(projectName));
      return null;
    } on FileSystemException catch (error) {
      return _SmokeFailure(
        BootstrapExecutionStopCategory.smokeTestGenerationFailed,
        error.message,
      );
    }
  }

  String _smokeTestSource(String projectName) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:$projectName/main.dart';

void main() {
  testWidgets('bootstrap scaffold mounts', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
''';
  }

  Future<_GitCapture> _captureGitState(
    String repositoryPath,
    List<BootstrapProcessResult> commands,
  ) async {
    final topLevel = await _run(
      gitExecutable,
      ['rev-parse', '--show-toplevel'],
      workingDirectory: repositoryPath,
      commands: commands,
    );
    if (!topLevel.succeeded) {
      return _GitCapture(failure: topLevel);
    }
    final branch = await _run(
      gitExecutable,
      ['symbolic-ref', '--quiet', '--short', 'HEAD'],
      workingDirectory: repositoryPath,
      commands: commands,
    );
    if (!branch.didStart) {
      return _GitCapture(failure: branch);
    }
    final head = await _run(
      gitExecutable,
      ['rev-parse', '--verify', 'HEAD'],
      workingDirectory: repositoryPath,
      commands: commands,
    );
    if (!head.didStart) {
      return _GitCapture(failure: head);
    }
    final remotes = await _run(
      gitExecutable,
      ['remote'],
      workingDirectory: repositoryPath,
      commands: commands,
    );
    if (!remotes.succeeded) {
      return _GitCapture(failure: remotes);
    }
    final status = await _run(
      gitExecutable,
      ['status', '--short'],
      workingDirectory: repositoryPath,
      commands: commands,
    );
    if (!status.succeeded) {
      return _GitCapture(failure: status);
    }
    final tracked = await _run(
      gitExecutable,
      ['ls-files', '-z'],
      workingDirectory: repositoryPath,
      commands: commands,
    );
    if (!tracked.succeeded) {
      return _GitCapture(failure: tracked);
    }
    var trackedPaths = _nulSeparated(tracked.stdout).toSet();
    if (head.succeeded) {
      final headTracked = await _run(
        gitExecutable,
        ['ls-tree', '-r', '--name-only', '-z', 'HEAD'],
        workingDirectory: repositoryPath,
        commands: commands,
      );
      if (!headTracked.succeeded) {
        return _GitCapture(failure: headTracked);
      }
      trackedPaths = {...trackedPaths, ..._nulSeparated(headTracked.stdout)};
    }

    final metadataCapture = await _captureSnapshot(
      path.join(repositoryPath, '.git'),
      expectedType: FileSystemEntityType.directory,
    );
    if (metadataCapture.status == _SnapshotStatus.failure) {
      return _GitCapture(
        inspectionFailure: metadataCapture.inspectionFailure,
      );
    }
    if (!metadataCapture.succeeded) {
      return _GitCapture(
        inspectionFailure: _inspectionFailureForCapture(metadataCapture),
      );
    }
    return _GitCapture(
      state: _GitState(
        topLevel: _singleLine(topLevel.stdout),
        branch: branch.succeeded ? _singleLine(branch.stdout) : 'HEAD',
        headIdentity: head.succeeded ? _singleLine(head.stdout) : null,
        remotes: _lines(remotes.stdout),
        status: _lines(status.stdout),
        trackedPaths: trackedPaths.toList()..sort(),
        metadata: metadataCapture.manifest,
      ),
    );
  }

  Future<BootstrapProcessResult> _run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required List<BootstrapProcessResult> commands,
  }) async {
    final result = await _processRunner.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
    commands.add(result);
    return result;
  }

  Future<BootstrapExecutionResult> _stopAfterValidationFailure({
    required BootstrapPreflightReady ready,
    required BootstrapExecutionStopCategory category,
    required BootstrapExecutionStage stage,
    required List<BootstrapProcessResult> commands,
    required Directory staging,
    required String targetPath,
    required BootstrapProcessResult failedCommand,
    required List<String> completedValidationSteps,
    required List<String> unperformedValidationSteps,
  }) async {
    final ownedCapture = await _captureSnapshot(
      staging.path,
      expectedType: FileSystemEntityType.directory,
    );
    if (!ownedCapture.succeeded) {
      final failure = ownedCapture.inspectionFailure ??
          _inspectionFailureForCapture(ownedCapture);
      return _partial(
        category: BootstrapExecutionStopCategory.validationEvidenceUntrusted,
        stage: stage,
        targetPath: targetPath,
        stagingPath: staging.path,
        createdOrMovedEntries: const [],
        rollbackFailed: [staging.path],
        commands: commands,
        failure:
            'Validation failed and exact staging ownership could not be captured. '
            '${_inspectionFailureDescription(failure, stage, productMutationStarted: false)}',
        gitMetadataAffected: false,
        actualManifest: ownedCapture.manifest,
      );
    }

    var hookEvidence = <String>[];
    try {
      await _runHook(
        BootstrapExecutionStage.ownershipVerification,
        staging.path,
        targetPath,
      );
    } catch (_) {
      hookEvidence = const [
        'The ownership verification hook failed after the validation failure.',
      ];
    }

    final facts = [
      'Final target: $targetPath',
      'Failed validation step: ${stage.name}',
      'Completed validation steps: ${completedValidationSteps.isEmpty ? 'None' : completedValidationSteps.join(', ')}',
      'Product installation was not started.',
    ];
    final evidence = [
      'Failed executable: ${failedCommand.executable}',
      'Argument list: ${failedCommand.arguments.join(', ')}',
      'Working directory: ${failedCommand.workingDirectory}',
      'Exit code: ${failedCommand.exitCode?.toString() ?? 'Process did not start'}',
      'stdout captured safely: ${failedCommand.stdout.length} characters',
      'stderr captured safely: ${failedCommand.stderr.length} characters',
      ...hookEvidence,
    ];
    final notPerformed = [
      for (final step in unperformedValidationSteps)
        'Validation not performed: $step',
      'Final Product installation was not performed.',
      'Prepared, Ready, Approved, commit, remote, and push were not performed.',
    ];
    final validationFailure =
        '${stage.name} did not pass; no automatic repair or retry was performed.';

    if (ready.confirmedRepositoryMode == RepositoryMode.newRepository) {
      return _stopNewAfterOwnedCleanup(
        category: category,
        stage: stage,
        commands: commands,
        staging: staging,
        targetPath: targetPath,
        ownedManifest: ownedCapture.manifest,
        validationFailure: validationFailure,
        failedCommand: failedCommand,
        facts: facts,
        evidence: evidence,
        notPerformed: notPerformed,
      );
    }
    return _stopExistingAfterOwnedCleanup(
      category: category,
      stage: stage,
      commands: commands,
      staging: staging,
      targetPath: targetPath,
      authoritativeManifest: ownedCapture.manifest,
      failedCommand: failedCommand,
      validationFailure: validationFailure,
      facts: facts,
      evidence: evidence,
      notPerformed: notPerformed,
    );
  }

  BootstrapExecutionPartialFailure _factoryBaselinePartial({
    required BootstrapExecutionStopCategory category,
    required String targetPath,
    required String? stagingPath,
    required List<BootstrapProcessResult> commands,
    required String failure,
  }) {
    return _partial(
      category: category,
      stage: BootstrapExecutionStage.factoryBaselineVerification,
      targetPath: targetPath,
      stagingPath: stagingPath,
      createdOrMovedEntries: const [],
      rollbackFailed: const [],
      commands: commands,
      failure: failure,
      gitMetadataAffected: false,
    );
  }

  bool _isTechnicalValidationCommand(BootstrapProcessResult command) {
    if (command.executable != flutterExecutable) {
      return false;
    }
    return _sameList(command.arguments, const ['pub', 'get']) ||
        _requiredProductValidations.any(
          (validation) => _sameList(command.arguments, validation.arguments),
        );
  }

  Future<BootstrapExecutionResult> _stopNewAfterOwnedCleanup({
    required BootstrapExecutionStopCategory category,
    required BootstrapExecutionStage stage,
    required List<BootstrapProcessResult> commands,
    required Directory staging,
    required String targetPath,
    required Map<String, String> ownedManifest,
    required String validationFailure,
    BootstrapProcessResult? failedCommand,
    List<String>? facts,
    List<String>? evidence,
    List<String>? notPerformed,
  }) async {
    final stagingCapture = await _captureSnapshot(
      staging.path,
      expectedType: FileSystemEntityType.directory,
    );
    if (stagingCapture.status == _SnapshotStatus.failure) {
      return _inspectionPartial(
        stage: stage,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: stagingCapture.inspectionFailure!,
        productMutationStarted: false,
        gitMetadataAffected: true,
      );
    }

    FileSystemEntityType targetType;
    try {
      targetType = await _inspectType(targetPath);
    } on _InspectionFault catch (fault) {
      return _inspectionPartial(
        stage: stage,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: fault.failure,
        productMutationStarted: false,
        gitMetadataAffected: true,
      );
    }

    if (!stagingCapture.succeeded) {
      return _ownershipPartial(
        stage: stage,
        targetPath: targetPath,
        stagingPath: staging.path,
        createdOrMovedEntries: const [],
        commands: commands,
        expectedManifest: ownedManifest,
        actualManifest: stagingCapture.manifest,
        failure:
            'The post-manifest staging entity is missing or has an unexpected type; no cleanup was performed. Original failure: $validationFailure',
        actualManifestAvailable: false,
        rollbackFailed: [staging.path, targetPath],
      );
    }

    if (!_sameSnapshot(ownedManifest, stagingCapture.manifest)) {
      return _ownershipPartial(
        stage: stage,
        targetPath: targetPath,
        stagingPath: staging.path,
        createdOrMovedEntries: const [],
        commands: commands,
        expectedManifest: ownedManifest,
        actualManifest: stagingCapture.manifest,
        failure:
            'Staging changed after the New Repository ownership manifest was captured; no cleanup was performed. Original failure: $validationFailure',
        actualManifestAvailable: true,
        rollbackFailed: [staging.path],
      );
    }

    try {
      await staging.delete(recursive: true);
    } on FileSystemException catch (error) {
      final remainingCapture = await _captureSnapshot(
        staging.path,
        expectedType: FileSystemEntityType.directory,
      );
      if (remainingCapture.status == _SnapshotStatus.failure) {
        return _inspectionPartial(
          stage: BootstrapExecutionStage.rollback,
          targetPath: targetPath,
          stagingPath: staging.path,
          commands: commands,
          failure: remainingCapture.inspectionFailure!,
          productMutationStarted: false,
          gitMetadataAffected: true,
        );
      }
      return _partial(
        category: BootstrapExecutionStopCategory.rollbackFailed,
        stage: BootstrapExecutionStage.rollback,
        targetPath: targetPath,
        stagingPath: staging.path,
        createdOrMovedEntries: const [],
        rollbackFailed: [staging.path],
        commands: commands,
        failure:
            'Guarded staging cleanup failed: ${error.message}. Original failure: $validationFailure',
        gitMetadataAffected: _gitMetadataAffected(
          ownedManifest,
          remainingCapture.manifest,
          actualManifestAvailable: remainingCapture.succeeded,
        ),
        expectedManifest: ownedManifest,
        actualManifest: remainingCapture.manifest,
        ownershipDifferences: _manifestDifferences(
          ownedManifest,
          remainingCapture.manifest,
        ),
      );
    }

    final targetExists = targetType != FileSystemEntityType.notFound;
    return _stopped(
      category: category,
      stage: stage,
      commands: commands,
      failedCommand: failedCommand,
      validationFailure: validationFailure,
      facts: facts ??
          [
            'Final target: $targetPath',
            if (targetExists)
              'An external target exists and was preserved: $targetPath',
          ],
      evidence: [
        ...?evidence,
        'The execution-owned staging manifest matched exactly and the staging directory was removed.',
        if (targetExists)
          'Target type observed before guarded cleanup: $targetType',
      ],
      notPerformed: notPerformed ?? _notPerformedFrom(stage),
      targetUnchangedOrRestored: !targetExists,
    );
  }

  Future<BootstrapExecutionResult> _stopAfterCleanup({
    required BootstrapExecutionStopCategory category,
    required BootstrapExecutionStage stage,
    required List<BootstrapProcessResult> commands,
    required Directory staging,
    required String targetPath,
    BootstrapProcessResult? failedCommand,
    String? validationFailure,
    bool targetUnchangedOrRestored = true,
    List<String>? facts,
    List<String>? evidence,
    List<String>? notPerformed,
  }) async {
    try {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
      return _stopped(
        category: category,
        stage: stage,
        commands: commands,
        failedCommand: failedCommand,
        validationFailure: validationFailure,
        facts: facts ?? ['Final target: $targetPath'],
        evidence: [
          ...?evidence,
          'The execution-owned staging directory was removed.',
        ],
        notPerformed: notPerformed ?? _notPerformedFrom(stage),
        targetUnchangedOrRestored: targetUnchangedOrRestored,
      );
    } on FileSystemException catch (error) {
      return _partial(
        category: BootstrapExecutionStopCategory.rollbackFailed,
        stage: BootstrapExecutionStage.rollback,
        targetPath: targetPath,
        stagingPath: staging.path,
        createdOrMovedEntries: const [],
        rollbackFailed: [staging.path],
        commands: commands,
        failure: error.message,
        gitMetadataAffected: false,
      );
    }
  }

  Future<BootstrapExecutionResult> _stopExistingAfterOwnedCleanup({
    required BootstrapExecutionStopCategory category,
    required BootstrapExecutionStage stage,
    required List<BootstrapProcessResult> commands,
    required Directory staging,
    required String targetPath,
    required Map<String, String> authoritativeManifest,
    BootstrapProcessResult? failedCommand,
    String? validationFailure,
    bool targetUnchangedOrRestored = true,
    List<String>? facts,
    List<String>? evidence,
    List<String>? notPerformed,
  }) async {
    final actualCapture = await _captureSnapshot(
      staging.path,
      expectedType: FileSystemEntityType.directory,
    );
    if (actualCapture.status == _SnapshotStatus.failure) {
      return _inspectionPartial(
        stage: stage,
        targetPath: targetPath,
        stagingPath: staging.path,
        commands: commands,
        failure: actualCapture.inspectionFailure!,
        productMutationStarted: false,
        gitMetadataAffected: false,
      );
    }
    final actualManifest = actualCapture.manifest;
    if (!actualCapture.succeeded ||
        !_sameSnapshot(authoritativeManifest, actualManifest)) {
      return _ownershipPartial(
        stage: stage,
        targetPath: targetPath,
        stagingPath: await staging.exists() ? staging.path : null,
        createdOrMovedEntries: const [],
        commands: commands,
        expectedManifest: authoritativeManifest,
        actualManifest: actualManifest,
        failure:
            'Staging ownership changed after the authoritative manifest was captured; no cleanup was performed.',
        actualManifestAvailable: actualCapture.succeeded,
        rollbackFailed: [staging.path],
      );
    }
    return _stopAfterCleanup(
      category: category,
      stage: stage,
      commands: commands,
      staging: staging,
      targetPath: targetPath,
      failedCommand: failedCommand,
      validationFailure: validationFailure,
      targetUnchangedOrRestored: targetUnchangedOrRestored,
      facts: facts,
      evidence: evidence,
      notPerformed: notPerformed,
    );
  }

  BootstrapExecutionStopped _stopped({
    required BootstrapExecutionStopCategory category,
    required BootstrapExecutionStage stage,
    required List<BootstrapProcessResult> commands,
    required List<String> facts,
    required List<String> evidence,
    required List<String> notPerformed,
    BootstrapProcessResult? failedCommand,
    String? validationFailure,
    bool targetUnchangedOrRestored = true,
  }) {
    return BootstrapExecutionStopped(
      category: category,
      stage: stage,
      confirmedFacts: facts,
      failedCommand: failedCommand,
      validationFailure: validationFailure,
      targetUnchangedOrRestored: targetUnchangedOrRestored,
      evidence: evidence,
      notPerformed: notPerformed,
      commandsCompleted: commands,
    );
  }

  BootstrapExecutionPartialFailure _partial({
    required BootstrapExecutionStopCategory category,
    required BootstrapExecutionStage stage,
    required String targetPath,
    required String? stagingPath,
    required List<String> createdOrMovedEntries,
    required List<String> rollbackFailed,
    required List<BootstrapProcessResult> commands,
    required String failure,
    required bool gitMetadataAffected,
    List<String> rollbackSucceeded = const [],
    Map<String, String> expectedManifest = const {},
    Map<String, String> actualManifest = const {},
    List<String> ownershipDifferences = const [],
  }) {
    return BootstrapExecutionPartialFailure(
      category: category,
      stage: stage,
      finalTargetPath: targetPath,
      stagingPath: stagingPath,
      createdOrMovedEntries: createdOrMovedEntries,
      rollbackSucceeded: rollbackSucceeded,
      rollbackFailed: rollbackFailed,
      gitMetadataAffected: gitMetadataAffected,
      pathsRequiringUserInspection: [
        targetPath,
        if (stagingPath != null) stagingPath,
      ],
      cleanupNotPerformed: const [
        'No additional automatic deletion was attempted.',
      ],
      expectedManifest: expectedManifest,
      actualManifest: actualManifest,
      ownershipDifferences: ownershipDifferences,
      commandsCompleted: commands,
      failure: failure,
    );
  }

  BootstrapExecutionStopped _inspectionStopped({
    required BootstrapExecutionStage stage,
    required String targetPath,
    required List<BootstrapProcessResult> commands,
    required _InspectionFailure failure,
  }) {
    return _stopped(
      category: BootstrapExecutionStopCategory.filesystemMutationFailed,
      stage: stage,
      commands: commands,
      validationFailure: _inspectionFailureDescription(
        failure,
        stage,
        productMutationStarted: false,
      ),
      facts: [
        'Target: $targetPath',
        'No Product mutation was started.',
      ],
      evidence: [
        'Inspection path: ${failure.path}',
        'Failed operation: ${failure.operation}',
        'Error type: ${failure.errorType}',
        'Safe error message: ${failure.message}',
      ],
      notPerformed: _notPerformedFrom(stage),
      targetUnchangedOrRestored: true,
    );
  }

  BootstrapExecutionPartialFailure _inspectionPartial({
    required BootstrapExecutionStage stage,
    required String targetPath,
    required String? stagingPath,
    required List<BootstrapProcessResult> commands,
    required _InspectionFailure failure,
    required bool productMutationStarted,
    required bool gitMetadataAffected,
  }) {
    final inspectionPaths = <String>{
      targetPath,
      if (stagingPath != null) stagingPath,
      failure.path,
    }.toList(growable: false);
    return BootstrapExecutionPartialFailure(
      category: BootstrapExecutionStopCategory.ownershipMismatch,
      stage: stage,
      finalTargetPath: targetPath,
      stagingPath: stagingPath,
      createdOrMovedEntries: const [],
      rollbackSucceeded: const [],
      rollbackFailed: [failure.path],
      gitMetadataAffected: gitMetadataAffected,
      pathsRequiringUserInspection: inspectionPaths,
      cleanupNotPerformed: const [
        'No automatic cleanup was attempted because ownership could not be proven.',
      ],
      expectedManifest: const {},
      actualManifest: const {},
      ownershipDifferences: const [],
      commandsCompleted: commands,
      failure: _inspectionFailureDescription(
        failure,
        stage,
        productMutationStarted: productMutationStarted,
      ),
    );
  }

  String _inspectionFailureDescription(
    _InspectionFailure failure,
    BootstrapExecutionStage stage, {
    required bool productMutationStarted,
  }) {
    return 'Inspection path: ${failure.path}; '
        'Failed operation: ${failure.operation}; '
        'Error type: ${failure.errorType}; '
        'Safe error message: ${failure.message}; '
        'Stage: ${stage.name}; '
        'Product mutation started: $productMutationStarted.';
  }

  _InspectionFailure _inspectionFailureForCapture(
    _SnapshotCapture capture,
  ) {
    return _InspectionFailure(
      path: capture.path,
      operation: 'snapshot',
      errorType: capture.status == _SnapshotStatus.missing
          ? 'MissingEntity'
          : 'UnexpectedEntityType',
      message: capture.status == _SnapshotStatus.missing
          ? 'The inspected entity is missing.'
          : 'Expected entity type was not found; actual type: ${capture.actualType}.',
    );
  }

  BootstrapExecutionPartialFailure _ownershipPartial({
    required BootstrapExecutionStage stage,
    required String targetPath,
    required String? stagingPath,
    required List<String> createdOrMovedEntries,
    required List<BootstrapProcessResult> commands,
    required Map<String, String> expectedManifest,
    required Map<String, String> actualManifest,
    required String failure,
    required bool actualManifestAvailable,
    List<String>? rollbackFailed,
  }) {
    return _partial(
      category: BootstrapExecutionStopCategory.ownershipMismatch,
      stage: stage,
      targetPath: targetPath,
      stagingPath: stagingPath,
      createdOrMovedEntries: createdOrMovedEntries,
      rollbackFailed: rollbackFailed ?? [targetPath],
      commands: commands,
      failure: failure,
      gitMetadataAffected: _gitMetadataAffected(
        expectedManifest,
        actualManifest,
        actualManifestAvailable: actualManifestAvailable,
      ),
      expectedManifest: expectedManifest,
      actualManifest: actualManifest,
      ownershipDifferences: _manifestDifferences(
        expectedManifest,
        actualManifest,
      ),
    );
  }

  Future<void> _runHook(
    BootstrapExecutionStage stage,
    String stagingPath,
    String targetPath,
  ) async {
    await _executionHook?.call(
      stage,
      stagingPath: stagingPath,
      finalTargetPath: targetPath,
    );
  }

  BootstrapRequest _requestFrom(ValidatedBootstrapRequest request) {
    return BootstrapRequest(
      productDisplayName: request.productDisplayName,
      productPurpose: request.productPurpose,
      initialProductScopeOrFirstIntendedOutcome:
          request.initialProductScopeOrFirstIntendedOutcome,
      exactOutputPath: request.exactOutputPath,
      repositoryMode: request.repositoryMode.name,
      initialBranchName: request.initialBranchName,
      repositoryPolicy: request.repositoryPolicy,
      flutterProjectName: request.flutterProjectName,
      organizationIdentifier: request.organizationIdentifier,
      requestedTechnology: request.requestedTechnology,
      targetPlatforms: request.targetPlatforms,
    );
  }

  bool _sameReady(
    BootstrapPreflightReady original,
    BootstrapPreflightReady current,
  ) {
    final left = original.validatedRequest;
    final right = current.validatedRequest;
    return path.equals(
          original.normalizedOutputPath,
          current.normalizedOutputPath,
        ) &&
        left.productDisplayName == right.productDisplayName &&
        left.productPurpose == right.productPurpose &&
        left.initialProductScopeOrFirstIntendedOutcome ==
            right.initialProductScopeOrFirstIntendedOutcome &&
        left.exactOutputPath == right.exactOutputPath &&
        left.repositoryMode == right.repositoryMode &&
        left.initialBranchName == right.initialBranchName &&
        left.repositoryPolicy == right.repositoryPolicy &&
        left.flutterProjectName == right.flutterProjectName &&
        left.organizationIdentifier == right.organizationIdentifier &&
        left.requestedTechnology == right.requestedTechnology &&
        _sameList(left.targetPlatforms, right.targetPlatforms) &&
        original.inspection.targetExists == current.inspection.targetExists &&
        original.inspection.repositoryMode ==
            current.inspection.repositoryMode &&
        original.inspection.hasIndependentGitDirectory ==
            current.inspection.hasIndependentGitDirectory &&
        path.equals(
          original.inspection.nearestExistingParent,
          current.inspection.nearestExistingParent,
        ) &&
        _sameList(
          original.inspection.targetEntries,
          current.inspection.targetEntries,
        );
  }

  Future<_RootEntriesCapture> _captureRootEntries(Directory directory) async {
    try {
      await _inspect('directoryList', directory.path);
      final entries = await directory
          .list(followLinks: false)
          .map((entity) => path.basename(entity.path))
          .toList();
      entries.sort();
      return _RootEntriesCapture.success(entries);
    } on _InspectionFault catch (fault) {
      return _RootEntriesCapture.failure(fault.failure);
    } on FileSystemException catch (error) {
      return _RootEntriesCapture.failure(
        _inspectionFailure(
          directory.path,
          'directoryList',
          error,
        ),
      );
    }
  }

  Future<_SnapshotCapture> _captureSnapshot(
    String entityPath, {
    FileSystemEntityType? expectedType,
  }) async {
    try {
      final rootType = await _inspectType(entityPath);
      if (rootType == FileSystemEntityType.notFound) {
        return _SnapshotCapture.missing(entityPath);
      }
      if (expectedType != null && rootType != expectedType) {
        return _SnapshotCapture.unexpectedType(entityPath, rootType);
      }
      final manifest = await _snapshotKnownType(entityPath, rootType);
      return _SnapshotCapture.success(entityPath, manifest);
    } on _InspectionFault catch (fault) {
      return _SnapshotCapture.failure(entityPath, fault.failure);
    } on FileSystemException catch (error) {
      return _SnapshotCapture.failure(
        entityPath,
        _inspectionFailure(entityPath, 'snapshot', error),
      );
    }
  }

  Future<Map<String, String>> _snapshotKnownType(
    String entityPath,
    FileSystemEntityType rootType,
  ) async {
    final result = <String, String>{};
    await _addSnapshotEntry(
      result,
      entityPath,
      entityPath,
      rootType,
    );
    if (rootType == FileSystemEntityType.directory) {
      try {
        await _inspect('directoryList', entityPath);
        await for (final entity in Directory(entityPath)
            .list(recursive: true, followLinks: false)) {
          await _addSnapshotEntry(
            result,
            entityPath,
            entity.path,
            await _inspectType(entity.path),
          );
        }
      } on _InspectionFault {
        rethrow;
      } on FileSystemException catch (error) {
        throw _InspectionFault(
          _inspectionFailure(entityPath, 'directoryList', error),
        );
      }
    }
    return Map<String, String>.unmodifiable(result);
  }

  Future<void> _addSnapshotEntry(
    Map<String, String> result,
    String root,
    String entityPath,
    FileSystemEntityType type,
  ) async {
    final relative = path.equals(root, entityPath)
        ? '.'
        : path.relative(entityPath, from: root);
    if (type == FileSystemEntityType.file) {
      try {
        await _inspect('fileRead', entityPath);
        result[relative] = 'file:${base64Encode(
          await File(entityPath).readAsBytes(),
        )}';
      } on _InspectionFault {
        rethrow;
      } on FileSystemException catch (error) {
        throw _InspectionFault(
          _inspectionFailure(entityPath, 'fileRead', error),
        );
      }
    } else if (type == FileSystemEntityType.link) {
      try {
        await _inspect('linkTarget', entityPath);
        result[relative] = 'link:${await Link(entityPath).target()}';
      } on _InspectionFault {
        rethrow;
      } on FileSystemException catch (error) {
        throw _InspectionFault(
          _inspectionFailure(entityPath, 'linkTarget', error),
        );
      }
    } else {
      result[relative] = type.toString();
    }
  }

  Future<String> _readText(String filePath) async {
    try {
      await _inspect('fileRead', filePath);
      return await File(filePath).readAsString();
    } on _InspectionFault {
      rethrow;
    } on FileSystemException catch (error) {
      throw _InspectionFault(
        _inspectionFailure(filePath, 'fileRead', error),
      );
    }
  }

  Future<FileSystemEntityType> _inspectType(String entityPath) async {
    await _inspect('entityType', entityPath);
    try {
      return await FileSystemEntity.type(entityPath, followLinks: false);
    } on FileSystemException catch (error) {
      throw _InspectionFault(
        _inspectionFailure(entityPath, 'entityType', error),
      );
    }
  }

  Future<void> _inspect(String operation, String inspectionPath) async {
    try {
      await _inspectionHook?.call(operation, inspectionPath);
    } on FileSystemException catch (error) {
      throw _InspectionFault(
        _inspectionFailure(inspectionPath, operation, error),
      );
    }
  }

  _InspectionFailure _inspectionFailure(
    String inspectionPath,
    String operation,
    Object error,
  ) {
    return _InspectionFailure(
      path: inspectionPath,
      operation: operation,
      errorType: error.runtimeType.toString(),
      message: error is FileSystemException ? error.message : '$error',
    );
  }

  bool _sameSnapshot(
    Map<String, String> left,
    Map<String, String> right,
  ) {
    if (left.length != right.length) {
      return false;
    }
    return left.entries.every((entry) => right[entry.key] == entry.value);
  }

  bool _sameGitPolicy(_GitState left, _GitState right) {
    return path.equals(left.topLevel, right.topLevel) &&
        left.branch == right.branch &&
        left.headIdentity == right.headIdentity &&
        _sameList(left.remotes, right.remotes) &&
        _sameList(left.trackedPaths, right.trackedPaths) &&
        _sameSnapshot(left.metadata, right.metadata);
  }

  bool _sameGitBaseline(_GitState left, _GitState right) {
    return _sameGitPolicy(left, right) && _sameList(left.status, right.status);
  }

  bool _statusPreservesBaseline(
    List<String> baseline,
    List<String> current,
    List<String> generatedEntries,
  ) {
    final remaining = [...current];
    for (final entry in baseline) {
      if (!remaining.remove(entry)) {
        return false;
      }
    }
    return remaining.every((entry) {
      if (!entry.startsWith('?? ')) {
        return false;
      }
      final relative = entry.substring(3).replaceAll(RegExp(r'/$'), '');
      return generatedEntries.any(
        (generated) =>
            relative == generated || relative.startsWith('$generated/'),
      );
    });
  }

  List<String> _trackedPathConflicts(
    List<String> trackedPaths,
    Map<String, String> generatedManifest,
  ) {
    final generatedPaths = generatedManifest.keys
        .where((entry) => entry != '.' && entry != '.git')
        .map(path.normalize)
        .toList();
    final conflicts = <String>{};
    for (final tracked in trackedPaths.map(path.normalize)) {
      for (final generated in generatedPaths) {
        if (tracked == generated ||
            path.isWithin(tracked, generated) ||
            path.isWithin(generated, tracked)) {
          conflicts.add('$tracked <-> $generated');
        }
      }
    }
    final sorted = conflicts.toList()..sort();
    return sorted;
  }

  List<String> _manifestDifferences(
    Map<String, String> expected,
    Map<String, String> actual,
  ) {
    final differences = <String>[];
    for (final relative in expected.keys) {
      if (!actual.containsKey(relative)) {
        differences.add('deleted:$relative');
      } else if (expected[relative] != actual[relative]) {
        differences.add('changed:$relative');
      }
    }
    for (final relative in actual.keys) {
      if (!expected.containsKey(relative)) {
        differences.add('added:$relative');
      }
    }
    differences.sort();
    return differences;
  }

  bool _gitMetadataAffected(
    Map<String, String> expected,
    Map<String, String> actual, {
    required bool actualManifestAvailable,
  }) {
    if (!actualManifestAvailable) {
      return true;
    }
    final changedPaths = <String>{
      ...expected.keys.where(
        (relative) =>
            !actual.containsKey(relative) ||
            actual[relative] != expected[relative],
      ),
      ...actual.keys.where(
        (relative) =>
            !expected.containsKey(relative) ||
            expected[relative] != actual[relative],
      ),
    };
    return changedPaths.any(
      (relative) =>
          relative == '.git' ||
          relative.startsWith('.git/') ||
          relative.startsWith('.git${path.separator}'),
    );
  }

  bool _sameList<T>(List<T> left, List<T> right) {
    return left.length == right.length &&
        Iterable<int>.generate(left.length)
            .every((index) => left[index] == right[index]);
  }

  Set<String> _yamlKeys(Object? value) {
    if (value is! YamlMap) {
      return const {};
    }
    return value.keys.map((key) => key.toString()).toSet();
  }

  bool _equalsOrIsWithin(String parent, String child) {
    return path.equals(parent, child) || path.isWithin(parent, child);
  }

  String _singleLine(String output) {
    final lines = _lines(output);
    return lines.isEmpty ? '' : lines.single;
  }

  List<String> _lines(String output) {
    return const LineSplitter()
        .convert(output)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _nulSeparated(String output) {
    return output
        .split('\u0000')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _notPerformedFrom(BootstrapExecutionStage stage) {
    return [
      'No Product operation after ${stage.name} was performed.',
      'No commit, remote, push, Product feature, or Product authority was created.',
    ];
  }
}

final class _SmokeFailure {
  const _SmokeFailure(this.category, this.message);

  final BootstrapExecutionStopCategory category;
  final String message;
}

final class _RequiredValidation {
  const _RequiredValidation({
    required this.label,
    required this.arguments,
    required this.failureCategory,
    required this.stage,
  });

  final String label;
  final List<String> arguments;
  final BootstrapExecutionStopCategory failureCategory;
  final BootstrapExecutionStage stage;
}

final class _AuthorityWriteCapture {
  const _AuthorityWriteCapture._({
    this.failure,
    this.inspectionFailure,
  });

  const _AuthorityWriteCapture.success() : this._();

  const _AuthorityWriteCapture.failure(String failure)
      : this._(failure: failure);

  const _AuthorityWriteCapture.inspection(_InspectionFailure failure)
      : this._(inspectionFailure: failure);

  final String? failure;
  final _InspectionFailure? inspectionFailure;
}

final class _GitCapture {
  const _GitCapture({
    this.state,
    this.failure,
    this.inspectionFailure,
  });

  final _GitState? state;
  final BootstrapProcessResult? failure;
  final _InspectionFailure? inspectionFailure;
}

final class _VerificationCapture {
  const _VerificationCapture._({
    this.validationFailure,
    this.inspectionFailure,
  });

  const _VerificationCapture.success() : this._();

  const _VerificationCapture.validation(String failure)
      : this._(validationFailure: failure);

  const _VerificationCapture.inspection(_InspectionFailure failure)
      : this._(inspectionFailure: failure);

  final String? validationFailure;
  final _InspectionFailure? inspectionFailure;
}

final class _GitState {
  const _GitState({
    required this.topLevel,
    required this.branch,
    required this.headIdentity,
    required this.remotes,
    required this.status,
    required this.trackedPaths,
    required this.metadata,
  });

  final String topLevel;
  final String branch;
  final String? headIdentity;
  final List<String> remotes;
  final List<String> status;
  final List<String> trackedPaths;
  final Map<String, String> metadata;

  bool get headExists => headIdentity != null;
}

final class _ExistingBaseline {
  _ExistingBaseline({
    required this.git,
    required List<String> rootEntries,
  }) : rootEntries = List<String>.unmodifiable(rootEntries);

  final _GitState git;
  final List<String> rootEntries;
}

enum _SnapshotStatus {
  success,
  missing,
  unexpectedType,
  failure,
}

final class _SnapshotCapture {
  _SnapshotCapture._({
    required this.path,
    required this.status,
    Map<String, String>? manifest,
    this.actualType,
    this.inspectionFailure,
  }) : manifest = Map<String, String>.unmodifiable(manifest ?? const {});

  factory _SnapshotCapture.success(
    String path,
    Map<String, String> manifest,
  ) =>
      _SnapshotCapture._(
        path: path,
        status: _SnapshotStatus.success,
        manifest: manifest,
      );

  factory _SnapshotCapture.missing(String path) => _SnapshotCapture._(
        path: path,
        status: _SnapshotStatus.missing,
      );

  factory _SnapshotCapture.unexpectedType(
    String path,
    FileSystemEntityType actualType,
  ) =>
      _SnapshotCapture._(
        path: path,
        status: _SnapshotStatus.unexpectedType,
        actualType: actualType,
      );

  factory _SnapshotCapture.failure(
    String path,
    _InspectionFailure failure,
  ) =>
      _SnapshotCapture._(
        path: path,
        status: _SnapshotStatus.failure,
        inspectionFailure: failure,
      );

  final String path;
  final _SnapshotStatus status;
  final Map<String, String> manifest;
  final FileSystemEntityType? actualType;
  final _InspectionFailure? inspectionFailure;

  bool get succeeded => status == _SnapshotStatus.success;
}

final class _RootEntriesCapture {
  _RootEntriesCapture._({
    required List<String> entries,
    this.inspectionFailure,
  }) : entries = List<String>.unmodifiable(entries);

  factory _RootEntriesCapture.success(List<String> entries) =>
      _RootEntriesCapture._(entries: entries);

  factory _RootEntriesCapture.failure(_InspectionFailure failure) =>
      _RootEntriesCapture._(
        entries: const [],
        inspectionFailure: failure,
      );

  final List<String> entries;
  final _InspectionFailure? inspectionFailure;

  bool get succeeded => inspectionFailure == null;
}

final class _InspectionFailure {
  const _InspectionFailure({
    required this.path,
    required this.operation,
    required this.errorType,
    required this.message,
  });

  final String path;
  final String operation;
  final String errorType;
  final String message;
}

final class _InspectionFault implements Exception {
  const _InspectionFault(this.failure);

  final _InspectionFailure failure;
}
