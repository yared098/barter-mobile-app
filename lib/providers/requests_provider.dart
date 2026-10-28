import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_provider.dart';
import '../services/requests_service.dart';

final requestsServiceProvider = Provider<RequestsService>((ref) {
  return RequestsService(ref.read(apiProvider));
});

/// Feed — scope: 'all' | 'mine' | 'replies'
final wantedFeedProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, scope) async {
  return ref.read(requestsServiceProvider).list(scope: scope);
});

/// Detail — autoDispose so every screen open refetches replies.
final requestDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, id) async {
    return ref.read(requestsServiceProvider).get(id);
  },
);