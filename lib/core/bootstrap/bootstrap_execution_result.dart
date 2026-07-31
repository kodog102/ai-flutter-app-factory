import 'bootstrap_execution_stop_reason.dart';
import 'bootstrap_process_runner.dart';
import 'bootstrap_runtime_proposal.dart';
import 'bootstrap_technical_validation.dart';
import 'repository_mode.dart';
import 'validated_bootstrap_request.dart';

sealed class BootstrapExecutionResult {
  const BootstrapExecutionResult();
}

final class BootstrapExecutionPrepared extends BootstrapExecutionResult {
  BootstrapExecutionPrepared({
    required this.validatedRequest,
    required this.finalProductPath,
    required this.repositoryMode,
    required this.gitTopLevel,
    required this.branch,
    required this.headExists,
    required this.hasRemotes,
    required Set<String> generatedPlatforms,
    required this.dependencyPreparationSucceeded,
    required List<String> createdRootEntries,
    required List<BootstrapProcessResult> commandsCompleted,
    required this.rollbackRequired,
    required this.environmentNote,
    required this.productAuthorityEvidence,
    required this.technicalValidationEvidence,
    required this.firstAgreementProposal,
    required this.baselineHandoffProposal,
  })  : generatedPlatforms = Set<String>.unmodifiable(generatedPlatforms),
        createdRootEntries = List<String>.unmodifiable(createdRootEntries),
        commandsCompleted =
            List<BootstrapProcessResult>.unmodifiable(commandsCompleted);

  final ValidatedBootstrapRequest validatedRequest;
  final String finalProductPath;
  final RepositoryMode repositoryMode;
  final String gitTopLevel;
  final String branch;
  final bool headExists;
  final bool hasRemotes;
  final Set<String> generatedPlatforms;
  final bool dependencyPreparationSucceeded;
  final List<String> createdRootEntries;
  final List<BootstrapProcessResult> commandsCompleted;
  final bool rollbackRequired;
  final String environmentNote;
  final ProductAuthorityEvidence productAuthorityEvidence;
  final BootstrapTechnicalValidationEvidence technicalValidationEvidence;
  final FirstAgreementProposal firstAgreementProposal;
  final BaselineHandoffProposal baselineHandoffProposal;
  String get automatedTechnicalValidationStatus =>
      technicalValidationEvidence.overallStatus;
  String get userReadyApprovalStatus => 'Pending';
  String get firstAgreementApprovalStatus => 'Pending';
}

final class BootstrapExecutionStopped extends BootstrapExecutionResult {
  BootstrapExecutionStopped({
    required this.category,
    required this.stage,
    required List<String> confirmedFacts,
    required this.targetUnchangedOrRestored,
    required List<String> evidence,
    required List<String> notPerformed,
    required List<BootstrapProcessResult> commandsCompleted,
    this.failedCommand,
    this.validationFailure,
  })  : confirmedFacts = List<String>.unmodifiable(confirmedFacts),
        evidence = List<String>.unmodifiable(evidence),
        notPerformed = List<String>.unmodifiable(notPerformed),
        commandsCompleted =
            List<BootstrapProcessResult>.unmodifiable(commandsCompleted);

  final BootstrapExecutionStopCategory category;
  final BootstrapExecutionStage stage;
  final List<String> confirmedFacts;
  final BootstrapProcessResult? failedCommand;
  final String? validationFailure;
  final bool targetUnchangedOrRestored;
  final List<String> evidence;
  final List<String> notPerformed;
  final List<BootstrapProcessResult> commandsCompleted;
}

final class BootstrapExecutionPartialFailure extends BootstrapExecutionResult {
  BootstrapExecutionPartialFailure({
    required this.category,
    required this.stage,
    required this.finalTargetPath,
    required this.stagingPath,
    required List<String> createdOrMovedEntries,
    required List<String> rollbackSucceeded,
    required List<String> rollbackFailed,
    required this.gitMetadataAffected,
    required List<String> pathsRequiringUserInspection,
    required List<String> cleanupNotPerformed,
    required List<BootstrapProcessResult> commandsCompleted,
    Map<String, String> expectedManifest = const {},
    Map<String, String> actualManifest = const {},
    List<String> ownershipDifferences = const [],
    this.failure,
  })  : createdOrMovedEntries =
            List<String>.unmodifiable(createdOrMovedEntries),
        rollbackSucceeded = List<String>.unmodifiable(rollbackSucceeded),
        rollbackFailed = List<String>.unmodifiable(rollbackFailed),
        pathsRequiringUserInspection =
            List<String>.unmodifiable(pathsRequiringUserInspection),
        cleanupNotPerformed = List<String>.unmodifiable(cleanupNotPerformed),
        expectedManifest = Map<String, String>.unmodifiable(expectedManifest),
        actualManifest = Map<String, String>.unmodifiable(actualManifest),
        ownershipDifferences = List<String>.unmodifiable(ownershipDifferences),
        commandsCompleted =
            List<BootstrapProcessResult>.unmodifiable(commandsCompleted);

  final BootstrapExecutionStopCategory category;
  final BootstrapExecutionStage stage;
  final String finalTargetPath;
  final String? stagingPath;
  final List<String> createdOrMovedEntries;
  final List<String> rollbackSucceeded;
  final List<String> rollbackFailed;
  final bool gitMetadataAffected;
  final List<String> pathsRequiringUserInspection;
  final List<String> cleanupNotPerformed;
  final Map<String, String> expectedManifest;
  final Map<String, String> actualManifest;
  final List<String> ownershipDifferences;
  final List<BootstrapProcessResult> commandsCompleted;
  final String? failure;
}
