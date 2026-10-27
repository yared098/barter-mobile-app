import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_provider.dart';

/// Ranked matches for the current user.
/// Invalidate to force a refresh.
final matchesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final api = ref.watch(apiProvider);
  return api.matches();
});
