/// Central configuration. Change `apiBaseUrl` per environment.
class AppConfig {
  // ─────────────────────────────────────────────
  // API URL — change depending on test environment
  // ─────────────────────────────────────────────
  //
  // Android emulator  → http://10.0.2.2:3000/api/v1     (10.0.2.2 = host machine)
  // iOS simulator     → http://localhost:3000/api/v1
  // Real device WiFi  → http://<YOUR_LAN_IP>:3000/api/v1
  //                     (run `ip addr` on laptop → find 192.168.x.x or 10.x.x.x)
  // Production        → https://api.yourdomain.com/api/v1
  //
  // static const String apiBaseUrl = 'http://172.20.0.1:3000/api/v1';
  static const String apiBaseUrl = 'http://192.168.43.246:3000/api/v1';
  // ─────────────────────────────────────────────
  // App metadata
  // ─────────────────────────────────────────────
  static const String appName = 'Barter Ethio';
  static const String appTagline = 'Trade what you have';

  // ─────────────────────────────────────────────
  // Dev toggles
  // ─────────────────────────────────────────────
  /// When `true`, login screen auto-fills the test email.
  static const bool showDevHelpers = true;
  static const String devTestEmail = 'test@barter.local';
  static const String devTestPassword = 'password123';

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  /// Backend returns "/uploads/xxx.png" — we prepend the origin.
  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final origin = apiBaseUrl.replaceFirst('/api/v1', '');
    return '$origin$path';
  }

  /// Root origin (no /api/v1) — useful for health checks or non-API URLs.
  static String get apiOrigin => apiBaseUrl.replaceFirst('/api/v1', '');
}
