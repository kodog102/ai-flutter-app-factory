import 'factory_manifest.dart';

abstract class FactoryManifestRepository {
  Future<FactoryManifest> load();
}
