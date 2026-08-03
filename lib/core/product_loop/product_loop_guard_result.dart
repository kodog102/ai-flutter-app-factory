import 'product_loop_guard_request.dart';
import 'product_loop_process_runner.dart';
import 'product_loop_repository_snapshot.dart';

enum ProductLoopStopCategory {
  invalidProductRoot,
  repositoryBoundaryConflict,
  gitInspectionFailed,
  baselineMismatch,
  missingProductAuthority,
  healthGateFailed,
  candidateChanged,
  factoryChanged,
}

enum ProductLoopStage {
  baselineCapture,
  baselineInspection,
  candidateCapture,
  healthGate,
  candidateRevalidation,
}

sealed class ProductLoopBaselineCaptureResult {
  const ProductLoopBaselineCaptureResult();
}

final class ProductLoopBaselineProposal
    extends ProductLoopBaselineCaptureResult {
  const ProductLoopBaselineProposal({required this.snapshot});

  final ProductLoopRepositorySnapshot snapshot;
  String get proposalStatus => 'Proposed';
  String get userApprovalStatus => 'Pending';
}

final class ProductLoopBaselineCaptureStopped
    extends ProductLoopBaselineCaptureResult {
  ProductLoopBaselineCaptureStopped({
    required this.category,
    required List<String> evidence,
  }) : evidence = List<String>.unmodifiable(evidence);

  final ProductLoopStopCategory category;
  final List<String> evidence;
}

sealed class ProductLoopInspectionResult {
  const ProductLoopInspectionResult();
}

final class ProductLoopGuardReady extends ProductLoopInspectionResult {
  const ProductLoopGuardReady({
    required this.expectedBaseline,
    required this.buildPolicy,
  });

  final ProductLoopRepositorySnapshot expectedBaseline;
  final ProductLoopBuildPolicy buildPolicy;
  String get baselineStatus => 'Matched';
  String get userApprovalStatus => 'Pending';
}

final class ProductLoopInspectionStopped extends ProductLoopInspectionResult {
  ProductLoopInspectionStopped({
    required this.category,
    required List<String> evidence,
    this.actualSnapshot,
  }) : evidence = List<String>.unmodifiable(evidence);

  final ProductLoopStopCategory category;
  final List<String> evidence;
  final ProductLoopRepositorySnapshot? actualSnapshot;
}

sealed class ProductLoopValidationResult {
  const ProductLoopValidationResult();
}

final class ProductLoopCandidateValidated extends ProductLoopValidationResult {
  ProductLoopCandidateValidated({
    required this.candidate,
    required List<ProductLoopProcessResult> commandsCompleted,
    required this.buildPolicy,
  }) : commandsCompleted = List<ProductLoopProcessResult>.unmodifiable(
          commandsCompleted,
        );

  final ProductLoopRepositorySnapshot candidate;
  final List<ProductLoopProcessResult> commandsCompleted;
  final ProductLoopBuildPolicy buildPolicy;
  String get technicalValidationStatus => 'Passed';
  String get productContextReviewStatus => 'ReviewRequired';
  String get qaStatus => 'Pending';
  String get userApprovalStatus => 'Pending';
  String get commitStatus => 'NotPerformed';
}

final class ProductLoopValidationStopped extends ProductLoopValidationResult {
  ProductLoopValidationStopped({
    required this.category,
    required this.stage,
    required List<String> evidence,
    required List<String> notPerformed,
    required List<ProductLoopProcessResult> commandsCompleted,
    this.candidateBefore,
    this.candidateAfter,
    this.failedCommand,
  })  : evidence = List<String>.unmodifiable(evidence),
        notPerformed = List<String>.unmodifiable(notPerformed),
        commandsCompleted = List<ProductLoopProcessResult>.unmodifiable(
          commandsCompleted,
        );

  final ProductLoopStopCategory category;
  final ProductLoopStage stage;
  final List<String> evidence;
  final List<String> notPerformed;
  final List<ProductLoopProcessResult> commandsCompleted;
  final ProductLoopRepositorySnapshot? candidateBefore;
  final ProductLoopRepositorySnapshot? candidateAfter;
  final ProductLoopProcessResult? failedCommand;
  String get qaStatus => 'NotProposed';
  String get userApprovalStatus => 'Pending';
  String get commitStatus => 'NotPerformed';
}
