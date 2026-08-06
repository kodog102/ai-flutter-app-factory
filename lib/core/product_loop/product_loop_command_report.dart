import 'dart:convert';

import 'product_loop_guard_result.dart';
import 'product_loop_process_runner.dart';
import 'product_loop_repository_snapshot.dart';
import 'product_loop_request_file.dart';

const int productLoopCommandSchemaVersion = 1;

final class ProductLoopCommandReport {
  const ProductLoopCommandReport._();

  static String help({required int exitCode}) {
    return _encode({
      'commandSchemaVersion': productLoopCommandSchemaVersion,
      'outcomeState': 'help',
      'exitCode': exitCode,
      'usage': _usage,
      'approvalStatuses': _approvalStatuses(),
    });
  }

  static String usage({required int exitCode}) {
    return _encode({
      'commandSchemaVersion': productLoopCommandSchemaVersion,
      'outcomeState': 'usageError',
      'exitCode': exitCode,
      'usage': _usage,
      'approvalStatuses': _approvalStatuses(),
    });
  }

  static String requestStopped({
    required int exitCode,
    required ProductLoopRequestFileStopped stopped,
  }) {
    return _encode({
      'commandSchemaVersion': productLoopCommandSchemaVersion,
      'outcomeState': 'requestStopped',
      'exitCode': exitCode,
      if (stopped.requestSha256 != null)
        'requestEvidence': {'sha256': stopped.requestSha256},
      'issues': [
        for (final issue in stopped.issues)
          {
            'code': issue.code.name,
            'field': issue.field,
            'message': issue.message,
          },
      ],
      'approvalStatuses': _approvalStatuses(),
    });
  }

  static String artifactStopped({
    required int exitCode,
    required String outcomeState,
    required String code,
    required String message,
    String? actualSha256,
  }) {
    return _encode({
      'commandSchemaVersion': productLoopCommandSchemaVersion,
      'outcomeState': outcomeState,
      'exitCode': exitCode,
      'failure': {
        'code': code,
        'message': message,
        if (actualSha256 != null) 'actualSha256': actualSha256,
      },
      'approvalStatuses': _approvalStatuses(),
    });
  }

  static String baselineStopped({
    required int exitCode,
    required ProductLoopRequestFileReady requestFile,
    required ProductLoopBaselineCaptureStopped stopped,
  }) {
    return _encode({
      ..._base(
        outcomeState: 'baselineCaptureStopped',
        exitCode: exitCode,
        requestFile: requestFile,
      ),
      'baseline': {
        'status': 'stopped',
        'category': stopped.category.name,
        'evidence': stopped.evidence,
      },
    });
  }

  static String baselineProposed({
    required int exitCode,
    required ProductLoopRequestFileReady requestFile,
    required ProductLoopBaselineProposal proposal,
    required String baselinePath,
    required String baselineSha256,
  }) {
    return _encode({
      ..._base(
        outcomeState: 'baselineProposed',
        exitCode: exitCode,
        requestFile: requestFile,
      ),
      'baseline': {
        'status': proposal.proposalStatus,
        'userApprovalStatus': proposal.userApprovalStatus,
        'path': baselinePath,
        'sha256': baselineSha256,
        'snapshot': _snapshot(proposal.snapshot),
      },
    });
  }

  static String validation({
    required int exitCode,
    required ProductLoopRequestFileReady requestFile,
    required String baselinePath,
    required String approvedBaselineSha256,
    required ProductLoopValidationResult result,
  }) {
    return _encode({
      ..._base(
        outcomeState: result is ProductLoopCandidateValidated
            ? 'candidateValidated'
            : 'validationStopped',
        exitCode: exitCode,
        requestFile: requestFile,
        qaStatus:
            result is ProductLoopCandidateValidated ? 'Pending' : 'NotProposed',
      ),
      'approvedBaselineEvidence': {
        'path': baselinePath,
        'sha256': approvedBaselineSha256,
        'callerDeclaredUserApproval': true,
      },
      'validation': switch (result) {
        ProductLoopCandidateValidated validated => {
            'status': 'validated',
            'technicalValidationStatus': validated.technicalValidationStatus,
            'productContextReviewStatus': validated.productContextReviewStatus,
            'qaStatus': validated.qaStatus,
            'userApprovalStatus': validated.userApprovalStatus,
            'commitStatus': validated.commitStatus,
            'buildPolicy': validated.buildPolicy.name,
            'candidate': _snapshot(validated.candidate),
            'commandsCompleted': _commands(validated.commandsCompleted),
          },
        ProductLoopValidationStopped stopped => {
            'status': 'stopped',
            'category': stopped.category.name,
            'stage': stopped.stage.name,
            'evidence': stopped.evidence,
            'notPerformed': stopped.notPerformed,
            'qaStatus': stopped.qaStatus,
            'userApprovalStatus': stopped.userApprovalStatus,
            'commitStatus': stopped.commitStatus,
            'commandsCompleted': _commands(stopped.commandsCompleted),
            if (stopped.candidateBefore != null)
              'candidateBefore': _snapshot(stopped.candidateBefore!),
            if (stopped.candidateAfter != null)
              'candidateAfter': _snapshot(stopped.candidateAfter!),
            if (stopped.failedCommand != null)
              'failedCommand': _command(stopped.failedCommand!),
          },
      },
    });
  }

  static String unexpected({required int exitCode}) {
    return _encode({
      'commandSchemaVersion': productLoopCommandSchemaVersion,
      'outcomeState': 'unexpectedCommandFailure',
      'exitCode': exitCode,
      'failure': {
        'message':
            'The command layer failed before a safe result was available.',
      },
      'approvalStatuses': _approvalStatuses(),
    });
  }

  static Map<String, Object?> _base({
    required String outcomeState,
    required int exitCode,
    required ProductLoopRequestFileReady requestFile,
    String qaStatus = 'NotProposed',
  }) {
    return {
      'commandSchemaVersion': productLoopCommandSchemaVersion,
      'outcomeState': outcomeState,
      'exitCode': exitCode,
      'requestEvidence': {'sha256': requestFile.requestSha256},
      'approvalStatuses': _approvalStatuses(qaStatus: qaStatus),
    };
  }

  static Map<String, String> _approvalStatuses({
    String qaStatus = 'NotProposed',
  }) {
    return {
      'qaStatus': qaStatus,
      'userApprovalStatus': 'Pending',
      'commitStatus': 'NotPerformed',
    };
  }

  static Map<String, Object?> _snapshot(
    ProductLoopRepositorySnapshot snapshot,
  ) {
    return {
      'productRoot': snapshot.productRoot,
      'gitTopLevel': snapshot.gitTopLevel,
      'branch': snapshot.branch,
      'headIdentity': snapshot.headIdentity,
      'gitStatusEntries': snapshot.gitStatusEntries,
      'contentManifest': Map<String, String>.fromEntries(
        snapshot.contentManifest.entries.toList()
          ..sort((first, second) => first.key.compareTo(second.key)),
      ),
    };
  }

  static List<Map<String, Object?>> _commands(
    List<ProductLoopProcessResult> commands,
  ) {
    return [for (final command in commands) _command(command)];
  }

  static Map<String, Object?> _command(ProductLoopProcessResult command) {
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
    return '${jsonEncode(report)}\n';
  }

  static const _usage =
      'dart run ai_flutter_app_factory:factory_product_loop --request /absolute/path/product_loop_request.yaml --phase capture | --phase validate --approved-baseline-sha256 <64 lowercase hex>';
}
