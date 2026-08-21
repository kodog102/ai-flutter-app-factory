import 'dart:io';

import '../../ai_flutter_app_factory.dart';
import 'bootstrap_command_report.dart';
import 'factory_bootstrap_request_template.dart';
import 'factory_environment_doctor.dart';
import 'product_request_file.dart';

typedef BootstrapInspectCallback = Future<BootstrapPreflightResult> Function(
  BootstrapRequest request,
);
typedef BootstrapExecuteCallback = Future<BootstrapExecutionResult> Function(
  BootstrapPreflightReady ready,
);
typedef BootstrapProgressCallback = void Function(String message);

final class FactoryBootstrapCommandResult {
  const FactoryBootstrapCommandResult({
    required this.exitCode,
    required this.stdoutJson,
    required this.stderrText,
  });

  final int exitCode;
  final String stdoutJson;
  final String stderrText;
}

final class FactoryBootstrapCommand {
  FactoryBootstrapCommand({
    required Directory factoryRoot,
    ProductRequestFileReader? requestReader,
    BootstrapInspectCallback? inspect,
    BootstrapExecuteCallback? execute,
    BootstrapProgressCallback? progress,
    FactoryEnvironmentDoctor? doctor,
    FactoryBootstrapRequestTemplate? requestTemplate,
  })  : _factoryRoot = factoryRoot.absolute,
        _requestReader = requestReader,
        _inspect = inspect,
        _execute = execute,
        _progress = progress,
        _doctor = doctor,
        _requestTemplate =
            requestTemplate ?? const FactoryBootstrapRequestTemplate();

  final Directory _factoryRoot;
  final ProductRequestFileReader? _requestReader;
  final BootstrapInspectCallback? _inspect;
  final BootstrapExecuteCallback? _execute;
  final BootstrapProgressCallback? _progress;
  final FactoryEnvironmentDoctor? _doctor;
  final FactoryBootstrapRequestTemplate _requestTemplate;

  Future<FactoryBootstrapCommandResult> run(List<String> arguments) async {
    try {
      if (arguments.length == 1 && arguments.single == '--help') {
        return FactoryBootstrapCommandResult(
          exitCode: 64,
          stdoutJson: BootstrapCommandReport.help(exitCode: 64),
          stderrText: _humanHelp,
        );
      }
      if (arguments.length == 1 && arguments.single == '--doctor') {
        _progress?.call('팩토리 실행 환경을 읽기 전용으로 확인하고 있습니다.');
        final doctor =
            _doctor ?? FactoryEnvironmentDoctor(factoryRoot: _factoryRoot);
        final result = await doctor.inspect();
        final exitCode = result.isOperational ? 0 : 3;
        return FactoryBootstrapCommandResult(
          exitCode: exitCode,
          stdoutJson: BootstrapCommandReport.doctor(
            exitCode: exitCode,
            result: result,
          ),
          stderrText: result.isOperational
              ? _humanDoctorOperational
              : _humanDoctorIncomplete,
        );
      }
      if (arguments.length == 1 &&
          arguments.single == '--print-request-template') {
        return FactoryBootstrapCommandResult(
          exitCode: 0,
          stdoutJson: _requestTemplate.render(),
          stderrText: _humanRequestTemplate,
        );
      }

      final hasRequestPath = arguments.length >= 2 &&
          arguments.first == '--request' &&
          !arguments[1].startsWith('--');
      final isExecution = arguments.length == 2 && hasRequestPath;
      final isDryRun = arguments.length == 3 &&
          hasRequestPath &&
          arguments.last == '--dry-run';
      if (!isExecution && !isDryRun) {
        return FactoryBootstrapCommandResult(
          exitCode: 64,
          stdoutJson: BootstrapCommandReport.usage(exitCode: 64),
          stderrText: _humanUsageError,
        );
      }

      _progress?.call('요청 파일을 안전하게 검사하고 있습니다.');
      final reader =
          _requestReader ?? ProductRequestFileReader(factoryRoot: _factoryRoot);
      final requestFile = await reader.read(arguments[1]);
      if (requestFile is ProductRequestFileStopped) {
        return FactoryBootstrapCommandResult(
          exitCode: 2,
          stdoutJson: BootstrapCommandReport.requestStopped(
            exitCode: 2,
            stopped: requestFile,
          ),
          stderrText: _humanRequestStopped,
        );
      }
      final readyRequest = requestFile as ProductRequestFileReady;
      _progress?.call('요청 Schema 검증을 통과해 Runtime 사전 검사를 시작합니다.');

      late final BootstrapInspectCallback inspect;
      late final BootstrapExecuteCallback execute;
      if (_inspect != null && _execute != null) {
        inspect = _inspect!;
        execute = _execute!;
      } else if (_inspect == null && _execute == null) {
        final runtime = FlutterAppFactoryRuntime(factoryRoot: _factoryRoot);
        inspect = runtime.inspect;
        execute = runtime.execute;
      } else {
        throw StateError(
          'Command runtime callbacks must be supplied together.',
        );
      }

      final preflight = await inspect(readyRequest.request);
      if (preflight is BootstrapPreflightStopped) {
        return FactoryBootstrapCommandResult(
          exitCode: 2,
          stdoutJson: BootstrapCommandReport.preflightStopped(
            exitCode: 2,
            requestFile: readyRequest,
            stopped: preflight,
          ),
          stderrText: _humanPreflightStopped,
        );
      }

      if (isDryRun) {
        return FactoryBootstrapCommandResult(
          exitCode: 0,
          stdoutJson: BootstrapCommandReport.dryRun(
            exitCode: 0,
            requestFile: readyRequest,
            ready: preflight as BootstrapPreflightReady,
          ),
          stderrText: _humanDryRunCandidate,
        );
      }

      _progress?.call('사전 검사를 통과해 Operational Bootstrap을 실행합니다.');
      final execution = await execute(preflight as BootstrapPreflightReady);
      final exitCode = switch (execution) {
        BootstrapExecutionPrepared() => 0,
        BootstrapExecutionStopped() => 3,
        BootstrapExecutionPartialFailure() => 4,
      };
      return FactoryBootstrapCommandResult(
        exitCode: exitCode,
        stdoutJson: BootstrapCommandReport.execution(
          exitCode: exitCode,
          requestFile: readyRequest,
          result: execution,
        ),
        stderrText: switch (execution) {
          BootstrapExecutionPrepared() => _humanPrepared,
          BootstrapExecutionStopped() => _humanExecutionStopped,
          BootstrapExecutionPartialFailure() => _humanPartialFailure,
        },
      );
    } catch (_) {
      return FactoryBootstrapCommandResult(
        exitCode: 70,
        stdoutJson: BootstrapCommandReport.unexpected(exitCode: 70),
        stderrText: _humanUnexpected,
      );
    }
  }

  static const _humanHelp = '''사용법을 확인했습니다.
환경 확인: dart run ai_flutter_app_factory:factory_bootstrap --doctor
요청 예시: dart run ai_flutter_app_factory:factory_bootstrap --print-request-template
실행 전 검사: dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml --dry-run
실행: dart run ai_flutter_app_factory:factory_bootstrap --request /absolute/intake/product_request.yaml
다음 사용자 결정: 환경과 요청 예시를 확인하고 실행 전 검사 또는 실제 실행 여부를 결정하세요.
''';

  static const _humanUsageError = '''명령 인수를 확인할 수 없습니다.
지원 인수는 --doctor, --print-request-template, --request <absolute path> [--dry-run] 또는 --help입니다.
다음 사용자 결정: 올바른 절대 요청 파일 경로로 다시 실행할지 결정하세요.
''';

  static const _humanDoctorOperational = '''팩토리 실행 환경 확인을 마쳤습니다.
필수 도구를 모두 확인했지만 제품 실행이나 사용자 승인은 수행하지 않았습니다.
다음 사용자 결정: 요청 예시를 확인하고 실행 전 검사를 진행할지 결정하세요.
''';

  static const _humanDoctorIncomplete = '''팩토리 실행 환경에 확인이 필요한 항목이 있습니다.
자동 설치, 복구 또는 라이선스 승인은 수행하지 않았습니다.
다음 사용자 결정: 구조화된 환경 항목을 확인하고 필요한 도구를 직접 준비할지 결정하세요.
''';

  static const _humanRequestTemplate = '''요청 파일 예시를 stdout으로 출력했습니다.
파일과 제품은 생성하지 않았으며 예시값을 실제 값으로 바꿔야 합니다.
다음 사용자 결정: 팩토리 밖의 안전한 위치에 product_request.yaml을 직접 준비할지 결정하세요.
''';

  static const _humanDryRunCandidate = '''실행 전 검사를 통과한 후보입니다.
제품, Git과 팩토리는 변경되지 않았고 Bootstrap executor도 실행하지 않았습니다.
다음 사용자 결정: 구조화된 후보와 미수행 단계를 확인하고 실제 실행 여부를 결정하세요.
''';

  static const _humanRequestStopped = '''요청 파일 검증에서 안전하게 중단했습니다.
Product와 Factory는 이 결과로 변경되지 않았습니다.
다음 사용자 결정: 구조화된 요청 오류를 확인하고 요청 파일만 수정할지 결정하세요.
''';

  static const _humanPreflightStopped = '''사전 Bootstrap 검사에서 안전하게 중단했습니다.
Product 실행은 시작되지 않았습니다.
다음 사용자 결정: 구조화된 중단 근거를 확인하고 입력 또는 Target을 수정할지 결정하세요.
''';

  static const _humanPrepared =
      '''기술 검증을 마친 Flutter Product 시작점이 Prepared 상태로 준비됐습니다.
Prepared는 Ready 또는 Approved가 아닙니다.
다음 사용자 결정: Evidence와 Baseline Handoff Proposal을 검토하고 Ready 및 baseline 승인 여부를 결정하세요.
''';

  static const _humanExecutionStopped = '''실행 중 Bootstrap이 안전한 Stop 결과로 종료됐습니다.
구조화된 복구 및 미수행 Evidence를 확인하세요.
다음 사용자 결정: 중단 근거를 검토하고 다시 실행할지 결정하세요.
''';

  static const _humanPartialFailure = '''부분 실패로 Bootstrap이 종료됐습니다.
표시된 경로를 이동하거나 삭제하지 말고 User 검사가 필요합니다.
다음 사용자 결정: 구조화된 Evidence를 기준으로 별도 안전 검사를 요청할지 결정하세요.
''';

  static const _humanUnexpected = '''명령 계층에서 예상하지 못한 실패가 발생했습니다.
안전한 Bootstrap 결과를 확인할 수 없어 추가 작업을 수행하지 않습니다.
다음 사용자 결정: Factory와 Product 상태를 별도로 검사할지 결정하세요.
''';
}
