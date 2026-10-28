import 'dart:convert';
import 'dart:io';

import 'package:barter_ethio/services/google_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

import '../config.dart';

/// Thrown for any non-2xx response. Providers catch it and surface `.message`.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Stateless HTTP client. All methods either return data or throw [ApiException].
/// State lives in Riverpod providers — this class does not notify anyone.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;
  String? _refreshToken;

  // ─────────────────────────── TOKEN MANAGEMENT ───────────────────────────

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  bool get isLoggedIn => _accessToken != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // ─────────────────────────── RESPONSE HANDLING ───────────────────────────

  Map<String, dynamic> _parse(http.Response res) {
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }

    final msg = body is Map && body['message'] != null
        ? (body['message'] is List
              ? (body['message'] as List).join(', ')
              : body['message'].toString())
        : 'Request failed (${res.statusCode})';

    throw ApiException(msg, res.statusCode);
  }

  List<dynamic> _parseList(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      return body is List ? body : [];
    }
    throw ApiException('Request failed (${res.statusCode})', res.statusCode);
  }

  // ─────────────────────────── AUTO-REFRESH ON 401 ───────────────────────────

  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && _refreshToken != null) {
        final ok = await _tryRefresh();
        if (ok) return await fn();
      }
      rethrow;
    }
  }

  /// Real email + password login.
  /// Use this for testing with bob@barter.local or admin@barter.local.
  Future<Map<String, dynamic>> loginWithPassword(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _parse(res);
    await _saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  Future<bool> _tryRefresh() async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _saveTokens(data['accessToken'], data['refreshToken']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─────────────────────────── AUTH ───────────────────────────

  /// Dev-only: uses password login with the seeded test account.
  ///
  /// 🔁 TODO: when backend adds OTP:
  ///   1) Add `requestOtp(email)` → POST /auth/request-otp
  ///   2) Replace body below with POST /auth/verify-otp { email, code }
  Future<Map<String, dynamic>> loginWithOtpDev(String email, String otp) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': 'password123'}),
    );
    final data = _parse(res);
    await _saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  /// Real Google login (client gets ID token from Google SDK, posts here).
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    final data = _parse(res);
    await _saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  Future<Map<String, dynamic>> me() => _withRetry(() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
      headers: _headers,
    );
    return _parse(res);
  });

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
        headers: _headers,
      );
    } catch (_) {}
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // await GoogleAuthService().signOut();
  }

  Future<Map<String, dynamic>> loginWithGoogleCode(
    String code,
    String redirectUri,
  ) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/google-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'redirectUri': redirectUri}),
    );
    final data = _parse(res);
    await _saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  // ─────────────────────────── CATEGORIES ───────────────────────────

  Future<List<dynamic>> categories() => _withRetry(() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/categories'),
      headers: _headers,
    );
    return _parseList(res);
  });

  // ─────────────────────────── PRODUCTS ───────────────────────────

  Future<List<dynamic>> myProducts() => _withRetry(() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/products?mine=true'),
      headers: _headers,
    );
    return _parseList(res);
  });
  Future<Map<String, dynamic>> getProduct(String productId) =>
      _withRetry(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/products/$productId'),
          headers: _headers,
        );
        return _parse(res);
      });
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> payload) =>
      _withRetry(() async {
        final res = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/products'),
          headers: _headers,
          body: jsonEncode(payload),
        );
        return _parse(res);
      });

  // ─────────────────────────── MATCHES ───────────────────────────

  Future<Map<String, dynamic>> matches() => _withRetry(() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/matches'),
      headers: _headers,
    );
    return _parse(res);
  });

  // ─────────────────────────── OFFERS ───────────────────────────

  Future<Map<String, dynamic>> createOffer({
    required String offeredProductId,
    required String requestedProductId,
    String? message,
  }) => _withRetry(() async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/offers'),
      headers: _headers,
      body: jsonEncode({
        'offeredProductId': offeredProductId,
        'requestedProductId': requestedProductId,
        if (message != null && message.isNotEmpty) 'message': message,
      }),
    );
    return _parse(res);
  });
  Future<Map<String, dynamic>> getOffer(String offerId) => _withRetry(() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/offers/$offerId'),
      headers: _headers,
    );
    return _parse(res);
  });
  Future<List<dynamic>> offers({String box = 'incoming'}) =>
      _withRetry(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/offers?box=$box'),
          headers: _headers,
        );
        return _parseList(res);
      });

  Future<Map<String, dynamic>> offerAction(String offerId, String action) =>
      _withRetry(() async {
        final res = await http.patch(
          Uri.parse('${AppConfig.apiBaseUrl}/offers/$offerId'),
          headers: _headers,
          body: jsonEncode({'action': action}),
        );
        return _parse(res);
      });

  Future<List<dynamic>> offerMessages(String offerId) => _withRetry(() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/offers/$offerId/messages'),
      headers: _headers,
    );
    return _parseList(res);
  });

  Future<Map<String, dynamic>> sendOfferMessage(
    String offerId,
    String content,
  ) => _withRetry(() async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/offers/$offerId/messages'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
    return _parse(res);
  });

  // ─────────────────────────── NOTIFICATIONS ───────────────────────────

  Future<void> registerDeviceToken(
    String token, {
    required String platform,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/register'),
      headers: _headers,
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    _parse(res);
  }

  Future<void> unregisterDeviceToken(String token) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/unregister'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    _parse(res);
  }

  // ─────────────────────────── UPLOAD ───────────────────────────

  // Future<String> uploadImage(File file) async {
  //   final req = http.MultipartRequest(
  //     'POST',
  //     Uri.parse('${AppConfig.apiBaseUrl}/upload'),
  //   );
  //   req.headers['Authorization'] = 'Bearer $_accessToken';
  //   req.files.add(await http.MultipartFile.fromPath('file', file.path));

  //   final streamed = await req.send();
  //   final res = await http.Response.fromStream(streamed);
  //   final data = jsonDecode(res.body);

  //   if (res.statusCode >= 200 && res.statusCode < 300) {
  //     return data['url'] as String;
  //   }

  //   throw ApiException(
  //     data['message']?.toString() ?? 'Upload failed',
  //     res.statusCode,
  //   );
  // }

  // ─────────────────────────── UPLOAD ───────────────────────────

  Future<String> uploadImage(File file) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/upload'),
    );
    req.headers['Authorization'] = 'Bearer $_accessToken';

    //  Explicit MIME — without this, Flutter sends octet-stream
    final mimeType = _mimeTypeForPath(file.path);

    req.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType,
      ),
    );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    // Handle empty body safely
    final body = res.body.isEmpty ? '{}' : res.body;
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final url = data['url'];
      if (url is String) return url;
      throw ApiException(
        'Upload succeeded but no URL returned',
        res.statusCode,
      );
    }

    throw ApiException(
      data['message']?.toString() ?? 'Upload failed (${res.statusCode})',
      res.statusCode,
    );
  }

  MediaType _mimeTypeForPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
