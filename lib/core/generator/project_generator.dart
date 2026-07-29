import 'dart:io';

abstract interface class ProjectGenerator {
  Future<Directory> generate({
    required Directory template,
    required Directory output,
  });
}
