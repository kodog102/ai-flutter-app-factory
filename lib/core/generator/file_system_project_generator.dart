import 'dart:io';

import 'project_generator.dart';

final class FileSystemProjectGenerator implements ProjectGenerator {
  @override
  Future<Directory> generate({
    required Directory template,
    required Directory output,
  }) async {
    final outputType = await FileSystemEntity.type(
      output.path,
      followLinks: false,
    );

    if (outputType != FileSystemEntityType.notFound) {
      throw FileSystemException(
        'Output path already exists.',
        output.path,
      );
    }

    await output.create(recursive: true);
    await _copyDirectory(
      source: template,
      destination: output,
    );

    return output.absolute;
  }

  Future<void> _copyDirectory({
    required Directory source,
    required Directory destination,
  }) async {
    await destination.create(recursive: true);

    await for (final entity in source.list(followLinks: false)) {
      final destinationPath = _resolveChildPath(
        parent: destination,
        name: _entityName(entity),
      );

      if (entity is Directory) {
        await _copyDirectory(
          source: entity,
          destination: Directory(destinationPath),
        );
      } else if (entity is File) {
        await entity.copy(destinationPath);
      }
    }
  }

  String _resolveChildPath({
    required Directory parent,
    required String name,
  }) {
    return Uri.directory(parent.absolute.path).resolve(name).toFilePath();
  }

  String _entityName(FileSystemEntity entity) {
    return entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
  }
}
