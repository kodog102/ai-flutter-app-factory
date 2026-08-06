import 'dart:convert';
import 'dart:io';

import '../bootstrap/product_request_file.dart' show sha256HexForRequestBytes;
import 'product_loop_guard_request.dart';
import 'product_loop_repository_snapshot.dart';

const int productLoopBaselineSchemaVersion = 1;
const int productLoopBaselineMaximumBytes = 4 * 1024 * 1024;
const String productLoopBaselineFilename = 'product_loop_baseline.json';
const String productLoopCaptureReportFilename =
    'product_loop_capture_report.json';
const String productLoopValidationReportFilename =
    'product_loop_validation_report.json';

final class ProductLoopBaselineArtifact {
  const ProductLoopBaselineArtifact({
    required this.requestSha256,
    required this.buildPolicy,
    required this.snapshot,
  });

  final String requestSha256;
  final ProductLoopBuildPolicy buildPolicy;
  final ProductLoopRepositorySnapshot snapshot;
}

sealed class ProductLoopBaselineReadResult {
  const ProductLoopBaselineReadResult();
}

final class ProductLoopBaselineReadReady extends ProductLoopBaselineReadResult {
  ProductLoopBaselineReadReady({
    required this.artifact,
    required this.sha256,
    required List<int> originalBytes,
  }) : originalBytes = List<int>.unmodifiable(originalBytes);

  final ProductLoopBaselineArtifact artifact;
  final String sha256;
  final List<int> originalBytes;
}

final class ProductLoopBaselineReadStopped
    extends ProductLoopBaselineReadResult {
  const ProductLoopBaselineReadStopped({
    required this.code,
    required this.message,
    this.actualSha256,
  });

  final String code;
  final String message;
  final String? actualSha256;
}

final class ProductLoopSnapshotCodec {
  const ProductLoopSnapshotCodec();

  List<int> encodeBaseline(ProductLoopBaselineArtifact artifact) {
    final manifest = Map<String, String>.fromEntries(
      artifact.snapshot.contentManifest.entries.toList()
        ..sort((first, second) => first.key.compareTo(second.key)),
    );
    final document = <String, Object?>{
      'schemaVersion': productLoopBaselineSchemaVersion,
      'artifactType': 'productLoopBaselineProposal',
      'requestSha256': artifact.requestSha256,
      'buildPolicy': artifact.buildPolicy.name,
      'proposalStatus': 'Proposed',
      'userApprovalStatus': 'Pending',
      'snapshot': {
        'productRoot': artifact.snapshot.productRoot,
        'gitTopLevel': artifact.snapshot.gitTopLevel,
        'branch': artifact.snapshot.branch,
        'headIdentity': artifact.snapshot.headIdentity,
        'gitStatusEntries': artifact.snapshot.gitStatusEntries,
        'contentManifest': manifest,
      },
    };
    return utf8.encode('${jsonEncode(document)}\n');
  }

  Future<ProductLoopBaselineReadResult> read(
    File file, {
    required String approvedSha256,
  }) async {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(approvedSha256)) {
      return const ProductLoopBaselineReadStopped(
        code: 'invalidApprovedBaselineSha256',
        message:
            'The approved baseline SHA-256 must contain 64 lowercase hexadecimal characters.',
      );
    }
    try {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        return const ProductLoopBaselineReadStopped(
          code: 'baselineFileNotFound',
          message: 'The Product Loop baseline file does not exist.',
        );
      }
      if (type == FileSystemEntityType.link) {
        return const ProductLoopBaselineReadStopped(
          code: 'baselineFileMustNotBeSymlink',
          message: 'The Product Loop baseline file must not be a symlink.',
        );
      }
      if (type != FileSystemEntityType.file) {
        return const ProductLoopBaselineReadStopped(
          code: 'baselineFileMustBeRegular',
          message: 'The Product Loop baseline path must be a regular file.',
        );
      }
      if (await file.length() > productLoopBaselineMaximumBytes) {
        return const ProductLoopBaselineReadStopped(
          code: 'baselineFileTooLarge',
          message: 'The Product Loop baseline exceeds the 4 MiB limit.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > productLoopBaselineMaximumBytes) {
        return const ProductLoopBaselineReadStopped(
          code: 'baselineFileTooLarge',
          message: 'The Product Loop baseline exceeds the 4 MiB limit.',
        );
      }
      final actualSha256 = sha256HexForRequestBytes(bytes);
      if (actualSha256 != approvedSha256) {
        return ProductLoopBaselineReadStopped(
          code: 'approvedBaselineMismatch',
          message:
              'The baseline file does not match the User-approved SHA-256.',
          actualSha256: actualSha256,
        );
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      } on FormatException {
        return ProductLoopBaselineReadStopped(
          code: 'malformedBaseline',
          message: 'The baseline file is not valid UTF-8 JSON.',
          actualSha256: actualSha256,
        );
      }
      final artifact = _decode(decoded);
      if (artifact == null) {
        return ProductLoopBaselineReadStopped(
          code: 'invalidBaselineSchema',
          message: 'The baseline file does not match schema version 1.',
          actualSha256: actualSha256,
        );
      }
      return ProductLoopBaselineReadReady(
        artifact: artifact,
        sha256: actualSha256,
        originalBytes: bytes,
      );
    } on FileSystemException {
      return const ProductLoopBaselineReadStopped(
        code: 'baselineInspectionFailed',
        message: 'The baseline file could not be inspected safely.',
      );
    } on OSError {
      return const ProductLoopBaselineReadStopped(
        code: 'baselineInspectionFailed',
        message: 'The baseline file could not be inspected safely.',
      );
    }
  }

  ProductLoopBaselineArtifact? _decode(dynamic document) {
    if (document is! Map<String, dynamic> ||
        !_exactKeys(document, const {
          'schemaVersion',
          'artifactType',
          'requestSha256',
          'buildPolicy',
          'proposalStatus',
          'userApprovalStatus',
          'snapshot',
        }) ||
        document['schemaVersion'] != productLoopBaselineSchemaVersion ||
        document['artifactType'] != 'productLoopBaselineProposal' ||
        document['proposalStatus'] != 'Proposed' ||
        document['userApprovalStatus'] != 'Pending') {
      return null;
    }
    final requestSha256 = document['requestSha256'];
    if (requestSha256 is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(requestSha256)) {
      return null;
    }
    final buildPolicy = switch (document['buildPolicy']) {
      'none' => ProductLoopBuildPolicy.none,
      'android' => ProductLoopBuildPolicy.android,
      'ios' => ProductLoopBuildPolicy.ios,
      'both' => ProductLoopBuildPolicy.both,
      _ => null,
    };
    if (buildPolicy == null) return null;

    final snapshot = document['snapshot'];
    if (snapshot is! Map<String, dynamic> ||
        !_exactKeys(snapshot, const {
          'productRoot',
          'gitTopLevel',
          'branch',
          'headIdentity',
          'gitStatusEntries',
          'contentManifest',
        })) {
      return null;
    }
    final productRoot = snapshot['productRoot'];
    final gitTopLevel = snapshot['gitTopLevel'];
    final branch = snapshot['branch'];
    final headIdentity = snapshot['headIdentity'];
    final status = snapshot['gitStatusEntries'];
    final manifest = snapshot['contentManifest'];
    if (productRoot is! String ||
        productRoot.isEmpty ||
        gitTopLevel is! String ||
        gitTopLevel.isEmpty ||
        branch is! String ||
        branch.isEmpty ||
        (headIdentity != null && headIdentity is! String) ||
        status is! List<dynamic> ||
        status.any((entry) => entry is! String) ||
        manifest is! Map<String, dynamic> ||
        manifest.entries.any(
          (entry) => entry.value is! String || entry.key.isEmpty,
        )) {
      return null;
    }
    return ProductLoopBaselineArtifact(
      requestSha256: requestSha256,
      buildPolicy: buildPolicy,
      snapshot: ProductLoopRepositorySnapshot(
        productRoot: productRoot,
        gitTopLevel: gitTopLevel,
        branch: branch,
        headIdentity: headIdentity as String?,
        gitStatusEntries: status.cast<String>(),
        contentManifest: manifest.cast<String, String>(),
      ),
    );
  }

  bool _exactKeys(Map<String, dynamic> map, Set<String> keys) {
    return map.length == keys.length && map.keys.every(keys.contains);
  }
}

String sha256HexForProductLoopBytes(List<int> bytes) {
  return sha256HexForRequestBytes(bytes);
}
