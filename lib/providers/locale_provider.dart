import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initial locale loaded in main() before runApp.
/// Override this in ProviderScope so the provider is synchronous.
final initialLocaleProvider = Provider<String>((ref) => 'en');

/// Holds the current locale and persists changes to SharedPreferences.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final initial = ref.read(initialLocaleProvider);
    return Locale(initial);
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', locale.languageCode);
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    await setLocale(Locale(code));
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Convenience list of supported locales for menus.
const supportedLanguages = [
  {'code': 'en', 'name': 'English'},
  {'code': 'am', 'name': 'አማርኛ'},
];
