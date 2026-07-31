import 'bootstrap_process_runner.dart';

final class BootstrapTechnicalValidationEvidence {
  BootstrapTechnicalValidationEvidence.passed({
    required List<BootstrapProcessResult> completedCommands,
    required this.factoryRoot,
    required this.factoryBranch,
    required this.factoryHeadIdentity,
    required List<String> factoryStatusEntries,
  })  : completedCommands =
            List<BootstrapProcessResult>.unmodifiable(completedCommands),
        factoryStatusEntries = List<String>.unmodifiable(factoryStatusEntries);

  final List<BootstrapProcessResult> completedCommands;
  final String factoryRoot;
  final String factoryBranch;
  final String? factoryHeadIdentity;
  final List<String> factoryStatusEntries;

  String get dependencyPreparationStatus => 'Passed';
  String get staticAnalysisStatus => 'Passed';
  String get defaultTestsStatus => 'Passed';
  String get androidApkBuildStatus => 'Passed';
  String get iosSimulatorBuildStatus => 'Passed';
  String get factoryRepositoryUnchangedStatus => 'Confirmed';
  String get overallStatus => 'Passed';
}
