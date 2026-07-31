import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_runtime_proposal.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/repository_mode.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/validated_bootstrap_request.dart';
import 'package:test/test.dart';

void main() {
  test('builds a fixed proposed clarification-first Agreement', () {
    final proposal = FirstAgreementProposal.fromValidatedRequest(
      _request(),
    );

    expect(proposal.goal, 'Clarify the first intended outcome.');
    expect(proposal.includedScope, ['Clarify the first intended outcome.']);
    expect(proposal.excludedScope, isNotEmpty);
    expect(proposal.acceptanceCriteria, isNotEmpty);
    expect(proposal.verification, isNotEmpty);
    expect(proposal.openQuestions, isNotEmpty);
    expect(proposal.productLocalSources, ['README.md', 'AGENTS.md']);
    expect(proposal.approvalStatus, 'Proposed — User approval required');
    expect(
      () => proposal.includedScope.add('implementation'),
      throwsUnsupportedError,
    );
    expect(
      () => proposal.productLocalSources.clear(),
      throwsUnsupportedError,
    );
  });

  test('keeps fixed validated baseline proposal status immutable', () {
    final proposal = BaselineHandoffProposal(
      repositoryIdentity: '/portable/product',
      branch: 'main',
      headAvailable: false,
      headIdentity: null,
      remotePresent: false,
      gitStatusEntries: const ['?? README.md', '?? AGENTS.md'],
      generatedProductAuthorityPaths: const ['README.md', 'AGENTS.md'],
      generatedRootEntries: const ['README.md', 'AGENTS.md', 'lib'],
    );

    expect(proposal.proposalStatus, 'Proposed');
    expect(proposal.technicalValidationStatus, 'Passed');
    expect(proposal.userApprovalStatus, 'Pending');
    expect(proposal.headAvailable, isFalse);
    expect(proposal.headIdentity, isNull);
    expect(
      () => proposal.gitStatusEntries.add('approved'),
      throwsUnsupportedError,
    );
    expect(
      () => proposal.generatedProductAuthorityPaths.clear(),
      throwsUnsupportedError,
    );
  });
}

ValidatedBootstrapRequest _request() {
  return ValidatedBootstrapRequest(
    productDisplayName: 'Product',
    productPurpose: 'Validate a Product purpose.',
    initialProductScopeOrFirstIntendedOutcome:
        'Clarify the first intended outcome.',
    exactOutputPath: '/portable/product',
    repositoryMode: RepositoryMode.newRepository,
    initialBranchName: 'main',
    repositoryPolicy: null,
    flutterProjectName: 'product',
    organizationIdentifier: 'com.example',
    requestedTechnology: 'flutter',
    targetPlatforms: const ['ios', 'android'],
  );
}
