import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

/// Fetches categories once and caches them.
/// `.autoDispose` isn't used — we want them resident across screens.
final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.categories();
});