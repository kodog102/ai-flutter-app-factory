import 'dart:convert';

import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_command_report.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight_result.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_request.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_stop_reason.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/product_request_file.dart';
import 'package:test/test.dart';

void main() {
  test('encodes exactly one versioned JSON document', () {
    final report = BootstrapCommandReport.preflightStopped(
      exitCode: 2,
      requestFile: _requestFile(),
      stopped: BootstrapPreflightStopped(
        reasons: const [
          BootstrapStopReason(
            category: BootstrapStopCategory.missingInput,
            fieldOrFact: 'productPurpose',
            description: 'Product purpose is required.',
          ),
        ],
        notPerformed: const ['No Product mutation was performed.'],
      ),
    );

    final decoded = jsonDecode(report) as Map<String, dynamic>;
    expect(decoded['commandSchemaVersion'], 1);
    expect(decoded['outcomeState'], 'preflightStopped');
    expect(decoded['exitCode'], 2);
    expect(decoded['requestEvidence']['requestId'], 'safe-001');
    expect(decoded['approvalStatuses']['readyApprovalStatus'], 'Pending');
    expect(decoded['approvalStatuses']['agreementApprovalStatus'], 'Pending');
    expect(() => jsonDecode('$report trailing'), throwsFormatException);
  });

  test('redacts secret-like structured values and never includes raw YAML', () {
    final report = BootstrapCommandReport.preflightStopped(
      exitCode: 2,
      requestFile: _requestFile(),
      stopped: BootstrapPreflightStopped(
        reasons: const [
          BootstrapStopReason(
            category: BootstrapStopCategory.filesystemInspectionFailed,
            fieldOrFact: 'exactOutputPath',
            description: 'token=do-not-echo',
          ),
        ],
        notPerformed: const [],
      ),
    );

    expect(report, isNot(contains('do-not-echo')));
    expect(report, contains('[REDACTED]'));
    expect(report, isNot(contains('schemaVersion: 1')));
  });

  test('request errors expose only fixed issue metadata', () {
    final report = BootstrapCommandReport.requestStopped(
      exitCode: 2,
      stopped: ProductRequestFileStopped(
        issues: const [
          ProductRequestIssue(
            code: ProductRequestIssueCode.unknownKey,
            field: 'bootstrap',
            message: 'The request contains an unknown key.',
          ),
        ],
        requestSha256: 'abc123',
      ),
    );

    final decoded = jsonDecode(report) as Map<String, dynamic>;
    expect(decoded['requestEvidence']['sha256'], 'abc123');
    expect(decoded['requestIssues'].single['code'], 'unknownKey');
    expect(decoded['approvalStatuses']['readyApprovalStatus'], 'Pending');
  });
}

ProductRequestFileReady _requestFile() {
  return ProductRequestFileReady(
    request: BootstrapRequest(
      productDisplayName: 'Product',
      productPurpose: 'Purpose',
      initialProductScopeOrFirstIntendedOutcome: 'Scope',
      exactOutputPath: '/portable/product',
      repositoryMode: 'newRepository',
      initialBranchName: 'main',
      repositoryPolicy: null,
      flutterProjectName: 'product',
      organizationIdentifier: 'com.example',
      requestedTechnology: 'flutter',
      targetPlatforms: const ['ios', 'android'],
    ),
    requestId: 'safe-001',
    requestSha256: 'hash',
    originalBytes: const [1, 2, 3],
  );
}
