import 'dart:convert';

import 'bootstrap_execution_result.dart';
import 'bootstrap_preflight_result.dart';
import 'bootstrap_process_runner.dart';
import 'product_request_file.dart';

const int bootstrapCommandSchemaVersion = 1;

final class BootstrapCommandReport {
  const BootstrapCommandReport._();

  static String help({required int exitCode}) {
    return _encode({
      'commandSchemaVersion': bootstrapCommandSchemaVersion,
      'outcomeState': 'help',
      'exitCode': exitCode,
      'usage':
          'dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml',
      'supportedArguments': ['--request <absolute path>', '--help'],
      'approvalStatuses': _pendingApprovals,
    });
  }

  static String usage({required int exitCode}) {
    return _encode({
      'commandSchemaVersion': bootstrapCommandSchemaVersion,
      'outcomeState': 'usageError',
      'exitCode': exitCode,
      'usage':
          'dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml',
      'approvalStatuses': _pendingApprovals,
    });
  }

  static String requestStopped({
    required int exitCode,
    required ProductRequestFileStopped stopped,
  }) {
    return _encode({
      'commandSchemaVersion': bootstrapCommandSchemaVersion,
      'outcomeState': 'requestStopped',
      'exitCode': exitCode,
      'requestEvidence': {
        if (stopped.requestSha256 != null) 'sha256': stopped.requestSha256,
      },
      'requestIssues': [
        for (final issue in stopped.issues)
          {
            'code': issue.code.name,
            'field': issue.field,
            'message': issue.message,
          },
      ],
      'approvalStatuses': _pendingApprovals,
    });
  }

  static String preflightStopped({
    required int exitCode,
    required ProductRequestFileReady requestFile,
    required BootstrapPreflightStopped stopped,
  }) {
    return _encode({
      ..._base(
        outcomeState: 'preflightStopped',
        exitCode: exitCode,
        requestFile: requestFile,
      ),
      'preflight': {
        'status': 'stopped',
        'reasons': [
          for (final reason in stopped.reasons)
            {
              'category': reason.category.name,
              'fieldOrFact': reason.fieldOrFact,
              'description': reason.description,
            },
        ],
        'notPerformed': stopped.notPerformed,
      },
    });
  }

  static String execution({
    required int exitCode,
    required ProductRequestFileReady requestFile,
    required BootstrapExecutionResult result,
  }) {
    final details = switch (result) {
      BootstrapExecutionPrepared prepared => _prepared(prepared),
      BootstrapExecutionStopped stopped => _stopped(stopped),
      BootstrapExecutionPartialFailure partial => _partial(partial),
    };
    final outcome = switch (result) {
      BootstrapExecutionPrepared() => 'prepared',
      BootstrapExecutionStopped() => 'executionStopped',
      BootstrapExecutionPartialFailure() => 'partialFailure',
    };
    return _encode({
      ..._base(
        outcomeState: outcome,
        exitCode: exitCode,
        requestFile: requestFile,
      ),
      'execution': details,
    });
  }

  static String unexpected({required int exitCode}) {
    return _encode({
      'commandSchemaVersion': bootstrapCommandSchemaVersion,
      'outcomeState': 'unexpectedCommandFailure',
      'exitCode': exitCode,
      'failure': {
        'message':
            'The command layer failed before a safe result was available.',
      },
      'approvalStatuses': _pendingApprovals,
    });
  }

  static Map<String, Object?> _base({
    required String outcomeState,
    required int exitCode,
    required ProductRequestFileReady requestFile,
  }) {
    return {
      'commandSchemaVersion': bootstrapCommandSchemaVersion,
      'outcomeState': outcomeState,
      'exitCode': exitCode,
      'requestEvidence': {
        if (requestFile.requestId != null) 'requestId': requestFile.requestId,
        'sha256': requestFile.requestSha256,
      },
      'approvalStatuses': _pendingApprovals,
    };
  }

  static const Map<String, String> _pendingApprovals = {
    'readyApprovalStatus': 'Pending',
    'agreementApprovalStatus': 'Pending',
  };

  static Map<String, Object?> _prepared(BootstrapExecutionPrepared result) {
    return {
      'status': 'prepared',
      'product': {
        'path': result.finalProductPath,
        'repositoryMode': result.repositoryMode.name,
        'gitTopLevel': result.gitTopLevel,
        'branch': result.branch,
        'headAvailable': result.headExists,
        'remotePresent': result.hasRemotes,
        'generatedPlatforms': result.generatedPlatforms.toList()..sort(),
        'createdRootEntries': result.createdRootEntries,
      },
      'commandsCompleted': _commands(result.commandsCompleted),
      'productAuthority': {
        'generatedPaths': result.productAuthorityEvidence.generatedPaths,
        'productLocalStartingPoint':
            result.productAuthorityEvidence.productLocalStartingPoint,
        'factoryReferenceRequired':
            result.productAuthorityEvidence.factoryReferenceRequired,
      },
      'technicalValidationEvidence': {
        'overallStatus': result.technicalValidationEvidence.overallStatus,
        'dependencyPreparationStatus':
            result.technicalValidationEvidence.dependencyPreparationStatus,
        'staticAnalysisStatus':
            result.technicalValidationEvidence.staticAnalysisStatus,
        'defaultTestsStatus':
            result.technicalValidationEvidence.defaultTestsStatus,
        'androidApkBuildStatus':
            result.technicalValidationEvidence.androidApkBuildStatus,
        'iosSimulatorBuildStatus':
            result.technicalValidationEvidence.iosSimulatorBuildStatus,
        'factoryRepositoryUnchangedStatus':
            result.technicalValidationEvidence.factoryRepositoryUnchangedStatus,
        'factory': {
          'root': result.technicalValidationEvidence.factoryRoot,
          'branch': result.technicalValidationEvidence.factoryBranch,
          'headIdentity':
              result.technicalValidationEvidence.factoryHeadIdentity,
          'statusEntries':
              result.technicalValidationEvidence.factoryStatusEntries,
        },
      },
      'firstAgreementProposal': {
        'goal': result.firstAgreementProposal.goal,
        'includedScope': result.firstAgreementProposal.includedScope,
        'excludedScope': result.firstAgreementProposal.excludedScope,
        'acceptanceCriteria': result.firstAgreementProposal.acceptanceCriteria,
        'verification': result.firstAgreementProposal.verification,
        'openQuestions': result.firstAgreementProposal.openQuestions,
        'productLocalSources':
            result.firstAgreementProposal.productLocalSources,
        'approvalStatus': 'Pending',
      },
      'baselineHandoffProposal': {
        'repositoryIdentity': result.baselineHandoffProposal.repositoryIdentity,
        'branch': result.baselineHandoffProposal.branch,
        'headAvailable': result.baselineHandoffProposal.headAvailable,
        'headIdentity': result.baselineHandoffProposal.headIdentity,
        'remotePresent': result.baselineHandoffProposal.remotePresent,
        'gitStatusEntries': result.baselineHandoffProposal.gitStatusEntries,
        'generatedProductAuthorityPaths':
            result.baselineHandoffProposal.generatedProductAuthorityPaths,
        'generatedRootEntries':
            result.baselineHandoffProposal.generatedRootEntries,
        'proposalStatus': result.baselineHandoffProposal.proposalStatus,
        'technicalValidationStatus':
            result.baselineHandoffProposal.technicalValidationStatus,
        'userApprovalStatus': 'Pending',
      },
    };
  }

  static Map<String, Object?> _stopped(BootstrapExecutionStopped result) {
    return {
      'status': 'stopped',
      'category': result.category.name,
      'stage': result.stage.name,
      'confirmedFacts': result.confirmedFacts,
      'targetUnchangedOrRestored': result.targetUnchangedOrRestored,
      'evidence': result.evidence,
      'notPerformed': result.notPerformed,
      'commandsCompleted': _commands(result.commandsCompleted),
      if (result.failedCommand != null)
        'failedCommand': _command(result.failedCommand!),
      if (result.validationFailure != null)
        'validationFailure': result.validationFailure,
    };
  }

  static Map<String, Object?> _partial(
    BootstrapExecutionPartialFailure result,
  ) {
    return {
      'status': 'partialFailure',
      'category': result.category.name,
      'stage': result.stage.name,
      'finalTargetPath': result.finalTargetPath,
      'stagingPath': result.stagingPath,
      'createdOrMovedEntries': result.createdOrMovedEntries,
      'rollbackSucceeded': result.rollbackSucceeded,
      'rollbackFailed': result.rollbackFailed,
      'gitMetadataAffected': result.gitMetadataAffected,
      'pathsRequiringUserInspection': result.pathsRequiringUserInspection,
      'cleanupNotPerformed': result.cleanupNotPerformed,
      'expectedManifest': result.expectedManifest,
      'actualManifest': result.actualManifest,
      'ownershipDifferences': result.ownershipDifferences,
      'commandsCompleted': _commands(result.commandsCompleted),
      if (result.failure != null) 'failure': result.failure,
    };
  }

  static List<Map<String, Object?>> _commands(
    List<BootstrapProcessResult> commands,
  ) {
    return [for (final command in commands) _command(command)];
  }

  static Map<String, Object?> _command(BootstrapProcessResult command) {
    return {
      'executable': command.executable,
      'arguments': command.arguments,
      'workingDirectory': command.workingDirectory,
      'didStart': command.didStart,
      'exitCode': command.exitCode,
      'succeeded': command.succeeded,
    };
  }

  static String _encode(Map<String, Object?> report) {
    return jsonEncode(_redact(report));
  }

  static Object? _redact(Object? value) {
    if (value is String) return _redactString(value);
    if (value is List) return [for (final item in value) _redact(item)];
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _redact(entry.value),
      };
    }
    return value;
  }

  static String _redactString(String value) {
    final secretAssignment = RegExp(
      r'(password|secret|token|api[_-]?key|authorization|bearer)\s*[:=]\s*\S+',
      caseSensitive: false,
    );
    final tokenShape = RegExp(
      r'(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|AIza[0-9A-Za-z_-]{30,})',
    );
    final privateKey = RegExp(r'-----BEGIN [^-]*PRIVATE KEY-----');
    if (secretAssignment.hasMatch(value) ||
        tokenShape.hasMatch(value) ||
        privateKey.hasMatch(value)) {
      return '[REDACTED]';
    }
    return value;
  }
}
