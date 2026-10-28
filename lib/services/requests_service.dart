import 'api_service.dart';


import 'api_service.dart';

class RequestsService {
  final ApiService _api;
  RequestsService(this._api);

  Future<List<dynamic>> list({
    String scope = 'all',
    String? categoryId,
    String? q,
    String? type,
  }) async {
    final qs = {
      'scope': scope,
      if (categoryId != null) 'categoryId': categoryId,
      if (q != null && q.isNotEmpty) 'q': q,
      if (type != null) 'type': type,
    };
    return _api.getList('/requests', query: qs);
  }

  Future<Map<String, dynamic>> get(String id) => _api.get('/requests/$id');

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) =>
      _api.post('/requests', body: body);

  Future<Map<String, dynamic>> reply(String id, {
    required String message,
    String? productId,
    double? offeredPrice,
  }) =>
      _api.post('/requests/$id/replies', body: {
        'message': message,
        if (productId != null) 'productId': productId,
        if (offeredPrice != null) 'offeredPrice': offeredPrice,
      });

  Future<Map<String, dynamic>> acceptReply(String id, String replyId) =>
      _api.post('/requests/$id/replies/$replyId/accept', body: {});

  Future<void> cancel(String id) => _api.delete('/requests/$id');
  Future<void> withdrawReply(String id, String replyId) =>
      _api.delete('/requests/$id/replies/$replyId');
}