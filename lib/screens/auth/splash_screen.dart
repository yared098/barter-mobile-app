import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../theme.dart';
import 'login_screen.dart';
import '../home_screen.dart';
import '../barter/post_product_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_navigate);
  }

  Future<void> _navigate() async {
    // Minimum splash time — feels intentional
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Wait for AuthNotifier to resolve (up to 10s)
    var auth = ref.read(authProvider);
    var waited = 0;
    while (auth.status == AuthStatus.unknown && waited < 10000) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      auth = ref.read(authProvider);
      waited += 100;
    }

    debugPrint('[Splash] auth resolved: ${auth.status} after ${waited}ms');

    // Unauthenticated → login
    if (auth.status != AuthStatus.authenticated) {
      _go(const LoginScreen());
      return;
    }

    // Authenticated → decide where to land
    try {
      final products = await ref.read(myProductsProvider.future);
      if (!mounted) return;
      _go(
        products.isEmpty
            ? const PostProductScreen(isFirstProduct: true)
            : const HomeScreen(),
      );
    } catch (e) {
      debugPrint('[Splash] products fetch failed: $e');
      if (!mounted) return;
      _go(const HomeScreen());
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'B',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Barter Ethio',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trade what you have',
              style: TextStyle(fontSize: 14, color: AppColors.white),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
