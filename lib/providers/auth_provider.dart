// import 'package:barter_ethio/providers/categories_provider.dart';
// import 'package:barter_ethio/providers/matches_provider.dart';
// import 'package:barter_ethio/providers/products_provider.dart';
// import 'package:barter_ethio/services/google_auth_service.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'api_provider.dart';
// import '../services/push_service.dart';

// enum AuthStatus { unknown, authenticated, unauthenticated }

// class AuthState {
//   final AuthStatus status;
//   final Map<String, dynamic>? user;
//   final String? error;

//   const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

//   AuthState copyWith({
//     AuthStatus? status,
//     Map<String, dynamic>? user,
//     String? error,
//     bool clearError = false,
//     bool clearUser = false,
//   }) {
//     return AuthState(
//       status: status ?? this.status,
//       user: clearUser ? null : (user ?? this.user),
//       error: clearError ? null : (error ?? this.error),
//     );
//   }
// }

// class AuthNotifier extends Notifier<AuthState> {
//   @override
//   AuthState build() {
//     _init();
//     return const AuthState();
//   }

//   Future<void> _init() async {
//     final api = ref.read(apiProvider);
//     await api.loadTokens();

//     if (!api.isLoggedIn) {
//       state = state.copyWith(status: AuthStatus.unauthenticated);
//       return;
//     }

//     try {
//       final user = await api.me();
//       state = state.copyWith(status: AuthStatus.authenticated, user: user);
//     } catch (_) {
//       await api.logout();

//       state = state.copyWith(
//         status: AuthStatus.unauthenticated,
//         clearUser: true,
//       );
//     }
//   }

//   /// Real password login. Use this for testing with any seeded user.
//   Future<bool> loginWithPassword(String email, String password) async {
//     state = state.copyWith(clearError: true);
//     try {
//       final api = ref.read(apiProvider);
//       final data = await api.loginWithPassword(email, password);
//       state = state.copyWith(
//         status: AuthStatus.authenticated,
//         user: data['user'] as Map<String, dynamic>?,
//       );
//       // Refresh dependent providers with the new token
//       ref.invalidate(categoriesProvider);
//       ref.invalidate(myProductsProvider);
//       ref.invalidate(matchesProvider);
//       PushService().saveTokenForUser().catchError((_) {});
//       return true;
//     } catch (e) {
//       state = state.copyWith(
//         error: e.toString().replaceFirst('Exception: ', ''),
//       );
//       return false;
//     }
//   }

//   Future<bool> loginWithGoogle() async {
//     state = state.copyWith(clearError: true);
//     try {
//       // Get ID token via native SDK
//       final idToken = await GoogleAuthService().signInAndGetIdToken();
//       if (idToken == null) return false;

//       // Send to backend
//       final api = ref.read(apiProvider);
//       final data = await api.loginWithGoogle(idToken);

//       state = state.copyWith(
//         status: AuthStatus.authenticated,
//         user: data['user'] as Map<String, dynamic>?,
//       );
//       ref.invalidate(categoriesProvider);
//       ref.invalidate(myProductsProvider);
//       ref.invalidate(matchesProvider);
//       PushService().saveTokenForUser().catchError((_) {});
//       return true;
//     } catch (e) {
//       state = state.copyWith(
//         error: e.toString().replaceFirst('Exception: ', ''),
//       );
//       return false;
//     }
//   }

//   /// Dev-mode login: uses seeded test password behind the scenes.
//   /// TODO: swap to api.loginWithOtp(email, code) when backend adds OTP.
//   Future<bool> login(String email, String otp) async {
//     state = state.copyWith(clearError: true);
//     try {
//       final api = ref.read(apiProvider);
//       final data = await api.loginWithOtpDev(email, otp);
//       state = state.copyWith(
//         status: AuthStatus.authenticated,
//         user: data['user'] as Map<String, dynamic>?,
//       );
//       // Invalidate other providers so they refetch with the new token.
//       ref.invalidate(categoriesProvider);
//       ref.invalidate(myProductsProvider);
//       ref.invalidate(matchesProvider);
//       PushService().saveTokenForUser().catchError((_) {});
//       return true;
//     } catch (e) {
//       state = state.copyWith(
//         error: e.toString().replaceFirst('Exception: ', ''),
//       );
//       return false;
//     }
//   }

//   Future<void> logout() async {
//     // Remove FCM token BEFORE clearing auth
//     await PushService().removeTokenForUser();
//     final api = ref.read(apiProvider);
//     await api.logout();
//     state = const AuthState(status: AuthStatus.unauthenticated);
//   }
// }

// final authProvider = NotifierProvider<AuthNotifier, AuthState>(
//   AuthNotifier.new,
// );


import 'package:barter_ethio/providers/categories_provider.dart';
import 'package:barter_ethio/providers/matches_provider.dart';
import 'package:barter_ethio/providers/products_provider.dart';
import 'package:barter_ethio/services/google_auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_provider.dart';
import '../services/push_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  Future<void> _init() async {
    final api = ref.read(apiProvider);
    await api.loadTokens();

    if (!api.isLoggedIn) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await api.me();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await api.logout();

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ⭐ NEW: refreshUser() — force-refresh user from backend
  //
  // Called after a successful payment so the app immediately reflects the
  // new tier (PRO / DAILY / CREDIT), credits, and expiry dates.
  //
  // Also called on app resume (see main.dart lifecycle listener).
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> refreshUser() async {
    final api = ref.read(apiProvider);
    if (!api.isLoggedIn) return;

    try {
      final fresh = await api.me();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: fresh,
      );

      // Re-fetch everything that depends on the user's tier
      _refreshDependents();
    } catch (_) {
      // Silent fail — stale data is better than crashing the app.
      // Next refresh (payment / app resume / manual refresh) will retry.
    }
  }

  /// Invalidate providers that render tier-dependent UI.
  void _refreshDependents() {
    try {
      ref.invalidate(categoriesProvider);
      ref.invalidate(myProductsProvider);
      ref.invalidate(matchesProvider);
    } catch (_) {
      // Some providers may not be mounted yet — safe to ignore
    }
  }

  /// Real password login. Use this for testing with any seeded user.
  Future<bool> loginWithPassword(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final api = ref.read(apiProvider);
      final data = await api.loginWithPassword(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: data['user'] as Map<String, dynamic>?,
      );
      // Refresh dependent providers with the new token
      _refreshDependents();
      PushService().saveTokenForUser().catchError((_) {});
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(clearError: true);
    try {
      // Get ID token via native SDK
      final idToken = await GoogleAuthService().signInAndGetIdToken();
      if (idToken == null) return false;

      // Send to backend
      final api = ref.read(apiProvider);
      final data = await api.loginWithGoogle(idToken);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: data['user'] as Map<String, dynamic>?,
      );
      _refreshDependents();
      PushService().saveTokenForUser().catchError((_) {});
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Dev-mode login: uses seeded test password behind the scenes.
  /// TODO: swap to api.loginWithOtp(email, code) when backend adds OTP.
  Future<bool> login(String email, String otp) async {
    state = state.copyWith(clearError: true);
    try {
      final api = ref.read(apiProvider);
      final data = await api.loginWithOtpDev(email, otp);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: data['user'] as Map<String, dynamic>?,
      );
      // Invalidate other providers so they refetch with the new token.
      _refreshDependents();
      PushService().saveTokenForUser().catchError((_) {});
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    // Remove FCM token BEFORE clearing auth
    await PushService().removeTokenForUser();
    final api = ref.read(apiProvider);
    await api.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);