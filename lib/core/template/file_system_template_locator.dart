import 'dart:io';

import '../factory/factory_manifest.dart';
import 'template_locator.dart';

final class FileSystemTemplateLocator implements TemplateLocator {
  FileSystemTemplateLocator({
    Directory? repositoryRoot,
  }) : _repositoryRoot = repositoryRoot ?? Directory.current;

  final Directory _repositoryRoot;

  @override
  Future<Directory> locate(TemplateInfo template) async {
    final templateDirectory = Directory.fromUri(
      Uri.directory(_repositoryRoot.absolute.path).resolve(template.path),
    );

    if (!await templateDirectory.exists()) {
      throw FileSystemException(
        'Template directory not found.',
        templateDirectory.path,
      );
    }

    return templateDirectory.absolute;
  }
}
