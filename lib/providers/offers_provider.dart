import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

final incomingOffersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.offers(box: 'incoming');
});

final outgoingOffersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.offers(box: 'outgoing');
});
