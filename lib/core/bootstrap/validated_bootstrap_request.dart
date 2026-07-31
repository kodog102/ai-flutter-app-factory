import 'repository_mode.dart';

final class ValidatedBootstrapRequest {
  ValidatedBootstrapRequest({
    required this.productDisplayName,
    required this.productPurpose,
    required this.initialProductScopeOrFirstIntendedOutcome,
    required this.exactOutputPath,
    required this.repositoryMode,
    required this.initialBranchName,
    required this.repositoryPolicy,
    required this.flutterProjectName,
    required this.organizationIdentifier,
    required this.requestedTechnology,
    required List<String> targetPlatforms,
  }) : targetPlatforms = List<String>.unmodifiable(targetPlatforms);

  final String productDisplayName;
  final String productPurpose;
  final String initialProductScopeOrFirstIntendedOutcome;
  final String exactOutputPath;
  final RepositoryMode repositoryMode;
  final String? initialBranchName;
  final String? repositoryPolicy;
  final String flutterProjectName;
  final String organizationIdentifier;
  final String requestedTechnology;
  final List<String> targetPlatforms;
}
