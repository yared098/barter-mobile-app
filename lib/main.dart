import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/push_service.dart';
import 'theme.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── 1. Load .env ───
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('[Env]  Loaded — API: ${AppConfig.apiBaseUrl}');
  } catch (e) {
    debugPrint('[Env] ❌ Failed to load .env: $e');
  }

  // ─── 2. Load saved locale BEFORE runApp ───
  String initialLocale = 'en';
  try {
    final prefs = await SharedPreferences.getInstance();
    initialLocale = prefs.getString('locale') ?? 'en';
    debugPrint('[Locale]  Loaded: $initialLocale');
  } catch (e) {
    debugPrint('[Locale] ❌ Failed to load: $e');
  }

  // ─── 3. Firebase init ───
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase]  Initialized');
  } catch (e) {
    debugPrint('[Firebase] ❌ Init failed: $e');
  }

  // ─── 4. Push service ───
  try {
    await PushService().init();
  } catch (e) {
    debugPrint('[Push] Init error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(initialLocale),
      ],
      child: const BarterApp(),
    ),
  );
}

class BarterApp extends ConsumerWidget {
  const BarterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,

      // ─── Localization support ───
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],

      home: const SplashScreen(),
    );
  }
}