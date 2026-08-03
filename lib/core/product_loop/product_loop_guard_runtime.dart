import 'dart:io';

import 'package:path/path.dart' as path;

import 'product_loop_guard_request.dart';
import 'product_loop_guard_result.dart';
import 'product_loop_process_runner.dart';
import 'product_loop_repository_inspector.dart';
import 'product_loop_repository_snapshot.dart';

final class ProductLoopGuardRuntime {
  ProductLoopGuardRuntime({
    required Directory factoryRoot,
    ProductLoopProcessRunner? processRunner,
  })  : _factoryRoot = factoryRoot.absolute,
        _runner = processRunner ?? const SystemProductLoopProcessRunner(),
        _inspector = ProductLoopRepositoryInspector(runner: processRunner);

  final Directory _factoryRoot;
  final ProductLoopProcessRunner _runner;
  final ProductLoopRepositoryInspector _inspector;

  Future<ProductLoopBaselineCaptureResult> captureBaseline(
    Directory productRoot,
  ) async {
    final boundaryFailure = await _boundaryFailure(productRoot);
    if (boundaryFailure != null) {
      return ProductLoopBaselineCaptureStopped(
        category: boundaryFailure.category,
        evidence: [boundaryFailure.message],
      );
    }
    final captured = await _inspector.capture(productRoot.absolute);
    if (!captured.succeeded) {
      return ProductLoopBaselineCaptureStopped(
        category: ProductLoopStopCategory.gitInspectionFailed,
        evidence: [captured.failure ?? 'Product inspection failed.'],
      );
    }
    return ProductLoopBaselineProposal(snapshot: captured.snapshot!);
  }

  Future<ProductLoopInspectionResult> inspect(
    ProductLoopGuardRequest request,
  ) async {
    final captured = await captureBaseline(
      Directory(request.expectedBaseline.productRoot),
    );
    if (captured is ProductLoopBaselineCaptureStopped) {
      return ProductLoopInspectionStopped(
        category: captured.category,
        evidence: captured.evidence,
      );
    }
    final actual = (captured as ProductLoopBaselineProposal).snapshot;
    if (!request.expectedBaseline.sameIdentity(actual)) {
      return ProductLoopInspectionStopped(
        category: ProductLoopStopCategory.baselineMismatch,
        actualSnapshot: actual,
        evidence: const [
          'The actual Product state differs from the expected baseline.',
        ],
      );
    }
    return ProductLoopGuardReady(
      expectedBaseline: request.expectedBaseline,
      buildPolicy: request.buildPolicy,
    );
  }

  Future<ProductLoopValidationResult> validate(
    ProductLoopGuardReady ready,
  ) async {
    final productRoot = Directory(ready.expectedBaseline.productRoot);
    final candidateCapture = await _inspector.capture(productRoot);
    if (!candidateCapture.succeeded) {
      return _stopped(
        category: ProductLoopStopCategory.gitInspectionFailed,
        stage: ProductLoopStage.candidateCapture,
        evidence: [candidateCapture.failure ?? 'Candidate capture failed.'],
        notPerformed: _allHealthCommands(ready.buildPolicy),
      );
    }
    final candidateBefore = candidateCapture.snapshot!;
    if (!ready.expectedBaseline.sameRepositoryBoundary(candidateBefore)) {
      return _stopped(
        category: ProductLoopStopCategory.baselineMismatch,
        stage: ProductLoopStage.candidateCapture,
        evidence: const [
          'The Product root, Git top-level, branch, or HEAD changed after inspection.',
        ],
        notPerformed: _allHealthCommands(ready.buildPolicy),
        candidateBefore: candidateBefore,
      );
    }
    if (candidateBefore.readmeIdentity == null ||
        candidateBefore.agentsIdentity == null) {
      return _stopped(
        category: ProductLoopStopCategory.missingProductAuthority,
        stage: ProductLoopStage.candidateCapture,
        evidence: const ['README.md and AGENTS.md are required.'],
        notPerformed: _allHealthCommands(ready.buildPolicy),
        candidateBefore: candidateBefore,
      );
    }

    final factoryBeforeCapture = await _inspector.capture(_factoryRoot);
    if (!factoryBeforeCapture.succeeded) {
      return _stopped(
        category: ProductLoopStopCategory.gitInspectionFailed,
        stage: ProductLoopStage.candidateCapture,
        evidence: [
          factoryBeforeCapture.failure ?? 'Factory inspection failed.',
        ],
        notPerformed: _allHealthCommands(ready.buildPolicy),
        candidateBefore: candidateBefore,
      );
    }

    final commands = <ProductLoopProcessResult>[];
    ProductLoopProcessResult? failedCommand;
    for (final command in _healthCommands(ready.buildPolicy)) {
      final result = await _runner.run(
        command.executable,
        command.arguments,
        workingDirectory: candidateBefore.productRoot,
      );
      commands.add(result);
      if (!result.succeeded) {
        failedCommand = result;
        break;
      }
    }

    final candidateAfterCapture = await _inspector.capture(productRoot);
    if (!candidateAfterCapture.succeeded) {
      return _stopped(
        category: ProductLoopStopCategory.gitInspectionFailed,
        stage: ProductLoopStage.candidateRevalidation,
        evidence: [
          candidateAfterCapture.failure ?? 'Candidate reinspection failed.',
        ],
        notPerformed: _remainingCommands(ready.buildPolicy, commands.length),
        commandsCompleted: commands,
        candidateBefore: candidateBefore,
        failedCommand: failedCommand,
      );
    }
    final candidateAfter = candidateAfterCapture.snapshot!;
    if (!candidateBefore.sameIdentity(candidateAfter)) {
      return _stopped(
        category: ProductLoopStopCategory.candidateChanged,
        stage: ProductLoopStage.candidateRevalidation,
        evidence: const [
          'The QA candidate changed while the Health Gate was running.',
        ],
        notPerformed: _remainingCommands(ready.buildPolicy, commands.length),
        commandsCompleted: commands,
        candidateBefore: candidateBefore,
        candidateAfter: candidateAfter,
        failedCommand: failedCommand,
      );
    }

    final factoryAfterCapture = await _inspector.capture(_factoryRoot);
    if (!factoryAfterCapture.succeeded ||
        !factoryBeforeCapture.snapshot!.sameIdentity(
          factoryAfterCapture.snapshot!,
        )) {
      return _stopped(
        category: ProductLoopStopCategory.factoryChanged,
        stage: ProductLoopStage.candidateRevalidation,
        evidence: const [
          'The Factory state changed while the Product Health Gate was running.',
        ],
        notPerformed: _remainingCommands(ready.buildPolicy, commands.length),
        commandsCompleted: commands,
        candidateBefore: candidateBefore,
        candidateAfter: candidateAfter,
        failedCommand: failedCommand,
      );
    }
    if (failedCommand != null) {
      return _stopped(
        category: ProductLoopStopCategory.healthGateFailed,
        stage: ProductLoopStage.healthGate,
        evidence: const ['A required Flutter Health Gate command failed.'],
        notPerformed: _remainingCommands(ready.buildPolicy, commands.length),
        commandsCompleted: commands,
        candidateBefore: candidateBefore,
        candidateAfter: candidateAfter,
        failedCommand: failedCommand,
      );
    }
    return ProductLoopCandidateValidated(
      candidate: candidateAfter,
      commandsCompleted: commands,
      buildPolicy: ready.buildPolicy,
    );
  }

  Future<({ProductLoopStopCategory category, String message})?>
      _boundaryFailure(Directory productRoot) async {
    try {
      if (!await productRoot.exists()) {
        return (
          category: ProductLoopStopCategory.invalidProductRoot,
          message: 'The Product root must exist.',
        );
      }
      if (!await _factoryRoot.exists()) {
        return (
          category: ProductLoopStopCategory.repositoryBoundaryConflict,
          message: 'The Factory root must exist.',
        );
      }
      final product = path.normalize(await productRoot.resolveSymbolicLinks());
      final factory = path.normalize(await _factoryRoot.resolveSymbolicLinks());
      if (product == factory ||
          path.isWithin(factory, product) ||
          path.isWithin(product, factory)) {
        return (
          category: ProductLoopStopCategory.repositoryBoundaryConflict,
          message: 'The Factory and Product Repository boundaries overlap.',
        );
      }
      return null;
    } on FileSystemException catch (error) {
      return (
        category: ProductLoopStopCategory.repositoryBoundaryConflict,
        message: error.message,
      );
    }
  }

  ProductLoopValidationStopped _stopped({
    required ProductLoopStopCategory category,
    required ProductLoopStage stage,
    required List<String> evidence,
    required List<String> notPerformed,
    List<ProductLoopProcessResult> commandsCompleted = const [],
    ProductLoopRepositorySnapshot? candidateBefore,
    ProductLoopRepositorySnapshot? candidateAfter,
    ProductLoopProcessResult? failedCommand,
  }) {
    return ProductLoopValidationStopped(
      category: category,
      stage: stage,
      evidence: evidence,
      notPerformed: notPerformed,
      commandsCompleted: commandsCompleted,
      candidateBefore: candidateBefore,
      candidateAfter: candidateAfter,
      failedCommand: failedCommand,
    );
  }

  List<_HealthCommand> _healthCommands(ProductLoopBuildPolicy policy) {
    return [
      const _HealthCommand('dart', [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        'lib',
        'test',
      ]),
      const _HealthCommand('flutter', ['analyze']),
      const _HealthCommand('flutter', ['test']),
      if (policy == ProductLoopBuildPolicy.android ||
          policy == ProductLoopBuildPolicy.both)
        const _HealthCommand('flutter', ['build', 'apk', '--debug']),
      if (policy == ProductLoopBuildPolicy.ios ||
          policy == ProductLoopBuildPolicy.both)
        const _HealthCommand('flutter', [
          'build',
          'ios',
          '--simulator',
          '--no-codesign',
        ]),
    ];
  }

  List<String> _allHealthCommands(ProductLoopBuildPolicy policy) {
    return [for (final command in _healthCommands(policy)) command.label];
  }

  List<String> _remainingCommands(
    ProductLoopBuildPolicy policy,
    int completedCount,
  ) {
    final commands = _healthCommands(policy);
    return [
      for (var index = completedCount; index < commands.length; index++)
        commands[index].label,
    ];
  }
}

final class _HealthCommand {
  const _HealthCommand(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
  String get label => '$executable ${arguments.join(' ')}';
}
