import 'package:barter_ethio/providers/categories_provider.dart';
import 'package:barter_ethio/providers/matches_provider.dart';
import 'package:barter_ethio/providers/products_provider.dart';
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
      ref.invalidate(categoriesProvider);
      ref.invalidate(myProductsProvider);
      ref.invalidate(matchesProvider);
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
      ref.invalidate(categoriesProvider);
      ref.invalidate(myProductsProvider);
      ref.invalidate(matchesProvider);
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
