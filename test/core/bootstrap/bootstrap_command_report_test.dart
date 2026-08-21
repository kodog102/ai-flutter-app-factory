import 'dart:convert';

import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_command_report.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight_result.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_request.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_stop_reason.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/factory_environment_doctor.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/product_request_file.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/repository_mode.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/validated_bootstrap_request.dart';
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

  test('doctor report contains fixed summaries without raw command output', () {
    final report = BootstrapCommandReport.doctor(
      exitCode: 3,
      result: FactoryEnvironmentDoctorResult(
        checks: const [
          FactoryDoctorCheck(
            id: FactoryDoctorCheckId.androidToolchain,
            status: FactoryDoctorCheckStatus.unavailable,
            summary: 'Android build 도구를 확인할 수 없다.',
          ),
        ],
      ),
    );

    final decoded = jsonDecode(report) as Map<String, dynamic>;
    expect(decoded['outcomeState'], 'environmentIncomplete');
    expect(decoded['doctor']['checks'].single['status'], 'unavailable');
    expect(decoded['doctor']['notPerformed'], contains('SDK 또는 도구 설치'));
    expect(decoded['approvalStatuses']['readyApprovalStatus'], 'Pending');
  });

  test('dry-run report preserves Pending approvals and omitted execution', () {
    final report = BootstrapCommandReport.dryRun(
      exitCode: 0,
      requestFile: _requestFile(),
      ready: BootstrapPreflightReady(
        validatedRequest: _validatedRequest(),
        normalizedOutputPath: '/portable/product',
        inspection: BootstrapTargetInspection(
          inspectedPath: '/portable/product',
          normalizedPath: '/portable/product',
          targetExists: false,
          repositoryMode: RepositoryMode.newRepository,
          nearestExistingParent: '/portable',
          hasIndependentGitDirectory: false,
          targetEntries: const [],
        ),
      ),
    );

    final decoded = jsonDecode(report) as Map<String, dynamic>;
    expect(decoded['outcomeState'], 'preflightCandidate');
    expect(decoded['dryRun']['status'], 'candidate');
    expect(decoded['dryRun']['notPerformed'], contains('Flutter scaffold 생성'));
    expect(decoded['approvalStatuses']['readyApprovalStatus'], 'Pending');
    expect(decoded, isNot(contains('execution')));
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

ValidatedBootstrapRequest _validatedRequest() {
  return ValidatedBootstrapRequest(
    productDisplayName: 'Product',
    productPurpose: 'Purpose',
    initialProductScopeOrFirstIntendedOutcome: 'Scope',
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
