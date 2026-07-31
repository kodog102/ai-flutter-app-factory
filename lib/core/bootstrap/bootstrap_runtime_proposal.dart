import 'validated_bootstrap_request.dart';

final class FirstAgreementProposal {
  FirstAgreementProposal({
    required this.goal,
    required List<String> includedScope,
    required List<String> excludedScope,
    required List<String> acceptanceCriteria,
    required List<String> verification,
    required List<String> openQuestions,
    required List<String> productLocalSources,
  })  : includedScope = List<String>.unmodifiable(includedScope),
        excludedScope = List<String>.unmodifiable(excludedScope),
        acceptanceCriteria = List<String>.unmodifiable(acceptanceCriteria),
        verification = List<String>.unmodifiable(verification),
        openQuestions = List<String>.unmodifiable(openQuestions),
        productLocalSources = List<String>.unmodifiable(productLocalSources);

  factory FirstAgreementProposal.fromValidatedRequest(
    ValidatedBootstrapRequest request,
  ) {
    return FirstAgreementProposal(
      goal: request.initialProductScopeOrFirstIntendedOutcome,
      includedScope: [request.initialProductScopeOrFirstIntendedOutcome],
      excludedScope: const [
        'Product behavior, dependencies, and implementation not explicitly approved by the User.',
      ],
      acceptanceCriteria: const [
        'The User confirms the first intended outcome, its boundaries, and observable completion evidence before implementation.',
      ],
      verification: const [
        'Compare the proposed Agreement with Product-local README.md and AGENTS.md before implementation.',
      ],
      openQuestions: const [
        'Which observable Product behavior and completion evidence should the User approve for the first implementation Agreement?',
      ],
      productLocalSources: const ['README.md', 'AGENTS.md'],
    );
  }

  final String goal;
  final List<String> includedScope;
  final List<String> excludedScope;
  final List<String> acceptanceCriteria;
  final List<String> verification;
  final List<String> openQuestions;
  final List<String> productLocalSources;
  String get approvalStatus => 'Proposed — User approval required';
}

final class BaselineHandoffProposal {
  BaselineHandoffProposal({
    required this.repositoryIdentity,
    required this.branch,
    required this.headAvailable,
    required this.headIdentity,
    required this.remotePresent,
    required List<String> gitStatusEntries,
    required List<String> generatedProductAuthorityPaths,
    required List<String> generatedRootEntries,
  })  : gitStatusEntries = List<String>.unmodifiable(gitStatusEntries),
        generatedProductAuthorityPaths =
            List<String>.unmodifiable(generatedProductAuthorityPaths),
        generatedRootEntries = List<String>.unmodifiable(generatedRootEntries);

  final String repositoryIdentity;
  final String branch;
  final bool headAvailable;
  final String? headIdentity;
  final bool remotePresent;
  final List<String> gitStatusEntries;
  final List<String> generatedProductAuthorityPaths;
  final List<String> generatedRootEntries;
  String get proposalStatus => 'Proposed';
  String get technicalValidationStatus => 'Passed';
  String get userApprovalStatus => 'Pending';
}

final class ProductAuthorityEvidence {
  ProductAuthorityEvidence({
    required List<String> generatedPaths,
    required this.productLocalStartingPoint,
    required this.factoryReferenceRequired,
  }) : generatedPaths = List<String>.unmodifiable(generatedPaths);

  final List<String> generatedPaths;
  final String productLocalStartingPoint;
  final bool factoryReferenceRequired;
}
