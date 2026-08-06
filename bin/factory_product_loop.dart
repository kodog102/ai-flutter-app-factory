import 'dart:io';

import 'package:ai_flutter_app_factory/core/product_loop/factory_product_loop_command.dart';

Future<void> main(List<String> arguments) async {
  final result = await FactoryProductLoopCommand(
    factoryRoot: Directory.current,
    progress: stderr.writeln,
  ).run(arguments);
  stdout.write(result.stdoutJson);
  stderr.write(result.stderrText);
  exitCode = result.exitCode;
}
