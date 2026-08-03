final class ProductLoopRepositorySnapshot {
  ProductLoopRepositorySnapshot({
    required this.productRoot,
    required this.gitTopLevel,
    required this.branch,
    required this.headIdentity,
    required List<String> gitStatusEntries,
    required Map<String, String> contentManifest,
  })  : gitStatusEntries = List<String>.unmodifiable(gitStatusEntries),
        contentManifest = Map<String, String>.unmodifiable(contentManifest);

  final String productRoot;
  final String gitTopLevel;
  final String branch;
  final String? headIdentity;
  final List<String> gitStatusEntries;
  final Map<String, String> contentManifest;

  bool get isClean => gitStatusEntries.isEmpty;
  String? get readmeIdentity => _existingIdentity('README.md');
  String? get agentsIdentity => _existingIdentity('AGENTS.md');

  String? _existingIdentity(String relativePath) {
    final identity = contentManifest['worktree:$relativePath'];
    return identity == null || identity == '<deleted>' ? null : identity;
  }

  bool sameIdentity(ProductLoopRepositorySnapshot other) {
    return productRoot == other.productRoot &&
        gitTopLevel == other.gitTopLevel &&
        branch == other.branch &&
        headIdentity == other.headIdentity &&
        _sameList(gitStatusEntries, other.gitStatusEntries) &&
        _sameMap(contentManifest, other.contentManifest);
  }

  bool sameRepositoryBoundary(ProductLoopRepositorySnapshot other) {
    return productRoot == other.productRoot &&
        gitTopLevel == other.gitTopLevel &&
        branch == other.branch &&
        headIdentity == other.headIdentity;
  }
}

bool _sameList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

bool _sameMap(Map<String, String> first, Map<String, String> second) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (second[entry.key] != entry.value) return false;
  }
  return true;
}
