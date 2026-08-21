import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'product_authority_audit_result.dart';
import 'product_authority_contract.dart';

final class ProductAuthorityAuditor {
  ProductAuthorityAuditor({required Directory factoryRoot})
      : _factoryRoot = factoryRoot.absolute;

  final Directory _factoryRoot;

  Future<ProductAuthorityAuditResult> audit(Directory productRoot) async {
    try {
      final factoryType = await FileSystemEntity.type(
        _factoryRoot.path,
        followLinks: false,
      );
      if (factoryType == FileSystemEntityType.notFound) {
        return _stopped(
          ProductAuthorityAuditStopCategory.factoryRootMissing,
          'factoryRoot',
          'Factory root가 존재하지 않는다.',
        );
      }
      if (factoryType == FileSystemEntityType.link) {
        return _stopped(
          ProductAuthorityAuditStopCategory.factoryRootSymlink,
          'factoryRoot',
          'Factory root symlink는 감사 경계로 사용할 수 없다.',
        );
      }
      if (factoryType != FileSystemEntityType.directory) {
        return _stopped(
          ProductAuthorityAuditStopCategory.factoryRootNotDirectory,
          'factoryRoot',
          'Factory root는 디렉터리여야 한다.',
        );
      }

      final resolvedFactoryInput = path.normalize(
        await _factoryRoot.resolveSymbolicLinks(),
      );
      final factoryGitMetadataType = await FileSystemEntity.type(
        path.join(resolvedFactoryInput, '.git'),
        followLinks: false,
      );
      if (factoryGitMetadataType != FileSystemEntityType.directory) {
        return _stopped(
          ProductAuthorityAuditStopCategory.factoryGitMetadataUnsupported,
          'factoryRoot/.git',
          'Factory root에는 독립 Git directory metadata가 필요하다.',
        );
      }
      final factoryTopLevelResult = await Process.run(
        'git',
        ['rev-parse', '--show-toplevel'],
        workingDirectory: resolvedFactoryInput,
        runInShell: false,
      );
      if (factoryTopLevelResult.exitCode != 0) {
        return _stopped(
          ProductAuthorityAuditStopCategory.factoryGitInspectionFailed,
          'factoryGitTopLevel',
          _nonEmptyOr(
            factoryTopLevelResult.stderr.toString(),
            'Factory Git top-level을 확인할 수 없다.',
          ),
        );
      }
      final reportedFactoryTopLevel =
          factoryTopLevelResult.stdout.toString().trim();
      if (reportedFactoryTopLevel.isEmpty) {
        return _stopped(
          ProductAuthorityAuditStopCategory.factoryGitInspectionFailed,
          'factoryGitTopLevel',
          'Factory Git top-level 결과가 비어 있다.',
        );
      }
      final resolvedFactory = path.normalize(
        await Directory(reportedFactoryTopLevel).resolveSymbolicLinks(),
      );
      if (resolvedFactory != resolvedFactoryInput) {
        return _stopped(
          ProductAuthorityAuditStopCategory.factoryGitTopLevelMismatch,
          'factoryGitTopLevel',
          'Factory root가 Git top-level과 일치하지 않는다.',
        );
      }

      final productType = await FileSystemEntity.type(
        productRoot.absolute.path,
        followLinks: false,
      );
      if (productType == FileSystemEntityType.notFound) {
        return _stopped(
          ProductAuthorityAuditStopCategory.productRootMissing,
          'productRoot',
          'Product root가 존재하지 않는다.',
        );
      }
      if (productType == FileSystemEntityType.link) {
        return _stopped(
          ProductAuthorityAuditStopCategory.productRootSymlink,
          'productRoot',
          'Product root symlink는 감사할 수 없다.',
        );
      }
      if (productType != FileSystemEntityType.directory) {
        return _stopped(
          ProductAuthorityAuditStopCategory.productRootNotDirectory,
          'productRoot',
          'Product root는 디렉터리여야 한다.',
        );
      }

      final resolvedProduct = path.normalize(
        await productRoot.absolute.resolveSymbolicLinks(),
      );
      if (resolvedFactory == resolvedProduct ||
          path.isWithin(resolvedFactory, resolvedProduct) ||
          path.isWithin(resolvedProduct, resolvedFactory)) {
        return _stopped(
          ProductAuthorityAuditStopCategory.repositoryBoundaryConflict,
          'repositoryBoundary',
          'Factory와 Product Repository 경계를 분리할 수 없다.',
        );
      }

      final gitMetadataPath = path.join(resolvedProduct, '.git');
      final gitMetadataType = await FileSystemEntity.type(
        gitMetadataPath,
        followLinks: false,
      );
      if (gitMetadataType != FileSystemEntityType.directory) {
        return _stopped(
          ProductAuthorityAuditStopCategory.gitMetadataUnsupported,
          '.git',
          '독립 Git directory metadata가 필요하다.',
        );
      }

      final gitTopLevelResult = await Process.run(
        'git',
        ['rev-parse', '--show-toplevel'],
        workingDirectory: resolvedProduct,
        runInShell: false,
      );
      if (gitTopLevelResult.exitCode != 0) {
        return _stopped(
          ProductAuthorityAuditStopCategory.gitInspectionFailed,
          'gitTopLevel',
          _nonEmptyOr(
            gitTopLevelResult.stderr.toString(),
            'Git top-level을 확인할 수 없다.',
          ),
        );
      }
      final reportedTopLevel = gitTopLevelResult.stdout.toString().trim();
      if (reportedTopLevel.isEmpty) {
        return _stopped(
          ProductAuthorityAuditStopCategory.gitInspectionFailed,
          'gitTopLevel',
          'Git top-level 결과가 비어 있다.',
        );
      }
      final resolvedTopLevel = path.normalize(
        await Directory(reportedTopLevel).resolveSymbolicLinks(),
      );
      if (resolvedTopLevel != resolvedProduct) {
        return _stopped(
          ProductAuthorityAuditStopCategory.gitTopLevelMismatch,
          'gitTopLevel',
          'Product root가 Git top-level과 일치하지 않는다.',
        );
      }

      final agentsPath = path.join(resolvedProduct, 'AGENTS.md');
      final agentsType = await FileSystemEntity.type(
        agentsPath,
        followLinks: false,
      );
      if (agentsType == FileSystemEntityType.notFound) {
        return _stopped(
          ProductAuthorityAuditStopCategory.agentsMissing,
          'AGENTS.md',
          'Product AGENTS.md가 존재하지 않는다.',
        );
      }
      if (agentsType != FileSystemEntityType.file) {
        return _stopped(
          ProductAuthorityAuditStopCategory.agentsNotRegularFile,
          'AGENTS.md',
          'Product AGENTS.md는 regular file이어야 한다.',
        );
      }

      final agentsFile = File(agentsPath);
      final before = await agentsFile.stat();
      if (before.size > ProductAuthorityContract.maximumDocumentBytes) {
        return _stopped(
          ProductAuthorityAuditStopCategory.agentsTooLarge,
          'AGENTS.md',
          'Product AGENTS.md가 허용된 크기를 초과한다.',
        );
      }

      late final String authority;
      try {
        authority = utf8.decode(
          await agentsFile.readAsBytes(),
          allowMalformed: false,
        );
      } on FormatException catch (error) {
        return _stopped(
          ProductAuthorityAuditStopCategory.agentsReadFailed,
          'AGENTS.md',
          error.message,
        );
      }
      final afterType = await FileSystemEntity.type(
        agentsPath,
        followLinks: false,
      );
      final after = await agentsFile.stat();
      if (afterType != FileSystemEntityType.file ||
          before.size != after.size ||
          before.modified != after.modified ||
          before.mode != after.mode) {
        return _stopped(
          ProductAuthorityAuditStopCategory.agentsChangedDuringAudit,
          'AGENTS.md',
          'Product AGENTS.md가 감사 중 변경되었다.',
        );
      }

      return _report(
        productRoot: resolvedProduct,
        gitTopLevel: resolvedTopLevel,
        authority: authority,
      );
    } on FileSystemException catch (error) {
      return _stopped(
        ProductAuthorityAuditStopCategory.agentsReadFailed,
        'filesystem',
        error.message,
      );
    } on ProcessException catch (error) {
      return _stopped(
        ProductAuthorityAuditStopCategory.gitInspectionFailed,
        'git',
        error.message,
      );
    }
  }

  ProductAuthorityAuditReport _report({
    required String productRoot,
    required String gitTopLevel,
    required String authority,
  }) {
    final versionMatches = RegExp(
      '^${RegExp.escape(ProductAuthorityContract.versionLabel)}: ([^\\s]+)\\s*\$',
      multiLine: true,
    ).allMatches(authority).toList(growable: false);
    final detectedVersions =
        versionMatches.map((match) => match.group(1)!).toList(growable: false);
    final detectedVersion =
        detectedVersions.length == 1 ? detectedVersions.single : null;
    final requirements = <ProductAuthorityRequirementStatus>[];
    final drifts = <ProductAuthorityDrift>[];

    final versionSatisfied = detectedVersions.length == 1 &&
        detectedVersion == ProductAuthorityContract.currentVersion;
    requirements.add(
      ProductAuthorityRequirementStatus(
        requirement: ProductAuthorityContract.versionLine,
        satisfied: versionSatisfied,
      ),
    );
    if (detectedVersions.isEmpty) {
      drifts.add(
        const ProductAuthorityDrift(
          category: ProductAuthorityDriftCategory.missingContractVersion,
          requirement: ProductAuthorityContract.versionLine,
        ),
      );
    } else if (detectedVersions.length > 1) {
      drifts.add(
        ProductAuthorityDrift(
          category: ProductAuthorityDriftCategory.ambiguousContractVersion,
          requirement: detectedVersions.join(', '),
        ),
      );
    } else if (!versionSatisfied) {
      drifts.add(
        ProductAuthorityDrift(
          category: ProductAuthorityDriftCategory.unsupportedContractVersion,
          requirement: detectedVersions.single,
        ),
      );
    }

    for (final section in ProductAuthorityContract.requiredSections) {
      final satisfied = RegExp(
        '^${RegExp.escape(section)}\\s*\$',
        multiLine: true,
      ).hasMatch(authority);
      requirements.add(
        ProductAuthorityRequirementStatus(
          requirement: section,
          satisfied: satisfied,
        ),
      );
      if (!satisfied) {
        drifts.add(
          ProductAuthorityDrift(
            category: ProductAuthorityDriftCategory.missingRequiredSection,
            requirement: section,
          ),
        );
      }
    }

    for (final marker in ProductAuthorityContract.requiredMarkers) {
      final satisfied = authority.contains(marker);
      requirements.add(
        ProductAuthorityRequirementStatus(
          requirement: marker,
          satisfied: satisfied,
        ),
      );
      if (!satisfied) {
        drifts.add(
          ProductAuthorityDrift(
            category: ProductAuthorityDriftCategory.missingRequiredMarker,
            requirement: marker,
          ),
        );
      }
    }

    return ProductAuthorityAuditReport(
      productRoot: productRoot,
      gitTopLevel: gitTopLevel,
      expectedContractVersion: ProductAuthorityContract.currentVersion,
      detectedContractVersion: detectedVersion,
      requirements: requirements,
      drifts: drifts,
    );
  }

  ProductAuthorityAuditStopped _stopped(
    ProductAuthorityAuditStopCategory category,
    String fieldOrFact,
    String description,
  ) {
    return ProductAuthorityAuditStopped(
      category: category,
      fieldOrFact: fieldOrFact,
      description: description,
      notPerformed: const [
        'Product 권한 계약 판정',
        'Product 권한 drift 보고',
      ],
    );
  }

  String _nonEmptyOr(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
