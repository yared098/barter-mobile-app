import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/push_service.dart';
import 'theme.dart';

Future<void> main() async {
  // Required before any plugin (Firebase, SharedPreferences, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  // ─── 1. Firebase init (must run FIRST) ───
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] ✅ Initialized');
  } catch (e) {
    debugPrint('[Firebase] ❌ Init failed: $e');
    // App still runs without push — login/product/matches all work
  }

  // ─── 2. Push service (needs Firebase ready) ───
  try {
    await PushService().init();
  } catch (e) {
    debugPrint('[Push] Init error: $e');
  }

  runApp(const ProviderScope(child: BarterApp()));
}

class BarterApp extends StatelessWidget {
  const BarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
