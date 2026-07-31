enum RepositoryMode {
  newRepository,
  existingEmptyRepository;

  static RepositoryMode? tryParse(String value) {
    return switch (value) {
      'newRepository' => RepositoryMode.newRepository,
      'existingEmptyRepository' => RepositoryMode.existingEmptyRepository,
      _ => null,
    };
  }
}
