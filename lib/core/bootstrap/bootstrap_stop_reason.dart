enum BootstrapStopCategory {
  missingInput,
  ambiguousInput,
  unsupportedTechnology,
  unsupportedTargetPlatforms,
  invalidFlutterProjectName,
  invalidOrganizationIdentifier,
  invalidRepositoryMode,
  invalidBranchOrRepositoryPolicy,
  unsafeOutputPath,
  outputAlreadyExists,
  outputDoesNotExist,
  targetIsNotDirectory,
  factoryBoundaryConflict,
  repositoryBoundaryConflict,
  existingRepositoryRequired,
  existingRepositoryNotEmpty,
  linkedGitMetadataUnsupported,
  gitInspectionFailed,
  filesystemInspectionFailed,
}

final class BootstrapStopReason {
  const BootstrapStopReason({
    required this.category,
    required this.fieldOrFact,
    required this.description,
  });

  final BootstrapStopCategory category;
  final String fieldOrFact;
  final String description;
}
