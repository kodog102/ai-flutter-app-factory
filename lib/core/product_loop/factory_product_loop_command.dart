import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'product_loop_command_report.dart';
import 'product_loop_guard_result.dart';
import 'product_loop_guard_runtime.dart';
import 'product_loop_request_file.dart';
import 'product_loop_snapshot_codec.dart';

typedef ProductLoopCaptureCallback = Future<ProductLoopBaselineCaptureResult>
    Function(Directory productRoot);
typedef ProductLoopValidateCallback = Future<ProductLoopValidationResult>
    Function(ProductLoopGuardReady ready);
typedef ProductLoopProgressCallback = void Function(String message);

final class FactoryProductLoopCommandResult {
  const FactoryProductLoopCommandResult({
    required this.exitCode,
    required this.stdoutJson,
    required this.stderrText,
  });

  final int exitCode;
  final String stdoutJson;
  final String stderrText;
}

final class FactoryProductLoopCommand {
  FactoryProductLoopCommand({
    required Directory factoryRoot,
    ProductLoopRequestFileReader? requestReader,
    ProductLoopSnapshotCodec snapshotCodec = const ProductLoopSnapshotCodec(),
    ProductLoopCaptureCallback? capture,
    ProductLoopValidateCallback? validate,
    ProductLoopProgressCallback? progress,
  })  : _factoryRoot = factoryRoot.absolute,
        _requestReader = requestReader,
        _snapshotCodec = snapshotCodec,
        _capture = capture,
        _validate = validate,
        _progress = progress;

  final Directory _factoryRoot;
  final ProductLoopRequestFileReader? _requestReader;
  final ProductLoopSnapshotCodec _snapshotCodec;
  final ProductLoopCaptureCallback? _capture;
  final ProductLoopValidateCallback? _validate;
  final ProductLoopProgressCallback? _progress;

  Future<FactoryProductLoopCommandResult> run(List<String> arguments) async {
    try {
      if (arguments.length == 1 && arguments.single == '--help') {
        return _result(
          exitCode: 64,
          stdoutJson: ProductLoopCommandReport.help(exitCode: 64),
          stderrText: _humanHelp,
        );
      }
      final parsed = _parse(arguments);
      if (parsed == null) {
        return _result(
          exitCode: 64,
          stdoutJson: ProductLoopCommandReport.usage(exitCode: 64),
          stderrText: _humanUsageError,
        );
      }

      _progress?.call('Product Loop 요청 파일을 안전하게 검사하고 있습니다.');
      final reader = _requestReader ??
          ProductLoopRequestFileReader(factoryRoot: _factoryRoot);
      final requestResult = await reader.read(parsed.requestPath);
      if (requestResult is ProductLoopRequestFileStopped) {
        return _result(
          exitCode: 2,
          stdoutJson: ProductLoopCommandReport.requestStopped(
            exitCode: 2,
            stopped: requestResult,
          ),
          stderrText: _humanRequestStopped,
        );
      }
      final requestFile = requestResult as ProductLoopRequestFileReady;
      final runtime = ProductLoopGuardRuntime(factoryRoot: _factoryRoot);
      final capture = _capture ?? runtime.captureBaseline;
      final validate = _validate ?? runtime.validate;

      return switch (parsed.phase) {
        _ProductLoopPhase.capture => _captureBaseline(
            requestFile: requestFile,
            capture: capture,
          ),
        _ProductLoopPhase.validate => _validateCandidate(
            requestFile: requestFile,
            approvedSha256: parsed.approvedBaselineSha256!,
            validate: validate,
          ),
      };
    } catch (_) {
      return _result(
        exitCode: 70,
        stdoutJson: ProductLoopCommandReport.unexpected(exitCode: 70),
        stderrText: _humanUnexpected,
      );
    }
  }

  Future<FactoryProductLoopCommandResult> _captureBaseline({
    required ProductLoopRequestFileReady requestFile,
    required ProductLoopCaptureCallback capture,
  }) async {
    final evidenceRoot = Directory(requestFile.request.evidenceDirectory);
    final baselineFile = File(
      path.join(evidenceRoot.path, productLoopBaselineFilename),
    );
    final reportFile = File(
      path.join(evidenceRoot.path, productLoopCaptureReportFilename),
    );
    final evidenceOwnership = await _evidenceDirectoryMatches(
      evidenceRoot,
      const [],
    );
    if (evidenceOwnership != null) return evidenceOwnership;
    final availability = await _artifactsAvailable([baselineFile, reportFile]);
    if (availability != null) return availability;

    _progress?.call('승인 전 Product 기준선을 읽기 전용으로 캡처합니다.');
    final result = await capture(Directory(requestFile.request.productRoot));
    if (result is ProductLoopBaselineCaptureStopped) {
      return _result(
        exitCode: 3,
        stdoutJson: ProductLoopCommandReport.baselineStopped(
          exitCode: 3,
          requestFile: requestFile,
          stopped: result,
        ),
        stderrText: _humanCaptureStopped,
      );
    }
    final proposal = result as ProductLoopBaselineProposal;
    final baselineBytes = _snapshotCodec.encodeBaseline(
      ProductLoopBaselineArtifact(
        requestSha256: requestFile.requestSha256,
        buildPolicy: requestFile.request.buildPolicy,
        snapshot: proposal.snapshot,
      ),
    );
    final baselineSha256 = sha256HexForProductLoopBytes(baselineBytes);
    final report = ProductLoopCommandReport.baselineProposed(
      exitCode: 0,
      requestFile: requestFile,
      proposal: proposal,
      baselinePath: baselineFile.path,
      baselineSha256: baselineSha256,
    );
    final requestDrift = await _requestStillMatches(requestFile);
    if (requestDrift != null) return requestDrift;
    final finalEvidenceOwnership = await _evidenceDirectoryMatches(
      evidenceRoot,
      const [],
    );
    if (finalEvidenceOwnership != null) return finalEvidenceOwnership;
    final writeFailure = await _writeArtifacts(
      [
        (file: baselineFile, bytes: baselineBytes),
        (file: reportFile, bytes: utf8.encode(report))
      ],
    );
    if (writeFailure != null) return writeFailure;
    return _result(
      exitCode: 0,
      stdoutJson: report,
      stderrText: _humanBaselineProposed,
    );
  }

  Future<FactoryProductLoopCommandResult> _validateCandidate({
    required ProductLoopRequestFileReady requestFile,
    required String approvedSha256,
    required ProductLoopValidateCallback validate,
  }) async {
    final evidenceRoot = Directory(requestFile.request.evidenceDirectory);
    final baselineFile = File(
      path.join(evidenceRoot.path, productLoopBaselineFilename),
    );
    final reportFile = File(
      path.join(evidenceRoot.path, productLoopValidationReportFilename),
    );
    final evidenceOwnership = await _evidenceDirectoryMatches(
      evidenceRoot,
      const [
        productLoopBaselineFilename,
        productLoopCaptureReportFilename,
      ],
    );
    if (evidenceOwnership != null) return evidenceOwnership;
    final availability = await _artifactsAvailable([reportFile]);
    if (availability != null) return availability;

    _progress?.call('User 승인 기준선의 SHA-256과 내용을 검사합니다.');
    final baselineRead = await _snapshotCodec.read(
      baselineFile,
      approvedSha256: approvedSha256,
    );
    if (baselineRead is ProductLoopBaselineReadStopped) {
      return _result(
        exitCode: 2,
        stdoutJson: ProductLoopCommandReport.artifactStopped(
          exitCode: 2,
          outcomeState: 'baselineArtifactStopped',
          code: baselineRead.code,
          message: baselineRead.message,
          actualSha256: baselineRead.actualSha256,
        ),
        stderrText: _humanBaselineArtifactStopped,
      );
    }
    final readyBaseline = baselineRead as ProductLoopBaselineReadReady;
    final artifact = readyBaseline.artifact;
    final canonicalRequestProductRoot = path.normalize(
      await Directory(
        requestFile.request.productRoot,
      ).resolveSymbolicLinks(),
    );
    if (artifact.requestSha256 != requestFile.requestSha256 ||
        artifact.buildPolicy != requestFile.request.buildPolicy ||
        !path.equals(
          path.normalize(artifact.snapshot.productRoot),
          canonicalRequestProductRoot,
        )) {
      return _result(
        exitCode: 2,
        stdoutJson: ProductLoopCommandReport.artifactStopped(
          exitCode: 2,
          outcomeState: 'baselineArtifactStopped',
          code: 'baselineRequestMismatch',
          message:
              'The current request does not match the approved baseline artifact.',
          actualSha256: readyBaseline.sha256,
        ),
        stderrText: _humanBaselineArtifactStopped,
      );
    }

    _progress?.call('승인된 기준선을 사용해 QA candidate와 Health Gate를 검증합니다.');
    // The external implementation intentionally changes Product content after
    // capture. The approved artifact therefore reconstructs the Ready boundary
    // instead of requiring the old baseline content to match the candidate.
    final result = await validate(
      ProductLoopGuardReady(
        expectedBaseline: artifact.snapshot,
        buildPolicy: artifact.buildPolicy,
      ),
    );
    final exitCode = result is ProductLoopCandidateValidated ? 0 : 3;
    final report = ProductLoopCommandReport.validation(
      exitCode: exitCode,
      requestFile: requestFile,
      baselinePath: baselineFile.path,
      approvedBaselineSha256: approvedSha256,
      result: result,
    );
    final requestDrift = await _requestStillMatches(requestFile);
    if (requestDrift != null) return requestDrift;
    final finalBaselineRead = await _snapshotCodec.read(
      baselineFile,
      approvedSha256: approvedSha256,
    );
    if (finalBaselineRead is ProductLoopBaselineReadStopped) {
      return _result(
        exitCode: 2,
        stdoutJson: ProductLoopCommandReport.artifactStopped(
          exitCode: 2,
          outcomeState: 'baselineArtifactStopped',
          code: 'baselineChangedDuringValidation',
          message:
              'The approved baseline artifact changed while validation was running.',
          actualSha256: finalBaselineRead.actualSha256,
        ),
        stderrText: _humanInputDriftStopped,
      );
    }
    final finalEvidenceOwnership = await _evidenceDirectoryMatches(
      evidenceRoot,
      const [
        productLoopBaselineFilename,
        productLoopCaptureReportFilename,
      ],
    );
    if (finalEvidenceOwnership != null) return finalEvidenceOwnership;
    final writeFailure = await _writeArtifacts(
      [(file: reportFile, bytes: utf8.encode(report))],
    );
    if (writeFailure != null) return writeFailure;
    return _result(
      exitCode: exitCode,
      stdoutJson: report,
      stderrText: result is ProductLoopCandidateValidated
          ? _humanCandidateValidated
          : _humanValidationStopped,
    );
  }

  Future<FactoryProductLoopCommandResult?> _artifactsAvailable(
    List<File> files,
  ) async {
    for (final file in files) {
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        return _result(
          exitCode: 2,
          stdoutJson: ProductLoopCommandReport.artifactStopped(
            exitCode: 2,
            outcomeState: 'artifactPathStopped',
            code: 'artifactAlreadyExists',
            message:
                'An output or temporary artifact already exists; no file was overwritten.',
          ),
          stderrText: _humanArtifactPathStopped,
        );
      }
    }
    return null;
  }

  Future<FactoryProductLoopCommandResult?> _requestStillMatches(
    ProductLoopRequestFileReady expected,
  ) async {
    final reader = _requestReader ??
        ProductLoopRequestFileReader(factoryRoot: _factoryRoot);
    final current = await reader.read(expected.sourcePath);
    if (current is ProductLoopRequestFileReady &&
        current.requestSha256 == expected.requestSha256) {
      return null;
    }
    return _result(
      exitCode: 2,
      stdoutJson: ProductLoopCommandReport.artifactStopped(
        exitCode: 2,
        outcomeState: 'requestDriftStopped',
        code: 'requestChangedDuringOperation',
        message:
            'The Product Loop request changed while the command was running.',
      ),
      stderrText: _humanInputDriftStopped,
    );
  }

  Future<FactoryProductLoopCommandResult?> _evidenceDirectoryMatches(
    Directory directory,
    List<String> expectedNames,
  ) async {
    final actualNames = await directory
        .list(followLinks: false)
        .map((entry) => path.basename(entry.path))
        .toList();
    actualNames.sort();
    final expected = [...expectedNames]..sort();
    if (actualNames.length == expected.length) {
      var matches = true;
      for (var index = 0; index < expected.length; index++) {
        if (actualNames[index] != expected[index]) {
          matches = false;
          break;
        }
      }
      if (matches) return null;
    }
    return _result(
      exitCode: 2,
      stdoutJson: ProductLoopCommandReport.artifactStopped(
        exitCode: 2,
        outcomeState: 'artifactPathStopped',
        code: 'evidenceDirectoryOwnershipMismatch',
        message:
            'The Evidence directory entries do not match the expected phase baseline.',
      ),
      stderrText: _humanArtifactPathStopped,
    );
  }

  Future<FactoryProductLoopCommandResult?> _writeArtifacts(
    List<({File file, List<int> bytes})> artifacts,
  ) async {
    try {
      for (final artifact in artifacts) {
        await artifact.file.create(exclusive: true);
        await artifact.file.writeAsBytes(artifact.bytes, flush: true);
      }
      return null;
    } on FileSystemException {
      return _result(
        exitCode: 4,
        stdoutJson: ProductLoopCommandReport.artifactStopped(
          exitCode: 4,
          outcomeState: 'artifactWritePartialFailure',
          code: 'artifactWriteFailed',
          message:
              'An Evidence artifact could not be written exclusively; inspect the evidence directory.',
        ),
        stderrText: _humanArtifactWriteFailed,
      );
    } on OSError {
      return _result(
        exitCode: 4,
        stdoutJson: ProductLoopCommandReport.artifactStopped(
          exitCode: 4,
          outcomeState: 'artifactWritePartialFailure',
          code: 'artifactWriteFailed',
          message:
              'An Evidence artifact could not be written exclusively; inspect the evidence directory.',
        ),
        stderrText: _humanArtifactWriteFailed,
      );
    }
  }

  _ParsedProductLoopArguments? _parse(List<String> arguments) {
    if (arguments.length == 4 &&
        arguments[0] == '--request' &&
        arguments[2] == '--phase' &&
        arguments[3] == 'capture') {
      return _ParsedProductLoopArguments(
        requestPath: arguments[1],
        phase: _ProductLoopPhase.capture,
      );
    }
    if (arguments.length == 6 &&
        arguments[0] == '--request' &&
        arguments[2] == '--phase' &&
        arguments[3] == 'validate' &&
        arguments[4] == '--approved-baseline-sha256') {
      return _ParsedProductLoopArguments(
        requestPath: arguments[1],
        phase: _ProductLoopPhase.validate,
        approvedBaselineSha256: arguments[5],
      );
    }
    return null;
  }

  FactoryProductLoopCommandResult _result({
    required int exitCode,
    required String stdoutJson,
    required String stderrText,
  }) {
    return FactoryProductLoopCommandResult(
      exitCode: exitCode,
      stdoutJson: stdoutJson,
      stderrText: stderrText,
    );
  }

  static const _humanHelp = '''Product Loop 명령 사용법을 확인했습니다.
Capture와 Validate는 User 승인 및 외부 구현 경계 때문에 별도 단계입니다.
다음 사용자 결정: 요청 파일과 별도 Evidence 디렉터리를 준비하세요.
''';
  static const _humanUsageError = '''Product Loop 명령 인수를 확인할 수 없습니다.
지원 단계는 capture 또는 승인 SHA-256이 포함된 validate입니다.
다음 사용자 결정: 구조화된 사용법을 확인하고 다시 실행하세요.
''';
  static const _humanRequestStopped = '''Product Loop 요청 검증에서 안전하게 중단했습니다.
Factory와 Product는 변경되지 않았습니다.
다음 사용자 결정: 요청 오류를 확인하고 요청 파일만 수정할지 결정하세요.
''';
  static const _humanCaptureStopped = '''Product 기준선 캡처가 안전하게 중단됐습니다.
승인 또는 Product 구현 단계로 진행하지 않습니다.
다음 사용자 결정: 구조화된 중단 Evidence를 검토하세요.
''';
  static const _humanBaselineProposed = '''Product 기준선 Proposal을 생성했습니다.
이 결과는 User 승인 또는 Product 구현 완료를 의미하지 않습니다.
다음 사용자 결정: 표시된 SHA-256과 기준선을 검토해 승인 여부를 결정하세요.
''';
  static const _humanBaselineArtifactStopped = '''승인 기준선 검증에서 안전하게 중단했습니다.
Health Gate와 QA candidate 검증은 실행되지 않았습니다.
다음 사용자 결정: 기준선 파일과 승인 SHA-256을 다시 확인하세요.
''';
  static const _humanArtifactPathStopped = '''Evidence 출력 경로에 기존 파일이 있어 중단했습니다.
어떤 파일도 덮어쓰지 않았습니다.
다음 사용자 결정: 새로운 빈 Evidence 디렉터리를 사용할지 결정하세요.
''';
  static const _humanArtifactWriteFailed = '''Evidence 저장 중 부분 실패가 발생했습니다.
Product와 Factory를 수정하지 말고 Evidence 디렉터리를 먼저 검사하세요.
다음 사용자 결정: 남은 임시 또는 결과 파일의 안전 검사를 요청하세요.
''';
  static const _humanInputDriftStopped = '''승인 입력이 실행 중 변경되어 안전하게 중단했습니다.
기존 기준선이나 검증 결과를 사용하지 않습니다.
다음 사용자 결정: 요청 파일과 승인 기준선 Evidence를 다시 검사하세요.
''';
  static const _humanCandidateValidated =
      '''Flutter 기술 검증이 통과한 QA candidate가 준비됐습니다.
QA와 User 승인은 여전히 Pending이며 commit은 수행되지 않았습니다.
다음 사용자 결정: 독립 QA를 진행하고 결과 승인 여부를 결정하세요.
''';
  static const _humanValidationStopped = '''Product Loop 검증이 안전하게 중단됐습니다.
QA PASS 또는 User 승인 상태를 제안하지 않습니다.
다음 사용자 결정: 구조화된 실패 Evidence를 검토하세요.
''';
  static const _humanUnexpected = '''Product Loop 명령에서 예상하지 못한 실패가 발생했습니다.
안전한 결과를 확인할 수 없어 추가 작업을 수행하지 않습니다.
다음 사용자 결정: Factory, Product와 Evidence 디렉터리를 별도로 검사하세요.
''';
}

enum _ProductLoopPhase { capture, validate }

final class _ParsedProductLoopArguments {
  const _ParsedProductLoopArguments({
    required this.requestPath,
    required this.phase,
    this.approvedBaselineSha256,
  });

  final String requestPath;
  final _ProductLoopPhase phase;
  final String? approvedBaselineSha256;
}
