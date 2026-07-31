import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'bootstrap_request.dart';

const int productRequestMaximumBytes = 128 * 1024;

enum ProductRequestIssueCode {
  pathMustBeAbsolute,
  filenameMustBeProductRequestYaml,
  fileNotFound,
  fileMustBeRegular,
  fileMustNotBeSymlink,
  fileInsideFactory,
  fileInsideProductOutput,
  fileTooLarge,
  invalidUtf8,
  malformedYaml,
  prohibitedYamlFeature,
  missingKey,
  unknownKey,
  invalidType,
  unsupportedSchemaVersion,
  blankValue,
  invalidRequestId,
  secretLikeContent,
  unsafeOutputPath,
  filesystemInspectionFailed,
}

final class ProductRequestIssue {
  const ProductRequestIssue({
    required this.code,
    required this.field,
    required this.message,
  });

  final ProductRequestIssueCode code;
  final String field;
  final String message;
}

sealed class ProductRequestFileResult {
  const ProductRequestFileResult();
}

final class ProductRequestFileReady extends ProductRequestFileResult {
  ProductRequestFileReady({
    required this.request,
    required this.requestId,
    required this.requestSha256,
    required List<int> originalBytes,
  }) : originalBytes = List<int>.unmodifiable(originalBytes);

  final BootstrapRequest request;
  final String? requestId;
  final String requestSha256;
  final List<int> originalBytes;
}

final class ProductRequestFileStopped extends ProductRequestFileResult {
  ProductRequestFileStopped({
    required List<ProductRequestIssue> issues,
    required this.requestSha256,
  }) : issues = List<ProductRequestIssue>.unmodifiable(issues);

  final List<ProductRequestIssue> issues;
  final String? requestSha256;
}

final class ProductRequestFileReader {
  ProductRequestFileReader({required Directory factoryRoot})
      : _factoryRoot = factoryRoot.absolute;

  final Directory _factoryRoot;

  Future<ProductRequestFileResult> read(String requestPath) async {
    if (!path.isAbsolute(requestPath)) {
      return _stopped(
        ProductRequestIssueCode.pathMustBeAbsolute,
        'requestPath',
        'The request-file path must be absolute.',
      );
    }
    if (path.basename(path.normalize(requestPath)) != 'product_request.yaml') {
      return _stopped(
        ProductRequestIssueCode.filenameMustBeProductRequestYaml,
        'requestPath',
        'The request filename must be product_request.yaml.',
      );
    }

    try {
      final entityType = await FileSystemEntity.type(
        requestPath,
        followLinks: false,
      );
      if (entityType == FileSystemEntityType.notFound) {
        return _stopped(
          ProductRequestIssueCode.fileNotFound,
          'requestPath',
          'The request file does not exist.',
        );
      }
      if (entityType == FileSystemEntityType.link) {
        return _stopped(
          ProductRequestIssueCode.fileMustNotBeSymlink,
          'requestPath',
          'The request file must not be a symbolic link.',
        );
      }
      if (entityType != FileSystemEntityType.file) {
        return _stopped(
          ProductRequestIssueCode.fileMustBeRegular,
          'requestPath',
          'The request path must identify a regular file.',
        );
      }

      final canonicalRequestPath = path.normalize(
        await File(requestPath).resolveSymbolicLinks(),
      );
      final canonicalFactoryRoot = path.normalize(
        await _factoryRoot.resolveSymbolicLinks(),
      );
      if (_equalsOrIsWithin(canonicalFactoryRoot, canonicalRequestPath)) {
        return _stopped(
          ProductRequestIssueCode.fileInsideFactory,
          'requestPath',
          'The request file must be outside the Factory root.',
        );
      }

      final file = File(requestPath);
      final length = await file.length();
      if (length > productRequestMaximumBytes) {
        return _stopped(
          ProductRequestIssueCode.fileTooLarge,
          'requestPath',
          'The request file exceeds the 128 KiB limit.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > productRequestMaximumBytes) {
        return _stopped(
          ProductRequestIssueCode.fileTooLarge,
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
          ProductRequestIssueCode.invalidUtf8,
          'requestFile',
          'The request file must contain valid UTF-8 text.',
          requestSha256: requestSha256,
        );
      }

      final normalizedSource =
          source.startsWith('\uFEFF') ? source.substring(1) : source;
      if (_containsProhibitedYamlFeature(normalizedSource)) {
        return _stopped(
          ProductRequestIssueCode.prohibitedYamlFeature,
          'requestFile',
          'The request file uses a YAML feature outside the strict subset.',
          requestSha256: requestSha256,
        );
      }

      dynamic document;
      try {
        document = loadYaml(normalizedSource);
      } on YamlException {
        return _stopped(
          ProductRequestIssueCode.malformedYaml,
          'requestFile',
          'The request file is not one valid YAML document.',
          requestSha256: requestSha256,
        );
      } on FormatException {
        return _stopped(
          ProductRequestIssueCode.malformedYaml,
          'requestFile',
          'The request file is not one valid YAML document.',
          requestSha256: requestSha256,
        );
      }

      final decoded = _decodeDocument(document);
      if (decoded case _DecodedRequestStopped(:final issues)) {
        return ProductRequestFileStopped(
          issues: issues,
          requestSha256: requestSha256,
        );
      }
      final ready = decoded as _DecodedRequestReady;

      final outputPath = ready.request.exactOutputPath!;
      if (!path.isAbsolute(outputPath) ||
          outputPath.startsWith('~') ||
          outputPath.contains(r'$')) {
        return _stopped(
          ProductRequestIssueCode.unsafeOutputPath,
          'bootstrap.exactOutputPath',
          'The Product output path must be an explicit absolute path.',
          requestSha256: requestSha256,
        );
      }
      final canonicalOutputPath = await _canonicalizePotentialPath(outputPath);
      if (_equalsOrIsWithin(canonicalOutputPath, canonicalRequestPath)) {
        return _stopped(
          ProductRequestIssueCode.fileInsideProductOutput,
          'requestPath',
          'The request file must be outside the Product output root.',
          requestSha256: requestSha256,
        );
      }

      return ProductRequestFileReady(
        request: ready.request,
        requestId: ready.requestId,
        requestSha256: requestSha256,
        originalBytes: bytes,
      );
    } on FileSystemException {
      return _stopped(
        ProductRequestIssueCode.filesystemInspectionFailed,
        'requestPath',
        'The request file could not be inspected safely.',
      );
    } on OSError {
      return _stopped(
        ProductRequestIssueCode.filesystemInspectionFailed,
        'requestPath',
        'The request file could not be inspected safely.',
      );
    }
  }

  _DecodedRequest _decodeDocument(dynamic document) {
    if (document is! YamlMap) {
      return _decodeStopped(
        ProductRequestIssueCode.invalidType,
        'root',
        'The request root must be a mapping.',
      );
    }
    const rootKeys = {'schemaVersion', 'requestId', 'bootstrap'};
    const requiredRootKeys = {'schemaVersion', 'bootstrap'};
    final rootIssue = _validateKeys(
      document,
      allowed: rootKeys,
      required: requiredRootKeys,
      field: 'root',
    );
    if (rootIssue != null) return _DecodedRequestStopped([rootIssue]);

    final schemaVersion = document['schemaVersion'];
    if (schemaVersion is! int) {
      return _decodeStopped(
        ProductRequestIssueCode.invalidType,
        'schemaVersion',
        'schemaVersion must be the integer 1.',
      );
    }
    if (schemaVersion != 1) {
      return _decodeStopped(
        ProductRequestIssueCode.unsupportedSchemaVersion,
        'schemaVersion',
        'Only request schema version 1 is supported.',
      );
    }

    final requestIdValue = document['requestId'];
    String? requestId;
    if (document.containsKey('requestId')) {
      if (requestIdValue is! String) {
        return _decodeStopped(
          ProductRequestIssueCode.invalidType,
          'requestId',
          'requestId must be a string when supplied.',
        );
      }
      if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')
          .hasMatch(requestIdValue)) {
        return _decodeStopped(
          ProductRequestIssueCode.invalidRequestId,
          'requestId',
          'requestId must be a short opaque correlation value.',
        );
      }
      if (_looksSecretLike(requestIdValue)) {
        return _decodeStopped(
          ProductRequestIssueCode.secretLikeContent,
          'requestId',
          'requestId must not contain secret-like content.',
        );
      }
      requestId = requestIdValue;
    }

    final bootstrap = document['bootstrap'];
    if (bootstrap is! YamlMap) {
      return _decodeStopped(
        ProductRequestIssueCode.invalidType,
        'bootstrap',
        'bootstrap must be a mapping.',
      );
    }
    const bootstrapKeys = {
      'productDisplayName',
      'productPurpose',
      'initialProductScopeOrFirstIntendedOutcome',
      'exactOutputPath',
      'repositoryMode',
      'initialBranchName',
      'repositoryPolicy',
      'flutterProjectName',
      'organizationIdentifier',
      'requestedTechnology',
      'targetPlatforms',
    };
    final bootstrapIssue = _validateKeys(
      bootstrap,
      allowed: bootstrapKeys,
      required: bootstrapKeys,
      field: 'bootstrap',
    );
    if (bootstrapIssue != null) {
      return _DecodedRequestStopped([bootstrapIssue]);
    }

    const requiredTextFields = {
      'productDisplayName',
      'productPurpose',
      'initialProductScopeOrFirstIntendedOutcome',
      'exactOutputPath',
      'repositoryMode',
      'flutterProjectName',
      'organizationIdentifier',
      'requestedTechnology',
    };
    for (final field in requiredTextFields) {
      final value = bootstrap[field];
      if (value is! String) {
        return _decodeStopped(
          ProductRequestIssueCode.invalidType,
          'bootstrap.$field',
          'A required bootstrap field has the wrong type.',
        );
      }
      if (value.trim().isEmpty) {
        return _decodeStopped(
          ProductRequestIssueCode.blankValue,
          'bootstrap.$field',
          'A required bootstrap text value must not be blank.',
        );
      }
      if (_looksSecretLike(value)) {
        return _decodeStopped(
          ProductRequestIssueCode.secretLikeContent,
          'bootstrap.$field',
          'Bootstrap text fields must not contain secret-like content.',
        );
      }
    }

    for (final field in ['initialBranchName', 'repositoryPolicy']) {
      final value = bootstrap[field];
      if (value != null && value is! String) {
        return _decodeStopped(
          ProductRequestIssueCode.invalidType,
          'bootstrap.$field',
          'Branch and Repository policy values must be strings or null.',
        );
      }
      if (value is String && value.trim().isEmpty) {
        return _decodeStopped(
          ProductRequestIssueCode.blankValue,
          'bootstrap.$field',
          'Branch and Repository policy strings must not be blank.',
        );
      }
      if (value is String && _looksSecretLike(value)) {
        return _decodeStopped(
          ProductRequestIssueCode.secretLikeContent,
          'bootstrap.$field',
          'Branch and Repository policy must not contain secret-like content.',
        );
      }
    }

    final platforms = bootstrap['targetPlatforms'];
    if (platforms is! YamlList ||
        platforms.any((item) => item is! String || item.trim().isEmpty)) {
      return _decodeStopped(
        ProductRequestIssueCode.invalidType,
        'bootstrap.targetPlatforms',
        'targetPlatforms must be a list of non-blank strings.',
      );
    }

    return _DecodedRequestReady(
      BootstrapRequest(
        productDisplayName: bootstrap['productDisplayName'] as String,
        productPurpose: bootstrap['productPurpose'] as String,
        initialProductScopeOrFirstIntendedOutcome:
            bootstrap['initialProductScopeOrFirstIntendedOutcome'] as String,
        exactOutputPath: bootstrap['exactOutputPath'] as String,
        repositoryMode: bootstrap['repositoryMode'] as String,
        initialBranchName: bootstrap['initialBranchName'] as String?,
        repositoryPolicy: bootstrap['repositoryPolicy'] as String?,
        flutterProjectName: bootstrap['flutterProjectName'] as String,
        organizationIdentifier: bootstrap['organizationIdentifier'] as String,
        requestedTechnology: bootstrap['requestedTechnology'] as String,
        targetPlatforms: platforms.cast<String>().toList(growable: false),
      ),
      requestId,
    );
  }

  ProductRequestIssue? _validateKeys(
    YamlMap map, {
    required Set<String> allowed,
    required Set<String> required,
    required String field,
  }) {
    if (map.keys.any((key) => key is! String || !allowed.contains(key))) {
      return ProductRequestIssue(
        code: ProductRequestIssueCode.unknownKey,
        field: field,
        message: 'The request contains an unknown key.',
      );
    }
    if (required.any((key) => !map.containsKey(key))) {
      return ProductRequestIssue(
        code: ProductRequestIssueCode.missingKey,
        field: field,
        message: 'The request is missing a required key.',
      );
    }
    return null;
  }

  ProductRequestFileStopped _stopped(
    ProductRequestIssueCode code,
    String field,
    String message, {
    String? requestSha256,
  }) {
    return ProductRequestFileStopped(
      issues: [ProductRequestIssue(code: code, field: field, message: message)],
      requestSha256: requestSha256,
    );
  }

  _DecodedRequestStopped _decodeStopped(
    ProductRequestIssueCode code,
    String field,
    String message,
  ) {
    return _DecodedRequestStopped([
      ProductRequestIssue(code: code, field: field, message: message),
    ]);
  }

  bool _containsProhibitedYamlFeature(String source) {
    final syntax = _syntaxOnly(source);
    for (final line in const LineSplitter().convert(syntax)) {
      final trimmed = line.trim();
      if (trimmed == '---' ||
          trimmed == '...' ||
          trimmed.startsWith('%') ||
          RegExp(r'^<<\s*:').hasMatch(trimmed) ||
          RegExp(r'^\?\s').hasMatch(trimmed) ||
          RegExp(r':\s*[|>]\s*$').hasMatch(line)) {
        return true;
      }
    }
    return RegExp(r'(^|[\s:\[,{-])[&*!](?=\S)', multiLine: true)
            .hasMatch(syntax) ||
        RegExp(r'[\[\]{}]').hasMatch(syntax);
  }

  bool _looksSecretLike(String value) {
    return RegExp(
          r'(password|secret|token|api[_-]?key|authorization|bearer)\s*[:=]\s*\S+',
          caseSensitive: false,
        ).hasMatch(value) ||
        RegExp(
          r'(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|AIza[0-9A-Za-z_-]{30,})',
        ).hasMatch(value) ||
        RegExp(r'-----BEGIN [^-]*PRIVATE KEY-----').hasMatch(value);
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
        if (character == "'" &&
            index + 1 < source.length &&
            source[index + 1] == "'") {
          output.write('  ');
          index++;
          continue;
        }
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
    final missingSegments = <String>[];
    var current = normalized;
    var currentType = await FileSystemEntity.type(current, followLinks: false);
    while (currentType == FileSystemEntityType.notFound) {
      final parent = path.dirname(current);
      if (parent == current) break;
      missingSegments.insert(0, path.basename(current));
      current = parent;
      currentType = await FileSystemEntity.type(current, followLinks: false);
    }
    final resolvedPath = switch (currentType) {
      FileSystemEntityType.file => await File(current).resolveSymbolicLinks(),
      FileSystemEntityType.link => await Link(current).resolveSymbolicLinks(),
      _ => await Directory(current).resolveSymbolicLinks(),
    };
    final resolved = path.normalize(resolvedPath);
    return path.normalize(path.joinAll([resolved, ...missingSegments]));
  }

  bool _equalsOrIsWithin(String parent, String child) {
    return path.equals(parent, child) || path.isWithin(parent, child);
  }
}

sealed class _DecodedRequest {
  const _DecodedRequest();
}

final class _DecodedRequestReady extends _DecodedRequest {
  const _DecodedRequestReady(this.request, this.requestId);

  final BootstrapRequest request;
  final String? requestId;
}

final class _DecodedRequestStopped extends _DecodedRequest {
  const _DecodedRequestStopped(this.issues);

  final List<ProductRequestIssue> issues;
}

String sha256HexForRequestBytes(List<int> bytes) {
  const initial = <int>[
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];
  const constants = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];
  final padded = List<int>.from(bytes);
  final bitLength = bytes.length * 8;
  padded.add(0x80);
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  for (var shift = 56; shift >= 0; shift -= 8) {
    padded.add((bitLength >> shift) & 0xff);
  }

  final hash = List<int>.from(initial);
  final words = List<int>.filled(64, 0);
  for (var offset = 0; offset < padded.length; offset += 64) {
    for (var index = 0; index < 16; index++) {
      final position = offset + index * 4;
      words[index] = ((padded[position] << 24) |
              (padded[position + 1] << 16) |
              (padded[position + 2] << 8) |
              padded[position + 3]) &
          0xffffffff;
    }
    for (var index = 16; index < 64; index++) {
      final s0 = _rotateRight(words[index - 15], 7) ^
          _rotateRight(words[index - 15], 18) ^
          (words[index - 15] >> 3);
      final s1 = _rotateRight(words[index - 2], 17) ^
          _rotateRight(words[index - 2], 19) ^
          (words[index - 2] >> 10);
      words[index] =
          (words[index - 16] + s0 + words[index - 7] + s1) & 0xffffffff;
    }

    var a = hash[0];
    var b = hash[1];
    var c = hash[2];
    var d = hash[3];
    var e = hash[4];
    var f = hash[5];
    var g = hash[6];
    var h = hash[7];
    for (var index = 0; index < 64; index++) {
      final sum1 =
          _rotateRight(e, 6) ^ _rotateRight(e, 11) ^ _rotateRight(e, 25);
      final choice = (e & f) ^ ((~e) & g);
      final temp1 =
          (h + sum1 + choice + constants[index] + words[index]) & 0xffffffff;
      final sum0 =
          _rotateRight(a, 2) ^ _rotateRight(a, 13) ^ _rotateRight(a, 22);
      final majority = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (sum0 + majority) & 0xffffffff;
      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }
    hash[0] = (hash[0] + a) & 0xffffffff;
    hash[1] = (hash[1] + b) & 0xffffffff;
    hash[2] = (hash[2] + c) & 0xffffffff;
    hash[3] = (hash[3] + d) & 0xffffffff;
    hash[4] = (hash[4] + e) & 0xffffffff;
    hash[5] = (hash[5] + f) & 0xffffffff;
    hash[6] = (hash[6] + g) & 0xffffffff;
    hash[7] = (hash[7] + h) & 0xffffffff;
  }
  return hash.map((word) => word.toRadixString(16).padLeft(8, '0')).join();
}

int _rotateRight(int value, int count) {
  final normalized = value & 0xffffffff;
  return ((normalized >> count) | (normalized << (32 - count))) & 0xffffffff;
}
