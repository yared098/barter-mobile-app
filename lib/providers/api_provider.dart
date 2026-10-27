import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Single instance of the API service, shared by all providers.
final apiProvider = Provider<ApiService>((ref) {
  return ApiService();
});