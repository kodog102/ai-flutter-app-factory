enum ProductAuthorityDriftCategory {
  missingContractVersion,
  unsupportedContractVersion,
  ambiguousContractVersion,
  missingRequiredSection,
  missingRequiredMarker,
}

final class ProductAuthorityDrift {
  const ProductAuthorityDrift({
    required this.category,
    required this.requirement,
  });

  final ProductAuthorityDriftCategory category;
  final String requirement;
}

final class ProductAuthorityRequirementStatus {
  const ProductAuthorityRequirementStatus({
    required this.requirement,
    required this.satisfied,
  });

  final String requirement;
  final bool satisfied;
}

enum ProductAuthorityAuditStopCategory {
  factoryRootMissing,
  factoryRootNotDirectory,
  factoryRootSymlink,
  factoryGitMetadataUnsupported,
  factoryGitInspectionFailed,
  factoryGitTopLevelMismatch,
  productRootMissing,
  productRootNotDirectory,
  productRootSymlink,
  repositoryBoundaryConflict,
  gitMetadataUnsupported,
  gitInspectionFailed,
  gitTopLevelMismatch,
  agentsMissing,
  agentsNotRegularFile,
  agentsTooLarge,
  agentsReadFailed,
  agentsChangedDuringAudit,
}

sealed class ProductAuthorityAuditResult {
  const ProductAuthorityAuditResult();
}

final class ProductAuthorityAuditReport extends ProductAuthorityAuditResult {
  ProductAuthorityAuditReport({
    required this.productRoot,
    required this.gitTopLevel,
    required this.expectedContractVersion,
    required this.detectedContractVersion,
    required List<ProductAuthorityRequirementStatus> requirements,
    required List<ProductAuthorityDrift> drifts,
  })  : requirements = List<ProductAuthorityRequirementStatus>.unmodifiable(
          requirements,
        ),
        drifts = List<ProductAuthorityDrift>.unmodifiable(drifts);

  final String productRoot;
  final String gitTopLevel;
  final String expectedContractVersion;
  final String? detectedContractVersion;
  final List<ProductAuthorityRequirementStatus> requirements;
  final List<ProductAuthorityDrift> drifts;

  bool get isCompliant => drifts.isEmpty;
}

final class ProductAuthorityAuditStopped extends ProductAuthorityAuditResult {
  ProductAuthorityAuditStopped({
    required this.category,
    required this.fieldOrFact,
    required this.description,
    required List<String> notPerformed,
  }) : notPerformed = List<String>.unmodifiable(notPerformed);

  final ProductAuthorityAuditStopCategory category;
  final String fieldOrFact;
  final String description;
  final List<String> notPerformed;
}
