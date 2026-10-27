import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central configuration. Values come from `.env`.
/// Fallback values are used if a key is missing (safety net for prod).
class AppConfig {
  AppConfig._();

  // ─────────────────────────────────────────────
  // API URL — read from .env, with sane fallback
  // ─────────────────────────────────────────────
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api/v1';

  // ─────────────────────────────────────────────
  // Google OAuth Web Client ID
  // MUST match GOOGLE_CLIENT_ID in backend .env
  // ─────────────────────────────────────────────
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  // ─────────────────────────────────────────────
  // App metadata
  // ─────────────────────────────────────────────
  static String get appName => dotenv.env['APP_NAME'] ?? 'Barter Ethio';
  static String get appTagline =>
      dotenv.env['APP_TAGLINE'] ?? 'Trade what you have';

  // ─────────────────────────────────────────────
  // Dev toggles
  // ─────────────────────────────────────────────
  static bool get showDevHelpers =>
      dotenv.env['SHOW_DEV_HELPERS']?.toLowerCase() == 'true';

  static String get devTestEmail =>
      dotenv.env['DEV_TEST_EMAIL'] ?? 'test@barter.local';

  static String get devTestPassword =>
      dotenv.env['DEV_TEST_PASSWORD'] ?? 'password123';

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  /// Backend returns "/uploads/xxx.png" — prepend origin.
  static String resolveImageUrl(String? path) {
    if (path == null) return '';
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final origin = apiBaseUrl.replaceFirst('/api/v1', '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$origin$cleanPath';
  }

  /// Root origin (no /api/v1).
  static String get apiOrigin => apiBaseUrl.replaceFirst('/api/v1', '');
}
