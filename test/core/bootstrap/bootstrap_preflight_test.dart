import 'dart:io';

import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_preflight_result.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_request.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/bootstrap_stop_reason.dart';
import 'package:ai_flutter_app_factory/core/bootstrap/repository_mode.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory fixtureRoot;
  late Directory factoryRoot;
  late FileSystemBootstrapPreflight preflight;

  setUp(() async {
    final created = await Directory.systemTemp.createTemp(
      'factory_bootstrap_preflight_',
    );
    fixtureRoot = Directory(await created.resolveSymbolicLinks());
    factoryRoot = await Directory(
      path.join(fixtureRoot.path, 'factory'),
    ).create();
    preflight = FileSystemBootstrapPreflight(factoryRoot: factoryRoot);
  });

  tearDown(() async {
    if (await fixtureRoot.exists()) {
      await fixtureRoot.delete(recursive: true);
    }
  });

  group('valid requests', () {
    test('approves a valid New Repository request', () async {
      final output = path.join(fixtureRoot.path, 'new_product');

      final result = await preflight.inspect(_request(outputPath: output));

      final ready = _expectReady(result);
      expect(
        ready.validatedRequest.repositoryMode,
        RepositoryMode.newRepository,
      );
      expect(ready.validatedRequest.initialBranchName, 'main');
      expect(ready.validatedRequest.repositoryPolicy, isNull);
      expect(ready.normalizedOutputPath, path.normalize(output));
      expect(ready.inspection.targetExists, isFalse);
      expect(ready.inspection.hasIndependentGitDirectory, isFalse);
      expect(await Directory(output).exists(), isFalse);
    });

    test('approves a valid Existing Empty Repository request', () async {
      final output = await _createExistingEmptyRepository(
        fixtureRoot,
        'existing_product',
      );

      final result = await preflight.inspect(
        _request(
          outputPath: output.path,
          repositoryMode: 'existingEmptyRepository',
          initialBranchName: null,
          repositoryPolicy: 'preserve existing Repository policy',
        ),
      );

      final ready = _expectReady(result);
      expect(
        ready.validatedRequest.repositoryMode,
        RepositoryMode.existingEmptyRepository,
      );
      expect(ready.validatedRequest.initialBranchName, isNull);
      expect(
        ready.validatedRequest.repositoryPolicy,
        'preserve existing Repository policy',
      );
      expect(ready.inspection.targetExists, isTrue);
      expect(ready.inspection.hasIndependentGitDirectory, isTrue);
      expect(ready.inspection.targetEntries, ['.git']);
    });

    test('accepts the canonical platforms in either order', () async {
      final first = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'first'),
          targetPlatforms: const ['ios', 'android'],
        ),
      );
      final second = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'second'),
          targetPlatforms: const ['android', 'ios'],
        ),
      );

      expect(first, isA<BootstrapPreflightReady>());
      expect(second, isA<BootstrapPreflightReady>());
    });

    test('does not make Product domain a validation decision', () async {
      final commerce = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'commerce'),
          purpose: 'Track commerce orders.',
          scope: 'Prepare order tracking authority.',
        ),
      );
      final health = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'health'),
          purpose: 'Record wellness notes.',
          scope: 'Prepare wellness note authority.',
        ),
      );

      expect(commerce, isA<BootstrapPreflightReady>());
      expect(health, isA<BootstrapPreflightReady>());
    });
  });

  group('missing and ambiguous inputs', () {
    test('reports each missing required text input', () async {
      final output = path.join(fixtureRoot.path, 'product');
      final requests = <String, BootstrapRequest>{
        'productDisplayName': _request(
          outputPath: output,
          productDisplayName: null,
        ),
        'productPurpose': _request(outputPath: output, purpose: null),
        'initialProductScopeOrFirstIntendedOutcome': _request(
          outputPath: output,
          scope: null,
        ),
        'exactOutputPath': _request(outputPath: null),
        'repositoryMode': _request(
          outputPath: output,
          repositoryMode: null,
        ),
        'flutterProjectName': _request(
          outputPath: output,
          flutterProjectName: null,
        ),
        'organizationIdentifier': _request(
          outputPath: output,
          organizationIdentifier: null,
        ),
        'requestedTechnology': _request(
          outputPath: output,
          requestedTechnology: null,
        ),
        'targetPlatforms': _request(
          outputPath: output,
          targetPlatforms: null,
        ),
      };

      for (final entry in requests.entries) {
        final stopped = _expectStopped(await preflight.inspect(entry.value));
        expect(
          stopped.reasons,
          contains(
            isA<BootstrapStopReason>()
                .having(
                  (reason) => reason.category,
                  'category',
                  BootstrapStopCategory.missingInput,
                )
                .having(
                  (reason) => reason.fieldOrFact,
                  'field',
                  entry.key,
                ),
          ),
          reason: entry.key,
        );
      }
    });

    test('reports whitespace-only required values', () async {
      final output = path.join(fixtureRoot.path, 'product');
      final requests = [
        _request(outputPath: output, productDisplayName: '   '),
        _request(outputPath: output, purpose: '\t'),
        _request(outputPath: output, scope: '\n'),
        _request(outputPath: '   '),
        _request(outputPath: output, flutterProjectName: ' '),
        _request(outputPath: output, organizationIdentifier: '\t'),
        _request(outputPath: output, requestedTechnology: '\n'),
      ];

      for (final request in requests) {
        expect(
          _categories(await preflight.inspect(request)),
          contains(BootstrapStopCategory.missingInput),
        );
      }
    });

    test('stops when branch and Repository policy are both absent', () async {
      final result = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'product'),
          initialBranchName: null,
          repositoryPolicy: null,
        ),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.missingInput),
      );
    });

    test('stops when branch and Repository policy are both present', () async {
      final result = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'product'),
          initialBranchName: 'main',
          repositoryPolicy: 'preserve policy',
        ),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.ambiguousInput),
      );
    });

    test('requires a branch in New Repository mode', () async {
      final result = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'product'),
          initialBranchName: null,
          repositoryPolicy: 'use policy',
        ),
      );

      expect(
        _categories(result),
        contains(
          BootstrapStopCategory.invalidBranchOrRepositoryPolicy,
        ),
      );
    });

    test('stops unsafe branch names without implementing Git refs', () async {
      for (final branch in ['feature branch', '../main', 'main/', '-main']) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(fixtureRoot.path, 'product_$branch'),
            initialBranchName: branch,
          ),
        );

        expect(
          _categories(result),
          contains(
            BootstrapStopCategory.invalidBranchOrRepositoryPolicy,
          ),
          reason: branch,
        );
      }
    });

    test('stops an invalid Repository mode without normalizing it', () async {
      for (final mode in [
        'NewRepository',
        'new_repository',
        ' newRepository'
      ]) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(fixtureRoot.path, 'product'),
            repositoryMode: mode,
          ),
        );

        expect(
          _categories(result),
          contains(BootstrapStopCategory.invalidRepositoryMode),
          reason: mode,
        );
      }
    });
  });

  group('technology and platforms', () {
    test('supports only the exact flutter technology value', () async {
      for (final technology in [
        'Flutter',
        'dart',
        'react_native',
        ' flutter'
      ]) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(fixtureRoot.path, 'product'),
            requestedTechnology: technology,
          ),
        );

        expect(
          _categories(result),
          contains(BootstrapStopCategory.unsupportedTechnology),
          reason: technology,
        );
      }
    });

    test('stops non-canonical platform sets', () async {
      final platformSets = <List<String>>[
        const ['ios'],
        const ['android'],
        const ['ios', 'android', 'web'],
        const ['ios', 'android', 'macos'],
        const ['ios', 'android', 'windows'],
        const ['ios', 'ios', 'android'],
      ];

      for (final platforms in platformSets) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(fixtureRoot.path, 'product'),
            targetPlatforms: platforms,
          ),
        );

        expect(
          _categories(result),
          contains(BootstrapStopCategory.unsupportedTargetPlatforms),
          reason: platforms.toString(),
        );
      }
    });

    test('stops an empty platform list as missing input', () async {
      final result = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'product'),
          targetPlatforms: const [],
        ),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.missingInput),
      );
    });
  });

  group('Flutter project identifier', () {
    test('accepts conservative lowercase identifiers', () async {
      for (final identifier in [
        'subscription_tracker',
        'app2',
        'my_product',
      ]) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(fixtureRoot.path, identifier),
            flutterProjectName: identifier,
          ),
        );

        expect(result, isA<BootstrapPreflightReady>(), reason: identifier);
      }
    });

    test('stops invalid identifiers and Dart reserved words', () async {
      for (final identifier in [
        'SubscriptionTracker',
        '2app',
        'my-app',
        'my.app',
        'my app',
        'class',
        'factory',
      ]) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(fixtureRoot.path, 'product'),
            flutterProjectName: identifier,
          ),
        );

        expect(
          _categories(result),
          contains(BootstrapStopCategory.invalidFlutterProjectName),
          reason: identifier,
        );
      }
    });
  });

  group('organization identifier', () {
    test('accepts lowercase reverse-domain identifiers', () async {
      for (final identifier in [
        'com.example',
        'com.example.factory',
        'io.company2',
      ]) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(
              fixtureRoot.path,
              identifier.replaceAll('.', '_'),
            ),
            organizationIdentifier: identifier,
          ),
        );

        expect(result, isA<BootstrapPreflightReady>(), reason: identifier);
      }
    });

    test('stops invalid reverse-domain identifiers', () async {
      for (final identifier in [
        'example',
        'Com.Example',
        'com..example',
        '2com.example',
        'com.2example',
        'com/example',
        'com example',
      ]) {
        final result = await preflight.inspect(
          _request(
            outputPath: path.join(fixtureRoot.path, 'product'),
            organizationIdentifier: identifier,
          ),
        );

        expect(
          _categories(result),
          contains(BootstrapStopCategory.invalidOrganizationIdentifier),
          reason: identifier,
        );
      }
    });
  });

  group('New Repository safety', () {
    test('stops a relative output path', () async {
      final result = await preflight.inspect(
        _request(outputPath: 'relative/product'),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.unsafeOutputPath),
      );
    });

    test('stops the filesystem root as an overly broad target', () async {
      final result = await preflight.inspect(
        _request(outputPath: path.rootPrefix(fixtureRoot.path)),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.unsafeOutputPath),
      );
    });

    test('stops when target already exists', () async {
      final output = await Directory(
        path.join(fixtureRoot.path, 'existing'),
      ).create();

      final result = await preflight.inspect(
        _request(outputPath: output.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.outputAlreadyExists),
      );
    });

    test('stops when target is the Factory root', () async {
      final result = await preflight.inspect(
        _request(outputPath: factoryRoot.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.factoryBoundaryConflict),
      );
    });

    test('stops when target is inside the Factory root', () async {
      final result = await preflight.inspect(
        _request(outputPath: path.join(factoryRoot.path, 'product')),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.factoryBoundaryConflict),
      );
    });

    test('does not confuse a Factory prefix sibling with a child', () async {
      final result = await preflight.inspect(
        _request(outputPath: '${factoryRoot.path}-other'),
      );

      expect(result, isA<BootstrapPreflightReady>());
    });

    test('stops when the nearest existing parent is a file', () async {
      final parentFile = File(path.join(fixtureRoot.path, 'parent_file'));
      await parentFile.writeAsString('user data');
      final output = path.join(parentFile.path, 'product');

      final result = await preflight.inspect(
        _request(outputPath: output),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.targetIsNotDirectory),
      );
    });

    test('stops when target would be inside another Git Repository', () async {
      final otherRepository = await Directory(
        path.join(fixtureRoot.path, 'other_repository'),
      ).create();
      await Directory(path.join(otherRepository.path, '.git')).create();
      final output = path.join(otherRepository.path, 'nested', 'product');

      final result = await preflight.inspect(
        _request(outputPath: output),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.repositoryBoundaryConflict),
      );
    });

    test('stops when a target path component is a symbolic link', () async {
      final realParent = await Directory(
        path.join(fixtureRoot.path, 'real_parent'),
      ).create();
      final linkedParent = Link(path.join(fixtureRoot.path, 'linked_parent'));
      await linkedParent.create(realParent.path);
      final output = path.join(linkedParent.path, 'product');

      final result = await preflight.inspect(
        _request(outputPath: output),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.unsafeOutputPath),
      );
    });

    test('does not create the inspected New Repository target', () async {
      final output = path.join(fixtureRoot.path, 'not_created');
      final before = _snapshot(fixtureRoot);

      final result = await preflight.inspect(
        _request(outputPath: output),
      );

      expect(result, isA<BootstrapPreflightReady>());
      expect(
          await FileSystemEntity.type(output), FileSystemEntityType.notFound);
      expect(_snapshot(fixtureRoot), before);
    });
  });

  group('Existing Empty Repository safety', () {
    test('stops when target does not exist', () async {
      final result = await preflight.inspect(
        _request(
          outputPath: path.join(fixtureRoot.path, 'missing'),
          repositoryMode: 'existingEmptyRepository',
          initialBranchName: null,
          repositoryPolicy: 'preserve policy',
        ),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.outputDoesNotExist),
      );
    });

    test('stops when target is a file', () async {
      final target = File(path.join(fixtureRoot.path, 'product'));
      await target.writeAsString('user data');

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.targetIsNotDirectory),
      );
    });

    test('stops when independent .git directory is absent', () async {
      final target = await Directory(
        path.join(fixtureRoot.path, 'product'),
      ).create();

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.existingRepositoryRequired),
      );
    });

    test('stops linked Git metadata represented by a .git file', () async {
      final target = await Directory(
        path.join(fixtureRoot.path, 'product'),
      ).create();
      await File(
        path.join(target.path, '.git'),
      ).writeAsString('gitdir: ../metadata');

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.linkedGitMetadataUnsupported),
      );
    });

    test('stops an empty fake .git directory', () async {
      final target = await Directory(
        path.join(fixtureRoot.path, 'product'),
      ).create();
      await Directory(path.join(target.path, '.git')).create();

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.existingRepositoryRequired),
      );
    });

    test('stops incomplete Git metadata with only HEAD', () async {
      final target = await Directory(
        path.join(fixtureRoot.path, 'product'),
      ).create();
      final gitDirectory = await Directory(
        path.join(target.path, '.git'),
      ).create();
      await File(
        path.join(gitDirectory.path, 'HEAD'),
      ).writeAsString('ref: refs/heads/main\n');

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.existingRepositoryRequired),
      );
    });

    test('stops Git metadata represented by a symbolic link', () async {
      final target = await Directory(
        path.join(fixtureRoot.path, 'product'),
      ).create();
      final metadata = await Directory(
        path.join(fixtureRoot.path, 'metadata'),
      ).create();
      try {
        await Link(path.join(target.path, '.git')).create(metadata.path);
      } on FileSystemException catch (error) {
        markTestSkipped('Symbolic links are unavailable: ${error.message}');
        return;
      }

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.linkedGitMetadataUnsupported),
      );
    });

    test('stops worktree-style linked Git metadata', () async {
      final target = await Directory(
        path.join(fixtureRoot.path, 'product'),
      ).create();
      await File(
        path.join(target.path, '.git'),
      ).writeAsString('gitdir: ../main/.git/worktrees/product\n');

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.linkedGitMetadataUnsupported),
      );
    });

    test('stops submodule-style linked Git metadata', () async {
      final target = await Directory(
        path.join(fixtureRoot.path, 'product'),
      ).create();
      await File(
        path.join(target.path, '.git'),
      ).writeAsString('gitdir: ../parent/.git/modules/product\n');

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.linkedGitMetadataUnsupported),
      );
    });

    test('stops when an unexpected file exists', () async {
      final target = await _createExistingEmptyRepository(
        fixtureRoot,
        'product',
      );
      await File(path.join(target.path, 'README.md')).writeAsString('data');

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.existingRepositoryNotEmpty),
      );
    });

    test('stops when an unexpected directory exists', () async {
      final target = await _createExistingEmptyRepository(
        fixtureRoot,
        'product',
      );
      await Directory(path.join(target.path, 'lib')).create();

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.existingRepositoryNotEmpty),
      );
    });

    test('stops an existing target nested in another Repository', () async {
      final outer = await Directory(
        path.join(fixtureRoot.path, 'outer'),
      ).create();
      await Directory(path.join(outer.path, '.git')).create();
      final target = await Directory(
        path.join(outer.path, 'product'),
      ).create();
      await Directory(path.join(target.path, '.git')).create();

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.repositoryBoundaryConflict),
      );
    });

    test('stops when Git reports a different top-level path', () async {
      final target = await _createExistingEmptyRepository(
        fixtureRoot,
        'product',
      );
      final conflictingPreflight = FileSystemBootstrapPreflight(
        factoryRoot: factoryRoot,
        gitInspector: _FixedGitRepositoryInspector(
          GitRepositoryInspection(
            status: GitRepositoryInspectionStatus.valid,
            topLevelPath: fixtureRoot.path,
          ),
        ),
      );

      final result = await conflictingPreflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.repositoryBoundaryConflict),
      );
    });

    test('stops with a structured result when Git cannot start', () async {
      final target = await _createExistingEmptyRepository(
        fixtureRoot,
        'product',
      );
      final unavailableGitPreflight = FileSystemBootstrapPreflight(
        factoryRoot: factoryRoot,
        gitInspector: const ProcessGitRepositoryInspector(
          executable: 'factory-test-git-executable-does-not-exist',
        ),
      );

      final result = await unavailableGitPreflight.inspect(
        _existingRequest(target.path),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.gitInspectionFailed),
      );
    });

    test('accepts an actual independent empty Git Repository', () async {
      final target = await _createExistingEmptyRepository(
        fixtureRoot,
        'product',
      );

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      final ready = _expectReady(result);
      expect(ready.normalizedOutputPath, path.normalize(target.path));
      expect(ready.inspection.hasIndependentGitDirectory, isTrue);
      expect(ready.inspection.targetEntries, ['.git']);
    });

    test('does not change Git status or Repository filesystem', () async {
      final target = await _createExistingEmptyRepository(
        fixtureRoot,
        'product',
      );
      final statusBefore = await _gitStatus(target);
      final before = _snapshot(target);

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(result, isA<BootstrapPreflightReady>());
      expect(await _gitStatus(target), statusBefore);
      expect(_snapshot(target), before);
    });

    test('accepts an independent Repository sibling', () async {
      final target = await _createExistingEmptyRepository(
        fixtureRoot,
        'product',
      );
      await _createExistingEmptyRepository(
        fixtureRoot,
        'sibling',
      );

      final result = await preflight.inspect(
        _existingRequest(target.path),
      );

      expect(result, isA<BootstrapPreflightReady>());
    });
  });

  group('structured results', () {
    test('aggregates independent pure input errors', () async {
      final result = await preflight.inspect(
        _request(
          outputPath: 'relative/path',
          productDisplayName: ' ',
          repositoryMode: 'unknown',
          initialBranchName: 'bad branch',
          flutterProjectName: 'Bad-Name',
          organizationIdentifier: 'Example',
          requestedTechnology: 'Flutter',
          targetPlatforms: const ['web'],
        ),
      );

      final categories = _categories(result);
      expect(categories, contains(BootstrapStopCategory.missingInput));
      expect(categories, contains(BootstrapStopCategory.invalidRepositoryMode));
      expect(
        categories,
        contains(BootstrapStopCategory.invalidBranchOrRepositoryPolicy),
      );
      expect(
        categories,
        contains(BootstrapStopCategory.invalidFlutterProjectName),
      );
      expect(
        categories,
        contains(BootstrapStopCategory.invalidOrganizationIdentifier),
      );
      expect(
        categories,
        contains(BootstrapStopCategory.unsupportedTechnology),
      );
      expect(
        categories,
        contains(BootstrapStopCategory.unsupportedTargetPlatforms),
      );
      expect(categories, contains(BootstrapStopCategory.unsafeOutputPath));
    });

    test('uses stable enum-backed stop categories', () {
      expect(BootstrapStopCategory.missingInput.name, 'missingInput');
      expect(
        BootstrapStopCategory.filesystemInspectionFailed.name,
        'filesystemInspectionFailed',
      );
      expect(
        BootstrapStopCategory.gitInspectionFailed.name,
        'gitInspectionFailed',
      );
      expect(
        BootstrapStopCategory.values.map((category) => category.name).toSet(),
        hasLength(BootstrapStopCategory.values.length),
      );
    });

    test('includes user-facing context and work not performed', () async {
      final result = await preflight.inspect(
        _request(outputPath: 'relative/path'),
      );

      final stopped = _expectStopped(result);
      expect(stopped.reasons, isNotEmpty);
      expect(
        stopped.reasons.every(
          (reason) =>
              reason.fieldOrFact.isNotEmpty && reason.description.isNotEmpty,
        ),
        isTrue,
      );
      expect(stopped.notPerformed, isNotEmpty);
      expect(
        stopped.notPerformed.join(' '),
        contains('No target path'),
      );
      expect(stopped.notPerformed.join(' '), contains('No Git metadata'));
    });

    test('success contains validated values and inspection summary', () async {
      final output = path.join(fixtureRoot.path, 'product');
      final result = await preflight.inspect(
        _request(outputPath: '$output${path.separator}.'),
      );

      final ready = _expectReady(result);
      expect(
        ready.validatedRequest.exactOutputPath,
        '$output${path.separator}.',
      );
      expect(ready.normalizedOutputPath, output);
      expect(ready.confirmedRepositoryMode, RepositoryMode.newRepository);
      expect(ready.confirmedTechnology, 'flutter');
      expect(ready.confirmedTargetPlatforms, ['ios', 'android']);
      expect(ready.inspection.inspectedPath, '$output${path.separator}.');
      expect(ready.inspection.normalizedPath, output);
      expect(ready.inspection.nearestExistingParent, fixtureRoot.path);
    });

    test('returns a filesystem stop when Factory root cannot be inspected',
        () async {
      final missingFactory = Directory(
        path.join(fixtureRoot.path, 'missing_factory'),
      );
      final invalidPreflight = FileSystemBootstrapPreflight(
        factoryRoot: missingFactory,
      );

      final result = await invalidPreflight.inspect(
        _request(outputPath: path.join(fixtureRoot.path, 'product')),
      );

      expect(
        _categories(result),
        contains(BootstrapStopCategory.filesystemInspectionFailed),
      );
    });

    test('exposes immutable request and result collections', () async {
      final platforms = <String>['ios', 'android'];
      final request = _request(
        outputPath: path.join(fixtureRoot.path, 'product'),
        targetPlatforms: platforms,
      );
      platforms.add('web');

      expect(request.targetPlatforms, ['ios', 'android']);
      expect(
        () => request.targetPlatforms!.add('web'),
        throwsUnsupportedError,
      );

      final ready = _expectReady(await preflight.inspect(request));
      expect(
        () => ready.validatedRequest.targetPlatforms.add('web'),
        throwsUnsupportedError,
      );
      expect(
        () => ready.inspection.targetEntries.add('README.md'),
        throwsUnsupportedError,
      );
    });
  });
}

BootstrapRequest _request({
  required String? outputPath,
  String? productDisplayName = 'Factory Validation App',
  String? purpose = 'Validate Factory Bootstrap.',
  String? scope = 'Prepare a Product Repository.',
  String? repositoryMode = 'newRepository',
  String? initialBranchName = 'main',
  String? repositoryPolicy,
  String? flutterProjectName = 'factory_validation_app',
  String? organizationIdentifier = 'com.example',
  String? requestedTechnology = 'flutter',
  List<String>? targetPlatforms = const ['ios', 'android'],
}) {
  return BootstrapRequest(
    productDisplayName: productDisplayName,
    productPurpose: purpose,
    initialProductScopeOrFirstIntendedOutcome: scope,
    exactOutputPath: outputPath,
    repositoryMode: repositoryMode,
    initialBranchName: initialBranchName,
    repositoryPolicy: repositoryPolicy,
    flutterProjectName: flutterProjectName,
    organizationIdentifier: organizationIdentifier,
    requestedTechnology: requestedTechnology,
    targetPlatforms: targetPlatforms,
  );
}

BootstrapRequest _existingRequest(String outputPath) {
  return _request(
    outputPath: outputPath,
    repositoryMode: 'existingEmptyRepository',
    initialBranchName: null,
    repositoryPolicy: 'preserve policy',
  );
}

Future<Directory> _createExistingEmptyRepository(
  Directory fixtureRoot,
  String name,
) async {
  final target = await Directory(path.join(fixtureRoot.path, name)).create();
  final result = await Process.run(
    'git',
    ['init', '--quiet', '--initial-branch=main', target.path],
  );
  expect(
    result.exitCode,
    0,
    reason: 'git init failed: ${result.stderr}',
  );
  return target;
}

Future<String> _gitStatus(Directory repository) async {
  final result = await Process.run(
    'git',
    ['-C', repository.path, 'status', '--short', '--branch'],
  );
  expect(
    result.exitCode,
    0,
    reason: 'git status failed: ${result.stderr}',
  );
  return result.stdout.toString();
}

BootstrapPreflightReady _expectReady(BootstrapPreflightResult result) {
  expect(result, isA<BootstrapPreflightReady>());
  return result as BootstrapPreflightReady;
}

BootstrapPreflightStopped _expectStopped(BootstrapPreflightResult result) {
  expect(result, isA<BootstrapPreflightStopped>());
  return result as BootstrapPreflightStopped;
}

Set<BootstrapStopCategory> _categories(BootstrapPreflightResult result) {
  return _expectStopped(result)
      .reasons
      .map((reason) => reason.category)
      .toSet();
}

List<String> _snapshot(Directory directory) {
  final entries =
      directory.listSync(recursive: true, followLinks: false).map((entity) {
    final relativePath = path.relative(entity.path, from: directory.path);
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      return 'file:$relativePath:${File(entity.path).readAsStringSync()}';
    }
    return '$type:$relativePath';
  }).toList();
  entries.sort();
  return entries;
}

final class _FixedGitRepositoryInspector implements GitRepositoryInspector {
  const _FixedGitRepositoryInspector(this.result);

  final GitRepositoryInspection result;

  @override
  Future<GitRepositoryInspection> inspect(String targetPath) async => result;
}
