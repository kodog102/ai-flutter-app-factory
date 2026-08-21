import 'dart:io';

import 'package:path/path.dart' as path;

import 'bootstrap_process_runner.dart';

enum FactoryDoctorCheckId {
  factoryRepository,
  dart,
  flutter,
  git,
  iosToolchain,
  androidToolchain,
}

enum FactoryDoctorCheckStatus { available, unavailable }

final class FactoryDoctorCheck {
  const FactoryDoctorCheck({
    required this.id,
    required this.status,
    required this.summary,
    this.version,
  });

  final FactoryDoctorCheckId id;
  final FactoryDoctorCheckStatus status;
  final String summary;
  final String? version;
}

final class FactoryEnvironmentDoctorResult {
  FactoryEnvironmentDoctorResult({required List<FactoryDoctorCheck> checks})
      : checks = List<FactoryDoctorCheck>.unmodifiable(checks);

  final List<FactoryDoctorCheck> checks;

  bool get isOperational => checks.every(
        (check) => check.status == FactoryDoctorCheckStatus.available,
      );
}

final class FactoryEnvironmentDoctor {
  FactoryEnvironmentDoctor({
    required Directory factoryRoot,
    BootstrapProcessRunner? processRunner,
  })  : _factoryRoot = factoryRoot.absolute,
        _runner = processRunner ?? const SystemBootstrapProcessRunner();

  final Directory _factoryRoot;
  final BootstrapProcessRunner _runner;

  Future<FactoryEnvironmentDoctorResult> inspect() async {
    final checks = <FactoryDoctorCheck>[
      await _factoryRepositoryCheck(),
    ];

    final dart = await _run('dart', ['--version']);
    checks.add(
      _commandCheck(
        id: FactoryDoctorCheckId.dart,
        result: dart,
        availableSummary: 'Dart 실행 환경을 확인했다.',
        unavailableSummary: 'Dart 실행 환경을 확인할 수 없다.',
        versionPattern: RegExp(r'Dart SDK version:\s*([^\s]+)'),
      ),
    );

    final flutter = await _run('flutter', ['--version']);
    checks.add(
      _commandCheck(
        id: FactoryDoctorCheckId.flutter,
        result: flutter,
        availableSummary: 'Flutter 실행 환경을 확인했다.',
        unavailableSummary: 'Flutter 실행 환경을 확인할 수 없다.',
        versionPattern: RegExp(r'Flutter\s+([^\s]+)'),
      ),
    );

    final git = await _run('git', ['--version']);
    checks.add(
      _commandCheck(
        id: FactoryDoctorCheckId.git,
        result: git,
        availableSummary: 'Git 실행 환경을 확인했다.',
        unavailableSummary: 'Git 실행 환경을 확인할 수 없다.',
        versionPattern: RegExp(r'git version\s+([^\s]+)'),
      ),
    );

    final xcode = await _run('xcodebuild', ['-version']);
    checks.add(
      _commandCheck(
        id: FactoryDoctorCheckId.iosToolchain,
        result: xcode,
        availableSummary: 'iOS build 도구를 확인했다.',
        unavailableSummary: 'iOS build 도구를 확인할 수 없다.',
        versionPattern: RegExp(r'Xcode\s+([^\s]+)'),
      ),
    );

    final flutterDoctor = await _run('flutter', ['doctor', '--verbose']);
    final doctorOutput = '${flutterDoctor.stdout}\n${flutterDoctor.stderr}';
    final androidAvailable = flutterDoctor.succeeded &&
        RegExp(r'\[[✓√]\]\s+Android toolchain').hasMatch(doctorOutput);
    checks.add(
      FactoryDoctorCheck(
        id: FactoryDoctorCheckId.androidToolchain,
        status: androidAvailable
            ? FactoryDoctorCheckStatus.available
            : FactoryDoctorCheckStatus.unavailable,
        summary: androidAvailable
            ? 'Android build 도구를 확인했다.'
            : 'Android build 도구를 확인할 수 없다.',
      ),
    );

    return FactoryEnvironmentDoctorResult(checks: checks);
  }

  Future<FactoryDoctorCheck> _factoryRepositoryCheck() async {
    if (!await _factoryRoot.exists()) {
      return const FactoryDoctorCheck(
        id: FactoryDoctorCheckId.factoryRepository,
        status: FactoryDoctorCheckStatus.unavailable,
        summary: '팩토리 Repository 위치를 확인할 수 없다.',
      );
    }

    final topLevel = await _run('git', ['rev-parse', '--show-toplevel']);
    final reportedPath = topLevel.stdout.trim();
    var matchesFactoryRoot = false;
    if (topLevel.succeeded && reportedPath.isNotEmpty) {
      try {
        final expectedPath =
            path.normalize(await _factoryRoot.resolveSymbolicLinks());
        final actualPath = path.normalize(
          await Directory(reportedPath).resolveSymbolicLinks(),
        );
        matchesFactoryRoot = path.equals(actualPath, expectedPath);
      } on FileSystemException {
        matchesFactoryRoot = false;
      }
    }

    return FactoryDoctorCheck(
      id: FactoryDoctorCheckId.factoryRepository,
      status: matchesFactoryRoot
          ? FactoryDoctorCheckStatus.available
          : FactoryDoctorCheckStatus.unavailable,
      summary: matchesFactoryRoot
          ? '팩토리 Repository 위치를 확인했다.'
          : '팩토리 Repository 위치를 확인할 수 없다.',
    );
  }

  Future<BootstrapProcessResult> _run(
    String executable,
    List<String> arguments,
  ) {
    return _runner.run(
      executable,
      arguments,
      workingDirectory: _factoryRoot.path,
    );
  }

  FactoryDoctorCheck _commandCheck({
    required FactoryDoctorCheckId id,
    required BootstrapProcessResult result,
    required String availableSummary,
    required String unavailableSummary,
    required RegExp versionPattern,
  }) {
    final output = '${result.stdout}\n${result.stderr}';
    final version = versionPattern.firstMatch(output)?.group(1);
    return FactoryDoctorCheck(
      id: id,
      status: result.succeeded
          ? FactoryDoctorCheckStatus.available
          : FactoryDoctorCheckStatus.unavailable,
      summary: result.succeeded ? availableSummary : unavailableSummary,
      version: result.succeeded ? version : null,
    );
  }
}
