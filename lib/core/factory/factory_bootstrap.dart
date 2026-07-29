import '../generator/file_system_project_generator.dart';
import '../generator/project_generator.dart';
import '../template/file_system_template_locator.dart';
import '../template/template_locator.dart';
import 'factory.dart';
import 'factory_manifest_mapper.dart';
import 'factory_manifest_repository.dart';
import 'factory_manifest_repository_impl.dart';
import 'yaml_factory_manifest_data_source.dart';

final class FactoryBootstrap {
  Factory createFactory() {
    return Factory(
      manifestRepository: createManifestRepository(),
      templateLocator: createTemplateLocator(),
      projectGenerator: createProjectGenerator(),
    );
  }

  TemplateLocator createTemplateLocator() {
    return FileSystemTemplateLocator();
  }

  ProjectGenerator createProjectGenerator() {
    return FileSystemProjectGenerator();
  }

  FactoryManifestRepository createManifestRepository() {
    final dataSource = YamlFactoryManifestDataSource();
    final mapper = FactoryManifestMapper();

    return FactoryManifestRepositoryImpl(
      dataSource: dataSource,
      mapper: mapper,
    );
  }
}
