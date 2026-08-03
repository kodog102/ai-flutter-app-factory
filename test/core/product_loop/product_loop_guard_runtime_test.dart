import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixture;
  late Directory factoryRoot;
  late Directory productRoot;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('product_loop_guard_');
    factoryRoot = await _repository(
      fixture,
      'factory',
      {'README.md': 'factory\n'},
    );
    productRoot = await _repository(
      fixture,
      'product',
      {
        'README.md': 'product\n',
        'AGENTS.md': 'authority\n',
        'lib/main.dart': 'void main() {}\n',
        'test/app_test.dart': 'void main() {}\n',
      },
    );
  });

  tearDown(() async {
    await fixture.delete(recursive: true);
  });

  test('captures a clean committed baseline with authority identities',
      () async {
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);

    final result = await runtime.captureBaseline(productRoot);

    expect(result, isA<ProductLoopBaselineProposal>());
    final proposal = result as ProductLoopBaselineProposal;
    expect(proposal.snapshot.isClean, isTrue);
    expect(proposal.snapshot.headIdentity, isNotNull);
    expect(proposal.snapshot.readmeIdentity, isNotNull);
    expect(proposal.snapshot.agentsIdentity, isNotNull);
    expect(proposal.proposalStatus, 'Proposed');
    expect(proposal.userApprovalStatus, 'Pending');
  });

  test('stops baseline capture for a missing Product root', () async {
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);

    final result = await runtime.captureBaseline(
      Directory(path.join(fixture.path, 'missing_product')),
    );

    expect(result, isA<ProductLoopBaselineCaptureStopped>());
    expect(
      (result as ProductLoopBaselineCaptureStopped).category,
      ProductLoopStopCategory.invalidProductRoot,
    );
  });

  test('captures an unborn branch with no HEAD as a non-clean baseline',
      () async {
    final unborn = await Directory(
      path.join(fixture.path, 'unborn_product'),
    ).create();
    await _git(unborn, ['init', '-b', 'unborn-main']);
    await File(path.join(unborn.path, 'README.md')).writeAsString('product\n');
    await File(path.join(unborn.path, 'AGENTS.md')).writeAsString('rules\n');
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);

    final result = await runtime.captureBaseline(unborn);

    expect(result, isA<ProductLoopBaselineProposal>());
    final snapshot = (result as ProductLoopBaselineProposal).snapshot;
    expect(snapshot.branch, 'unborn-main');
    expect(snapshot.headIdentity, isNull);
    expect(snapshot.gitStatusEntries, ['?? AGENTS.md', '?? README.md']);
    expect(snapshot.readmeIdentity, isNotNull);
    expect(snapshot.agentsIdentity, isNotNull);
  });

  test('captures staged unstaged untracked and deleted content identity',
      () async {
    await File(path.join(productRoot.path, 'README.md')).writeAsString(
      'staged\n',
    );
    await _git(productRoot, ['add', 'README.md']);
    await File(path.join(productRoot.path, 'AGENTS.md')).writeAsString(
      'unstaged\n',
    );
    await File(path.join(productRoot.path, 'new.txt')).writeAsString('new\n');
    await File(path.join(productRoot.path, 'lib/main.dart')).delete();
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);

    final result = await runtime.captureBaseline(productRoot);

    final snapshot = (result as ProductLoopBaselineProposal).snapshot;
    expect(snapshot.isClean, isFalse);
    expect(snapshot.gitStatusEntries, contains('M  README.md'));
    expect(snapshot.gitStatusEntries, contains(' M AGENTS.md'));
    expect(snapshot.gitStatusEntries, contains('?? new.txt'));
    expect(snapshot.gitStatusEntries, contains(' D lib/main.dart'));
    expect(snapshot.contentManifest['worktree:lib/main.dart'], '<deleted>');
    expect(snapshot.contentManifest['worktree:new.txt'], isNotNull);
    expect(snapshot.contentManifest['index:README.md'], isNotNull);
  });

  test('detects content changes even when Git status entries stay equal',
      () async {
    final agents = File(path.join(productRoot.path, 'AGENTS.md'));
    await agents.writeAsString('first modified value\n');
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);
    final baseline = (await runtime.captureBaseline(productRoot)
            as ProductLoopBaselineProposal)
        .snapshot;
    final statusBefore = baseline.gitStatusEntries;
    await agents.writeAsString('second modified value\n');

    final result = await runtime.inspect(
      ProductLoopGuardRequest(expectedBaseline: baseline),
    );

    expect(result, isA<ProductLoopInspectionStopped>());
    final stopped = result as ProductLoopInspectionStopped;
    expect(stopped.category, ProductLoopStopCategory.baselineMismatch);
    expect(stopped.actualSnapshot?.gitStatusEntries, statusBefore);
    expect(
      stopped.actualSnapshot?.contentManifest,
      isNot(equals(baseline.contentManifest)),
    );
  });

  test('matches an unchanged expected baseline', () async {
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);
    final baseline = (await runtime.captureBaseline(productRoot)
            as ProductLoopBaselineProposal)
        .snapshot;

    final result = await runtime.inspect(
      ProductLoopGuardRequest(
        expectedBaseline: baseline,
        buildPolicy: ProductLoopBuildPolicy.both,
      ),
    );

    expect(result, isA<ProductLoopGuardReady>());
    final ready = result as ProductLoopGuardReady;
    expect(ready.baselineStatus, 'Matched');
    expect(ready.userApprovalStatus, 'Pending');
    expect(ready.buildPolicy, ProductLoopBuildPolicy.both);
  });

  test('stops when branch or HEAD changes after baseline capture', () async {
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);
    final baseline = (await runtime.captureBaseline(productRoot)
            as ProductLoopBaselineProposal)
        .snapshot;
    await File(path.join(productRoot.path, 'README.md')).writeAsString(
      'next\n',
    );
    await _git(productRoot, ['add', 'README.md']);
    await _git(productRoot, ['commit', '-m', 'next']);

    final result = await runtime.inspect(
      ProductLoopGuardRequest(expectedBaseline: baseline),
    );

    expect(result, isA<ProductLoopInspectionStopped>());
    expect(
      (result as ProductLoopInspectionStopped).category,
      ProductLoopStopCategory.baselineMismatch,
    );
  });

  test('runs the default Health Gate and preserves pending approvals',
      () async {
    final runner = _TestRunner();
    final runtime = ProductLoopGuardRuntime(
      factoryRoot: factoryRoot,
      processRunner: runner,
    );
    final ready = await _ready(runtime, productRoot);

    final result = await runtime.validate(ready);

    expect(result, isA<ProductLoopCandidateValidated>());
    final validated = result as ProductLoopCandidateValidated;
    expect(runner.healthLabels, [
      'dart format --output=none --set-exit-if-changed lib test',
      'flutter analyze',
      'flutter test',
    ]);
    expect(validated.technicalValidationStatus, 'Passed');
    expect(validated.productContextReviewStatus, 'ReviewRequired');
    expect(validated.qaStatus, 'Pending');
    expect(validated.userApprovalStatus, 'Pending');
    expect(validated.commitStatus, 'NotPerformed');
  });

  for (final entry in {
    ProductLoopBuildPolicy.android: ['flutter build apk --debug'],
    ProductLoopBuildPolicy.ios: [
      'flutter build ios --simulator --no-codesign',
    ],
    ProductLoopBuildPolicy.both: [
      'flutter build apk --debug',
      'flutter build ios --simulator --no-codesign',
    ],
  }.entries) {
    test('runs only ${entry.key.name} build policy commands', () async {
      final runner = _TestRunner();
      final runtime = ProductLoopGuardRuntime(
        factoryRoot: factoryRoot,
        processRunner: runner,
      );
      final ready = await _ready(runtime, productRoot, policy: entry.key);

      final result = await runtime.validate(ready);

      expect(result, isA<ProductLoopCandidateValidated>());
      expect(
        runner.healthLabels.where((label) => label.contains(' build ')),
        entry.value,
      );
    });
  }

  test('stops after a failed Health Gate command', () async {
    final runner = _TestRunner(failLabel: 'flutter analyze');
    final runtime = ProductLoopGuardRuntime(
      factoryRoot: factoryRoot,
      processRunner: runner,
    );
    final ready = await _ready(
      runtime,
      productRoot,
      policy: ProductLoopBuildPolicy.both,
    );

    final result = await runtime.validate(ready);

    expect(result, isA<ProductLoopValidationStopped>());
    final stopped = result as ProductLoopValidationStopped;
    expect(stopped.category, ProductLoopStopCategory.healthGateFailed);
    expect(stopped.failedCommand?.exitCode, 1);
    expect(stopped.notPerformed, [
      'flutter test',
      'flutter build apk --debug',
      'flutter build ios --simulator --no-codesign',
    ]);
    expect(stopped.qaStatus, 'NotProposed');
    expect(stopped.commitStatus, 'NotPerformed');
  });

  test('invalidates a candidate changed during validation', () async {
    final runner = _TestRunner(
      mutateAtLabel: 'flutter test',
      mutation: () => File(
        path.join(productRoot.path, 'README.md'),
      ).writeAsString('changed during validation\n'),
    );
    final runtime = ProductLoopGuardRuntime(
      factoryRoot: factoryRoot,
      processRunner: runner,
    );
    final ready = await _ready(runtime, productRoot);

    final result = await runtime.validate(ready);

    expect(result, isA<ProductLoopValidationStopped>());
    final stopped = result as ProductLoopValidationStopped;
    expect(stopped.category, ProductLoopStopCategory.candidateChanged);
    expect(
      stopped.candidateBefore?.contentManifest,
      isNot(equals(stopped.candidateAfter?.contentManifest)),
    );
  });

  test('stops when the Factory changes during validation', () async {
    final runner = _TestRunner(
      mutateAtLabel: 'flutter test',
      mutation: () => File(
        path.join(factoryRoot.path, 'README.md'),
      ).writeAsString('factory changed during validation\n'),
    );
    final runtime = ProductLoopGuardRuntime(
      factoryRoot: factoryRoot,
      processRunner: runner,
    );
    final ready = await _ready(runtime, productRoot);

    final result = await runtime.validate(ready);

    expect(result, isA<ProductLoopValidationStopped>());
    final stopped = result as ProductLoopValidationStopped;
    expect(stopped.category, ProductLoopStopCategory.factoryChanged);
    expect(stopped.qaStatus, 'NotProposed');
    expect(stopped.commitStatus, 'NotPerformed');
  });

  test('stops before Health Gate when Product authority is missing', () async {
    final runner = _TestRunner();
    final runtime = ProductLoopGuardRuntime(
      factoryRoot: factoryRoot,
      processRunner: runner,
    );
    final baseline = (await runtime.captureBaseline(productRoot)
            as ProductLoopBaselineProposal)
        .snapshot;
    final ready = await runtime.inspect(
      ProductLoopGuardRequest(expectedBaseline: baseline),
    ) as ProductLoopGuardReady;
    await File(path.join(productRoot.path, 'AGENTS.md')).delete();

    final result = await runtime.validate(ready);

    expect(result, isA<ProductLoopValidationStopped>());
    expect(
      (result as ProductLoopValidationStopped).category,
      ProductLoopStopCategory.missingProductAuthority,
    );
    expect(runner.healthLabels, isEmpty);
  });

  test('rejects nested Factory and Product boundaries', () async {
    final nested = await Directory(
      path.join(factoryRoot.path, 'nested'),
    ).create();
    await _git(nested, ['init', '-b', 'main']);
    final runtime = ProductLoopGuardRuntime(factoryRoot: factoryRoot);

    final result = await runtime.captureBaseline(nested);

    expect(result, isA<ProductLoopBaselineCaptureStopped>());
    expect(
      (result as ProductLoopBaselineCaptureStopped).category,
      ProductLoopStopCategory.repositoryBoundaryConflict,
    );
  });

  test('returns immutable snapshot and command evidence', () async {
    final runner = _TestRunner();
    final runtime = ProductLoopGuardRuntime(
      factoryRoot: factoryRoot,
      processRunner: runner,
    );
    final ready = await _ready(runtime, productRoot);
    final result =
        await runtime.validate(ready) as ProductLoopCandidateValidated;

    expect(
      () => result.candidate.gitStatusEntries.add('unexpected'),
      throwsUnsupportedError,
    );
    expect(
      () => result.candidate.contentManifest['x'] = 'y',
      throwsUnsupportedError,
    );
    expect(
      () => result.commandsCompleted.add(
        ProductLoopProcessResult(
          executable: 'x',
          arguments: const [],
          workingDirectory: productRoot.path,
          exitCode: 0,
          stdout: '',
          stderr: '',
        ),
      ),
      throwsUnsupportedError,
    );
  });
}

Future<ProductLoopGuardReady> _ready(
  ProductLoopGuardRuntime runtime,
  Directory productRoot, {
  ProductLoopBuildPolicy policy = ProductLoopBuildPolicy.none,
}) async {
  final baseline = (await runtime.captureBaseline(productRoot)
          as ProductLoopBaselineProposal)
      .snapshot;
  return await runtime.inspect(
    ProductLoopGuardRequest(
      expectedBaseline: baseline,
      buildPolicy: policy,
    ),
  ) as ProductLoopGuardReady;
}

Future<Directory> _repository(
  Directory parent,
  String name,
  Map<String, String> files,
) async {
  final root = await Directory(path.join(parent.path, name)).create();
  await _git(root, ['init', '-b', 'main']);
  await _git(root, ['config', 'user.email', 'factory@example.invalid']);
  await _git(root, ['config', 'user.name', 'Factory Test']);
  for (final entry in files.entries) {
    final file = File(path.join(root.path, entry.key));
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  await _git(root, ['add', '.']);
  await _git(root, ['commit', '-m', 'baseline']);
  return root;
}

Future<void> _git(Directory root, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: root.path,
    runInShell: false,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
}

final class _TestRunner implements ProductLoopProcessRunner {
  _TestRunner({this.failLabel, this.mutateAtLabel, this.mutation});

  final String? failLabel;
  final String? mutateAtLabel;
  final Future<void> Function()? mutation;
  final List<String> healthLabels = [];

  @override
  Future<ProductLoopProcessResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    if (executable == 'git') {
      final result = await Process.run(
        'git',
        arguments,
        workingDirectory: workingDirectory,
        runInShell: false,
      );
      return ProductLoopProcessResult(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
    }
    final label = '$executable ${arguments.join(' ')}';
    healthLabels.add(label);
    if (label == mutateAtLabel) await mutation?.call();
    final failed = label == failLabel;
    return ProductLoopProcessResult(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      exitCode: failed ? 1 : 0,
      stdout: '',
      stderr: failed ? 'failed' : '',
    );
  }
}
