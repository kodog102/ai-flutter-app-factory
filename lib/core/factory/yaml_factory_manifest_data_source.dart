import 'dart:io';

import 'package:yaml/yaml.dart';

import 'factory_manifest_data_source.dart';

final class YamlFactoryManifestDataSource implements FactoryManifestDataSource {
  const YamlFactoryManifestDataSource({
    this.path = 'factory.yaml',
  });

  final String path;

  @override
  Future<Map<String, dynamic>> load() async {
    final content = await File(path).readAsString();
    final yaml = loadYaml(content);

    return _toMap(yaml as YamlMap);
  }

  Map<String, dynamic> _toMap(YamlMap yaml) {
    return {
      for (final entry in yaml.entries)
        entry.key as String: _toRawValue(entry.value),
    };
  }

  Object? _toRawValue(Object? value) {
    if (value is YamlMap) {
      return _toMap(value);
    }

    if (value is YamlList) {
      return value.map(_toRawValue).toList();
    }

    return value;
  }
}
