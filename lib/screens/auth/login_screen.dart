// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../config.dart';
// import '../../l10n/app_localizations.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/locale_provider.dart';
// import '../../providers/products_provider.dart';
// import '../../theme.dart';
// import '../home_screen.dart';
// import '../barter/post_product_screen.dart';

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
//         _error = ref.read(authProvider).error;
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
//       setState(() {
//         _error = ref.read(authProvider).error;
//         _googleLoading = false;
//       });
//       return;
//     }

//     await _navigateAfterAuth();
//   }

//   void _comingSoon(String provider) {
//     final t = AppLocalizations.of(context)!;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(t.comingSoon(provider)),
//         backgroundColor: AppColors.text,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showLanguageSheet() {
//     final t = AppLocalizations.of(context)!;
//     final current = ref.read(localeProvider).languageCode;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppColors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Text(
//                 t.language,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.text,
//                 ),
//               ),
//             ),
//             for (final lang in supportedLanguages)
//               ListTile(
//                 leading: Icon(
//                   current == lang['code']
//                       ? Icons.radio_button_checked
//                       : Icons.radio_button_unchecked,
//                   color: current == lang['code']
//                       ? AppColors.primary
//                       : AppColors.textMuted,
//                 ),
//                 title: Text(lang['name']!),
//                 onTap: () {
//                   ref
//                       .read(localeProvider.notifier)
//                       .setLanguage(lang['code']!);
//                   Navigator.of(context).pop();
//                 },
//               ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = AppLocalizations.of(context)!;
//     final currentLang = ref.watch(localeProvider).languageCode;
//     final langLabel = currentLang == 'am' ? 'አማርኛ' : 'English';

//     return Scaffold(
//       backgroundColor: AppColors.white,
//       resizeToAvoidBottomInset: true,
//       body: Stack(
//         children: [
//           // ══════ Soft green glow behind logo ══════
//           Positioned(
//             top: -60,
//             left: 0,
//             right: 0,
//             height: 340,
//             child: IgnorePointer(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: RadialGradient(
//                     center: const Alignment(0, -0.3),
//                     radius: 1.1,
//                     colors: [
//                       AppColors.primaryLight,
//                       AppColors.primaryLight.withValues(alpha: 0.35),
//                       AppColors.white.withValues(alpha: 0),
//                     ],
//                     stops: const [0.0, 0.55, 1.0],
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // ══════ Content ══════
//           SafeArea(
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 final h = constraints.maxHeight;
//                 final isCompact = h < 700;

//                 final gapL = isCompact ? 20.0 : 26.0;
//                 final gapM = isCompact ? 14.0 : 18.0;
//                 final gapS = isCompact ? 10.0 : 12.0;
//                 final logoSize = isCompact ? 60.0 : 72.0;
//                 final titleSize = isCompact ? 22.0 : 26.0;
//                 final subtitleSize = isCompact ? 13.0 : 14.0;

//                 return SingleChildScrollView(
//                   physics: const ClampingScrollPhysics(),
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(minHeight: h),
//                     child: Center(
//                       child: ConstrainedBox(
//                         constraints: const BoxConstraints(maxWidth: 420),
//                         child: Padding(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: isCompact ? 16 : 20,
//                           ),
//                           child: Form(
//                             key: _formKey,
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               crossAxisAlignment: CrossAxisAlignment.stretch,
//                               children: [
//                                 // ══════ HEADER: Logo + Language chip ══════
//                                 Row(
//                                   children: [
//                                     _Logo(size: logoSize),
//                                     const Spacer(),
//                                     _LanguageChip(
//                                       label: langLabel,
//                                       onTap: _showLanguageSheet,
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: gapL),

//                                 // ══════ HEADLINE ══════
//                                 Text(
//                                   t.welcome,
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     fontSize: titleSize,
//                                     fontWeight: FontWeight.w700,
//                                     color: AppColors.text,
//                                     letterSpacing: -0.5,
//                                     height: 1.2,
//                                   ),
//                                 ),
//                                 SizedBox(height: gapS),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                   ),
//                                   child: Text(
//                                     t.signInToContinue,
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       fontSize: subtitleSize,
//                                       color: AppColors.textMuted,
//                                       height: 1.45,
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(height: gapL),

//                                 // ══════ EMAIL ══════
//                                 _FloatingField(
//                                   label: t.email,
//                                   hint: t.emailHint,
//                                   controller: _emailCtrl,
//                                   keyboardType: TextInputType.emailAddress,
//                                   textInputAction: TextInputAction.next,
//                                   validator: (v) {
//                                     final value = (v ?? '').trim();
//                                     if (value.isEmpty) return t.emailRequired;
//                                     final re =
//                                         RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
//                                     if (!re.hasMatch(value)) {
//                                       return t.emailInvalid;
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                                 SizedBox(height: gapS),

//                                 // ══════ PASSWORD ══════
//                                 _FloatingField(
//                                   label: t.password,
//                                   hint: t.passwordHint,
//                                   controller: _passwordCtrl,
//                                   obscure: _obscure,
//                                   textInputAction: TextInputAction.done,
//                                   onFieldSubmitted: (_) => _loginWithEmail(),
//                                   validator: (v) {
//                                     if ((v ?? '').isEmpty) {
//                                       return t.passwordRequired;
//                                     }
//                                     if ((v ?? '').length < 6) {
//                                       return t.passwordMinLength;
//                                     }
//                                     return null;
//                                   },
//                                   suffix: IconButton(
//                                     onPressed: () =>
//                                         setState(() => _obscure = !_obscure),
//                                     icon: Icon(
//                                       _obscure
//                                           ? Icons.visibility_off_outlined
//                                           : Icons.visibility_outlined,
//                                       size: 20,
//                                       color: AppColors.textMuted,
//                                     ),
//                                     splashRadius: 20,
//                                     tooltip: _obscure
//                                         ? t.showPassword
//                                         : t.hidePassword,
//                                   ),
//                                 ),

//                                 // ══════ ERROR ══════
//                                 if (_error != null) ...[
//                                   SizedBox(height: gapS),
//                                   _ErrorBanner(message: _error!),
//                                 ],

//                                 SizedBox(height: gapM),

//                                 // ══════ SIGN IN (with soft shadow) ══════
//                                 _SignInButton(
//                                   label: t.signIn,
//                                   loading: _emailLoading,
//                                   onPressed: _loginWithEmail,
//                                 ),
//                                 SizedBox(height: gapL),

//                                 // ══════ SOCIAL DIVIDER ══════
//                                 _OrDivider(text: t.orContinueWith),
//                                 SizedBox(height: gapM),

//                                 // ══════ SOCIAL ROW ══════
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceEvenly,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     _SocialProviderButton(
//                                       iconWidget:
//                                           const _GoogleIcon(size: 24),
//                                       label: 'Google',
//                                       loading: _googleLoading,
//                                       onPressed: _emailLoading
//                                           ? null
//                                           : _loginWithGoogle,
//                                     ),
//                                     _SocialProviderButton(
//                                       iconWidget: const Icon(
//                                         Icons.facebook,
//                                         size: 24,
//                                         color: Color(0xFF1877F2),
//                                       ),
//                                       label: t.facebook,
//                                       onPressed: () => _comingSoon(t.facebook),
//                                     ),
//                                     _SocialProviderButton(
//                                       iconWidget: const Icon(
//                                         Icons.apple,
//                                         size: 26,
//                                         color: Colors.black,
//                                       ),
//                                       label: t.apple,
//                                       onPressed: () => _comingSoon(t.apple),
//                                     ),
//                                     _SocialProviderButton(
//                                       iconWidget: Icon(
//                                         Icons.phone_android,
//                                         size: 24,
//                                         color: AppColors.primary,
//                                       ),
//                                       label: t.phone,
//                                       onPressed: () => _comingSoon(t.phone),
//                                     ),
//                                   ],
//                                 ),

//                                 // ══════ DEV ACCOUNTS ══════
//                                 // if (AppConfig.showDevHelpers) ...[
//                                 //   SizedBox(height: gapM),
//                                 //   _DevAccounts(
//                                 //     onSelect: (email) {
//                                 //       setState(() {
//                                 //         _emailCtrl.text = email;
//                                 //         _passwordCtrl.text = 'password123';
//                                 //       });
//                                 //     },
//                                 //   ),
//                                 // ],
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  Sub-widgets
// // ═══════════════════════════════════════════════════════

// /// Logo with a soft floating shadow — feels elevated, not cramped.
// class _Logo extends StatelessWidget {
//   final double size;
//   const _Logo({required this.size});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(size * 0.3),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withValues(alpha: 0.18),
//             blurRadius: 24,
//             offset: const Offset(0, 6),
//           ),
//           BoxShadow(
//             color: AppColors.primary.withValues(alpha: 0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Center(
//         child: Text(
//           'B',
//           style: TextStyle(
//             fontSize: size * 0.5,
//             fontWeight: FontWeight.w800,
//             color: AppColors.primary,
//             height: 1,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _LanguageChip extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;

//   const _LanguageChip({required this.label, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(20),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: AppColors.primary.withValues(alpha: 0.2),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.primary.withValues(alpha: 0.06),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.language, size: 14, color: AppColors.primary),
//               const SizedBox(width: 5),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Floating label field with generous vertical padding.
// class _FloatingField extends StatelessWidget {
//   final String label;
//   final String hint;
//   final TextEditingController controller;
//   final TextInputType? keyboardType;
//   final TextInputAction? textInputAction;
//   final String? Function(String?)? validator;
//   final Widget? suffix;
//   final bool obscure;
//   final void Function(String)? onFieldSubmitted;

//   const _FloatingField({
//     required this.label,
//     required this.hint,
//     required this.controller,
//     this.keyboardType,
//     this.textInputAction,
//     this.validator,
//     this.suffix,
//     this.obscure = false,
//     this.onFieldSubmitted,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       textInputAction: textInputAction,
//       obscureText: obscure,
//       validator: validator,
//       onFieldSubmitted: onFieldSubmitted,
//       style: const TextStyle(fontSize: 15, color: AppColors.text),
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         hintStyle: const TextStyle(
//           fontSize: 14,
//           color: AppColors.textSubtle,
//         ),
//         labelStyle: const TextStyle(
//           fontSize: 14,
//           color: AppColors.textMuted,
//         ),
//         floatingLabelStyle: const TextStyle(
//           fontSize: 13,
//           color: AppColors.primary,
//           fontWeight: FontWeight.w600,
//         ),
//         suffixIcon: suffix,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 18,
//           vertical: 18,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.border),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: AppColors.primary,
//             width: 2,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Sign-in button with a soft green shadow — feels like a real CTA.
// class _SignInButton extends StatelessWidget {
//   final String label;
//   final bool loading;
//   final VoidCallback? onPressed;

//   const _SignInButton({
//     required this.label,
//     required this.loading,
//     this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 54,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withValues(alpha: 0.28),
//             blurRadius: 18,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed: loading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: AppColors.white,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//         ),
//         child: loading
//             ? const SizedBox(
//                 width: 22,
//                 height: 22,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.5,
//                   color: AppColors.white,
//                 ),
//               )
//             : Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 0.2,
//                 ),
//               ),
//       ),
//     );
//   }
// }

// class _ErrorBanner extends StatelessWidget {
//   final String message;
//   const _ErrorBanner({required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: AppColors.error.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(top: 1),
//             child: Icon(Icons.error_outline,
//                 color: AppColors.error, size: 16),
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

// class _OrDivider extends StatelessWidget {
//   final String text;
//   const _OrDivider({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const Expanded(child: Divider(color: AppColors.divider, height: 1)),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Text(
//             text,
//             style: const TextStyle(
//               fontSize: 12,
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

// /// Bigger social button — 60×48 — with more breathing room.
// class _SocialProviderButton extends StatelessWidget {
//   final Widget iconWidget;
//   final String label;
//   final VoidCallback? onPressed;
//   final bool loading;

//   const _SocialProviderButton({
//     required this.iconWidget,
//     required this.label,
//     this.onPressed,
//     this.loading = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: loading ? null : onPressed,
//             borderRadius: BorderRadius.circular(14),
//             child: Container(
//               width: 60,
//               height: 48,
//               decoration: BoxDecoration(
//                 color: AppColors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: AppColors.border),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.04),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: loading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: AppColors.primary,
//                         ),
//                       )
//                     : iconWidget,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textMuted,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _GoogleIcon extends StatelessWidget {
//   final double size;
//   const _GoogleIcon({this.size = 24});

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
//       ..strokeWidth = stroke;

//     final rect = Rect.fromCircle(center: center, radius: r * 0.75);

//     canvas.drawArc(rect, -0.5, 1.0, false, paint(const Color(0xFF4285F4)));
//     canvas.drawArc(rect, 0.55, 0.9, false, paint(const Color(0xFF34A853)));
//     canvas.drawArc(rect, 1.5, 0.9, false, paint(const Color(0xFFFBBC05)));
//     canvas.drawArc(rect, 2.45, 0.95, false, paint(const Color(0xFFEA4335)));

//     canvas.drawLine(
//       Offset(center.dx, r),
//       Offset(size.width * 0.9, r),
//       paint(const Color(0xFF4285F4)),
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class _DevAccounts extends StatelessWidget {
//   final ValueChanged<String> onSelect;
//   const _DevAccounts({required this.onSelect});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: AppColors.primaryLight.withValues(alpha: 0.6),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.science_outlined,
//               size: 14, color: AppColors.primary),
//           const SizedBox(width: 8),
//           // const Text(
//           //   'Test:',
//           //   style: TextStyle(
//           //     fontSize: 11,
//           //     color: AppColors.textMuted,
//           //     fontWeight: FontWeight.w600,
//           //   ),
//           // ),
//           const SizedBox(width: 8),
//           // Expanded(
//           //   child: Wrap(
//           //     spacing: 8,
//           //     runSpacing: 6,
//           //     children: [
//           //       _DevChip(
//           //         label: 'Alice',
//           //         onTap: () => onSelect('test@barter.local'),
//           //       ),
//           //       _DevChip(
//           //         label: 'Bob',
//           //         onTap: () => onSelect('bob@barter.local'),
//           //       ),
//           //       _DevChip(
//           //         label: 'Admin',
//           //         onTap: () => onSelect('admin@barter.local'),
//           //       ),
//           //     ],
//           //   ),
          
//           // ),
//         ],
//       ),
//     );
//   }
// }

// class _DevChip extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;

//   const _DevChip({required this.label, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(10),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(
//               color: AppColors.primary.withValues(alpha: 0.25),
//             ),
//           ),
//           child: Text(
//             label,
//             style: const TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//               color: AppColors.primary,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }  

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/products_provider.dart';
import '../../theme.dart';
import '../home_screen.dart';
import '../barter/post_product_screen.dart';

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

  void _showLanguageSheet() {
    final t = AppLocalizations.of(context)!;
    final current = ref.read(localeProvider).languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t.language,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final lang in supportedLanguages)
                _LanguageOption(
                  name: lang['name']!,
                  code: lang['code']!,
                  selected: current == lang['code'],
                  onTap: () async {
                    await ref
                        .read(localeProvider.notifier)
                        .setLanguage(lang['code']!);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentLang = ref.watch(localeProvider).languageCode;
    final langLabel = currentLang == 'am' ? 'አማርኛ' : 'English';

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ══════ Soft green glow behind logo ══════
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: 340,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 1.1,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primaryLight.withValues(alpha: 0.35),
                      AppColors.white.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ══════ Content ══════
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final isCompact = h < 700;

                final gapL = isCompact ? 22.0 : 30.0;
                final gapM = isCompact ? 14.0 : 18.0;
                final gapS = isCompact ? 10.0 : 12.0;
                final logoSize = isCompact ? 64.0 : 76.0;
                final titleSize = isCompact ? 24.0 : 28.0;
                final subtitleSize = isCompact ? 13.5 : 14.5;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isCompact ? 16 : 20,
                          ),
                          child: _AnimatedEntrance(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ══════ HEADER: Logo + Language chip ══════
                                  Row(
                                    children: [
                                      _Logo(size: logoSize),
                                      const Spacer(),
                                      _LanguageChip(
                                        label: langLabel,
                                        onTap: _showLanguageSheet,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: gapL),

                                  // ══════ HEADLINE ══════
                                  Text(
                                    t.welcome,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                      letterSpacing: -0.6,
                                      height: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: gapS),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      t.signInToContinue,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: subtitleSize,
                                        color: AppColors.textMuted,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gapL),

                                  // ══════ EMAIL ══════
                                  _FloatingField(
                                    label: t.email,
                                    hint: t.emailHint,
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      final value = (v ?? '').trim();
                                      if (value.isEmpty) return t.emailRequired;
                                      final re =
                                          RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                                      if (!re.hasMatch(value)) {
                                        return t.emailInvalid;
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: gapS),

                                  // ══════ PASSWORD ══════
                                  _FloatingField(
                                    label: t.password,
                                    hint: t.passwordHint,
                                    controller: _passwordCtrl,
                                    obscure: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _loginWithEmail(),
                                    validator: (v) {
                                      if ((v ?? '').isEmpty) {
                                        return t.passwordRequired;
                                      }
                                      if ((v ?? '').length < 6) {
                                        return t.passwordMinLength;
                                      }
                                      return null;
                                    },
                                    suffix: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.textMuted,
                                      ),
                                      splashRadius: 20,
                                      tooltip: _obscure
                                          ? t.showPassword
                                          : t.hidePassword,
                                    ),
                                  ),

                                  // ══════ ERROR ══════
                                  if (_error != null) ...[
                                    SizedBox(height: gapS),
                                    _ErrorBanner(message: _error!),
                                  ],

                                  SizedBox(height: gapM),

                                  // ══════ SIGN IN ══════
                                  _PrimaryButton(
                                    label: t.signIn,
                                    loading: _emailLoading,
                                    onPressed: _loginWithEmail,
                                  ),
                                  SizedBox(height: gapL),

                                  // ══════ OR DIVIDER ══════
                                  _OrDivider(text: t.orContinueWith),
                                  SizedBox(height: gapM),

                                  // ══════ GOOGLE (single, full-width) ══════
                                  _GoogleSignInButton(
                                    loading: _googleLoading,
                                    disabled: _emailLoading,
                                    onPressed: _loginWithGoogle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Animated entrance wrapper
// ═══════════════════════════════════════════════════════

class _AnimatedEntrance extends StatefulWidget {
  final Widget child;
  const _AnimatedEntrance({required this.child});

  @override
  State<_AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<_AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Logo
// ═══════════════════════════════════════════════════════

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'B',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            height: 1,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Language chip
// ═══════════════════════════════════════════════════════

class _LanguageChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LanguageChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Floating label field
// ═══════════════════════════════════════════════════════

class _FloatingField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool obscure;
  final void Function(String)? onFieldSubmitted;

  const _FloatingField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffix,
    this.obscure = false,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscure,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 15, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSubtle,
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Primary (Sign In) button
// ═══════════════════════════════════════════════════════

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
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
                  color: AppColors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Error banner
// ═══════════════════════════════════════════════════════

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline,
                color: AppColors.error, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  "Or" divider
// ═══════════════════════════════════════════════════════

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
              letterSpacing: 0.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Google Sign-In button — full width, outlined
// ═══════════════════════════════════════════════════════

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
    required this.loading,
    required this.disabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !loading && !disabled;

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.text,
          side: BorderSide(
            color: isEnabled
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GoogleIcon(size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? AppColors.text
                          : AppColors.text.withValues(alpha: 0.5),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Google logo painter
// ═══════════════════════════════════════════════════════

class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 24});

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

// ═══════════════════════════════════════════════════════
//  Language option row (for the bottom sheet)
// ═══════════════════════════════════════════════════════

class _LanguageOption extends StatelessWidget {
  final String name;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.name,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.primaryLight.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? AppColors.primary : AppColors.text,
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}