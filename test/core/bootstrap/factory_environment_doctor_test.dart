import 'dart:io';

import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_process_runner.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/factory_environment_doctor.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('reports a complete environment without changing Factory files',
      () async {
    final root = await Directory.systemTemp.createTemp('factory_doctor_');
    final marker = File(path.join(root.path, 'marker.txt'));
    await marker.writeAsString('unchanged\n');
    final before = await _snapshot(root);
    final runner = _DoctorRunner(complete: true);

    try {
      final result = await FactoryEnvironmentDoctor(
        factoryRoot: root,
        processRunner: runner,
      ).inspect();

      expect(result.isOperational, isTrue);
      expect(result.checks, hasLength(6));
      expect(
        result.checks.every(
          (check) => check.status == FactoryDoctorCheckStatus.available,
        ),
        isTrue,
      );
      expect(
        result.checks
            .firstWhere((check) => check.id == FactoryDoctorCheckId.dart)
            .version,
        '3.13.0',
      );
      expect(
        runner.commands,
        [
          'git rev-parse --show-toplevel',
          'dart --version',
          'flutter --version',
          'git --version',
          'xcodebuild -version',
          'flutter doctor --verbose',
        ],
      );
      expect(await _snapshot(root), before);
      expect(() => result.checks.clear(), throwsUnsupportedError);
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('reports unavailable Android tooling without exposing raw output',
      () async {
    final root = await Directory.systemTemp.createTemp('factory_doctor_stop_');
    final runner = _DoctorRunner(complete: false);

    try {
      final result = await FactoryEnvironmentDoctor(
        factoryRoot: root,
        processRunner: runner,
      ).inspect();

      expect(result.isOperational, isFalse);
      final android = result.checks.firstWhere(
        (check) => check.id == FactoryDoctorCheckId.androidToolchain,
      );
      expect(android.status, FactoryDoctorCheckStatus.unavailable);
      expect(android.summary, isNot(contains('do-not-expose')));
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('rejects a Git top-level that differs from the Factory root', () async {
    final root = await Directory.systemTemp.createTemp('factory_doctor_root_');
    final runner = _DoctorRunner(
      complete: true,
      reportedTopLevel: Directory.systemTemp.path,
    );

    try {
      final result = await FactoryEnvironmentDoctor(
        factoryRoot: root,
        processRunner: runner,
      ).inspect();

      final repository = result.checks.firstWhere(
        (check) => check.id == FactoryDoctorCheckId.factoryRepository,
      );
      expect(repository.status, FactoryDoctorCheckStatus.unavailable);
      expect(result.isOperational, isFalse);
    } finally {
      await root.delete(recursive: true);
    }
  });
}

final class _DoctorRunner implements BootstrapProcessRunner {
  _DoctorRunner({required this.complete, this.reportedTopLevel});

  final bool complete;
  final String? reportedTopLevel;
  final commands = <String>[];

  @override
  Future<BootstrapProcessResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    commands.add('$executable ${arguments.join(' ')}');
    final output = switch ((executable, arguments.join(' '))) {
      ('git', 'rev-parse --show-toplevel') =>
        reportedTopLevel ?? workingDirectory,
      ('dart', '--version') => 'Dart SDK version: 3.13.0 (stable)',
      ('flutter', '--version') => 'Flutter 3.41.0 • stable',
      ('git', '--version') => 'git version 2.53.0',
      ('xcodebuild', '-version') => 'Xcode 17.0\nBuild version 1A1',
      ('flutter', 'doctor --verbose') when complete =>
        '[✓] Android toolchain - develop for Android devices',
      ('flutter', 'doctor --verbose') =>
        '[!] Android toolchain token=do-not-expose',
      _ => '',
    };
    return BootstrapProcessResult(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      exitCode: 0,
      stdout: output,
      stderr: '',
    );
  }
}

Future<Map<String, String>> _snapshot(Directory root) async {
  final snapshot = <String, String>{};
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    final relative = path.relative(entity.path, from: root.path);
    if (entity is File) {
      snapshot[relative] = await entity.readAsString();
    } else {
      snapshot[relative] = entity.runtimeType.toString();
    }
  }
  return snapshot;
}
