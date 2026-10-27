// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../config.dart';
// import '../providers/auth_provider.dart';
// import '../providers/products_provider.dart';
// import '../theme.dart';
// import '../widgets/input_field.dart';
// import '../widgets/primary_button.dart';
// import 'home_screen.dart';
// import 'post_product_screen.dart';

// /// Shared max-width so login feels great on phone, tablet, and web.
// const double _maxContentWidth = 460;

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final _emailCtrl = TextEditingController(
//     text: AppConfig.showDevHelpers ? AppConfig.devTestEmail : '',
//   );
//   final _passwordCtrl = TextEditingController(
//     text: AppConfig.showDevHelpers ? AppConfig.devTestPassword : '',
//   );
//   final _formKey = GlobalKey<FormState>();

//   bool _emailLoading = false;
//   bool _googleLoading = false;
//   bool _obscure = true;
//   String? _error;

//   @override
//   void dispose() {
//     _emailCtrl.dispose();
//     _passwordCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _navigateAfterAuth() async {
//     try {
//       final products = await ref.read(myProductsProvider.future);
//       if (!mounted) return;
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(
//           builder: (_) => products.isEmpty
//               ? const PostProductScreen(isFirstProduct: true)
//               : const HomeScreen(),
//         ),
//         (_) => false,
//       );
//     } catch (_) {
//       if (!mounted) return;
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//         (_) => false,
//       );
//     }
//   }

//   Future<void> _loginWithEmail() async {
//     FocusScope.of(context).unfocus();
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _emailLoading = true;
//       _error = null;
//     });

//     final ok = await ref
//         .read(authProvider.notifier)
//         .loginWithPassword(_emailCtrl.text.trim(), _passwordCtrl.text);

//     if (!mounted) return;

//     if (!ok) {
//       setState(() {
//         _error = ref.read(authProvider).error ?? 'Login failed';
//         _emailLoading = false;
//       });
//       return;
//     }

//     await _navigateAfterAuth();
//   }

//   Future<void> _loginWithGoogle() async {
//     FocusScope.of(context).unfocus();
//     setState(() {
//       _googleLoading = true;
//       _error = null;
//     });

//     final ok = await ref.read(authProvider.notifier).loginWithGoogle();
//     if (!mounted) return;

//     if (!ok) {
//       final authState = ref.read(authProvider);
//       setState(() {
//         _error = authState.error;
//         _googleLoading = false;
//       });
//       return;
//     }

//     await _navigateAfterAuth();
//   }

//   void _comingSoon(String provider) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('$provider login is coming soon'),
//         backgroundColor: AppColors.text,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final screenWidth = mediaQuery.size.width;
//     final isSmall = screenWidth < 360;
//     final horizontalPadding = isSmall ? 16.0 : 24.0;

//     return Scaffold(
//       backgroundColor: AppColors.white,
//       resizeToAvoidBottomInset: true,
//       body: SafeArea(
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: _maxContentWidth),
//             child: SingleChildScrollView(
//               padding: EdgeInsets.symmetric(
//                 horizontal: horizontalPadding,
//                 vertical: 24,
//               ),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // ─── Logo + headline ───
//                     _Header(isSmall: isSmall),

//                     SizedBox(height: isSmall ? 28 : 36),

//                     // ─── Google (primary) ───
//                     _GoogleButton(
//                       loading: _googleLoading,
//                       onPressed: _emailLoading ? null : _loginWithGoogle,
//                     ),

//                     const SizedBox(height: 20),
//                     const _OrDivider(text: 'or sign in with email'),
//                     const SizedBox(height: 20),

//                     // ─── Email form ───
//                     InputField(
//                       label: 'Email',
//                       hint: 'you@example.com',
//                       controller: _emailCtrl,
//                       keyboardType: TextInputType.emailAddress,
//                       textInputAction: TextInputAction.next,
//                       validator: (v) {
//                         final value = (v ?? '').trim();
//                         if (value.isEmpty) return 'Email is required';
//                         final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
//                         if (!re.hasMatch(value)) return 'Enter a valid email';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     InputField(
//                       label: 'Password',
//                       hint: 'Enter your password',
//                       controller: _passwordCtrl,
//                       obscureText: _obscure,
//                       textInputAction: TextInputAction.done,
//                       onFieldSubmitted: (_) => _loginWithEmail(),
//                       validator: (v) {
//                         if ((v ?? '').isEmpty) return 'Password is required';
//                         if ((v ?? '').length < 6) return 'Min 6 characters';
//                         return null;
//                       },
//                     ),

//                     // Show / Hide
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton.icon(
//                         onPressed: () => setState(() => _obscure = !_obscure),
//                         icon: Icon(
//                           _obscure ? Icons.visibility_off : Icons.visibility,
//                           size: 16,
//                           color: AppColors.textMuted,
//                         ),
//                         label: Text(
//                           _obscure ? 'Show password' : 'Hide password',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: AppColors.textMuted,
//                           ),
//                         ),
//                       ),
//                     ),

//                     // Error banner
//                     if (_error != null) ...[
//                       const SizedBox(height: 4),
//                       _ErrorBanner(message: _error!),
//                     ],

//                     const SizedBox(height: 16),
//                     PrimaryButton(
//                       label: 'Sign in',
//                       onPressed: _loginWithEmail,
//                       loading: _emailLoading,
//                       icon: Icons.login,
//                     ),

//                     const SizedBox(height: 24),

//                     // ─── Other providers (responsive wrap) ───
//                     const _OrDivider(text: 'or continue with'),
//                     const SizedBox(height: 16),
//                     _SocialButtonsRow(
//                       onFacebook: () => _comingSoon('Facebook'),
//                       onApple: () => _comingSoon('Apple'),
//                       onPhone: () => _comingSoon('Phone'),
//                     ),

//                     // ─── Dev hint ───
//                     if (AppConfig.showDevHelpers) ...[
//                       const SizedBox(height: 24),
//                       _DevAccountsCard(
//                         onSelect: (email) {
//                           setState(() {
//                             _emailCtrl.text = email;
//                             _passwordCtrl.text = 'password123';
//                           });
//                         },
//                       ),
//                     ],

//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  Sub-widgets
// // ═══════════════════════════════════════════════════════

// class _Header extends StatelessWidget {
//   final bool isSmall;
//   const _Header({required this.isSmall});

//   @override
//   Widget build(BuildContext context) {
//     final logoSize = isSmall ? 64.0 : 72.0;
//     final titleSize = isSmall ? 24.0 : 28.0;
//     final subtitleSize = isSmall ? 13.0 : 15.0;

//     return Column(
//       children: [
//         Container(
//           width: logoSize,
//           height: logoSize,
//           decoration: BoxDecoration(
//             color: AppColors.primaryLight,
//             borderRadius: BorderRadius.circular(logoSize * 0.28),
//           ),
//           child: Center(
//             child: Text(
//               'B',
//               style: TextStyle(
//                 fontSize: logoSize * 0.55,
//                 fontWeight: FontWeight.w800,
//                 color: AppColors.primary,
//                 height: 1,
//               ),
//             ),
//           ),
//         ),
//         SizedBox(height: isSmall ? 20 : 24),
//         Text(
//           'Welcome to Barter',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: titleSize,
//             fontWeight: FontWeight.w700,
//             color: AppColors.text,
//             letterSpacing: -0.5,
//             height: 1.15,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Trade what you have for what you want.',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: subtitleSize,
//             color: AppColors.textMuted,
//             height: 1.4,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _GoogleButton extends StatelessWidget {
//   final bool loading;
//   final VoidCallback? onPressed;

//   const _GoogleButton({required this.loading, this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 54,
//       child: OutlinedButton(
//         onPressed: loading ? null : onPressed,
//         style: OutlinedButton.styleFrom(
//           backgroundColor: AppColors.white,
//           foregroundColor: AppColors.text,
//           side: const BorderSide(color: AppColors.border, width: 1.5),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//         ),
//         child: loading
//             ? const SizedBox(
//                 width: 22,
//                 height: 22,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.5,
//                   color: AppColors.primary,
//                 ),
//               )
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.min,
//                 children: const [
//                   _GoogleIcon(size: 20),
//                   SizedBox(width: 10),
//                   Flexible(
//                     child: Text(
//                       'Continue with Google',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.text,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }

// /// Colored "G" logo drawn with CustomPainter (no image assets needed).
// class _GoogleIcon extends StatelessWidget {
//   final double size;
//   const _GoogleIcon({this.size = 20});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: CustomPaint(painter: _GoogleLogoPainter()),
//     );
//   }
// }

// class _GoogleLogoPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = size.width / 2;
//     final center = Offset(r, r);
//     final stroke = size.width * 0.22;

//     Paint paint(Color c) => Paint()
//       ..color = c
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = stroke
//       ..strokeCap = StrokeCap.butt;

//     final rect = Rect.fromCircle(center: center, radius: r * 0.75);

//     // Approximate Google "G" using 4 colored arcs
//     canvas.drawArc(rect, -0.5, 1.0, false, paint(const Color(0xFF4285F4)));
//     canvas.drawArc(rect, 0.55, 0.9, false, paint(const Color(0xFF34A853)));
//     canvas.drawArc(rect, 1.5, 0.9, false, paint(const Color(0xFFFBBC05)));
//     canvas.drawArc(rect, 2.45, 0.95, false, paint(const Color(0xFFEA4335)));

//     // Crossbar extending right
//     canvas.drawLine(
//       Offset(center.dx, r),
//       Offset(size.width * 0.9, r),
//       paint(const Color(0xFF4285F4)),
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class _OrDivider extends StatelessWidget {
//   final String text;
//   const _OrDivider({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const Expanded(child: Divider(color: AppColors.divider, height: 1)),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           child: Text(
//             text,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 11,
//               color: AppColors.textMuted,
//               fontWeight: FontWeight.w500,
//               letterSpacing: 0.2,
//             ),
//           ),
//         ),
//         const Expanded(child: Divider(color: AppColors.divider, height: 1)),
//       ],
//     );
//   }
// }

// /// Responsive row of social buttons — uses Wrap so it doesn't overflow
// /// on narrow phones.
// class _SocialButtonsRow extends StatelessWidget {
//   final VoidCallback onFacebook;
//   final VoidCallback onApple;
//   final VoidCallback onPhone;

//   const _SocialButtonsRow({
//     required this.onFacebook,
//     required this.onApple,
//     required this.onPhone,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isNarrow = constraints.maxWidth < 340;

//         if (isNarrow) {
//           // Stack vertically on very small screens
//           return Column(
//             children: [
//               _SocialButton(
//                 label: 'Facebook',
//                 icon: Icons.facebook,
//                 color: const Color(0xFF1877F2),
//                 onPressed: onFacebook,
//                 fullWidth: true,
//               ),
//               const SizedBox(height: 10),
//               _SocialButton(
//                 label: 'Apple',
//                 icon: Icons.apple,
//                 color: Colors.black,
//                 onPressed: onApple,
//                 fullWidth: true,
//               ),
//               const SizedBox(height: 10),
//               _SocialButton(
//                 label: 'Phone',
//                 icon: Icons.phone_android,
//                 color: AppColors.primary,
//                 onPressed: onPhone,
//                 fullWidth: true,
//               ),
//             ],
//           );
//         }

//         // Horizontal row on normal screens — Wrap prevents overflow
//         return Wrap(
//           alignment: WrapAlignment.center,
//           spacing: 8,
//           runSpacing: 8,
//           children: [
//             _SocialButton(
//               label: 'Facebook',
//               icon: Icons.facebook,
//               color: const Color(0xFF1877F2),
//               onPressed: onFacebook,
//             ),
//             _SocialButton(
//               label: 'Apple',
//               icon: Icons.apple,
//               color: Colors.black,
//               onPressed: onApple,
//             ),
//             _SocialButton(
//               label: 'Phone',
//               icon: Icons.phone_android,
//               color: AppColors.primary,
//               onPressed: onPhone,
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _SocialButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final Color color;
//   final VoidCallback onPressed;
//   final bool fullWidth;

//   const _SocialButton({
//     required this.label,
//     required this.icon,
//     required this.color,
//     required this.onPressed,
//     this.fullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final content = Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: fullWidth ? 16 : 14,
//         vertical: 12,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.border),
//       ),
//       child: Row(
//         mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 18),
//           const SizedBox(width: 6),
//           Flexible(
//             child: Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.text,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );

//     return InkWell(
//       onTap: onPressed,
//       borderRadius: BorderRadius.circular(12),
//       child: fullWidth ? SizedBox(width: double.infinity, child: content) : content,
//     );
//   }
// }

// class _ErrorBanner extends StatelessWidget {
//   final String message;
//   const _ErrorBanner({required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.error.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(top: 1),
//             child: Icon(Icons.error_outline, color: AppColors.error, size: 16),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               message,
//               style: const TextStyle(
//                 color: AppColors.error,
//                 fontSize: 13,
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DevAccountsCard extends StatelessWidget {
//   final ValueChanged<String> onSelect;
//   const _DevAccountsCard({required this.onSelect});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.primaryLight,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             children: [
//               Icon(Icons.science_outlined, size: 14, color: AppColors.primary),
//               SizedBox(width: 6),
//               Text(
//                 'Test accounts (password: password123)',
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.text,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           _DevAccountRow(
//             label: 'Alice (FREE)',
//             email: 'test@barter.local',
//             onTap: () => onSelect('test@barter.local'),
//           ),
//           _DevAccountRow(
//             label: 'Bob (PRO)',
//             email: 'bob@barter.local',
//             onTap: () => onSelect('bob@barter.local'),
//           ),
//           _DevAccountRow(
//             label: 'Admin',
//             email: 'admin@barter.local',
//             onTap: () => onSelect('admin@barter.local'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DevAccountRow extends StatelessWidget {
//   final String label;
//   final String email;
//   final VoidCallback onTap;

//   const _DevAccountRow({
//     required this.label,
//     required this.email,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(6),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Row(
//           children: [
//             Text(
//               '$label: ',
//               style: const TextStyle(
//                 fontSize: 11,
//                 color: AppColors.textMuted,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 email,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontSize: 11,
//                   color: AppColors.primary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             const Icon(
//               Icons.touch_app_outlined,
//               size: 13,
//               color: AppColors.primary,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/products_provider.dart';
import '../theme.dart';
import '../widgets/input_field.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';
import 'post_product_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(
    text: AppConfig.showDevHelpers ? AppConfig.devTestEmail : '',
  );
  final _passwordCtrl = TextEditingController(
    text: AppConfig.showDevHelpers ? AppConfig.devTestPassword : '',
  );
  final _formKey = GlobalKey<FormState>();

  bool _emailLoading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth() async {
    try {
      final products = await ref.read(myProductsProvider.future);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => products.isEmpty
              ? const PostProductScreen(isFirstProduct: true)
              : const HomeScreen(),
        ),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _loginWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _emailLoading = true;
      _error = null;
    });

    final ok = await ref
        .read(authProvider.notifier)
        .loginWithPassword(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _error = ref.read(authProvider).error;
        _emailLoading = false;
      });
      return;
    }

    await _navigateAfterAuth();
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    final ok = await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _error = ref.read(authProvider).error;
        _googleLoading = false;
      });
      return;
    }

    await _navigateAfterAuth();
  }

  void _comingSoon(String provider) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.comingSoon(provider)),
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLanguageSheet() {
    final t = AppLocalizations.of(context)!;
    final current = ref.read(localeProvider).languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t.language,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            for (final lang in supportedLanguages)
              ListTile(
                leading: Icon(
                  current == lang['code']
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: current == lang['code']
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(lang['name']!),
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLanguage(lang['code']!);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmall = screenWidth < 360;
    final horizontalPadding = isSmall ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Language button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _showLanguageSheet,
                            icon: const Icon(
                              Icons.language,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              t.language,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Logo
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'B',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Welcome
                        Text(
                          t.welcome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.signInToContinue,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Google
                        _GoogleButton(
                          label: t.continueWithGoogle,
                          loading: _googleLoading,
                          onPressed: _emailLoading ? null : _loginWithGoogle,
                        ),
                        const SizedBox(height: 20),
                        _OrDivider(text: t.orSignInWithEmail),
                        const SizedBox(height: 20),

                        // Email
                        InputField(
                          label: t.email,
                          hint: t.emailHint,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return t.emailRequired;
                            final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                            if (!re.hasMatch(value)) return t.emailInvalid;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: t.password,
                          hint: t.passwordHint,
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loginWithEmail(),
                          validator: (v) {
                            if ((v ?? '').isEmpty) return t.passwordRequired;
                            if ((v ?? '').length < 6) {
                              return t.passwordMinLength;
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            label: Text(
                              _obscure ? t.showPassword : t.hidePassword,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: t.signIn,
                          onPressed: _loginWithEmail,
                          loading: _emailLoading,
                          icon: Icons.login,
                        ),

                        const SizedBox(height: 24),
                        _OrDivider(text: t.orContinueWith),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialButton(
                              label: t.facebook,
                              icon: Icons.facebook,
                              color: const Color(0xFF1877F2),
                              onPressed: () => _comingSoon(t.facebook),
                            ),
                            const SizedBox(width: 12),
                            _SocialButton(
                              label: t.apple,
                              icon: Icons.apple,
                              color: Colors.black,
                              onPressed: () => _comingSoon(t.apple),
                            ),
                            const SizedBox(width: 12),
                            _SocialButton(
                              label: t.phone,
                              icon: Icons.phone_android,
                              color: AppColors.primary,
                              onPressed: () => _comingSoon(t.phone),
                            ),
                          ],
                        ),

                        if (AppConfig.showDevHelpers) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.testAccounts,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _devAccount('Alice', 'test@barter.local'),
                                _devAccount('Bob', 'bob@barter.local'),
                                _devAccount('Admin', 'admin@barter.local'),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _devAccount(String label, String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _emailCtrl.text = email;
            _passwordCtrl.text = 'password123';
          });
        },
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.touch_app_outlined,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Sub-widgets (unchanged from before)
// ═══════════════════════════════════════════════════════

class _GoogleButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _GoogleButton({
    required this.label,
    required this.loading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleIcon(size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final stroke = size.width * 0.22;

    Paint paint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final rect = Rect.fromCircle(center: center, radius: r * 0.75);

    canvas.drawArc(rect, -0.5, 1.0, false, paint(const Color(0xFF4285F4)));
    canvas.drawArc(rect, 0.55, 0.9, false, paint(const Color(0xFF34A853)));
    canvas.drawArc(rect, 1.5, 0.9, false, paint(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 2.45, 0.95, false, paint(const Color(0xFFEA4335)));

    canvas.drawLine(
      Offset(center.dx, r),
      Offset(size.width * 0.9, r),
      paint(const Color(0xFF4285F4)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrDivider extends StatelessWidget {
  final String text;
  const _OrDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}