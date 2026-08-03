import 'product_loop_repository_snapshot.dart';

enum ProductLoopBuildPolicy { none, android, ios, both }

final class ProductLoopGuardRequest {
  const ProductLoopGuardRequest({
    required this.expectedBaseline,
    this.buildPolicy = ProductLoopBuildPolicy.none,
  });

  final ProductLoopRepositorySnapshot expectedBaseline;
  final ProductLoopBuildPolicy buildPolicy;
}
