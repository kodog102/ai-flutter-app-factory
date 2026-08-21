enum ExecutionRiskLevel { low, medium, high }

enum ExecutionRole {
  architecture,
  implementation,
  design,
  independentQa,
}

enum ExecutionVerificationLevel { v0, v1, v2, v3, v4, v5 }

final class ExecutionAgentInstance {
  ExecutionAgentInstance({
    required this.instanceId,
    required Set<ExecutionRole> roles,
    required this.canObserveUserApproval,
  }) : roles = Set<ExecutionRole>.unmodifiable(roles);

  final String instanceId;
  final Set<ExecutionRole> roles;
  final bool canObserveUserApproval;
}

final class ExecutionContextPack {
  ExecutionContextPack({
    required List<String> approvedAgreement,
    required List<String> allowedFiles,
    required List<String> protectedTargets,
    required List<String> authorityExcerpts,
    required List<String> relevantTests,
    required List<String> baselinesAndCommands,
  })  : approvedAgreement = List<String>.unmodifiable(approvedAgreement),
        allowedFiles = List<String>.unmodifiable(allowedFiles),
        protectedTargets = List<String>.unmodifiable(protectedTargets),
        authorityExcerpts = List<String>.unmodifiable(authorityExcerpts),
        relevantTests = List<String>.unmodifiable(relevantTests),
        baselinesAndCommands = List<String>.unmodifiable(
          baselinesAndCommands,
        );

  final List<String> approvedAgreement;
  final List<String> allowedFiles;
  final List<String> protectedTargets;
  final List<String> authorityExcerpts;
  final List<String> relevantTests;
  final List<String> baselinesAndCommands;
}

final class DirectApprovalAction {
  const DirectApprovalAction({
    required this.actionId,
    required this.description,
  });

  final String actionId;
  final String description;
}

final class ExecutionEnvironmentBudget {
  const ExecutionEnvironmentBudget({
    required this.maximumAttempts,
    required this.maximumRetries,
    required this.maximumMinutes,
  });

  final int maximumAttempts;
  final int maximumRetries;
  final int maximumMinutes;
}

final class ExecutionEnvironmentRetryEvidence {
  const ExecutionEnvironmentRetryEvidence({
    required this.reason,
    required this.evidence,
  });

  final String reason;
  final String evidence;
}

final class ExecutionProfile {
  ExecutionProfile({
    required this.riskLevel,
    required List<String> riskReasons,
    required Set<ExecutionRole> activatedRoles,
    required List<ExecutionAgentInstance> agentInstances,
    required this.capabilityTier,
    required this.contextPack,
    required List<DirectApprovalAction> directApprovalActions,
    required this.directExecutorId,
    required Set<ExecutionVerificationLevel> verificationLadder,
    required this.qaCount,
    required this.repairLimit,
    required this.environmentBudget,
    required List<String> stopConditions,
  })  : riskReasons = List<String>.unmodifiable(riskReasons),
        activatedRoles = Set<ExecutionRole>.unmodifiable(activatedRoles),
        agentInstances = List<ExecutionAgentInstance>.unmodifiable(
          agentInstances,
        ),
        directApprovalActions = List<DirectApprovalAction>.unmodifiable(
          directApprovalActions,
        ),
        verificationLadder = Set<ExecutionVerificationLevel>.unmodifiable(
          verificationLadder,
        ),
        stopConditions = List<String>.unmodifiable(stopConditions);

  final ExecutionRiskLevel riskLevel;
  final List<String> riskReasons;
  final Set<ExecutionRole> activatedRoles;
  final List<ExecutionAgentInstance> agentInstances;
  final String capabilityTier;
  final ExecutionContextPack contextPack;
  final List<DirectApprovalAction> directApprovalActions;
  final String? directExecutorId;
  final Set<ExecutionVerificationLevel> verificationLadder;
  final int qaCount;
  final int repairLimit;
  final ExecutionEnvironmentBudget environmentBudget;
  final List<String> stopConditions;
}

final class ExecutionActual {
  ExecutionActual({
    required this.executionProfile,
    required this.qaCount,
    required this.repairCount,
    required this.environmentAttempts,
    required this.environmentRetries,
    required this.environmentMinutes,
    required List<ExecutionEnvironmentRetryEvidence> environmentRetryEvidence,
  }) : environmentRetryEvidence =
            List<ExecutionEnvironmentRetryEvidence>.unmodifiable(
          environmentRetryEvidence,
        );

  final ExecutionProfile executionProfile;
  final int qaCount;
  final int repairCount;
  final int environmentAttempts;
  final int environmentRetries;
  final int environmentMinutes;
  final List<ExecutionEnvironmentRetryEvidence> environmentRetryEvidence;
}
