import '../common/mapper.dart';
import 'factory_manifest.dart';

final class FactoryManifestMapper
    implements Mapper<Map<String, dynamic>, FactoryManifest> {
  @override
  FactoryManifest map(Map<String, dynamic> input) {
    return FactoryManifest.fromMap(input);
  }
}
