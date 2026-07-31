import 'dart:io';

abstract interface class BootstrapProcessRunner {
  Future<BootstrapProcessResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  });
}

final class SystemBootstrapProcessRunner implements BootstrapProcessRunner {
  const SystemBootstrapProcessRunner();

  @override
  Future<BootstrapProcessResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    try {
      final result = await Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: false,
        environment: const {
          'LANG': 'C',
          'LC_ALL': 'C',
        },
      );
      return BootstrapProcessResult(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
    } on ProcessException catch (error) {
      return BootstrapProcessResult(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        exitCode: null,
        stdout: '',
        stderr: error.message,
        didStart: false,
      );
    }
  }
}

final class BootstrapProcessResult {
  BootstrapProcessResult({
    required this.executable,
    required List<String> arguments,
    required this.workingDirectory,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.didStart = true,
  }) : arguments = List<String>.unmodifiable(arguments);

  final String executable;
  final List<String> arguments;
  final String workingDirectory;
  final int? exitCode;
  final String stdout;
  final String stderr;
  final bool didStart;

  bool get succeeded => didStart && exitCode == 0;
}
