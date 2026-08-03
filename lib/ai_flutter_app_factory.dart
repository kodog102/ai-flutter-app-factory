import 'dart:io';

import 'core/bootstrap/bootstrap_execution_result.dart';
import 'core/bootstrap/bootstrap_executor.dart';
import 'core/bootstrap/bootstrap_preflight.dart';
import 'core/bootstrap/bootstrap_preflight_result.dart';
import 'core/bootstrap/bootstrap_request.dart';

export 'core/bootstrap/bootstrap_execution_result.dart';
export 'core/bootstrap/bootstrap_execution_stop_reason.dart';
export 'core/bootstrap/bootstrap_preflight_result.dart';
export 'core/bootstrap/bootstrap_process_runner.dart'
    show BootstrapProcessResult;
export 'core/bootstrap/bootstrap_request.dart';
export 'core/bootstrap/bootstrap_runtime_proposal.dart';
export 'core/bootstrap/bootstrap_stop_reason.dart';
export 'core/bootstrap/bootstrap_technical_validation.dart';
export 'core/bootstrap/repository_mode.dart';
export 'core/bootstrap/validated_bootstrap_request.dart';
export 'core/product_loop/product_loop_guard_request.dart';
export 'core/product_loop/product_loop_guard_result.dart';
export 'core/product_loop/product_loop_guard_runtime.dart';
export 'core/product_loop/product_loop_process_runner.dart'
    show ProductLoopProcessResult, ProductLoopProcessRunner;
export 'core/product_loop/product_loop_repository_snapshot.dart';

/// Official Flutter V1 execution boundary for Factory consumers.
final class FlutterAppFactoryRuntime {
  FlutterAppFactoryRuntime({required Directory factoryRoot})
      : _factoryRoot = factoryRoot.absolute,
        _preflight = FileSystemBootstrapPreflight(
          factoryRoot: factoryRoot,
        );

  final Directory _factoryRoot;
  final BootstrapPreflight _preflight;

  late final BootstrapExecutor _executor = FileSystemBootstrapExecutor(
    factoryRoot: _factoryRoot,
    preflight: _preflight,
  );

  Future<BootstrapPreflightResult> inspect(BootstrapRequest request) {
    return _preflight.inspect(request);
  }

  Future<BootstrapExecutionResult> execute(BootstrapPreflightReady ready) {
    return _executor.execute(ready);
  }
}
