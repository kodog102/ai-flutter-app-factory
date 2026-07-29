import 'dart:io';

import '../generator/project_generator.dart';
import '../template/template_locator.dart';
import 'factory_manifest.dart';
import 'factory_manifest_repository.dart';

final class Factory {
  Factory({
    required FactoryManifestRepository manifestRepository,
    required TemplateLocator templateLocator,
    required ProjectGenerator projectGenerator,
  })  : _manifestRepository = manifestRepository,
        _templateLocator = templateLocator,
        _projectGenerator = projectGenerator;

  final FactoryManifestRepository _manifestRepository;
  final TemplateLocator _templateLocator;
  final ProjectGenerator _projectGenerator;

  late FactoryManifest _manifest;

  FactoryManifest get manifest => _manifest;

  Future<void> initialize() async {
    _manifest = await _manifestRepository.load();
  }

  Future<Directory> generate({
    required Directory output,
  }) async {
    final template = await _templateLocator.locate(_manifest.template);

    return _projectGenerator.generate(
      template: template,
      output: output,
    );
  }
}
