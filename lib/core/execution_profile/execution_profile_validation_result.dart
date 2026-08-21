part of 'execution_profile_validator.dart';

enum ExecutionProfileIssueCategory {
  missingValue,
  duplicateValue,
  invalidRoleMapping,
  agentBudgetExceeded,
  independentQaConflict,
  directApprovalBoundaryInvalid,
  invalidVerificationLadder,
  invalidCount,
}

final class ExecutionProfileIssue {
  const ExecutionProfileIssue({
    required this.category,
    required this.field,
    required this.description,
  });

  final ExecutionProfileIssueCategory category;
  final String field;
  final String description;
}

final class ExecutionProfileDifference {
  const ExecutionProfileDifference._({
    required this.field,
    required this.expectedCanonicalJson,
    required this.actualCanonicalJson,
  });

  final String field;
  final String expectedCanonicalJson;
  final String actualCanonicalJson;
}

enum ExecutionProfileStopCategory {
  invalidApprovedProfile,
  missingApprovalEvidence,
  invalidApprovalEvidence,
  approvalEvidenceMismatch,
  invalidPlannedExecution,
  plannedExecutionMismatch,
  invalidActualExecution,
  actualExecutionMismatch,
}

sealed class ExecutionProfileInspectionResult {
  const ExecutionProfileInspectionResult();
}

final class ExecutionProfilePlanMatched
    extends ExecutionProfileInspectionResult {
  const ExecutionProfilePlanMatched._({
    required this.approvedProfile,
    required this.plannedExecution,
    required this.approvedProfileSha256,
  });

  final ExecutionProfile approvedProfile;
  final ExecutionProfile plannedExecution;
  final String approvedProfileSha256;

  String get profileStatus => 'Matched';
  String get approvalEvidenceStatus => 'Matched';
  String get userApprovalStatus => 'Pending';
  String get executionStatus => 'NotPerformed';
}

final class ExecutionProfileInspectionStopped
    extends ExecutionProfileInspectionResult {
  ExecutionProfileInspectionStopped._({
    required this.category,
    required List<ExecutionProfileIssue> issues,
    required List<ExecutionProfileDifference> differences,
    required List<String> notPerformed,
  })  : issues = List<ExecutionProfileIssue>.unmodifiable(issues),
        differences = List<ExecutionProfileDifference>.unmodifiable(
          differences,
        ),
        notPerformed = List<String>.unmodifiable(notPerformed);

  final ExecutionProfileStopCategory category;
  final List<ExecutionProfileIssue> issues;
  final List<ExecutionProfileDifference> differences;
  final List<String> notPerformed;

  String get executionStatus => 'NotPerformed';
}

sealed class ExecutionProfileActualResult {
  const ExecutionProfileActualResult();
}

final class ExecutionProfileActualMatched extends ExecutionProfileActualResult {
  const ExecutionProfileActualMatched._({
    required this.approvedProfileSha256,
    required this.actual,
  });

  final String approvedProfileSha256;
  final ExecutionActual actual;

  String get profileStatus => 'Matched';
  String get qaStatus => 'NotDetermined';
  String get userApprovalStatus => 'Pending';
}

final class ExecutionProfileActualStopped extends ExecutionProfileActualResult {
  ExecutionProfileActualStopped._({
    required this.category,
    required List<ExecutionProfileIssue> issues,
    required List<ExecutionProfileDifference> differences,
  })  : issues = List<ExecutionProfileIssue>.unmodifiable(issues),
        differences = List<ExecutionProfileDifference>.unmodifiable(
          differences,
        );

  final ExecutionProfileStopCategory category;
  final List<ExecutionProfileIssue> issues;
  final List<ExecutionProfileDifference> differences;

  String get qaStatus => 'NotProposed';
  String get userApprovalStatus => 'Pending';
}
