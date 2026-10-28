import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../providers/api_provider.dart';
import 'api_service.dart';

class BillingService {
  final ApiService _api;
  BillingService(this._api);

  /// Returns [{id, name, description, priceMinor, currency, interval, features, highlight}]
  Future<List<Map<String, dynamic>>> getPlans() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/billing/plans'),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return ((body['plans'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getStatus() async {
    final res = await _api.get('/billing/status');
    return res;
  }

  Future<Map<String, dynamic>> createCheckout(String planId) async {
    final res = await _api.post('/billing/checkout', body: {'plan': planId});
    return res;
  }

  Future<Map<String, dynamic>> verifySession(String sessionId) async {
    final res = await _api.get('/billing/verify?session=$sessionId');
    return res;
  }

  Future<Map<String, dynamic>> cancel() async {
    final res = await _api.post('/billing/cancel', body: {});
    return res;
  }
}

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService(ref.read(apiProvider));
});