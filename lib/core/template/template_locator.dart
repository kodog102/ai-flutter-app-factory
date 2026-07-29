import 'dart:io';

import '../factory/factory_manifest.dart';

abstract interface class TemplateLocator {
  Future<Directory> locate(TemplateInfo template);
}
