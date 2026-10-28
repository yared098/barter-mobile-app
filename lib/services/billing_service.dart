import 'api_service.dart';

class BiddingService {
  final ApiService _api;
  BiddingService(this._api);

  // ── Listings ──
  Future<Map<String, dynamic>> createListing(Map<String, dynamic> body) =>
      _api.post('/bidding/listings', body: body);

  Future<List<dynamic>> listListings({
    String scope = 'all',
    String? status,
    String? categoryId,
    String? q,
  }) {
    final qs = {
      'scope': scope,
      if (status != null) 'status': status,
      if (categoryId != null) 'categoryId': categoryId,
      if (q != null && q.isNotEmpty) 'q': q,
    };
    return _api.getList('/bidding/listings', query: qs);
  }

  Future<Map<String, dynamic>> getListing(String id) =>
      _api.get('/bidding/listings/$id');

  Future<void> cancelListing(String id) =>
      _api.delete('/bidding/listings/$id');

  // ── Bids ──
  Future<Map<String, dynamic>> placeBid(
    String listingId, {
    double? amount,
    String? offeredProductId,
    String? message,
  }) =>
      _api.post('/bidding/listings/$listingId/bids', body: {
        if (amount != null) 'amount': amount,
        if (offeredProductId != null) 'offeredProductId': offeredProductId,
        if (message != null && message.isNotEmpty) 'message': message,
      });

  Future<Map<String, dynamic>> acceptBid(
          String listingId, String bidId) =>
      _api.post('/bidding/listings/$listingId/bids/$bidId/accept', body: {});

  Future<Map<String, dynamic>> rejectBid(
          String listingId, String bidId) =>
      _api.post('/bidding/listings/$listingId/bids/$bidId/reject', body: {});

  Future<void> withdrawBid(String listingId, String bidId) =>
      _api.delete('/bidding/listings/$listingId/bids/$bidId');
}