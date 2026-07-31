import 'bootstrap_stop_reason.dart';
import 'repository_mode.dart';
import 'validated_bootstrap_request.dart';

sealed class BootstrapPreflightResult {
  const BootstrapPreflightResult();
}

final class BootstrapPreflightReady extends BootstrapPreflightResult {
  BootstrapPreflightReady({
    required this.validatedRequest,
    required this.normalizedOutputPath,
    required this.inspection,
  });

  final ValidatedBootstrapRequest validatedRequest;
  final String normalizedOutputPath;
  final BootstrapTargetInspection inspection;

  RepositoryMode get confirmedRepositoryMode => validatedRequest.repositoryMode;

  String get confirmedTechnology => validatedRequest.requestedTechnology;

  List<String> get confirmedTargetPlatforms => validatedRequest.targetPlatforms;
}

final class BootstrapPreflightStopped extends BootstrapPreflightResult {
  BootstrapPreflightStopped({
    required List<BootstrapStopReason> reasons,
    required List<String> notPerformed,
  })  : reasons = List<BootstrapStopReason>.unmodifiable(reasons),
        notPerformed = List<String>.unmodifiable(notPerformed);

  final List<BootstrapStopReason> reasons;
  final List<String> notPerformed;
}

final class BootstrapTargetInspection {
  BootstrapTargetInspection({
    required this.inspectedPath,
    required this.normalizedPath,
    required this.targetExists,
    required this.repositoryMode,
    required this.nearestExistingParent,
    required this.hasIndependentGitDirectory,
    required List<String> targetEntries,
  }) : targetEntries = List<String>.unmodifiable(targetEntries);

  final String inspectedPath;
  final String normalizedPath;
  final bool targetExists;
  final RepositoryMode repositoryMode;
  final String nearestExistingParent;
  final bool hasIndependentGitDirectory;
  final List<String> targetEntries;
}
