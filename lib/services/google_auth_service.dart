import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

/// Gets a Google ID token via the native Google Sign-In SDK.
/// The backend verifies it with google-auth-library.
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  bool _signInInProgress = false;

  GoogleSignIn get _signIn => GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: AppConfig.googleWebClientId,
      );

  Future<String?> signInAndGetIdToken() async {
    if (_signInInProgress) return null;
    _signInInProgress = true;
    try {
      final account = await _signIn.signIn();
      if (account == null) return null; // user cancelled

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception(
          'Google did not return an ID token. '
          'Check that AppConfig.googleWebClientId is set correctly.',
        );
      }
      return auth.idToken;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return null;
      throw Exception(_humanMessage(e));
    } finally {
      _signInInProgress = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _signIn.signOut();
    } catch (_) {}
  }

  String _humanMessage(PlatformException e) {
    switch (e.code) {
      case 'sign_in_failed':
        return 'Google sign-in failed. Check SHA-1 and google-services.json.';
      case 'network_error':
        return 'No internet connection.';
      case 'sign_in_required':
        return 'Please sign in to Google first.';
      default:
        return e.message ?? 'Google sign-in failed (${e.code}).';
    }
  }
}
