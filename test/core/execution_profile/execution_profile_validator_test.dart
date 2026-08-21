import 'package:ai_flutter_app_factory/core/execution_profile/execution_profile.dart';
import 'package:ai_flutter_app_factory/core/execution_profile/execution_profile_validator.dart';
import 'package:test/test.dart';

void main() {
  const validator = ExecutionProfileValidator();

  test('proposes a deterministic digest without implying approval', () {
    final first = validator.propose(_profile());
    final second = validator.propose(
      _profile(
        riskReasons: ['권한 경계', '구조 변경'],
        roles: {
          ExecutionRole.independentQa,
          ExecutionRole.implementation,
          ExecutionRole.architecture,
        },
        verification: {
          ExecutionVerificationLevel.v2,
          ExecutionVerificationLevel.v0,
          ExecutionVerificationLevel.v1,
        },
      ),
    );

    expect(first, isA<ExecutionProfileProposal>());
    expect(second, isA<ExecutionProfileProposal>());
    final proposal = first as ExecutionProfileProposal;
    expect(proposal.sha256, (second as ExecutionProfileProposal).sha256);
    expect(proposal.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(proposal.proposalStatus, 'Proposed');
    expect(proposal.userApprovalStatus, 'Pending');
  });

  test('stops an incomplete profile before proposing approval evidence', () {
    final result = validator.propose(
      _profile(
        riskReasons: const [],
        contextPack: _context(allowedFiles: const []),
      ),
    );

    expect(result, isA<ExecutionProfileProposalStopped>());
    final stopped = result as ExecutionProfileProposalStopped;
    expect(stopped.userApprovalStatus, 'NotProposed');
    expect(
      stopped.issues.map((issue) => issue.field),
      containsAll(['riskReasons', 'contextPack.allowedFiles']),
    );
  });

  test('matches approved evidence and an identical planned execution', () {
    final profile = _profile();
    final proposal = validator.propose(profile) as ExecutionProfileProposal;

    final result = validator.inspect(
      approvedProfile: profile,
      approvedProfileSha256: proposal.sha256,
      plannedExecution: _profile(),
    );

    expect(result, isA<ExecutionProfilePlanMatched>());
    final matched = result as ExecutionProfilePlanMatched;
    expect(matched.profileStatus, 'Matched');
    expect(matched.approvalEvidenceStatus, 'Matched');
    expect(matched.userApprovalStatus, 'Pending');
    expect(matched.executionStatus, 'NotPerformed');
  });

  test('stops missing, malformed, and mismatched approval evidence', () {
    final profile = _profile();

    final missing = validator.inspect(
      approvedProfile: profile,
      approvedProfileSha256: null,
      plannedExecution: profile,
    );
    final malformed = validator.inspect(
      approvedProfile: profile,
      approvedProfileSha256: 'ABC',
      plannedExecution: profile,
    );
    final mismatched = validator.inspect(
      approvedProfile: profile,
      approvedProfileSha256: List.filled(64, '0').join(),
      plannedExecution: profile,
    );

    expect(
      missing,
      isA<ExecutionProfileInspectionStopped>().having(
        (result) => result.category,
        'category',
        ExecutionProfileStopCategory.missingApprovalEvidence,
      ),
    );
    expect(
      malformed,
      isA<ExecutionProfileInspectionStopped>().having(
        (result) => result.category,
        'category',
        ExecutionProfileStopCategory.invalidApprovalEvidence,
      ),
    );
    expect(
      mismatched,
      isA<ExecutionProfileInspectionStopped>().having(
        (result) => result.category,
        'category',
        ExecutionProfileStopCategory.approvalEvidenceMismatch,
      ),
    );
  });

  test('reports planned execution differences field by field', () {
    final approved = _profile();
    final proposal = validator.propose(approved) as ExecutionProfileProposal;

    final result = validator.inspect(
      approvedProfile: approved,
      approvedProfileSha256: proposal.sha256,
      plannedExecution: _profile(capabilityTier: '상향 등급'),
    );

    expect(result, isA<ExecutionProfileInspectionStopped>());
    final stopped = result as ExecutionProfileInspectionStopped;
    expect(
      stopped.category,
      ExecutionProfileStopCategory.plannedExecutionMismatch,
    );
    expect(
      stopped.differences.map((difference) => difference.field),
      ['capabilityTier'],
    );
    expect(stopped.notPerformed, contains('Product 변경'));
  });

  test('rejects Main self-QA and a missing High-risk role', () {
    final selfQa = validator.propose(
      _profile(
        instances: [
          ExecutionAgentInstance(
            instanceId: 'main',
            roles: const {
              ExecutionRole.architecture,
              ExecutionRole.implementation,
              ExecutionRole.independentQa,
            },
            canObserveUserApproval: true,
          ),
        ],
      ),
    ) as ExecutionProfileProposalStopped;
    final missingArchitecture = validator.propose(
      _profile(
        roles: const {
          ExecutionRole.implementation,
          ExecutionRole.independentQa,
        },
        instances: _instances(
          mainRoles: const {ExecutionRole.implementation},
        ),
      ),
    ) as ExecutionProfileProposalStopped;

    expect(
      selfQa.issues.map((issue) => issue.category),
      contains(ExecutionProfileIssueCategory.independentQaConflict),
    );
    expect(
      missingArchitecture.issues.map((issue) => issue.category),
      contains(ExecutionProfileIssueCategory.invalidRoleMapping),
    );
  });

  test('requires a visible Direct Executor only for direct actions', () {
    const action = DirectApprovalAction(
      actionId: 'release',
      description: '공개 출시',
    );
    final invisible = validator.propose(
      _profile(
        actions: const [action],
        directExecutorId: 'qa',
      ),
    ) as ExecutionProfileProposalStopped;
    final unneeded = validator.propose(
      _profile(directExecutorId: 'main'),
    ) as ExecutionProfileProposalStopped;
    final valid = validator.propose(
      _profile(
        actions: const [action],
        directExecutorId: 'main',
      ),
    );

    expect(
      invisible.issues.map((issue) => issue.category),
      contains(ExecutionProfileIssueCategory.directApprovalBoundaryInvalid),
    );
    expect(
      unneeded.issues.map((issue) => issue.category),
      contains(ExecutionProfileIssueCategory.directApprovalBoundaryInvalid),
    );
    expect(valid, isA<ExecutionProfileProposal>());
  });

  test('requires a continuous verification ladder from V0', () {
    final result = validator.propose(
      _profile(
        verification: const {
          ExecutionVerificationLevel.v0,
          ExecutionVerificationLevel.v2,
        },
      ),
    ) as ExecutionProfileProposalStopped;

    expect(
      result.issues.map((issue) => issue.category),
      contains(ExecutionProfileIssueCategory.invalidVerificationLadder),
    );
  });

  test('matches an actual execution within every approved budget', () {
    final profile = _profile();
    final proposal = validator.propose(profile) as ExecutionProfileProposal;
    final matched = validator.inspect(
      approvedProfile: profile,
      approvedProfileSha256: proposal.sha256,
      plannedExecution: _profile(),
    ) as ExecutionProfilePlanMatched;

    final result = validator.validateActual(
      matchedPlan: matched,
      actual: ExecutionActual(
        executionProfile: _profile(),
        qaCount: 1,
        repairCount: 1,
        environmentAttempts: 1,
        environmentRetries: 1,
        environmentMinutes: 10,
        environmentRetryEvidence: const [
          ExecutionEnvironmentRetryEvidence(
            reason: 'SDK cache 권한 오류가 확인됨',
            evidence: '첫 실행의 권한 오류 출력',
          ),
        ],
      ),
    );

    expect(result, isA<ExecutionProfileActualMatched>());
    final actual = result as ExecutionProfileActualMatched;
    expect(actual.profileStatus, 'Matched');
    expect(actual.qaStatus, 'NotDetermined');
    expect(actual.userApprovalStatus, 'Pending');
  });

  test('stops actual role, QA, repair, and environment deviations', () {
    final profile = _profile();
    final proposal = validator.propose(profile) as ExecutionProfileProposal;
    final matched = validator.inspect(
      approvedProfile: profile,
      approvedProfileSha256: proposal.sha256,
      plannedExecution: profile,
    ) as ExecutionProfilePlanMatched;

    final result = validator.validateActual(
      matchedPlan: matched,
      actual: ExecutionActual(
        executionProfile: _profile(capabilityTier: '상향 등급'),
        qaCount: 2,
        repairCount: 2,
        environmentAttempts: 2,
        environmentRetries: 2,
        environmentMinutes: 16,
        environmentRetryEvidence: const [
          ExecutionEnvironmentRetryEvidence(
            reason: '첫 번째 환경 오류',
            evidence: '첫 번째 오류 출력',
          ),
          ExecutionEnvironmentRetryEvidence(
            reason: '두 번째 환경 오류',
            evidence: '두 번째 오류 출력',
          ),
        ],
      ),
    );

    expect(result, isA<ExecutionProfileActualStopped>());
    final stopped = result as ExecutionProfileActualStopped;
    expect(
      stopped.category,
      ExecutionProfileStopCategory.actualExecutionMismatch,
    );
    expect(
      stopped.differences.map((difference) => difference.field),
      containsAll([
        'capabilityTier',
        'actual.qaCount',
        'actual.repairCount',
        'actual.environmentAttempts',
        'actual.environmentRetries',
        'actual.environmentMinutes',
      ]),
    );
  });

  test('stops an environment retry without matching reason evidence', () {
    final profile = _profile();
    final proposal = validator.propose(profile) as ExecutionProfileProposal;
    final matched = validator.inspect(
      approvedProfile: profile,
      approvedProfileSha256: proposal.sha256,
      plannedExecution: profile,
    ) as ExecutionProfilePlanMatched;

    final result = validator.validateActual(
      matchedPlan: matched,
      actual: ExecutionActual(
        executionProfile: profile,
        qaCount: 1,
        repairCount: 0,
        environmentAttempts: 1,
        environmentRetries: 1,
        environmentMinutes: 2,
        environmentRetryEvidence: const [],
      ),
    );

    expect(result, isA<ExecutionProfileActualStopped>());
    final stopped = result as ExecutionProfileActualStopped;
    expect(
      stopped.category,
      ExecutionProfileStopCategory.invalidActualExecution,
    );
    expect(
      stopped.issues.map((issue) => issue.field),
      contains('actual.environmentRetryEvidence'),
    );
  });

  test('returns profile differences as immutable canonical strings', () {
    final approved = _profile();
    final proposal = validator.propose(approved) as ExecutionProfileProposal;

    final result = validator.inspect(
      approvedProfile: approved,
      approvedProfileSha256: proposal.sha256,
      plannedExecution: _profile(capabilityTier: '상향 등급'),
    ) as ExecutionProfileInspectionStopped;

    final difference = result.differences.single;
    expect(difference.expectedCanonicalJson, isA<String>());
    expect(difference.actualCanonicalJson, isA<String>());
    expect(() => result.differences.clear(), throwsUnsupportedError);
  });

  test('keeps profile collections immutable', () {
    final profile = _profile();
    final actual = ExecutionActual(
      executionProfile: profile,
      qaCount: 1,
      repairCount: 0,
      environmentAttempts: 1,
      environmentRetries: 1,
      environmentMinutes: 2,
      environmentRetryEvidence: const [
        ExecutionEnvironmentRetryEvidence(
          reason: '명확한 환경 오류',
          evidence: '오류 출력',
        ),
      ],
    );

    expect(() => profile.riskReasons.clear(), throwsUnsupportedError);
    expect(() => profile.activatedRoles.clear(), throwsUnsupportedError);
    expect(() => profile.agentInstances.clear(), throwsUnsupportedError);
    expect(
      () => profile.agentInstances.first.roles.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => profile.contextPack.allowedFiles.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => actual.environmentRetryEvidence.clear(),
      throwsUnsupportedError,
    );
  });
}

ExecutionProfile _profile({
  List<String> riskReasons = const ['구조 변경', '권한 경계'],
  Set<ExecutionRole> roles = const {
    ExecutionRole.architecture,
    ExecutionRole.implementation,
    ExecutionRole.independentQa,
  },
  List<ExecutionAgentInstance>? instances,
  String capabilityTier = '현재 등급',
  ExecutionContextPack? contextPack,
  List<DirectApprovalAction> actions = const [],
  String? directExecutorId,
  Set<ExecutionVerificationLevel> verification = const {
    ExecutionVerificationLevel.v0,
    ExecutionVerificationLevel.v1,
    ExecutionVerificationLevel.v2,
  },
}) {
  return ExecutionProfile(
    riskLevel: ExecutionRiskLevel.high,
    riskReasons: riskReasons,
    activatedRoles: roles,
    agentInstances: instances ?? _instances(),
    capabilityTier: capabilityTier,
    contextPack: contextPack ?? _context(),
    directApprovalActions: actions,
    directExecutorId: directExecutorId,
    verificationLadder: verification,
    qaCount: 1,
    repairLimit: 1,
    environmentBudget: const ExecutionEnvironmentBudget(
      maximumAttempts: 1,
      maximumRetries: 1,
      maximumMinutes: 15,
    ),
    stopConditions: const ['범위 편차', '검증 실패'],
  );
}

List<ExecutionAgentInstance> _instances({
  Set<ExecutionRole> mainRoles = const {
    ExecutionRole.architecture,
    ExecutionRole.implementation,
  },
}) {
  return [
    ExecutionAgentInstance(
      instanceId: 'main',
      roles: mainRoles,
      canObserveUserApproval: true,
    ),
    ExecutionAgentInstance(
      instanceId: 'qa',
      roles: const {ExecutionRole.independentQa},
      canObserveUserApproval: false,
    ),
  ];
}

ExecutionContextPack _context({
  List<String> allowedFiles = const ['lib/', 'test/'],
}) {
  return ExecutionContextPack(
    approvedAgreement: const ['P4 승인본'],
    allowedFiles: allowedFiles,
    protectedTargets: const ['dependency', 'Product Repository'],
    authorityExcerpts: const ['실행 프로필 잠금'],
    relevantTests: const ['execution_profile_validator_test.dart'],
    baselinesAndCommands: const ['main@baseline', 'dart test'],
  );
}
