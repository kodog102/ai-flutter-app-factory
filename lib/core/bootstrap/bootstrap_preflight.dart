import 'dart:io';

import 'package:path/path.dart' as path;

import 'bootstrap_preflight_result.dart';
import 'bootstrap_request.dart';
import 'bootstrap_stop_reason.dart';
import 'repository_mode.dart';
import 'validated_bootstrap_request.dart';

abstract interface class BootstrapPreflight {
  Future<BootstrapPreflightResult> inspect(BootstrapRequest request);
}

abstract interface class GitRepositoryInspector {
  Future<GitRepositoryInspection> inspect(String targetPath);
}

enum GitRepositoryInspectionStatus {
  valid,
  notRepository,
  toolUnavailable,
  failed,
}

final class GitRepositoryInspection {
  const GitRepositoryInspection({
    required this.status,
    this.topLevelPath,
    this.details,
  });

  final GitRepositoryInspectionStatus status;
  final String? topLevelPath;
  final String? details;
}

final class ProcessGitRepositoryInspector implements GitRepositoryInspector {
  const ProcessGitRepositoryInspector({
    this.executable = 'git',
  });

  final String executable;

  @override
  Future<GitRepositoryInspection> inspect(String targetPath) async {
    try {
      final insideWorkTree = await Process.run(
        executable,
        ['-C', targetPath, 'rev-parse', '--is-inside-work-tree'],
        environment: const {
          'LANG': 'C',
          'LC_ALL': 'C',
        },
      );
      if (insideWorkTree.exitCode != 0) {
        final details = insideWorkTree.stderr.toString();
        return GitRepositoryInspection(
          status: details.contains('not a git repository')
              ? GitRepositoryInspectionStatus.notRepository
              : GitRepositoryInspectionStatus.failed,
          details: details,
        );
      }
      if (_singleOutputLine(insideWorkTree.stdout) != 'true') {
        return const GitRepositoryInspection(
          status: GitRepositoryInspectionStatus.failed,
          details: 'Git did not confirm an independent working tree.',
        );
      }

      final topLevel = await Process.run(
        executable,
        ['-C', targetPath, 'rev-parse', '--show-toplevel'],
        environment: const {
          'LANG': 'C',
          'LC_ALL': 'C',
        },
      );
      if (topLevel.exitCode != 0) {
        return GitRepositoryInspection(
          status: GitRepositoryInspectionStatus.failed,
          details: topLevel.stderr.toString(),
        );
      }

      final topLevelPath = _singleOutputLine(topLevel.stdout);
      if (topLevelPath == null || !path.isAbsolute(topLevelPath)) {
        return const GitRepositoryInspection(
          status: GitRepositoryInspectionStatus.failed,
          details: 'Git returned an invalid top-level path.',
        );
      }

      return GitRepositoryInspection(
        status: GitRepositoryInspectionStatus.valid,
        topLevelPath: topLevelPath,
      );
    } on ProcessException catch (error) {
      return GitRepositoryInspection(
        status: GitRepositoryInspectionStatus.toolUnavailable,
        details: error.message,
      );
    }
  }

  static String? _singleOutputLine(Object? output) {
    final value = output.toString();
    final withoutTerminator = value.endsWith('\r\n')
        ? value.substring(0, value.length - 2)
        : value.endsWith('\n')
            ? value.substring(0, value.length - 1)
            : value;
    if (withoutTerminator.isEmpty ||
        withoutTerminator.contains('\n') ||
        withoutTerminator.contains('\r')) {
      return null;
    }
    return withoutTerminator;
  }
}

final class FileSystemBootstrapPreflight implements BootstrapPreflight {
  FileSystemBootstrapPreflight({
    required Directory factoryRoot,
    GitRepositoryInspector gitInspector = const ProcessGitRepositoryInspector(),
  })  : _factoryRoot = factoryRoot.absolute,
        _gitInspector = gitInspector;

  static const _notPerformed = <String>[
    'No target path, file, or directory was created or modified.',
    'No Git metadata, branch, template, scaffold, or Product authority was created.',
  ];

  static const _dartReservedWords = <String>{
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'of',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };

  final Directory _factoryRoot;
  final GitRepositoryInspector _gitInspector;

  @override
  Future<BootstrapPreflightResult> inspect(BootstrapRequest request) async {
    final validation = _validateInputs(request);
    if (validation.reasons.isNotEmpty) {
      return _stopped(validation.reasons);
    }

    final validatedRequest = validation.validatedRequest!;

    try {
      return await _inspectFileSystem(validatedRequest);
    } on FileSystemException catch (error) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.filesystemInspectionFailed,
          fieldOrFact: error.path ?? validatedRequest.exactOutputPath,
          description: 'Filesystem inspection failed: ${error.message}',
        ),
      ]);
    } on OSError catch (error) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.filesystemInspectionFailed,
          fieldOrFact: validatedRequest.exactOutputPath,
          description: 'Filesystem inspection failed: ${error.message}',
        ),
      ]);
    }
  }

  _InputValidation _validateInputs(BootstrapRequest request) {
    final reasons = <BootstrapStopReason>[];

    _requireText(
      request.productDisplayName,
      field: 'productDisplayName',
      reasons: reasons,
    );
    _requireText(
      request.productPurpose,
      field: 'productPurpose',
      reasons: reasons,
    );
    _requireText(
      request.initialProductScopeOrFirstIntendedOutcome,
      field: 'initialProductScopeOrFirstIntendedOutcome',
      reasons: reasons,
    );
    _requireText(
      request.exactOutputPath,
      field: 'exactOutputPath',
      reasons: reasons,
    );
    _requireText(
      request.flutterProjectName,
      field: 'flutterProjectName',
      reasons: reasons,
    );
    _requireText(
      request.organizationIdentifier,
      field: 'organizationIdentifier',
      reasons: reasons,
    );
    _requireText(
      request.requestedTechnology,
      field: 'requestedTechnology',
      reasons: reasons,
    );

    final rawMode = request.repositoryMode;
    RepositoryMode? repositoryMode;
    if (!_hasText(rawMode)) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.missingInput,
          fieldOrFact: 'repositoryMode',
          description: 'Repository mode is required.',
        ),
      );
    } else {
      repositoryMode = RepositoryMode.tryParse(rawMode!);
      if (repositoryMode == null) {
        reasons.add(
          const BootstrapStopReason(
            category: BootstrapStopCategory.invalidRepositoryMode,
            fieldOrFact: 'repositoryMode',
            description:
                'Repository mode must be exactly newRepository or existingEmptyRepository.',
          ),
        );
      }
    }

    final hasBranch = _hasText(request.initialBranchName);
    final hasPolicy = _hasText(request.repositoryPolicy);
    if (!hasBranch && !hasPolicy) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.missingInput,
          fieldOrFact: 'initialBranchNameOrRepositoryPolicy',
          description:
              'An initial branch name or Repository policy is required.',
        ),
      );
    } else if (hasBranch && hasPolicy) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.ambiguousInput,
          fieldOrFact: 'initialBranchNameOrRepositoryPolicy',
          description:
              'Provide either an initial branch name or a Repository policy, not both.',
        ),
      );
    }

    if (hasBranch && !_isSafeBranchName(request.initialBranchName!)) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.invalidBranchOrRepositoryPolicy,
          fieldOrFact: 'initialBranchName',
          description: 'The initial branch name is unsafe or ambiguous.',
        ),
      );
    }

    if (repositoryMode == RepositoryMode.newRepository && !hasBranch) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.invalidBranchOrRepositoryPolicy,
          fieldOrFact: 'initialBranchName',
          description: 'New Repository mode requires an initial branch name.',
        ),
      );
    }

    if (repositoryMode == RepositoryMode.existingEmptyRepository &&
        !hasPolicy) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.invalidBranchOrRepositoryPolicy,
          fieldOrFact: 'initialBranchNameOrRepositoryPolicy',
          description:
              'Existing Empty Repository mode requires a Repository policy and does not accept an initial branch name.',
        ),
      );
    }

    if (_hasText(request.requestedTechnology) &&
        request.requestedTechnology != 'flutter') {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.unsupportedTechnology,
          fieldOrFact: 'requestedTechnology',
          description: 'Executable V1 supports only the exact value flutter.',
        ),
      );
    }

    final platforms = request.targetPlatforms;
    if (platforms == null || platforms.isEmpty) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.missingInput,
          fieldOrFact: 'targetPlatforms',
          description: 'Target platforms are required.',
        ),
      );
    } else {
      final containsBlank = platforms.any((value) => value.trim().isEmpty);
      if (containsBlank) {
        reasons.add(
          const BootstrapStopReason(
            category: BootstrapStopCategory.missingInput,
            fieldOrFact: 'targetPlatforms',
            description: 'Target platform values cannot be blank.',
          ),
        );
      }

      final platformSet = platforms.toSet();
      final isCanonicalSet = platformSet.length == 2 &&
          platformSet.contains('ios') &&
          platformSet.contains('android');
      final hasDuplicates = platformSet.length != platforms.length;
      if (!containsBlank && (!isCanonicalSet || hasDuplicates)) {
        reasons.add(
          const BootstrapStopReason(
            category: BootstrapStopCategory.unsupportedTargetPlatforms,
            fieldOrFact: 'targetPlatforms',
            description:
                'Target platforms must contain ios and android exactly once each.',
          ),
        );
      }
    }

    if (_hasText(request.flutterProjectName) &&
        !_isValidFlutterProjectName(request.flutterProjectName!)) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.invalidFlutterProjectName,
          fieldOrFact: 'flutterProjectName',
          description:
              'The Flutter project name must be a lowercase Dart identifier and not a reserved word.',
        ),
      );
    }

    if (_hasText(request.organizationIdentifier) &&
        !_isValidOrganizationIdentifier(request.organizationIdentifier!)) {
      reasons.add(
        const BootstrapStopReason(
          category: BootstrapStopCategory.invalidOrganizationIdentifier,
          fieldOrFact: 'organizationIdentifier',
          description:
              'The organization identifier must be a lowercase reverse-domain value.',
        ),
      );
    }

    if (_hasText(request.exactOutputPath)) {
      final outputPath = request.exactOutputPath!;
      if (!path.isAbsolute(outputPath)) {
        reasons.add(
          const BootstrapStopReason(
            category: BootstrapStopCategory.unsafeOutputPath,
            fieldOrFact: 'exactOutputPath',
            description: 'The output path must be absolute.',
          ),
        );
      } else {
        final normalizedPath = path.normalize(outputPath);
        final homePath = Platform.environment['HOME'];
        if (path.equals(normalizedPath, path.rootPrefix(normalizedPath)) ||
            (homePath != null &&
                path.equals(normalizedPath, path.normalize(homePath)))) {
          reasons.add(
            const BootstrapStopReason(
              category: BootstrapStopCategory.unsafeOutputPath,
              fieldOrFact: 'exactOutputPath',
              description:
                  'The filesystem root or user home cannot be a Product target.',
            ),
          );
        }
      }
    }

    if (reasons.isNotEmpty) {
      return _InputValidation(reasons: reasons);
    }

    return _InputValidation(
      reasons: reasons,
      validatedRequest: ValidatedBootstrapRequest(
        productDisplayName: request.productDisplayName!,
        productPurpose: request.productPurpose!,
        initialProductScopeOrFirstIntendedOutcome:
            request.initialProductScopeOrFirstIntendedOutcome!,
        exactOutputPath: request.exactOutputPath!,
        repositoryMode: repositoryMode!,
        initialBranchName: hasBranch ? request.initialBranchName : null,
        repositoryPolicy: hasPolicy ? request.repositoryPolicy : null,
        flutterProjectName: request.flutterProjectName!,
        organizationIdentifier: request.organizationIdentifier!,
        requestedTechnology: request.requestedTechnology!,
        targetPlatforms: platforms!,
      ),
    );
  }

  Future<BootstrapPreflightResult> _inspectFileSystem(
    ValidatedBootstrapRequest request,
  ) async {
    final normalizedOutputPath = path.normalize(request.exactOutputPath);
    final factoryRootPath = path.normalize(
      await _factoryRoot.resolveSymbolicLinks(),
    );

    if (_equalsOrIsWithin(factoryRootPath, normalizedOutputPath)) {
      return _stopped([
        const BootstrapStopReason(
          category: BootstrapStopCategory.factoryBoundaryConflict,
          fieldOrFact: 'exactOutputPath',
          description:
              'The Product target cannot be the Factory root or a path inside it.',
        ),
      ]);
    }

    return switch (request.repositoryMode) {
      RepositoryMode.newRepository => _inspectNewRepository(
          request,
          normalizedOutputPath,
          factoryRootPath,
        ),
      RepositoryMode.existingEmptyRepository => _inspectExistingRepository(
          request,
          normalizedOutputPath,
          factoryRootPath,
        ),
    };
  }

  Future<BootstrapPreflightResult> _inspectNewRepository(
    ValidatedBootstrapRequest request,
    String normalizedOutputPath,
    String factoryRootPath,
  ) async {
    final targetType = await FileSystemEntity.type(
      normalizedOutputPath,
      followLinks: false,
    );

    if (targetType == FileSystemEntityType.link) {
      return _unsafeSymlink(normalizedOutputPath);
    }
    if (targetType != FileSystemEntityType.notFound) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.outputAlreadyExists,
          fieldOrFact: normalizedOutputPath,
          description: 'New Repository target already exists.',
        ),
      ]);
    }

    final nearest = await _nearestExistingEntity(
      path.dirname(normalizedOutputPath),
    );
    if (nearest.type == FileSystemEntityType.link) {
      return _unsafeSymlink(nearest.path);
    }
    if (nearest.type != FileSystemEntityType.directory) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.targetIsNotDirectory,
          fieldOrFact: nearest.path,
          description: 'The nearest existing parent is not a directory.',
        ),
      ]);
    }

    final linkedComponent = await _findLinkedPathComponent(nearest.path);
    if (linkedComponent != null) {
      return _unsafeSymlink(linkedComponent);
    }

    final resolvedParent = path.normalize(
      await Directory(nearest.path).resolveSymbolicLinks(),
    );
    if (_equalsOrIsWithin(factoryRootPath, resolvedParent)) {
      return _stopped([
        const BootstrapStopReason(
          category: BootstrapStopCategory.factoryBoundaryConflict,
          fieldOrFact: 'exactOutputPath',
          description:
              'The Product target resolves inside the Factory Repository.',
        ),
      ]);
    }

    final repositoryBoundary = await _findGitBoundary(
      Directory(nearest.path),
    );
    if (repositoryBoundary != null) {
      return _repositoryBoundaryConflict(repositoryBoundary);
    }

    return BootstrapPreflightReady(
      validatedRequest: request,
      normalizedOutputPath: normalizedOutputPath,
      inspection: BootstrapTargetInspection(
        inspectedPath: request.exactOutputPath,
        normalizedPath: normalizedOutputPath,
        targetExists: false,
        repositoryMode: request.repositoryMode,
        nearestExistingParent: nearest.path,
        hasIndependentGitDirectory: false,
        targetEntries: const [],
      ),
    );
  }

  Future<BootstrapPreflightResult> _inspectExistingRepository(
    ValidatedBootstrapRequest request,
    String normalizedOutputPath,
    String factoryRootPath,
  ) async {
    final targetType = await FileSystemEntity.type(
      normalizedOutputPath,
      followLinks: false,
    );
    if (targetType == FileSystemEntityType.notFound) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.outputDoesNotExist,
          fieldOrFact: normalizedOutputPath,
          description: 'Existing Repository target does not exist.',
        ),
      ]);
    }
    if (targetType == FileSystemEntityType.link) {
      return _unsafeSymlink(normalizedOutputPath);
    }
    if (targetType != FileSystemEntityType.directory) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.targetIsNotDirectory,
          fieldOrFact: normalizedOutputPath,
          description: 'Existing Repository target is not a directory.',
        ),
      ]);
    }

    final linkedComponent = await _findLinkedPathComponent(
      normalizedOutputPath,
    );
    if (linkedComponent != null) {
      return _unsafeSymlink(linkedComponent);
    }

    final resolvedTarget = path.normalize(
      await Directory(normalizedOutputPath).resolveSymbolicLinks(),
    );
    if (_equalsOrIsWithin(factoryRootPath, resolvedTarget)) {
      return _stopped([
        const BootstrapStopReason(
          category: BootstrapStopCategory.factoryBoundaryConflict,
          fieldOrFact: 'exactOutputPath',
          description:
              'The Product target resolves inside the Factory Repository.',
        ),
      ]);
    }

    final repositoryBoundary = await _findGitBoundary(
      Directory(path.dirname(normalizedOutputPath)),
    );
    if (repositoryBoundary != null) {
      return _repositoryBoundaryConflict(repositoryBoundary);
    }

    final gitPath = path.join(normalizedOutputPath, '.git');
    final gitType = await FileSystemEntity.type(
      gitPath,
      followLinks: false,
    );
    if (gitType == FileSystemEntityType.notFound) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.existingRepositoryRequired,
          fieldOrFact: gitPath,
          description:
              'Existing Empty Repository mode requires an independent .git directory.',
        ),
      ]);
    }
    if (gitType != FileSystemEntityType.directory) {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.linkedGitMetadataUnsupported,
          fieldOrFact: gitPath,
          description:
              'V1 does not support .git files, links, worktrees, or submodules.',
        ),
      ]);
    }

    final entries = await Directory(normalizedOutputPath)
        .list(followLinks: false)
        .map((entity) => path.basename(entity.path))
        .toList();
    entries.sort();
    if (entries.length != 1 || entries.single != '.git') {
      return _stopped([
        BootstrapStopReason(
          category: BootstrapStopCategory.existingRepositoryNotEmpty,
          fieldOrFact: normalizedOutputPath,
          description:
              'Existing Empty Repository target contains entries other than .git.',
        ),
      ]);
    }

    final gitInspection = await _gitInspector.inspect(normalizedOutputPath);
    switch (gitInspection.status) {
      case GitRepositoryInspectionStatus.notRepository:
        return _stopped([
          BootstrapStopReason(
            category: BootstrapStopCategory.existingRepositoryRequired,
            fieldOrFact: normalizedOutputPath,
            description:
                'The target is not a valid independent Git Repository.',
          ),
        ]);
      case GitRepositoryInspectionStatus.toolUnavailable:
      case GitRepositoryInspectionStatus.failed:
        return _stopped([
          BootstrapStopReason(
            category: BootstrapStopCategory.gitInspectionFailed,
            fieldOrFact: normalizedOutputPath,
            description:
                'Read-only Git inspection failed: ${gitInspection.details ?? 'unknown error'}',
          ),
        ]);
      case GitRepositoryInspectionStatus.valid:
        final topLevelPath = gitInspection.topLevelPath;
        if (topLevelPath == null) {
          return _stopped([
            BootstrapStopReason(
              category: BootstrapStopCategory.gitInspectionFailed,
              fieldOrFact: normalizedOutputPath,
              description:
                  'Read-only Git inspection did not return a top-level path.',
            ),
          ]);
        }
        if (!path.equals(path.normalize(topLevelPath), normalizedOutputPath)) {
          return _stopped([
            BootstrapStopReason(
              category: BootstrapStopCategory.repositoryBoundaryConflict,
              fieldOrFact: topLevelPath,
              description:
                  'Git reports a top-level path different from the Product target.',
            ),
          ]);
        }
    }

    return BootstrapPreflightReady(
      validatedRequest: request,
      normalizedOutputPath: normalizedOutputPath,
      inspection: BootstrapTargetInspection(
        inspectedPath: request.exactOutputPath,
        normalizedPath: normalizedOutputPath,
        targetExists: true,
        repositoryMode: request.repositoryMode,
        nearestExistingParent: normalizedOutputPath,
        hasIndependentGitDirectory: true,
        targetEntries: entries,
      ),
    );
  }

  Future<_ExistingEntity> _nearestExistingEntity(String startPath) async {
    var candidate = path.normalize(startPath);
    while (true) {
      final type = await FileSystemEntity.type(
        candidate,
        followLinks: false,
      );
      if (type != FileSystemEntityType.notFound) {
        return _ExistingEntity(path: candidate, type: type);
      }

      final parent = path.dirname(candidate);
      if (path.equals(parent, candidate)) {
        throw FileSystemException(
          'No existing parent could be inspected.',
          startPath,
        );
      }
      candidate = parent;
    }
  }

  Future<String?> _findLinkedPathComponent(String startPath) async {
    var candidate = path.normalize(startPath);
    while (true) {
      final type = await FileSystemEntity.type(
        candidate,
        followLinks: false,
      );
      if (type == FileSystemEntityType.link) {
        return candidate;
      }

      final parent = path.dirname(candidate);
      if (path.equals(parent, candidate)) {
        return null;
      }
      candidate = parent;
    }
  }

  Future<String?> _findGitBoundary(Directory start) async {
    var candidate = path.normalize(start.absolute.path);
    while (true) {
      final gitPath = path.join(candidate, '.git');
      final gitType = await FileSystemEntity.type(
        gitPath,
        followLinks: false,
      );
      if (gitType != FileSystemEntityType.notFound) {
        return gitPath;
      }

      final parent = path.dirname(candidate);
      if (path.equals(parent, candidate)) {
        return null;
      }
      candidate = parent;
    }
  }

  BootstrapPreflightStopped _unsafeSymlink(String linkedPath) {
    return _stopped([
      BootstrapStopReason(
        category: BootstrapStopCategory.unsafeOutputPath,
        fieldOrFact: linkedPath,
        description:
            'A symbolic link in the target path prevents a reliable Repository boundary decision.',
      ),
    ]);
  }

  BootstrapPreflightStopped _repositoryBoundaryConflict(
    String gitMetadataPath,
  ) {
    return _stopped([
      BootstrapStopReason(
        category: BootstrapStopCategory.repositoryBoundaryConflict,
        fieldOrFact: gitMetadataPath,
        description: 'The target is inside another existing Git Repository.',
      ),
    ]);
  }

  BootstrapPreflightStopped _stopped(
    List<BootstrapStopReason> reasons,
  ) {
    return BootstrapPreflightStopped(
      reasons: reasons,
      notPerformed: _notPerformed,
    );
  }

  void _requireText(
    String? value, {
    required String field,
    required List<BootstrapStopReason> reasons,
  }) {
    if (!_hasText(value)) {
      reasons.add(
        BootstrapStopReason(
          category: BootstrapStopCategory.missingInput,
          fieldOrFact: field,
          description: '$field is required and cannot be blank.',
        ),
      );
    }
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  bool _isValidFlutterProjectName(String value) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value) &&
        !_dartReservedWords.contains(value);
  }

  bool _isValidOrganizationIdentifier(String value) {
    final segments = value.split('.');
    return segments.length >= 2 &&
        segments.every(
          (segment) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(segment),
        );
  }

  bool _isSafeBranchName(String value) {
    if (value.trim() != value ||
        value.contains(RegExp(r'\s')) ||
        value.contains('..') ||
        value.contains('//') ||
        value.contains('@{') ||
        value.contains('\\') ||
        value.startsWith('-') ||
        value.startsWith('/') ||
        value.endsWith('/') ||
        value.endsWith('.')) {
      return false;
    }

    return RegExp(r'^[A-Za-z0-9][A-Za-z0-9._/-]*$').hasMatch(value);
  }

  bool _equalsOrIsWithin(String parent, String child) {
    return path.equals(parent, child) || path.isWithin(parent, child);
  }
}

final class _InputValidation {
  const _InputValidation({
    required this.reasons,
    this.validatedRequest,
  });

  final List<BootstrapStopReason> reasons;
  final ValidatedBootstrapRequest? validatedRequest;
}

final class _ExistingEntity {
  const _ExistingEntity({
    required this.path,
    required this.type,
  });

  final String path;
  final FileSystemEntityType type;
}
