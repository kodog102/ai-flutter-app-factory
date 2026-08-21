import 'dart:convert';

import '../bootstrap/product_request_file.dart' show sha256HexForRequestBytes;
import 'execution_profile.dart';

part 'execution_profile_proposal.dart';
part 'execution_profile_validation_result.dart';

final class ExecutionProfileValidator {
  const ExecutionProfileValidator();

  ExecutionProfileProposalResult propose(ExecutionProfile profile) {
    final issues = _profileIssues(profile);
    if (issues.isNotEmpty) {
      return ExecutionProfileProposalStopped._(issues: issues);
    }
    final canonicalJson = jsonEncode(_canonicalProfile(profile));
    return ExecutionProfileProposal._(
      profile: profile,
      canonicalJson: canonicalJson,
      sha256: sha256HexForRequestBytes(utf8.encode(canonicalJson)),
    );
  }

  ExecutionProfileInspectionResult inspect({
    required ExecutionProfile approvedProfile,
    required String? approvedProfileSha256,
    required ExecutionProfile plannedExecution,
  }) {
    final approvedIssues = _profileIssues(approvedProfile);
    if (approvedIssues.isNotEmpty) {
      return _inspectionStopped(
        category: ExecutionProfileStopCategory.invalidApprovedProfile,
        issues: approvedIssues,
      );
    }
    if (approvedProfileSha256 == null || approvedProfileSha256.trim().isEmpty) {
      return _inspectionStopped(
        category: ExecutionProfileStopCategory.missingApprovalEvidence,
      );
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(approvedProfileSha256)) {
      return _inspectionStopped(
        category: ExecutionProfileStopCategory.invalidApprovalEvidence,
      );
    }

    final expectedSha256 = _sha256(approvedProfile);
    if (approvedProfileSha256 != expectedSha256) {
      return _inspectionStopped(
        category: ExecutionProfileStopCategory.approvalEvidenceMismatch,
        differences: [
          ExecutionProfileDifference._(
            field: 'approvedProfileSha256',
            expectedCanonicalJson: jsonEncode(expectedSha256),
            actualCanonicalJson: jsonEncode(approvedProfileSha256),
          ),
        ],
      );
    }

    final plannedIssues = _profileIssues(plannedExecution);
    if (plannedIssues.isNotEmpty) {
      return _inspectionStopped(
        category: ExecutionProfileStopCategory.invalidPlannedExecution,
        issues: plannedIssues,
      );
    }
    final differences = _profileDifferences(
      approvedProfile,
      plannedExecution,
    );
    if (differences.isNotEmpty) {
      return _inspectionStopped(
        category: ExecutionProfileStopCategory.plannedExecutionMismatch,
        differences: differences,
      );
    }

    return ExecutionProfilePlanMatched._(
      approvedProfile: approvedProfile,
      plannedExecution: plannedExecution,
      approvedProfileSha256: approvedProfileSha256,
    );
  }

  ExecutionProfileActualResult validateActual({
    required ExecutionProfilePlanMatched matchedPlan,
    required ExecutionActual actual,
  }) {
    final reinspected = inspect(
      approvedProfile: matchedPlan.approvedProfile,
      approvedProfileSha256: matchedPlan.approvedProfileSha256,
      plannedExecution: matchedPlan.plannedExecution,
    );
    if (reinspected case ExecutionProfileInspectionStopped stopped) {
      return ExecutionProfileActualStopped._(
        category: stopped.category,
        issues: stopped.issues,
        differences: stopped.differences,
      );
    }

    final issues = _profileIssues(actual.executionProfile);
    if (actual.qaCount < 0) {
      issues.add(_invalidCount('actual.qaCount'));
    }
    if (actual.repairCount < 0) {
      issues.add(_invalidCount('actual.repairCount'));
    }
    if (actual.environmentAttempts < 0) {
      issues.add(_invalidCount('actual.environmentAttempts'));
    }
    if (actual.environmentRetries < 0) {
      issues.add(_invalidCount('actual.environmentRetries'));
    }
    if (actual.environmentMinutes < 0) {
      issues.add(_invalidCount('actual.environmentMinutes'));
    }
    if (actual.environmentRetries != actual.environmentRetryEvidence.length) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.invalidCount,
          field: 'actual.environmentRetryEvidence',
          description: '환경 재시도 횟수와 사유·증거 수가 일치하지 않는다.',
        ),
      );
    }
    if (actual.environmentRetryEvidence.any(
      (retry) => retry.reason.trim().isEmpty || retry.evidence.trim().isEmpty,
    )) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.missingValue,
          field: 'actual.environmentRetryEvidence',
          description: '환경 재시도에는 명확한 사유와 증거가 필요하다.',
        ),
      );
    }
    if (issues.isNotEmpty) {
      return ExecutionProfileActualStopped._(
        category: ExecutionProfileStopCategory.invalidActualExecution,
        issues: issues,
        differences: const [],
      );
    }

    final approved = matchedPlan.approvedProfile;
    final differences = _profileDifferences(
      approved,
      actual.executionProfile,
    );
    if (actual.qaCount != approved.qaCount) {
      differences.add(
        ExecutionProfileDifference._(
          field: 'actual.qaCount',
          expectedCanonicalJson: jsonEncode(approved.qaCount),
          actualCanonicalJson: jsonEncode(actual.qaCount),
        ),
      );
    }
    if (actual.repairCount > approved.repairLimit) {
      differences.add(
        ExecutionProfileDifference._(
          field: 'actual.repairCount',
          expectedCanonicalJson: jsonEncode('<= ${approved.repairLimit}'),
          actualCanonicalJson: jsonEncode(actual.repairCount),
        ),
      );
    }
    final budget = approved.environmentBudget;
    if (actual.environmentAttempts > budget.maximumAttempts) {
      differences.add(
        ExecutionProfileDifference._(
          field: 'actual.environmentAttempts',
          expectedCanonicalJson: jsonEncode('<= ${budget.maximumAttempts}'),
          actualCanonicalJson: jsonEncode(actual.environmentAttempts),
        ),
      );
    }
    if (actual.environmentRetries > budget.maximumRetries) {
      differences.add(
        ExecutionProfileDifference._(
          field: 'actual.environmentRetries',
          expectedCanonicalJson: jsonEncode('<= ${budget.maximumRetries}'),
          actualCanonicalJson: jsonEncode(actual.environmentRetries),
        ),
      );
    }
    if (actual.environmentMinutes > budget.maximumMinutes) {
      differences.add(
        ExecutionProfileDifference._(
          field: 'actual.environmentMinutes',
          expectedCanonicalJson: jsonEncode('<= ${budget.maximumMinutes}'),
          actualCanonicalJson: jsonEncode(actual.environmentMinutes),
        ),
      );
    }
    if (differences.isNotEmpty) {
      return ExecutionProfileActualStopped._(
        category: ExecutionProfileStopCategory.actualExecutionMismatch,
        issues: const [],
        differences: differences,
      );
    }

    return ExecutionProfileActualMatched._(
      approvedProfileSha256: matchedPlan.approvedProfileSha256,
      actual: actual,
    );
  }

  List<ExecutionProfileIssue> _profileIssues(ExecutionProfile profile) {
    final issues = <ExecutionProfileIssue>[];
    _requireStrings(issues, 'riskReasons', profile.riskReasons);
    _requireStrings(issues, 'stopConditions', profile.stopConditions);
    if (profile.capabilityTier.trim().isEmpty) {
      issues.add(_missing('capabilityTier'));
    }
    if (profile.activatedRoles.isEmpty) {
      issues.add(_missing('activatedRoles'));
    }
    if (profile.agentInstances.isEmpty) {
      issues.add(_missing('agentInstances'));
    }

    final maximumInstances = switch (profile.riskLevel) {
      ExecutionRiskLevel.low => 1,
      ExecutionRiskLevel.medium => 3,
      ExecutionRiskLevel.high => 4,
    };
    if (profile.agentInstances.length > maximumInstances) {
      issues.add(
        ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.agentBudgetExceeded,
          field: 'agentInstances',
          description: '위험도에 허용된 실행 주체 상한을 초과한다.',
        ),
      );
    }

    final instanceIds = <String>{};
    final mappedRoles = <ExecutionRole>{};
    final implementationInstances = <String>{};
    final qaInstances = <String>{};
    for (final instance in profile.agentInstances) {
      if (instance.instanceId.trim().isEmpty) {
        issues.add(_missing('agentInstances.instanceId'));
      } else if (!instanceIds.add(instance.instanceId)) {
        issues.add(_duplicate('agentInstances.instanceId'));
      }
      if (instance.roles.isEmpty) {
        issues.add(_missing('agentInstances.roles'));
      }
      mappedRoles.addAll(instance.roles);
      if (instance.roles.contains(ExecutionRole.implementation)) {
        implementationInstances.add(instance.instanceId);
      }
      if (instance.roles.contains(ExecutionRole.independentQa)) {
        qaInstances.add(instance.instanceId);
      }
    }
    if (!_setEquals(mappedRoles, profile.activatedRoles)) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.invalidRoleMapping,
          field: 'activatedRoles',
          description: '활성 역할과 실행 주체의 역할 대응이 일치하지 않는다.',
        ),
      );
    }

    final requiredRoles = switch (profile.riskLevel) {
      ExecutionRiskLevel.low => const <ExecutionRole>{},
      ExecutionRiskLevel.medium => const {
          ExecutionRole.implementation,
          ExecutionRole.independentQa,
        },
      ExecutionRiskLevel.high => const {
          ExecutionRole.architecture,
          ExecutionRole.implementation,
          ExecutionRole.independentQa,
        },
    };
    if (!profile.activatedRoles.containsAll(requiredRoles)) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.invalidRoleMapping,
          field: 'activatedRoles',
          description: '위험도에 필요한 역할이 활성화되지 않았다.',
        ),
      );
    }
    if (profile.qaCount < 0 || profile.repairLimit < 0) {
      issues.add(_invalidCount('qaCount/repairLimit'));
    }
    if (profile.riskLevel != ExecutionRiskLevel.low && profile.qaCount < 1) {
      issues.add(_invalidCount('qaCount'));
    }
    if (profile.qaCount > 0 && qaInstances.isEmpty) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.independentQaConflict,
          field: 'agentInstances',
          description: '독립 QA를 수행할 별도 실행 주체가 없다.',
        ),
      );
    }
    if (implementationInstances.intersection(qaInstances).isNotEmpty) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.independentQaConflict,
          field: 'agentInstances',
          description: 'Implementation과 독립 QA를 같은 실행 주체가 수행한다.',
        ),
      );
    }

    _validateDirectApprovalBoundary(profile, issues, instanceIds);
    _validateVerificationLadder(profile.verificationLadder, issues);
    _validateEnvironmentBudget(profile.environmentBudget, issues);
    _validateContextPack(profile.contextPack, issues);
    return issues;
  }

  void _validateDirectApprovalBoundary(
    ExecutionProfile profile,
    List<ExecutionProfileIssue> issues,
    Set<String> instanceIds,
  ) {
    final actionIds = <String>{};
    for (final action in profile.directApprovalActions) {
      if (action.actionId.trim().isEmpty || action.description.trim().isEmpty) {
        issues.add(_missing('directApprovalActions'));
      } else if (!actionIds.add(action.actionId)) {
        issues.add(_duplicate('directApprovalActions.actionId'));
      }
    }
    if (profile.directApprovalActions.isEmpty) {
      if (profile.directExecutorId != null) {
        issues.add(
          const ExecutionProfileIssue(
            category:
                ExecutionProfileIssueCategory.directApprovalBoundaryInvalid,
            field: 'directExecutorId',
            description: '직접 승인 작업이 없으면 직접 실행 주체도 없어야 한다.',
          ),
        );
      }
      return;
    }

    final executorId = profile.directExecutorId;
    if (executorId == null || !instanceIds.contains(executorId)) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.directApprovalBoundaryInvalid,
          field: 'directExecutorId',
          description: '직접 승인 작업을 수행할 실행 주체가 유효하지 않다.',
        ),
      );
      return;
    }
    final executor = profile.agentInstances.firstWhere(
      (instance) => instance.instanceId == executorId,
    );
    if (!executor.canObserveUserApproval) {
      issues.add(
        const ExecutionProfileIssue(
          category: ExecutionProfileIssueCategory.directApprovalBoundaryInvalid,
          field: 'directExecutorId',
          description: '직접 실행 주체가 사용자 승인 메시지를 확인할 수 없다.',
        ),
      );
    }
  }

  void _validateVerificationLadder(
    Set<ExecutionVerificationLevel> ladder,
    List<ExecutionProfileIssue> issues,
  ) {
    if (ladder.isEmpty) {
      issues.add(_missing('verificationLadder'));
      return;
    }
    final indexes = ladder.map((level) => level.index).toList()..sort();
    for (var index = 0; index <= indexes.last; index++) {
      if (!indexes.contains(index)) {
        issues.add(
          const ExecutionProfileIssue(
            category: ExecutionProfileIssueCategory.invalidVerificationLadder,
            field: 'verificationLadder',
            description: '검증 단계는 V0부터 연속되어야 한다.',
          ),
        );
        return;
      }
    }
  }

  void _validateEnvironmentBudget(
    ExecutionEnvironmentBudget budget,
    List<ExecutionProfileIssue> issues,
  ) {
    if (budget.maximumAttempts < 1 ||
        budget.maximumRetries < 0 ||
        budget.maximumMinutes < 1) {
      issues.add(_invalidCount('environmentBudget'));
    }
  }

  void _validateContextPack(
    ExecutionContextPack context,
    List<ExecutionProfileIssue> issues,
  ) {
    _requireStrings(
        issues, 'contextPack.approvedAgreement', context.approvedAgreement);
    _requireStrings(issues, 'contextPack.allowedFiles', context.allowedFiles);
    _requireStrings(
      issues,
      'contextPack.protectedTargets',
      context.protectedTargets,
    );
    _requireStrings(
      issues,
      'contextPack.authorityExcerpts',
      context.authorityExcerpts,
    );
    _requireStrings(
      issues,
      'contextPack.relevantTests',
      context.relevantTests,
    );
    _requireStrings(
      issues,
      'contextPack.baselinesAndCommands',
      context.baselinesAndCommands,
    );
  }

  void _requireStrings(
    List<ExecutionProfileIssue> issues,
    String field,
    List<String> values,
  ) {
    if (values.isEmpty || values.any((value) => value.trim().isEmpty)) {
      issues.add(_missing(field));
    }
    if (values.toSet().length != values.length) {
      issues.add(_duplicate(field));
    }
  }

  List<ExecutionProfileDifference> _profileDifferences(
    ExecutionProfile expected,
    ExecutionProfile actual,
  ) {
    final expectedMap = _canonicalProfile(expected);
    final actualMap = _canonicalProfile(actual);
    final differences = <ExecutionProfileDifference>[];
    for (final field in expectedMap.keys) {
      final expectedValue = expectedMap[field];
      final actualValue = actualMap[field];
      if (jsonEncode(expectedValue) != jsonEncode(actualValue)) {
        differences.add(
          ExecutionProfileDifference._(
            field: field,
            expectedCanonicalJson: jsonEncode(expectedValue),
            actualCanonicalJson: jsonEncode(actualValue),
          ),
        );
      }
    }
    return differences;
  }

  Map<String, Object?> _canonicalProfile(ExecutionProfile profile) {
    final instances = profile.agentInstances
        .map(
          (instance) => <String, Object?>{
            'instanceId': instance.instanceId,
            'roles': _enumNames(instance.roles),
            'canObserveUserApproval': instance.canObserveUserApproval,
          },
        )
        .toList()
      ..sort(
        (left, right) => (left['instanceId']! as String).compareTo(
          right['instanceId']! as String,
        ),
      );
    final actions = profile.directApprovalActions
        .map(
          (action) => <String, Object?>{
            'actionId': action.actionId,
            'description': action.description,
          },
        )
        .toList()
      ..sort(
        (left, right) => (left['actionId']! as String).compareTo(
          right['actionId']! as String,
        ),
      );
    return <String, Object?>{
      'riskLevel': profile.riskLevel.name,
      'riskReasons': _sorted(profile.riskReasons),
      'activatedRoles': _enumNames(profile.activatedRoles),
      'agentInstances': instances,
      'capabilityTier': profile.capabilityTier,
      'contextPack': <String, Object?>{
        'approvedAgreement': _sorted(profile.contextPack.approvedAgreement),
        'allowedFiles': _sorted(profile.contextPack.allowedFiles),
        'protectedTargets': _sorted(profile.contextPack.protectedTargets),
        'authorityExcerpts': _sorted(profile.contextPack.authorityExcerpts),
        'relevantTests': _sorted(profile.contextPack.relevantTests),
        'baselinesAndCommands':
            _sorted(profile.contextPack.baselinesAndCommands),
      },
      'directApprovalActions': actions,
      'directExecutorId': profile.directExecutorId,
      'verificationLadder': _enumNames(profile.verificationLadder),
      'qaCount': profile.qaCount,
      'repairLimit': profile.repairLimit,
      'environmentBudget': <String, Object?>{
        'maximumAttempts': profile.environmentBudget.maximumAttempts,
        'maximumRetries': profile.environmentBudget.maximumRetries,
        'maximumMinutes': profile.environmentBudget.maximumMinutes,
      },
      'stopConditions': _sorted(profile.stopConditions),
    };
  }

  String _sha256(ExecutionProfile profile) {
    return sha256HexForRequestBytes(
      utf8.encode(jsonEncode(_canonicalProfile(profile))),
    );
  }

  ExecutionProfileInspectionStopped _inspectionStopped({
    required ExecutionProfileStopCategory category,
    List<ExecutionProfileIssue> issues = const [],
    List<ExecutionProfileDifference> differences = const [],
  }) {
    return ExecutionProfileInspectionStopped._(
      category: category,
      issues: issues,
      differences: differences,
      notPerformed: const [
        'Product 변경',
        '실행 프로필에 따른 작업 실행',
        'QA 또는 사용자 승인 제안',
      ],
    );
  }

  ExecutionProfileIssue _missing(String field) {
    return ExecutionProfileIssue(
      category: ExecutionProfileIssueCategory.missingValue,
      field: field,
      description: '필수 값이 비어 있다.',
    );
  }

  ExecutionProfileIssue _duplicate(String field) {
    return ExecutionProfileIssue(
      category: ExecutionProfileIssueCategory.duplicateValue,
      field: field,
      description: '중복 값이 있다.',
    );
  }

  ExecutionProfileIssue _invalidCount(String field) {
    return ExecutionProfileIssue(
      category: ExecutionProfileIssueCategory.invalidCount,
      field: field,
      description: '허용되지 않는 횟수 또는 시간 값이다.',
    );
  }

  List<String> _sorted(Iterable<String> values) {
    return values.toList()..sort();
  }

  List<String> _enumNames(Iterable<Enum> values) {
    return values.map((value) => value.name).toList()..sort();
  }

  bool _setEquals<T>(Set<T> left, Set<T> right) {
    return left.length == right.length && left.containsAll(right);
  }
}
