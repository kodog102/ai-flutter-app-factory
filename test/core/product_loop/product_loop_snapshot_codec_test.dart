import 'dart:convert';
import 'dart:io';

import 'package:ai_flutter_app_factory/ai_flutter_app_factory.dart';
import 'package:ai_flutter_app_factory/core/product_loop/product_loop_snapshot_codec.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixture;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('product_loop_codec_');
  });

  tearDown(() async {
    await fixture.delete(recursive: true);
  });

  test('round-trips a deterministic baseline artifact', () async {
    const codec = ProductLoopSnapshotCodec();
    final artifact = _artifact();
    final first = codec.encodeBaseline(artifact);
    final second = codec.encodeBaseline(artifact);
    final file = File(path.join(fixture.path, productLoopBaselineFilename));
    await file.writeAsBytes(first);
    final sha256 = sha256HexForProductLoopBytes(first);

    final result = await codec.read(file, approvedSha256: sha256);

    expect(first, second);
    expect(result, isA<ProductLoopBaselineReadReady>());
    final ready = result as ProductLoopBaselineReadReady;
    expect(ready.sha256, sha256);
    expect(ready.artifact.requestSha256, List.filled(64, 'a').join());
    expect(ready.artifact.buildPolicy, ProductLoopBuildPolicy.both);
    expect(ready.artifact.snapshot.contentManifest, {
      'worktree:AGENTS.md': 'agents',
      'worktree:README.md': 'readme',
    });
  });

  test('rejects a baseline that differs from the approved SHA-256', () async {
    const codec = ProductLoopSnapshotCodec();
    final file = File(path.join(fixture.path, productLoopBaselineFilename));
    await file.writeAsBytes(codec.encodeBaseline(_artifact()));

    final result = await codec.read(
      file,
      approvedSha256: List.filled(64, 'b').join(),
    );

    expect(result, isA<ProductLoopBaselineReadStopped>());
    expect(
      (result as ProductLoopBaselineReadStopped).code,
      'approvedBaselineMismatch',
    );
  });

  test('rejects unknown baseline schema fields even with a matching hash',
      () async {
    const codec = ProductLoopSnapshotCodec();
    final decoded = jsonDecode(
      utf8.decode(codec.encodeBaseline(_artifact())),
    ) as Map<String, dynamic>;
    decoded['automaticApproval'] = true;
    final bytes = utf8.encode('${jsonEncode(decoded)}\n');
    final file = File(path.join(fixture.path, productLoopBaselineFilename));
    await file.writeAsBytes(bytes);

    final result = await codec.read(
      file,
      approvedSha256: sha256HexForProductLoopBytes(bytes),
    );

    expect(result, isA<ProductLoopBaselineReadStopped>());
    expect(
      (result as ProductLoopBaselineReadStopped).code,
      'invalidBaselineSchema',
    );
  });
}

ProductLoopBaselineArtifact _artifact() {
  return ProductLoopBaselineArtifact(
    requestSha256: List.filled(64, 'a').join(),
    buildPolicy: ProductLoopBuildPolicy.both,
    snapshot: ProductLoopRepositorySnapshot(
      productRoot: '/tmp/product',
      gitTopLevel: '/tmp/product',
      branch: 'main',
      headIdentity: 'abc123',
      gitStatusEntries: const [' M README.md'],
      contentManifest: const {
        'worktree:README.md': 'readme',
        'worktree:AGENTS.md': 'agents',
      },
    ),
  );
}
