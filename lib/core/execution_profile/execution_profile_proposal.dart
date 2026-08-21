part of 'execution_profile_validator.dart';

sealed class ExecutionProfileProposalResult {
  const ExecutionProfileProposalResult();
}

final class ExecutionProfileProposal extends ExecutionProfileProposalResult {
  const ExecutionProfileProposal._({
    required this.profile,
    required this.canonicalJson,
    required this.sha256,
  });

  final ExecutionProfile profile;
  final String canonicalJson;
  final String sha256;

  String get proposalStatus => 'Proposed';
  String get userApprovalStatus => 'Pending';
}

final class ExecutionProfileProposalStopped
    extends ExecutionProfileProposalResult {
  ExecutionProfileProposalStopped._({
    required List<ExecutionProfileIssue> issues,
  }) : issues = List<ExecutionProfileIssue>.unmodifiable(issues);

  final List<ExecutionProfileIssue> issues;

  String get userApprovalStatus => 'NotProposed';
}
