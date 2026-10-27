import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_provider.dart';

/// Offers I received (someone wants my product).
final incomingOffersProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final api = ref.watch(apiProvider);
  return api.offers(box: 'incoming');
});

/// Offers I sent (I want someone's product).
final outgoingOffersProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final api = ref.watch(apiProvider);
  return api.offers(box: 'outgoing');
});

/// Single offer with all messages — used by the chat detail screen.
final offerDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, offerId) async {
      final api = ref.watch(apiProvider);
      return api.getOffer(offerId);
    });

/// Combined inbox: incoming + outgoing offers merged and sorted by
/// most recent activity. Used by the chats list screen.
final allChatsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final incoming = await ref.watch(incomingOffersProvider.future);
    final outgoing = await ref.watch(outgoingOffersProvider.future);

    final combined = <Map<String, dynamic>>[];

    for (final o in incoming) {
      if (o is Map<String, dynamic>) {
        combined.add({...o, '_direction': 'incoming'});
      }
    }
    for (final o in outgoing) {
      if (o is Map<String, dynamic>) {
        combined.add({...o, '_direction': 'outgoing'});
      }
    }

    // Sort by last message time (or offer creation time)
    combined.sort((a, b) {
      final aTime = _lastActivityTime(a);
      final bTime = _lastActivityTime(b);
      return bTime.compareTo(aTime);
    });

    return combined;
  },
);

DateTime _lastActivityTime(Map<String, dynamic> offer) {
  final messages = (offer['messages'] as List?) ?? [];
  if (messages.isNotEmpty) {
    final last = messages.last as Map<String, dynamic>;
    final t = last['createdAt'];
    if (t is String) {
      try {
        return DateTime.parse(t);
      } catch (_) {}
    }
  }
  final created = offer['createdAt'];
  if (created is String) {
    try {
      return DateTime.parse(created);
    } catch (_) {}
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
