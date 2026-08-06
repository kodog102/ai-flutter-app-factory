import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../bootstrap/product_request_file.dart' show sha256HexForRequestBytes;
import 'product_loop_guard_request.dart';

const int productLoopRequestMaximumBytes = 128 * 1024;

enum ProductLoopRequestIssueCode {
  pathMustBeAbsolute,
  filenameMustBeProductLoopRequestYaml,
  fileNotFound,
  fileMustBeRegular,
  fileMustNotBeSymlink,
  fileTooLarge,
  invalidUtf8,
  malformedYaml,
  prohibitedYamlFeature,
  missingKey,
  unknownKey,
  invalidType,
  unsupportedSchemaVersion,
  blankValue,
  unsafeProductRoot,
  unsafeEvidenceDirectory,
  evidenceDirectoryNotFound,
  evidenceDirectoryMustBeDirectory,
  evidenceDirectoryMustNotBeSymlink,
  repositoryBoundaryConflict,
  secretLikeContent,
  filesystemInspectionFailed,
}

final class ProductLoopRequestIssue {
  const ProductLoopRequestIssue({
    required this.code,
    required this.field,
    required this.message,
  });

  final ProductLoopRequestIssueCode code;
  final String field;
  final String message;
}

final class ProductLoopCommandRequest {
  const ProductLoopCommandRequest({
    required this.productRoot,
    required this.buildPolicy,
    required this.evidenceDirectory,
  });

  final String productRoot;
  final ProductLoopBuildPolicy buildPolicy;
  final String evidenceDirectory;
}

sealed class ProductLoopRequestFileResult {
  const ProductLoopRequestFileResult();
}

final class ProductLoopRequestFileReady extends ProductLoopRequestFileResult {
  ProductLoopRequestFileReady({
    required this.request,
    required this.sourcePath,
    required this.requestSha256,
    required List<int> originalBytes,
  }) : originalBytes = List<int>.unmodifiable(originalBytes);

  final ProductLoopCommandRequest request;
  final String sourcePath;
  final String requestSha256;
  final List<int> originalBytes;
}

final class ProductLoopRequestFileStopped extends ProductLoopRequestFileResult {
  ProductLoopRequestFileStopped({
    required List<ProductLoopRequestIssue> issues,
    required this.requestSha256,
  }) : issues = List<ProductLoopRequestIssue>.unmodifiable(issues);

  final List<ProductLoopRequestIssue> issues;
  final String? requestSha256;
}

final class ProductLoopRequestFileReader {
  ProductLoopRequestFileReader({required Directory factoryRoot})
      : _factoryRoot = factoryRoot.absolute;

  final Directory _factoryRoot;

  Future<ProductLoopRequestFileResult> read(String requestPath) async {
    if (!path.isAbsolute(requestPath)) {
      return _stopped(
        ProductLoopRequestIssueCode.pathMustBeAbsolute,
        'requestPath',
        'The request-file path must be absolute.',
      );
    }
    if (path.basename(path.normalize(requestPath)) !=
        'product_loop_request.yaml') {
      return _stopped(
        ProductLoopRequestIssueCode.filenameMustBeProductLoopRequestYaml,
        'requestPath',
        'The request filename must be product_loop_request.yaml.',
      );
    }

    try {
      final requestType = await FileSystemEntity.type(
        requestPath,
        followLinks: false,
      );
      if (requestType == FileSystemEntityType.notFound) {
        return _stopped(
          ProductLoopRequestIssueCode.fileNotFound,
          'requestPath',
          'The request file does not exist.',
        );
      }
      if (requestType == FileSystemEntityType.link) {
        return _stopped(
          ProductLoopRequestIssueCode.fileMustNotBeSymlink,
          'requestPath',
          'The request file must not be a symbolic link.',
        );
      }
      if (requestType != FileSystemEntityType.file) {
        return _stopped(
          ProductLoopRequestIssueCode.fileMustBeRegular,
          'requestPath',
          'The request path must identify a regular file.',
        );
      }

      final requestFile = File(requestPath);
      if (await requestFile.length() > productLoopRequestMaximumBytes) {
        return _stopped(
          ProductLoopRequestIssueCode.fileTooLarge,
          'requestPath',
          'The request file exceeds the 128 KiB limit.',
        );
      }
      final bytes = await requestFile.readAsBytes();
      if (bytes.length > productLoopRequestMaximumBytes) {
        return _stopped(
          ProductLoopRequestIssueCode.fileTooLarge,
          'requestPath',
          'The request file exceeds the 128 KiB limit.',
        );
      }
      final requestSha256 = sha256HexForRequestBytes(bytes);

      late final String source;
      try {
        source = utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        return _stopped(
          ProductLoopRequestIssueCode.invalidUtf8,
          'requestFile',
          'The request file must contain valid UTF-8 text.',
          requestSha256: requestSha256,
        );
      }
      final normalizedSource =
          source.startsWith('\uFEFF') ? source.substring(1) : source;
      if (_containsProhibitedYamlFeature(normalizedSource)) {
        return _stopped(
          ProductLoopRequestIssueCode.prohibitedYamlFeature,
          'requestFile',
          'The request file uses a YAML feature outside the strict subset.',
          requestSha256: requestSha256,
        );
      }
      if (_looksSecretLike(normalizedSource)) {
        return _stopped(
          ProductLoopRequestIssueCode.secretLikeContent,
          'requestFile',
          'The request file must not contain secret-like content.',
          requestSha256: requestSha256,
        );
      }

      dynamic document;
      try {
        document = loadYaml(normalizedSource);
      } on YamlException {
        return _stopped(
          ProductLoopRequestIssueCode.malformedYaml,
          'requestFile',
          'The request file is not one valid YAML document.',
          requestSha256: requestSha256,
        );
      } on FormatException {
        return _stopped(
          ProductLoopRequestIssueCode.malformedYaml,
          'requestFile',
          'The request file is not one valid YAML document.',
          requestSha256: requestSha256,
        );
      }
      final decoded = _decode(document);
      if (decoded is ProductLoopRequestFileStopped) {
        return ProductLoopRequestFileStopped(
          issues: decoded.issues,
          requestSha256: requestSha256,
        );
      }
      final request = (decoded as _DecodedProductLoopRequest).request;

      final boundaryIssue = await _validateBoundaries(
        requestPath: requestPath,
        request: request,
      );
      if (boundaryIssue != null) {
        return ProductLoopRequestFileStopped(
          issues: [boundaryIssue],
          requestSha256: requestSha256,
        );
      }
      return ProductLoopRequestFileReady(
        request: request,
        sourcePath: path.normalize(
          await requestFile.resolveSymbolicLinks(),
        ),
        requestSha256: requestSha256,
        originalBytes: bytes,
      );
    } on FileSystemException {
      return _stopped(
        ProductLoopRequestIssueCode.filesystemInspectionFailed,
        'requestPath',
        'The request and evidence paths could not be inspected safely.',
      );
    } on OSError {
      return _stopped(
        ProductLoopRequestIssueCode.filesystemInspectionFailed,
        'requestPath',
        'The request and evidence paths could not be inspected safely.',
      );
    }
  }

  Object _decode(dynamic document) {
    if (document is! YamlMap) {
      return _decodeStopped(
        ProductLoopRequestIssueCode.invalidType,
        'root',
        'The request root must be a mapping.',
      );
    }
    const allowed = {
      'schemaVersion',
      'productRoot',
      'buildPolicy',
      'evidenceDirectory',
    };
    const required = allowed;
    final keyIssue = _validateKeys(
      document,
      allowed: allowed,
      required: required,
    );
    if (keyIssue != null)
      return ProductLoopRequestFileStopped(
          issues: [keyIssue], requestSha256: null);

    final schemaVersion = document['schemaVersion'];
    if (schemaVersion is! int) {
      return _decodeStopped(
        ProductLoopRequestIssueCode.invalidType,
        'schemaVersion',
        'schemaVersion must be the integer 1.',
      );
    }
    if (schemaVersion != 1) {
      return _decodeStopped(
        ProductLoopRequestIssueCode.unsupportedSchemaVersion,
        'schemaVersion',
        'Only request schema version 1 is supported.',
      );
    }

    final productRoot = _string(document, 'productRoot');
    if (productRoot is ProductLoopRequestIssue) {
      return ProductLoopRequestFileStopped(
          issues: [productRoot], requestSha256: null);
    }
    final evidenceDirectory = _string(document, 'evidenceDirectory');
    if (evidenceDirectory is ProductLoopRequestIssue) {
      return ProductLoopRequestFileStopped(
          issues: [evidenceDirectory], requestSha256: null);
    }
    final buildPolicyValue = document['buildPolicy'];
    if (buildPolicyValue is! String) {
      return _decodeStopped(
        ProductLoopRequestIssueCode.invalidType,
        'buildPolicy',
        'buildPolicy must be one of none, android, ios, or both.',
      );
    }
    final buildPolicy = switch (buildPolicyValue) {
      'none' => ProductLoopBuildPolicy.none,
      'android' => ProductLoopBuildPolicy.android,
      'ios' => ProductLoopBuildPolicy.ios,
      'both' => ProductLoopBuildPolicy.both,
      _ => null,
    };
    if (buildPolicy == null) {
      return _decodeStopped(
        ProductLoopRequestIssueCode.invalidType,
        'buildPolicy',
        'buildPolicy must be one of none, android, ios, or both.',
      );
    }
    return _DecodedProductLoopRequest(
      ProductLoopCommandRequest(
        productRoot: productRoot as String,
        buildPolicy: buildPolicy,
        evidenceDirectory: evidenceDirectory as String,
      ),
    );
  }

  Future<ProductLoopRequestIssue?> _validateBoundaries({
    required String requestPath,
    required ProductLoopCommandRequest request,
  }) async {
    if (!_explicitAbsolute(request.productRoot)) {
      return const ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.unsafeProductRoot,
        field: 'productRoot',
        message: 'productRoot must be an explicit absolute path.',
      );
    }
    if (!_explicitAbsolute(request.evidenceDirectory)) {
      return const ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.unsafeEvidenceDirectory,
        field: 'evidenceDirectory',
        message: 'evidenceDirectory must be an explicit absolute path.',
      );
    }
    final evidenceType = await FileSystemEntity.type(
      request.evidenceDirectory,
      followLinks: false,
    );
    if (evidenceType == FileSystemEntityType.notFound) {
      return const ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.evidenceDirectoryNotFound,
        field: 'evidenceDirectory',
        message: 'evidenceDirectory must already exist.',
      );
    }
    if (evidenceType == FileSystemEntityType.link) {
      return const ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.evidenceDirectoryMustNotBeSymlink,
        field: 'evidenceDirectory',
        message: 'evidenceDirectory must not be a symbolic link.',
      );
    }
    if (evidenceType != FileSystemEntityType.directory) {
      return const ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.evidenceDirectoryMustBeDirectory,
        field: 'evidenceDirectory',
        message: 'evidenceDirectory must be a directory.',
      );
    }

    final factory = path.normalize(await _factoryRoot.resolveSymbolicLinks());
    final product = await _canonicalizePotentialPath(request.productRoot);
    final evidence = path.normalize(
      await Directory(request.evidenceDirectory).resolveSymbolicLinks(),
    );
    final requestFile = path.normalize(
      await File(requestPath).resolveSymbolicLinks(),
    );
    if (_overlaps(factory, product) ||
        _overlaps(factory, evidence) ||
        _overlaps(product, evidence) ||
        _equalsOrIsWithin(factory, requestFile) ||
        _equalsOrIsWithin(product, requestFile)) {
      return const ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.repositoryBoundaryConflict,
        field: 'paths',
        message:
            'The request, evidence, Factory, and Product boundaries must be separate.',
      );
    }
    return null;
  }

  ProductLoopRequestIssue? _validateKeys(
    YamlMap map, {
    required Set<String> allowed,
    required Set<String> required,
  }) {
    for (final key in map.keys) {
      if (key is! String || !allowed.contains(key)) {
        return ProductLoopRequestIssue(
          code: ProductLoopRequestIssueCode.unknownKey,
          field: key?.toString() ?? 'null',
          message: 'The request contains an unknown key.',
        );
      }
    }
    for (final key in required) {
      if (!map.containsKey(key)) {
        return ProductLoopRequestIssue(
          code: ProductLoopRequestIssueCode.missingKey,
          field: key,
          message: 'The request is missing a required key.',
        );
      }
    }
    return null;
  }

  Object _string(YamlMap map, String key) {
    final value = map[key];
    if (value is! String) {
      return ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.invalidType,
        field: key,
        message: '$key must be a string.',
      );
    }
    if (value.trim().isEmpty) {
      return ProductLoopRequestIssue(
        code: ProductLoopRequestIssueCode.blankValue,
        field: key,
        message: '$key must not be blank.',
      );
    }
    return value;
  }

  bool _explicitAbsolute(String value) {
    return path.isAbsolute(value) &&
        !value.startsWith('~') &&
        !value.contains(r'$');
  }

  bool _containsProhibitedYamlFeature(String source) {
    final syntax = _syntaxOnly(source);
    return RegExp(r'(^|[\s\[{,])(?:&|\*)[A-Za-z0-9_-]+').hasMatch(syntax) ||
        RegExp(r'(^|\s)<<\s*:').hasMatch(syntax) ||
        RegExp(r'(^|\s)!{1,2}[A-Za-z0-9_]').hasMatch(syntax) ||
        RegExp(r'^\s*---\s*$', multiLine: true).allMatches(syntax).length > 1;
  }

  bool _looksSecretLike(String source) {
    return RegExp(
          r'(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|AIza[0-9A-Za-z_-]{30,})',
        ).hasMatch(source) ||
        RegExp(r'-----BEGIN [^-]*PRIVATE KEY-----').hasMatch(source);
  }

  String _syntaxOnly(String source) {
    final output = StringBuffer();
    var singleQuoted = false;
    var doubleQuoted = false;
    var escaped = false;
    var comment = false;
    for (var index = 0; index < source.length; index++) {
      final character = source[index];
      if (character == '\n') {
        comment = false;
        output.write('\n');
        continue;
      }
      if (comment) {
        output.write(' ');
        continue;
      }
      if (doubleQuoted) {
        if (escaped) {
          escaped = false;
        } else if (character == r'\') {
          escaped = true;
        } else if (character == '"') {
          doubleQuoted = false;
        }
        output.write(' ');
        continue;
      }
      if (singleQuoted) {
        if (character == "'") singleQuoted = false;
        output.write(' ');
        continue;
      }
      if (character == '#') {
        comment = true;
        output.write(' ');
      } else if (character == '"') {
        doubleQuoted = true;
        output.write(' ');
      } else if (character == "'") {
        singleQuoted = true;
        output.write(' ');
      } else {
        output.write(character);
      }
    }
    return output.toString();
  }

  Future<String> _canonicalizePotentialPath(String candidate) async {
    final normalized = path.normalize(candidate);
    var current = normalized;
    final missing = <String>[];
    var type = await FileSystemEntity.type(current, followLinks: false);
    while (type == FileSystemEntityType.notFound) {
      final parent = path.dirname(current);
      if (parent == current) break;
      missing.insert(0, path.basename(current));
      current = parent;
      type = await FileSystemEntity.type(current, followLinks: false);
    }
    final resolved = switch (type) {
      FileSystemEntityType.file => await File(current).resolveSymbolicLinks(),
      FileSystemEntityType.link => await Link(current).resolveSymbolicLinks(),
      _ => await Directory(current).resolveSymbolicLinks(),
    };
    return path.normalize(path.joinAll([resolved, ...missing]));
  }

  bool _overlaps(String first, String second) {
    return _equalsOrIsWithin(first, second) || _equalsOrIsWithin(second, first);
  }

  bool _equalsOrIsWithin(String parent, String child) {
    return path.equals(parent, child) || path.isWithin(parent, child);
  }

  ProductLoopRequestFileStopped _stopped(
    ProductLoopRequestIssueCode code,
    String field,
    String message, {
    String? requestSha256,
  }) {
    return ProductLoopRequestFileStopped(
      issues: [
        ProductLoopRequestIssue(code: code, field: field, message: message),
      ],
      requestSha256: requestSha256,
    );
  }

  ProductLoopRequestFileStopped _decodeStopped(
    ProductLoopRequestIssueCode code,
    String field,
    String message,
  ) {
    return _stopped(code, field, message);
  }
}

final class _DecodedProductLoopRequest {
  const _DecodedProductLoopRequest(this.request);

  final ProductLoopCommandRequest request;
}
