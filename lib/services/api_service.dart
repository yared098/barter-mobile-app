

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/posting_status.dart';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart'; // PaintingBinding
import '../models/plan_option.dart';
import 'package:barter_ethio/services/google_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

// ══════════════════════════════════════════════════════════════════════════
// ERROR CODES — let your UI branch on these instead of parsing messages
// ══════════════════════════════════════════════════════════════════════════
enum ApiErrorCode {
  network,         // no internet / DNS / socket
  timeout,         // request took too long
  unauthorized,    // 401 during login (wrong creds)
  sessionExpired,  // 401 on any other endpoint → user must sign in again
  forbidden,       // 403
  notFound,        // 404
  validation,      // 400 / 422
  conflict,        // 409
  rateLimited,     // 429
  server,          // 5xx
  parse,           // server sent non-JSON
  unknown,
}

// ══════════════════════════════════════════════════════════════════════════
// CUSTOM EXCEPTION
//   .message   → friendly, safe to show to the user (SnackBar, dialog)
//   .code      → enum for branching logic
//   .statusCode→ raw HTTP status (nullable)
//   .detail    → technical text, for logs ONLY — never show to user
// ══════════════════════════════════════════════════════════════════════════
class ApiException implements Exception {
  final String message;
  final ApiErrorCode code;
  final int? statusCode;
  final String? detail;

  ApiException(
    this.message, {
    this.code = ApiErrorCode.unknown,
    this.statusCode,
    this.detail,
  });

  // ── Convenience getters for your UI ──
  bool get isNetworkError => code == ApiErrorCode.network;
  bool get isTimeout => code == ApiErrorCode.timeout;
  bool get isAuthError =>
      code == ApiErrorCode.sessionExpired || code == ApiErrorCode.unauthorized;
  bool get shouldSignInAgain => code == ApiErrorCode.sessionExpired;
  bool get canRetry =>
      code == ApiErrorCode.network ||
      code == ApiErrorCode.timeout ||
      code == ApiErrorCode.server;

  // ── Factory constructors ──
  factory ApiException.network({String? detail}) => ApiException(
        'No internet connection. Please check your network and try again.',
        code: ApiErrorCode.network,
        detail: detail,
      );

  factory ApiException.timeout() => ApiException(
        'The request took too long. Please try again.',
        code: ApiErrorCode.timeout,
      );

  factory ApiException.sessionExpired({String? detail}) => ApiException(
        'Your session has expired. Please sign in again.',
        code: ApiErrorCode.sessionExpired,
        statusCode: 401,
        detail: detail,
      );

  factory ApiException.parse({String? detail}) => ApiException(
        'We received an unexpected response. Please try again.',
        code: ApiErrorCode.parse,
        detail: detail,
      );

  /// Build a friendly exception from an HTTP status code + server message.
  /// The [serverMessage] is only used verbatim for validation-type errors
  /// (400 / 422) and auth-flow 401s, where the backend usually writes
  /// human-readable text like "Password is too short".
  factory ApiException.fromStatus(
    int status,
    String? serverMessage, {
    bool authFlow = false,
  }) {
    switch (status) {
      case 400:
        return ApiException(
          serverMessage ?? 'Some information is missing or incorrect. Please check and try again.',
          code: ApiErrorCode.validation,
          statusCode: 400,
          detail: serverMessage,
        );
      case 401:
        if (authFlow) {
          return ApiException(
            serverMessage ?? 'Invalid email or password.',
            code: ApiErrorCode.unauthorized,
            statusCode: 401,
            detail: serverMessage,
          );
        }
        return ApiException.sessionExpired(detail: serverMessage);
      case 403:
        return ApiException(
          "You don't have permission to do that.",
          code: ApiErrorCode.forbidden,
          statusCode: 403,
          detail: serverMessage,
        );
      case 404:
        return ApiException(
          "We couldn't find what you were looking for.",
          code: ApiErrorCode.notFound,
          statusCode: 404,
          detail: serverMessage,
        );
      case 409:
        return ApiException(
          serverMessage ?? 'This already exists.',
          code: ApiErrorCode.conflict,
          statusCode: 409,
          detail: serverMessage,
        );
      case 422:
        return ApiException(
          serverMessage ?? 'Please check your input and try again.',
          code: ApiErrorCode.validation,
          statusCode: 422,
          detail: serverMessage,
        );
      case 429:
        return ApiException(
          'Too many attempts. Please wait a moment and try again.',
          code: ApiErrorCode.rateLimited,
          statusCode: 429,
          detail: serverMessage,
        );
      default:
        if (status >= 500) {
          return ApiException(
            'Something went wrong on our side. Please try again shortly.',
            code: ApiErrorCode.server,
            statusCode: status,
            detail: serverMessage,
          );
        }
        return ApiException(
          'Something went wrong. Please try again.',
          code: ApiErrorCode.unknown,
          statusCode: status,
          detail: serverMessage,
        );
    }
  }

  /// Convert any low-level exception into a friendly one.
  factory ApiException.fromException(Object e, [StackTrace? st]) {
    if (e is ApiException) return e;
    if (e is SocketException) return ApiException.network(detail: e.message);
    if (e is HandshakeException) {
      return ApiException.network(
        detail: 'TLS handshake failed: ${e.message}',
      );
    }
    if (e is http.ClientException) {
      return ApiException.network(detail: e.message);
    }
    if (e is TimeoutException) return ApiException.timeout();
    if (e is FormatException) return ApiException.parse(detail: e.message);
    return ApiException(
      'Something went wrong. Please try again.',
      detail: e.toString(),
    );
  }

  @override
  String toString() => message; // safe for `Text(e.toString())` in UI
}

// ══════════════════════════════════════════════════════════════════════════
// API SERVICE
// ══════════════════════════════════════════════════════════════════════════
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

  // ─────────────────────────── SAFE EXECUTION WRAPPER ─────────────────────

  /// Runs [fn]. On 401 tries to refresh once and retries. Converts every
  /// low-level error into a friendly [ApiException].
  ///
  /// Set [allowRefresh] to `false` for login/refresh endpoints — you never
  /// want to trigger a token refresh while logging in.
  Future<T> _safe<T>(
    Future<T> Function() fn, {
    bool allowRefresh = true,
  }) async {
    try {
      return await fn();
    } on ApiException catch (e) {
      if (allowRefresh && e.statusCode == 401 && _refreshToken != null) {
        final ok = await _tryRefresh();
        if (ok) {
          try {
            return await fn();
          } catch (e2, st2) {
            _log('retry after refresh failed', e2, st2);
            throw ApiException.fromException(e2, st2);
          }
        }
        throw ApiException.sessionExpired(detail: e.detail);
      }
      rethrow;
    } catch (e, st) {
      _log('request failed', e, st);
      throw ApiException.fromException(e, st);
    }
  }

  void _log(String context, Object e, [StackTrace? st]) {
    if (kDebugMode) {
      debugPrint('[ApiService] $context: $e');
      if (st != null) debugPrint('$st');
    }
  }

  Future<List<PlanOption>> getPlans() => _safe(() async {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/payments/plans'),
        headers: _headers,
      );
      final list = _parseList(res);
      return list
          .whereType<Map>()
          .map((j) => PlanOption.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }, allowRefresh: false);

  // ─────────────────────────── RESPONSE PARSING ───────────────────────────

  Map<String, dynamic> _parse(http.Response res, {bool authFlow = false}) {
    final raw = res.body.isEmpty ? '{}' : res.body;
    dynamic body;

    try {
      body = jsonDecode(raw);
    } on FormatException {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        throw ApiException.parse(
          detail:
              'Expected JSON, got: ${raw.substring(0, raw.length.clamp(0, 100))}',
        );
      }
      throw ApiException.fromStatus(res.statusCode, null, authFlow: authFlow);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }

    String? serverMsg;
    if (body is Map && body['message'] != null) {
      final m = body['message'];
      serverMsg = m is List ? m.join(', ') : m.toString();
    }
    throw ApiException.fromStatus(
      res.statusCode,
      serverMsg,
      authFlow: authFlow,
    );
  }

  List<dynamic> _parseList(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        final body = jsonDecode(res.body);
        return body is List ? body : [];
      } on FormatException {
        throw ApiException.parse(
          detail: 'Expected JSON array, got non-JSON body',
        );
      }
    }

    // try to pull a message
    String? serverMsg;
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        final m = body['message'];
        serverMsg = m is List ? m.join(', ') : m.toString();
      }
    } catch (_) {}

    throw ApiException.fromStatus(res.statusCode, serverMsg);
  }

  // ─────────────────────────── TOKEN REFRESH ───────────────────────────

  Future<bool> _tryRefresh() async {
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _saveTokens(data['accessToken'], data['refreshToken']);
        return true;
      }
    } catch (e, st) {
      _log('token refresh failed', e, st);
    }
    return false;
  }

  // ─────────────────────────── GENERIC HELPERS ───────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 20),
  }) =>
      _safe(() async {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}$path')
            .replace(queryParameters: query);
        final res = await http.get(uri, headers: _headers).timeout(timeout);
        return _parse(res);
      });

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 20),
  }) =>
      _safe(() async {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}$path')
            .replace(queryParameters: query);
        final res = await http.get(uri, headers: _headers).timeout(timeout);
        return _parseList(res);
      });

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('${AppConfig.apiBaseUrl}$path'),
              headers: _headers,
              body: jsonEncode(body ?? {}),
            )
            .timeout(timeout);
        return _parse(res);
      });

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _safe(() async {
        final res = await http
            .patch(
              Uri.parse('${AppConfig.apiBaseUrl}$path'),
              headers: _headers,
              body: jsonEncode(body ?? {}),
            )
            .timeout(timeout);
        return _parse(res);
      });

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 20),
  }) =>
      _safe(() async {
        final req = http.Request(
          'DELETE',
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
        )..headers.addAll(_headers);
        if (body != null) req.body = jsonEncode(body);

        final streamed = await req.send().timeout(timeout);
        final res = await http.Response.fromStream(streamed);
        return _parse(res);
      });

  // ─────────────────────────── AUTH ───────────────────────────

  Future<Map<String, dynamic>> loginWithPassword(
    String email,
    String password,
  ) =>
      _safe(
        () async {
          final res = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          );
          final data = _parse(res, authFlow: true);
          await _saveTokens(data['accessToken'], data['refreshToken']);
          return data;
        },
        allowRefresh: false, // never refresh during login
      );

  Future<Map<String, dynamic>> loginWithOtpDev(String email, String otp) =>
      _safe(
        () async {
          final res = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': 'password123'}),
          );
          final data = _parse(res, authFlow: true);
          await _saveTokens(data['accessToken'], data['refreshToken']);
          return data;
        },
        allowRefresh: false,
      );

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) => _safe(
        () async {
          final res = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          );
          final data = _parse(res, authFlow: true);
          await _saveTokens(data['accessToken'], data['refreshToken']);
          return data;
        },
        allowRefresh: false,
      );

  Future<Map<String, dynamic>> loginWithGoogleCode(
    String code,
    String redirectUri,
  ) =>
      _safe(
        () async {
          final res = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/google-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code, 'redirectUri': redirectUri}),
          );
          final data = _parse(res, authFlow: true);
          await _saveTokens(data['accessToken'], data['refreshToken']);
          return data;
        },
        allowRefresh: false,
      );

  Future<Map<String, dynamic>> me() => _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
          headers: _headers,
        );
        return _parse(res);
      });

  Future<void> logout() async {
    // Best-effort server logout, don't block on failure
    try {
      await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // ignore — we wipe locally below regardless
    }
    await clearAllLocalData();
  }

  Future<void> clearAllLocalData() async {
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    try {
      await GoogleAuthService().signOut();
    } catch (_) {}

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
  }

  // ─────────────────────────── CATEGORIES ───────────────────────────

  Future<List<dynamic>> categories() => _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/categories'),
          headers: _headers,
        );
        return _parseList(res);
      });

  // ─────────────────────────── PRODUCTS ───────────────────────────

  Future<List<dynamic>> myProducts() => _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/products?mine=true'),
          headers: _headers,
        );
        return _parseList(res);
      });

  Future<Map<String, dynamic>> getProduct(String productId) =>
      _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/products/$productId'),
          headers: _headers,
        );
        return _parse(res);
      });

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> payload) =>
      _safe(() async {
        final res = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/products'),
          headers: _headers,
          body: jsonEncode(payload),
        );
        return _parse(res);
      });

  // ─────────────────────────── MATCHES ───────────────────────────

  Future<Map<String, dynamic>> matches() => _safe(() async {
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
  }) =>
      _safe(() async {
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

  Future<Map<String, dynamic>> getOffer(String offerId) => _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/offers/$offerId'),
          headers: _headers,
        );
        return _parse(res);
      });

  Future<List<dynamic>> offers({String box = 'incoming'}) =>
      _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/offers?box=$box'),
          headers: _headers,
        );
        return _parseList(res);
      });

  Future<Map<String, dynamic>> offerAction(
    String offerId,
    String action,
  ) =>
      _safe(() async {
        final res = await http.patch(
          Uri.parse('${AppConfig.apiBaseUrl}/offers/$offerId'),
          headers: _headers,
          body: jsonEncode({'action': action}),
        );
        return _parse(res);
      });

  Future<List<dynamic>> offerMessages(String offerId) => _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/offers/$offerId/messages'),
          headers: _headers,
        );
        return _parseList(res);
      });

  Future<Map<String, dynamic>> sendOfferMessage(
    String offerId,
    String content,
  ) =>
      _safe(() async {
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
  }) =>
      _safe(() async {
        final res = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/notifications/register'),
          headers: _headers,
          body: jsonEncode({'token': token, 'platform': platform}),
        );
        _parse(res);
      });

  Future<void> unregisterDeviceToken(String token) => _safe(() async {
        final res = await http.delete(
          Uri.parse('${AppConfig.apiBaseUrl}/notifications/unregister'),
          headers: _headers,
          body: jsonEncode({'token': token}),
        );
        _parse(res);
      });

  // ─────────────────────────── UPLOAD ───────────────────────────

  Future<String> uploadImage(File file) => _safe(() async {
        final req = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConfig.apiBaseUrl}/upload'),
        );
        req.headers['Authorization'] = 'Bearer $_accessToken';

        req.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: _mimeTypeForPath(file.path),
          ),
        );

        final streamed = await req.send().timeout(
              const Duration(seconds: 60),
            );
        final res = await http.Response.fromStream(streamed);

        final raw = res.body.isEmpty ? '{}' : res.body;
        Map<String, dynamic> data;
        try {
          data = jsonDecode(raw) as Map<String, dynamic>;
        } on FormatException {
          throw ApiException.parse(detail: 'Upload response was not JSON');
        }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final url = data['url'];
          if (url is String) return url;
          throw ApiException.parse(
            detail: 'Upload succeeded but no "url" field was returned',
          );
        }

        throw ApiException.fromStatus(
          res.statusCode,
          data['message']?.toString(),
        );
      });

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


    // ─────────────────────────── PAYMENTS ───────────────────────────

  Future<Map<String, dynamic>> initPayment(String planId) => _safe(() async {
        final res = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/payments/init'),
          headers: _headers,
          body: jsonEncode({'plan': planId}),
        );
        return _parse(res);
      });

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) =>
      _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/payments/$paymentId/status'),
          headers: _headers,
        );
        return _parse(res);
      });

  Future<PostingStatus> getPostingStatus() => _safe(() async {
        final res = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/users/me/posting-status'),
          headers: _headers,
        );
        return PostingStatus.fromJson(_parse(res));
      });
}