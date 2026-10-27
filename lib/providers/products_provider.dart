import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

/// The current user's own products.
/// Invalidate after creating/updating a product to refresh.
final myProductsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.myProducts();
});