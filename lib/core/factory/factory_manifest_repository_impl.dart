import '../common/mapper.dart';
import 'factory_manifest.dart';
import 'factory_manifest_data_source.dart';
import 'factory_manifest_repository.dart';

final class FactoryManifestRepositoryImpl
    implements FactoryManifestRepository {
  FactoryManifestRepositoryImpl({
    required FactoryManifestDataSource dataSource,
    required Mapper<Map<String, dynamic>, FactoryManifest> mapper,
  })  : _dataSource = dataSource,
        _mapper = mapper;

  final FactoryManifestDataSource _dataSource;
  final Mapper<Map<String, dynamic>, FactoryManifest> _mapper;

  @override
  Future<FactoryManifest> load() async {
    final raw = await _dataSource.load();
    return _mapper.map(raw);
  }
}
