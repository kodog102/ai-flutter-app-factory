import 'dart:io';

import 'package:ai_flutter_app_factory/core/bootstrap/factory_bootstrap_command.dart';

Future<void> main(List<String> arguments) async {
  final result = await FactoryBootstrapCommand(
    factoryRoot: Directory.current,
    progress: stderr.writeln,
  ).run(arguments);
  stdout.writeln(result.stdoutJson);
  stderr.write(result.stderrText);
  exitCode = result.exitCode;
}
