import 'dart:io';

import 'package:path/path.dart' as path;

import 'product_loop_process_runner.dart';
import 'product_loop_repository_snapshot.dart';

final class ProductLoopSnapshotCapture {
  const ProductLoopSnapshotCapture.success(this.snapshot) : failure = null;
  const ProductLoopSnapshotCapture.failure(this.failure) : snapshot = null;

  final ProductLoopRepositorySnapshot? snapshot;
  final String? failure;
  bool get succeeded => snapshot != null;
}

final class ProductLoopRepositoryInspector {
  ProductLoopRepositoryInspector({
    ProductLoopProcessRunner? runner,
  }) : _runner = runner ?? const SystemProductLoopProcessRunner();

  final ProductLoopProcessRunner _runner;

  Future<ProductLoopSnapshotCapture> capture(Directory root) async {
    try {
      if (!await root.exists()) {
        return const ProductLoopSnapshotCapture.failure(
          'The Product root does not exist.',
        );
      }
      final resolvedRoot = path.normalize(await root.resolveSymbolicLinks());
      final inside = await _git(resolvedRoot, [
        'rev-parse',
        '--is-inside-work-tree',
      ]);
      if (!inside.succeeded || inside.stdout.trim() != 'true') {
        return const ProductLoopSnapshotCapture.failure(
          'The Product root is not a trusted Git working tree.',
        );
      }
      final topLevel = await _git(resolvedRoot, [
        'rev-parse',
        '--show-toplevel',
      ]);
      if (!topLevel.succeeded) {
        return ProductLoopSnapshotCapture.failure(topLevel.stderr.trim());
      }
      final resolvedTopLevel = path.normalize(
        await Directory(topLevel.stdout.trim()).resolveSymbolicLinks(),
      );
      if (resolvedTopLevel != resolvedRoot) {
        return const ProductLoopSnapshotCapture.failure(
          'The Product root does not match the Git top-level.',
        );
      }

      var branch = await _git(resolvedRoot, [
        'symbolic-ref',
        '--quiet',
        '--short',
        'HEAD',
      ]);
      if (!branch.succeeded) {
        branch = await _git(resolvedRoot, [
          'rev-parse',
          '--abbrev-ref',
          'HEAD',
        ]);
        if (!branch.succeeded) {
          return ProductLoopSnapshotCapture.failure(branch.stderr.trim());
        }
      }
      final head = await _git(resolvedRoot, [
        'rev-parse',
        '--verify',
        '--quiet',
        'HEAD',
      ]);
      if (!head.succeeded && head.exitCode != 1) {
        return ProductLoopSnapshotCapture.failure(head.stderr.trim());
      }
      final status = await _git(resolvedRoot, [
        'status',
        '--short',
        '--untracked-files=all',
      ]);
      if (!status.succeeded) {
        return ProductLoopSnapshotCapture.failure(status.stderr.trim());
      }
      final index = await _git(resolvedRoot, ['ls-files', '-s', '-z']);
      if (!index.succeeded) {
        return ProductLoopSnapshotCapture.failure(index.stderr.trim());
      }
      final paths = await _git(resolvedRoot, [
        'ls-files',
        '-c',
        '-o',
        '--exclude-standard',
        '-z',
      ]);
      if (!paths.succeeded) {
        return ProductLoopSnapshotCapture.failure(paths.stderr.trim());
      }

      final manifest = <String, String>{};
      for (final entry in _nulEntries(index.stdout)) {
        final tab = entry.indexOf('\t');
        if (tab <= 0 || tab == entry.length - 1) {
          return const ProductLoopSnapshotCapture.failure(
            'The Git index manifest could not be parsed.',
          );
        }
        manifest['index:${entry.substring(tab + 1)}'] = entry.substring(0, tab);
      }
      final uniquePaths = _nulEntries(paths.stdout).toSet().toList()..sort();
      for (final relativePath in uniquePaths) {
        final entityType = await FileSystemEntity.type(
          path.join(resolvedRoot, relativePath),
          followLinks: false,
        );
        if (entityType == FileSystemEntityType.notFound) {
          manifest['worktree:$relativePath'] = '<deleted>';
          continue;
        }
        if (entityType != FileSystemEntityType.file &&
            entityType != FileSystemEntityType.link) {
          return ProductLoopSnapshotCapture.failure(
            'Unsupported Product entity type at $relativePath.',
          );
        }
        final identity = await _git(resolvedRoot, [
          'hash-object',
          '--no-filters',
          '--',
          relativePath,
        ]);
        if (!identity.succeeded || identity.stdout.trim().isEmpty) {
          return ProductLoopSnapshotCapture.failure(
            'Product content identity failed for $relativePath.',
          );
        }
        final stat = await FileStat.stat(path.join(resolvedRoot, relativePath));
        final entityTypeLabel =
            entityType.toString().replaceFirst('FileSystemEntityType.', '');
        manifest['worktree:$relativePath'] =
            '$entityTypeLabel:${stat.mode}:${identity.stdout.trim()}';
      }

      final statusEntries = status.stdout
          .split('\n')
          .map((entry) => entry.trimRight())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      return ProductLoopSnapshotCapture.success(
        ProductLoopRepositorySnapshot(
          productRoot: resolvedRoot,
          gitTopLevel: resolvedTopLevel,
          branch: branch.stdout.trim(),
          headIdentity: head.succeeded ? head.stdout.trim() : null,
          gitStatusEntries: statusEntries,
          contentManifest: manifest,
        ),
      );
    } on FileSystemException catch (error) {
      return ProductLoopSnapshotCapture.failure(error.message);
    } on ProcessException catch (error) {
      return ProductLoopSnapshotCapture.failure(error.message);
    }
  }

  Future<ProductLoopProcessResult> _git(
    String workingDirectory,
    List<String> arguments,
  ) {
    return _runner.run('git', arguments, workingDirectory: workingDirectory);
  }

  List<String> _nulEntries(String value) {
    return value.split('\u0000').where((entry) => entry.isNotEmpty).toList();
  }
}
