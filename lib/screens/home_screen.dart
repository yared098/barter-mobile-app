

// import 'package:barter_ethio/l10n/app_localizations.dart';
// import 'package:barter_ethio/providers/offers_provider.dart';
// import 'package:barter_ethio/providers/requests_provider.dart';        // ⭐ NEW
// import 'package:barter_ethio/screens/chat/chats_screen.dart';
// import 'package:barter_ethio/screens/barter/product_detail_screen.dart';
// import 'package:barter_ethio/widgets/image_gallery.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../widgets/match_card.dart';
// import '../widgets/upgrade_prompt_sheet.dart';
// import '../providers/auth_provider.dart';
// import '../providers/matches_provider.dart';
// import '../providers/products_provider.dart';
// import '../theme.dart';
// import '../widgets/empty_view.dart';
// import '../widgets/error_view.dart';
// import '../widgets/loading_view.dart';
// import 'auth/login_screen.dart';
// import 'barter/post_product_screen.dart';
// import 'request/wanted_board_screen.dart';

// class HomeScreen extends ConsumerWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = AppLocalizations.of(context)!;
//     final matchesAsync = ref.watch(matchesProvider);

//     return Scaffold(
//       backgroundColor: AppColors.white,
//       appBar: _HomeAppBar(
//         onOpenChats: () {
//           Navigator.of(context).push(
//             MaterialPageRoute(builder: (_) => const ChatsScreen()),
//           );
//         },
//       ),
//       body: matchesAsync.when(
//         skipLoadingOnRefresh: true,
//         loading: () => LoadingView(message: t.findingMatches),
//         error: (e, _) => ErrorView(
//           message: e.toString().replaceFirst('Exception: ', ''),
//           onRetry: () => ref.invalidate(matchesProvider),
//         ),
//         data: (data) => _MatchesList(
//           data: data,
//           onRefresh: () async {
//             ref.invalidate(incomingOffersProvider);
//             ref.invalidate(outgoingOffersProvider);
//             await ref.refresh(matchesProvider.future);
//           },
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  SHARED HELPER — check if user has ANY paid access
// //  (PRO, DAILY pass still valid, or credits remaining)
// // ═══════════════════════════════════════════════════════
// bool hasPaidAccess(dynamic user) {
//   if (user == null) return false;
//   final tier = user['tier'] as String?;
//   final now = DateTime.now();

//   // PRO — check expiry
//   if (tier == 'PRO') {
//     final exp = user['proExpiresAt'];
//     if (exp == null) return true;
//     try {
//       return DateTime.parse(exp as String).isAfter(now);
//     } catch (_) {
//       return true;
//     }
//   }

//   // DAILY pass — check expiry
//   if (tier == 'DAILY') {
//     final exp = user['dailyPassExpiresAt'];
//     if (exp == null) return false;
//     try {
//       return DateTime.parse(exp as String).isAfter(now);
//     } catch (_) {
//       return false;
//     }
//   }

//   // CREDIT pack — check remaining credits
//   if (tier == 'CREDIT') {
//     final credits = (user['creditsRemaining'] as num?)?.toInt() ?? 0;
//     return credits > 0;
//   }

//   return false;
// }

// /// Resolve the display label for a user's tier (PRO / DAILY / CREDIT / '')
// String tierLabel(dynamic user) {
//   final tier = user?['tier'] as String?;
//   if (tier == 'PRO' || tier == 'DAILY' || tier == 'CREDIT') return tier!;
//   return '';
// }

// // ═══════════════════════════════════════════════════════
// //  BRANDED HOME APP BAR
// // ═══════════════════════════════════════════════════════

// class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
//   final VoidCallback onOpenChats;
//   const _HomeAppBar({required this.onOpenChats});

//   @override
//   Size get preferredSize => const Size.fromHeight(66);

//   /// Resolve the best possible display name from the user record.
//   String _resolveName(dynamic user) {
//     final name = (user?['name'] as String?)?.trim();
//     if (name != null && name.isNotEmpty) return name;

//     final first = (user?['firstName'] as String?)?.trim();
//     if (first != null && first.isNotEmpty) return first;

//     final email = (user?['email'] as String?)?.trim();
//     if (email != null && email.isNotEmpty) {
//       return email.split('@').first;
//     }

//     return '';
//   }

//   /// ⭐ NEW — count of OPEN wanted requests from OTHER users
//   /// (excludes current user's own requests). Shows as a badge.
//   int _openWantedCount(WidgetRef ref) {
//     final currentUserId = ref.watch(authProvider).user?['id'] as String?;
//     final feed = ref.watch(wantedFeedProvider('all')).asData?.value ?? [];

//     return feed
//         .whereType<Map<String, dynamic>>()
//         .where((r) =>
//             r['status'] == 'OPEN' && r['authorId'] != currentUserId)
//         .length;
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = AppLocalizations.of(context)!;
//     final user = ref.watch(authProvider).user;

//     final rawName = _resolveName(user);
//     final firstName = rawName.split(RegExp(r'\s+')).first;

//     final paid = hasPaidAccess(user);
//     final label = tierLabel(user);

//     final darkPrimary =
//         Color.lerp(AppColors.primary, Colors.black, 0.18) ?? AppColors.primary;

//     return AppBar(
//       automaticallyImplyLeading: false,
//       toolbarHeight: 66,
//       elevation: 0,
//       scrolledUnderElevation: 0,
//       backgroundColor: Colors.transparent,
//       surfaceTintColor: Colors.transparent,
//       flexibleSpace: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [AppColors.primary, darkPrimary],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primary.withValues(alpha: 0.22),
//               blurRadius: 16,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//       ),
//       titleSpacing: 12,
//       title: Row(
//         children: [
//           _Avatar(firstName: firstName, isPro: paid),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   children: [
//                     Flexible(
//                       child: Text(
//                         t.homeTitle,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w800,
//                           letterSpacing: -0.3,
//                           height: 1.2,
//                         ),
//                       ),
//                     ),
//                     if (paid && label.isNotEmpty) ...[
//                       const SizedBox(width: 5),
//                       _TierBadge(label: label),
//                     ],
//                   ],
//                 ),
//                 const SizedBox(height: 1),
//                 Text(
//                   firstName.isEmpty ? 'Welcome back 👋' : 'Hi, $firstName 👋',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.white.withValues(alpha: 0.85),
//                     fontSize: 11.5,
//                     fontWeight: FontWeight.w500,
//                     height: 1.2,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         const _PostActionButton(),
//         _CompactIconButton(
//           icon: Icons.chat_bubble_outline,
//           tooltip: t.chats,
//           onTap: onOpenChats,
//           showPendingBadge: true,
//         ),

//         // ⭐ Wanted Board — megaphone icon + count badge
//         //    Replaced Icons.assignment_outlined (clipboard, confusing)
//         //    with Icons.campaign_rounded (megaphone, universally understood)
//         _CompactIconButton(
//           icon: Icons.campaign_rounded,
//           tooltip: 'Wanted Board — see what people need',
//           onTap: () {
//             Navigator.of(context).push(
//               MaterialPageRoute(builder: (_) => const WantedBoardScreen()),
//             );
//           },
//           pendingCountOverride: _openWantedCount(ref),   // ⭐ visible count
//         ),

//         const _OverflowMenu(),
//         const SizedBox(width: 2),
//       ],
//     );
//   }
// }

// /// Compact 36×36 icon button for the AppBar actions row.
// /// Supports either a computed offers count or a custom override.
// class _CompactIconButton extends ConsumerWidget {
//   final IconData icon;
//   final String tooltip;
//   final VoidCallback onTap;
//   final bool showPendingBadge;

//   // ⭐ NEW — external count that overrides the offers-based badge
//   final int? pendingCountOverride;

//   const _CompactIconButton({
//     required this.icon,
//     required this.tooltip,
//     required this.onTap,
//     this.showPendingBadge = false,
//     this.pendingCountOverride,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Priority: explicit override wins over computed offers count
//     int count = pendingCountOverride ?? 0;

//     if (count == 0 && showPendingBadge) {
//       final incoming = ref.watch(incomingOffersProvider).value ?? [];
//       final outgoing = ref.watch(outgoingOffersProvider).value ?? [];
//       for (final o in [...incoming, ...outgoing]) {
//         if (o is Map && o['status'] == 'PENDING') count++;
//       }
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(20),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: onTap,
//           splashColor: Colors.white.withValues(alpha: 0.20),
//           highlightColor: Colors.white.withValues(alpha: 0.10),
//           child: Tooltip(
//             message: tooltip,
//             child: SizedBox(
//               width: 36,
//               height: 36,
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 alignment: Alignment.center,
//                 children: [
//                   Icon(icon, color: Colors.white, size: 20),
//                   if (count > 0)
//                     Positioned(
//                       right: -2,
//                       top: -2,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 4,
//                           vertical: 1,
//                         ),
//                         constraints: const BoxConstraints(
//                           minWidth: 15,
//                           minHeight: 15,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppColors.error,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                             color: Colors.white,
//                             width: 1.4,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.2),
//                               blurRadius: 3,
//                               offset: const Offset(0, 1),
//                             ),
//                           ],
//                         ),
//                         child: Text(
//                           count > 99 ? '99+' : '$count',
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 8.5,
//                             fontWeight: FontWeight.w800,
//                             height: 1.1,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  POST BUTTON — tier-gated pill
// // ═══════════════════════════════════════════════════════

// class _PostActionButton extends ConsumerWidget {
//   const _PostActionButton();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final user = ref.watch(authProvider).user;
//     final paid = hasPaidAccess(user);
//     final products = ref.watch(myProductsProvider).value;

//     if (products == null) return const SizedBox.shrink();

//     final activeCount = products
//         .whereType<Map<String, dynamic>>()
//         .where((p) => p['status'] == 'AVAILABLE')
//         .length;

//     if (paid) {
//       return _AppBarPillButton(
//         icon: Icons.add_rounded,
//         label: 'Post',
//         onTap: () => _openPostScreen(context, ref, products.isEmpty),
//       );
//     }

//     if (activeCount == 0) {
//       return _AppBarPillButton(
//         icon: Icons.add_rounded,
//         label: 'Post',
//         onTap: () => _openPostScreen(context, ref, true),
//       );
//     }

//     return _AppBarPillButton(
//       icon: Icons.workspace_premium,
//       label: 'PRO',
//       onTap: () => showUpgradePromptSheet(
//         context,
//         reason: UpgradeReason.products,
//       ),
//     );
//   }

//   Future<void> _openPostScreen(
//     BuildContext context,
//     WidgetRef ref,
//     bool isFirstProduct,
//   ) async {
//     await Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => PostProductScreen(isFirstProduct: isFirstProduct),
//       ),
//     );
//     ref.invalidate(matchesProvider);
//     ref.invalidate(myProductsProvider);
//   }
// }

// class _AppBarPillButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _AppBarPillButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
//       child: Material(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: onTap,
//           splashColor: AppColors.primary.withValues(alpha: 0.15),
//           highlightColor: AppColors.primary.withValues(alpha: 0.06),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(icon, size: 13, color: AppColors.primary),
//                 const SizedBox(width: 3),
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w800,
//                     color: AppColors.primary,
//                     letterSpacing: 0.2,
//                     height: 1.1,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  AVATAR — with PAID ring when applicable
// // ═══════════════════════════════════════════════════════

// class _Avatar extends StatelessWidget {
//   final String firstName;
//   final bool isPro;
//   const _Avatar({required this.firstName, this.isPro = false});

//   @override
//   Widget build(BuildContext context) {
//     final initial =
//         firstName.isNotEmpty ? firstName.characters.first.toUpperCase() : '?';

//     const proRing = Color(0xFF22C55E);
//     const proGlow = Color(0xFF16A34A);

//     final size = isPro ? 40.0 : 36.0;

//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         if (isPro)
//           Container(
//             width: size + 4,
//             height: size + 4,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: RadialGradient(
//                 colors: [
//                   proGlow.withValues(alpha: 0.30),
//                   proGlow.withValues(alpha: 0.0),
//                 ],
//               ),
//             ),
//           ),
//         Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white.withValues(alpha: 0.20),
//             border: Border.all(
//               color: isPro ? proRing : Colors.white.withValues(alpha: 0.35),
//               width: isPro ? 2.4 : 1.2,
//             ),
//             boxShadow: isPro
//                 ? [
//                     BoxShadow(
//                       color: proRing.withValues(alpha: 0.45),
//                       blurRadius: 8,
//                       spreadRadius: 1,
//                     ),
//                   ]
//                 : null,
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             initial,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: isPro ? 16 : 15,
//               fontWeight: FontWeight.w800,
//               letterSpacing: -0.3,
//             ),
//           ),
//         ),
//         if (isPro)
//           Positioned(
//             right: -2,
//             bottom: -2,
//             child: Container(
//               width: 16,
//               height: 16,
//               decoration: BoxDecoration(
//                 color: proRing,
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 1.8),
//               ),
//               child: const Icon(
//                 Icons.check_rounded,
//                 size: 10,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  TIER BADGE — shows PRO / DAILY / CREDIT dynamically
// // ═══════════════════════════════════════════════════════

// class _TierBadge extends StatelessWidget {
//   final String label;
//   const _TierBadge({required this.label});

//   @override
//   Widget build(BuildContext context) {
//     if (label.isEmpty) return const SizedBox.shrink();

//     final icon = switch (label) {
//       'PRO' => Icons.workspace_premium,
//       'DAILY' => Icons.today_rounded,
//       'CREDIT' => Icons.confirmation_number_outlined,
//       _ => Icons.star_rounded,
//     };

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 9, color: AppColors.primary),
//           const SizedBox(width: 2),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 8.5,
//               fontWeight: FontWeight.w800,
//               color: AppColors.primary,
//               letterSpacing: 0.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  OVERFLOW MENU
// // ═══════════════════════════════════════════════════════

// class _OverflowMenu extends ConsumerWidget {
//   const _OverflowMenu();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = AppLocalizations.of(context)!;

//     return PopupMenuButton<String>(
//       icon: const Icon(Icons.more_vert, color: Colors.white),
//       color: Colors.white,
//       elevation: 8,
//       offset: const Offset(0, 48),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       onSelected: (v) async {
//         if (v == 'refresh') {
//           await ref.read(authProvider.notifier).refreshUser().catchError((_) {});
//           ref.invalidate(incomingOffersProvider);
//           ref.invalidate(outgoingOffersProvider);
//           ref.refresh(matchesProvider.future);
//         } else if (v == 'logout') {
//           await ref.read(authProvider.notifier).logout();
//           if (context.mounted) {
//             Navigator.of(context).pushAndRemoveUntil(
//               MaterialPageRoute(builder: (_) => const LoginScreen()),
//               (_) => false,
//             );
//           }
//         }
//       },
//       itemBuilder: (_) => [
//         PopupMenuItem(
//           value: 'refresh',
//           child: Row(
//             children: [
//               const Icon(Icons.refresh, size: 18, color: AppColors.textMuted),
//               const SizedBox(width: 10),
//               Text(t.refresh),
//             ],
//           ),
//         ),
//         PopupMenuItem(
//           value: 'logout',
//           child: Row(
//             children: [
//               const Icon(Icons.logout, size: 18, color: AppColors.error),
//               const SizedBox(width: 10),
//               Text(t.signOut),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════
// //  MATCHES LIST  (unchanged)
// // ═══════════════════════════════════════════════════════

// class _MatchesList extends StatelessWidget {
//   final Map<String, dynamic> data;
//   final Future<void> Function() onRefresh;

//   const _MatchesList({required this.data, required this.onRefresh});

//   String _conditionLabel(String? condition, AppLocalizations t) {
//     switch (condition) {
//       case 'NEW':
//         return t.conditionNew;
//       case 'LIKE_NEW':
//         return t.conditionLikeNew;
//       case 'GOOD':
//         return t.conditionGood;
//       case 'FAIR':
//         return t.conditionFair;
//       default:
//         return condition?.replaceAll('_', ' ') ?? '';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = AppLocalizations.of(context)!;
//     final matches = (data['matches'] as List?) ?? [];
//     final teasers = (data['teaserMatches'] as List?) ?? [];
//     final total = data['totalCount'] ?? 0;
//     final hidden = data['hiddenCount'] ?? 0;
//     final tier = (data['tier'] as String?) ?? 'FREE';
//     final isFree = tier == 'FREE';

//     if (matches.isEmpty) {
//       return EmptyView(
//         icon: Icons.explore_outlined,
//         title: t.noMatchesYet,
//         message: t.noMatchesMessage,
//       );
//     }

//     final openUpgrade = () => showUpgradePromptSheet(
//           context,
//           hiddenCount: hidden,
//           totalCount: total,
//         );

//     return RefreshIndicator(
//       color: AppColors.primary,
//       onRefresh: onRefresh,
//       child: ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(bottom: 12),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.primaryLight,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     isFree
//                         ? '${matches.length} of $total'
//                         : t.matchesCount(total),
//                     style: const TextStyle(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w700,
//                       fontSize: 11.5,
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 if (isFree && hidden > 0)
//                   Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       onTap: openUpgrade,
//                       borderRadius: BorderRadius.circular(20),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         child: Row(
//                           children: const [
//                             Icon(
//                               Icons.workspace_premium,
//                               size: 13,
//                               color: AppColors.primary,
//                             ),
//                             SizedBox(width: 3),
//                             Text(
//                               'Upgrade',
//                               style: TextStyle(
//                                 fontSize: 11.5,
//                                 color: AppColors.primary,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           ...matches.map((m) {
//             final match = m as Map<String, dynamic>;
//             final p = match['product'] as Map<String, dynamic>;
//             final score = (match['score'] as num).toInt();
//             final reasons = (match['reasons'] as List?)?.cast<String>() ?? [];

//             final cardData = MatchCardData.fromMatch(
//               match,
//               conditionLabel: (raw) => _conditionLabel(raw, t),
//               fromPerson: t.fromPerson,
//             );

//             return MatchCard(
//               data: cardData,
//               onTap: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (_) => ProductDetailScreen(
//                       productId: p['id'] as String,
//                       matchScore: score,
//                       matchReasons: reasons,
//                     ),
//                   ),
//                 );
//               },
//               onImageTap: cardData.imageUrl != null
//                   ? () => showImageGallery(
//                         context,
//                         images: cardData.allImages,
//                         initialIndex: 0,
//                       )
//                   : null,
//             );
//           }),

//           if (isFree && teasers.isNotEmpty) ...[
//             const SizedBox(height: 6),
//             _TeaserSection(
//               teasers: teasers.cast<Map<String, dynamic>>(),
//               hidden: hidden,
//               onOpenUpgrade: openUpgrade,
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _TeaserSection extends StatelessWidget {
//   final List<Map<String, dynamic>> teasers;
//   final int hidden;
//   final VoidCallback onOpenUpgrade;

//   const _TeaserSection({
//     required this.teasers,
//     required this.hidden,
//     required this.onOpenUpgrade,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryLight,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: AppColors.primary.withValues(alpha: 0.2),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.lock,
//                       size: 11,
//                       color: AppColors.primary,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '$hidden locked match${hidden == 1 ? '' : 'es'}',
//                       style: const TextStyle(
//                         fontSize: 10.5,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.primary,
//                         letterSpacing: 0.1,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Container(height: 1, color: AppColors.border),
//               ),
//             ],
//           ),
//         ),
//         ...teasers.map(
//           (teaser) => MatchCard(
//             locked: true,
//             data: MatchCardData.fromTeaser(teaser),
//             onTap: onOpenUpgrade,
//           ),
//         ),
//       ],
//     );
//   }
// }  

import 'package:barter_ethio/l10n/app_localizations.dart';
import 'package:barter_ethio/providers/offers_provider.dart';
import 'package:barter_ethio/providers/requests_provider.dart';
import 'package:barter_ethio/screens/chat/chats_screen.dart';
import 'package:barter_ethio/screens/barter/product_detail_screen.dart';
import 'package:barter_ethio/widgets/image_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/match_card.dart';
import '../widgets/upgrade_prompt_sheet.dart';
import '../providers/auth_provider.dart';
import '../providers/matches_provider.dart';
import '../providers/products_provider.dart';
import '../theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'auth/login_screen.dart';
import 'barter/post_product_screen.dart';
import 'request/wanted_board_screen.dart';

// ═══════════════════════════════════════════════════════
//  HOME SCREEN — ConsumerStatefulWidget so we can hold a
//  Scaffold key to open the end drawer
// ═══════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      appBar: _HomeAppBar(
        onOpenChats: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatsScreen()),
          );
        },
        onOpenMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
      endDrawer: const _AppDrawer(),
      body: matchesAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => LoadingView(message: t.findingMatches),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(matchesProvider),
        ),
        data: (data) => _MatchesList(
          data: data,
          onRefresh: () async {
            ref.invalidate(incomingOffersProvider);
            ref.invalidate(outgoingOffersProvider);
            await ref.refresh(matchesProvider.future);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════

bool hasPaidAccess(dynamic user) {
  if (user == null) return false;
  final tier = user['tier'] as String?;
  final now = DateTime.now();

  if (tier == 'PRO') {
    final exp = user['proExpiresAt'];
    if (exp == null) return true;
    try {
      return DateTime.parse(exp as String).isAfter(now);
    } catch (_) {
      return true;
    }
  }

  if (tier == 'DAILY') {
    final exp = user['dailyPassExpiresAt'];
    if (exp == null) return false;
    try {
      return DateTime.parse(exp as String).isAfter(now);
    } catch (_) {
      return false;
    }
  }

  if (tier == 'CREDIT') {
    final credits = (user['creditsRemaining'] as num?)?.toInt() ?? 0;
    return credits > 0;
  }

  return false;
}

String tierLabel(dynamic user) {
  final tier = user?['tier'] as String?;
  if (tier == 'PRO' || tier == 'DAILY' || tier == 'CREDIT') return tier!;
  return '';
}

/// Human-readable plan + remaining quota summary.
String tierSummary(dynamic user) {
  if (user == null) return 'Not signed in';
  final tier = user['tier'] as String? ?? 'FREE';
  final now = DateTime.now();

  if (tier == 'PRO') {
    final exp = user['proExpiresAt'];
    if (exp != null) {
      try {
        final dt = DateTime.parse(exp as String);
        if (dt.isAfter(now)) {
          final days = dt.difference(now).inDays;
          final budget = (user['proBudgetRemaining'] as num?)?.toInt() ?? 0;
          return 'PRO · $budget posts left · $days days';
        }
      } catch (_) {}
    }
    return 'PRO';
  }

  if (tier == 'DAILY') {
    final exp = user['dailyPassExpiresAt'];
    if (exp != null) {
      try {
        final dt = DateTime.parse(exp as String);
        if (dt.isAfter(now)) {
          final hrs = dt.difference(now).inHours;
          return 'Daily Pass · ${hrs}h left';
        }
      } catch (_) {}
    }
    return 'Daily Pass (expired)';
  }

  if (tier == 'CREDIT') {
    final credits = (user['creditsRemaining'] as num?)?.toInt() ?? 0;
    return '$credits post credits';
  }

  return 'Free plan · 1 post/day';
}

String resolveName(dynamic user) {
  final name = (user?['name'] as String?)?.trim();
  if (name != null && name.isNotEmpty) return name;

  final first = (user?['firstName'] as String?)?.trim();
  if (first != null && first.isNotEmpty) return first;

  final email = (user?['email'] as String?)?.trim();
  if (email != null && email.isNotEmpty) {
    return email.split('@').first;
  }

  return '';
}

// ═══════════════════════════════════════════════════════
//  MINIMAL APP BAR — avatar + name + chat + menu
// ═══════════════════════════════════════════════════════

class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onOpenChats;
  final VoidCallback onOpenMenu;

  const _HomeAppBar({
    required this.onOpenChats,
    required this.onOpenMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;

    final rawName = resolveName(user);
    final firstName = rawName.split(RegExp(r'\s+')).first;
    final paid = hasPaidAccess(user);

    // Chat badge = pending offers
    int chatBadge = 0;
    final incoming = ref.watch(incomingOffersProvider).value ?? [];
    final outgoing = ref.watch(outgoingOffersProvider).value ?? [];
    for (final o in [...incoming, ...outgoing]) {
      if (o is Map && o['status'] == 'PENDING') chatBadge++;
    }

    final darkPrimary =
        Color.lerp(AppColors.primary, Colors.black, 0.18) ?? AppColors.primary;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 66,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, darkPrimary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      titleSpacing: 12,
      title: Row(
        children: [
          _Avatar(firstName: firstName, isPro: paid),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.homeTitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  firstName.isEmpty ? 'Welcome back 👋' : 'Hi, $firstName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Chat icon
        _AppBarIconButton(
          icon: Icons.chat_bubble_outline,
          tooltip: t.chats,
          badgeCount: chatBadge,
          onTap: onOpenChats,
        ),

        // 3-dot menu → opens end drawer
        _AppBarIconButton(
          icon: Icons.more_vert,
          tooltip: 'Menu',
          onTap: onOpenMenu,
        ),

        const SizedBox(width: 4),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  APP BAR ICON BUTTON
// ═══════════════════════════════════════════════════════

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int badgeCount;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.20),
          highlightColor: Colors.white.withValues(alpha: 0.10),
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  if (badgeCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  END DRAWER — all actions live here
// ═══════════════════════════════════════════════════════

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;

    final name = resolveName(user);
    final email = (user?['email'] as String?) ?? '';
    final paid = hasPaidAccess(user);
    final label = tierLabel(user);
    final summary = tierSummary(user);

    // Counts for badges
    final currentUserId = user?['id'] as String?;
    final wantedFeed = ref.watch(wantedFeedProvider('all')).asData?.value ?? [];
    final wantedCount = wantedFeed
        .whereType<Map<String, dynamic>>()
        .where((r) =>
            r['status'] == 'OPEN' && r['authorId'] != currentUserId)
        .length;

    int pendingOffers = 0;
    final incoming = ref.watch(incomingOffersProvider).value ?? [];
    final outgoing = ref.watch(outgoingOffersProvider).value ?? [];
    for (final o in [...incoming, ...outgoing]) {
      if (o is Map && o['status'] == 'PENDING') pendingOffers++;
    }

    final nav = Navigator.of(context, rootNavigator: true);

    Future<void> handlePost() async {
      nav.pop(); // close drawer first

      final products = ref.read(myProductsProvider).value ?? [];
      final activeCount = products
          .whereType<Map<String, dynamic>>()
          .where((p) => p['status'] == 'AVAILABLE')
          .length;

      if (!paid && activeCount > 0) {
        await showUpgradePromptSheet(
          context,
          reason: UpgradeReason.products,
        );
        return;
      }

      await nav.push(
        MaterialPageRoute(
          builder: (_) => PostProductScreen(
            isFirstProduct: products.isEmpty,
          ),
        ),
      );
      ref.invalidate(matchesProvider);
      ref.invalidate(myProductsProvider);
    }

    void handleWanted() {
      nav.pop();
      nav.push(
        MaterialPageRoute(builder: (_) => const WantedBoardScreen()),
      );
    }

    void handleChats() {
      nav.pop();
      nav.push(
        MaterialPageRoute(builder: (_) => const ChatsScreen()),
      );
    }

    Future<void> handleRefresh() async {
      await ref
          .read(authProvider.notifier)
          .refreshUser()
          .catchError((_) {});
      ref.invalidate(incomingOffersProvider);
      ref.invalidate(outgoingOffersProvider);
      ref.refresh(matchesProvider.future);
      if (context.mounted) nav.pop();
    }

    Future<void> handleLogout() async {
      nav.pop();
      await ref.read(authProvider.notifier).logout();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(
                        firstName: name,
                        isPro: paid,
                        size: 56,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Welcome' : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tierIcon(label),
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Post Product',
                    subtitle: paid || pendingOffers == 0
                        ? 'Share something you want to swap'
                        : 'Post another item',
                    onTap: handlePost,
                  ),
                  _DrawerItem(
                    icon: Icons.campaign_rounded,
                    label: 'Wanted Board',
                    subtitle: 'See what people are looking for',
                    trailingCount: wantedCount,
                    onTap: handleWanted,
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline,
                    label: t.chats,
                    subtitle: 'Your active barter conversations',
                    trailingCount: pendingOffers,
                    onTap: handleChats,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  _DrawerItem(
                    icon: Icons.refresh_rounded,
                    label: t.refresh,
                    subtitle: 'Sync your matches and profile',
                    onTap: handleRefresh,
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: t.signOut,
                    subtitle: 'Sign out of your account',
                    destructive: true,
                    onTap: handleLogout,
                  ),
                ],
              ),
            ),

            // ── Footer ──
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Barter Ethio · v1.0',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSubtle,  // ⭐ was textFaint
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _tierIcon(String label) {
    return switch (label) {
      'PRO' => Icons.workspace_premium,
      'DAILY' => Icons.today_rounded,
      'CREDIT' => Icons.confirmation_number_outlined,
      _ => Icons.person_outline,
    };
  }
}

// ═══════════════════════════════════════════════════════
//  DRAWER ROW WIDGET
// ═══════════════════════════════════════════════════════

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final int? trailingCount;
  final bool destructive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailingCount,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive ? AppColors.error : AppColors.primary;
    final iconBg = destructive
        ? AppColors.error.withValues(alpha: 0.10)
        : AppColors.primaryLight;
    final textColor = destructive ? AppColors.error : AppColors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: iconColor.withValues(alpha: 0.08),
          highlightColor: iconColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (trailingCount != null && trailingCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    constraints: const BoxConstraints(minWidth: 22),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      trailingCount! > 99 ? '99+' : '$trailingCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSubtle,  // ⭐ was textFaint
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  AVATAR — reusable, now supports custom size
// ═══════════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  final String firstName;
  final bool isPro;
  final double? size;

  const _Avatar({
    required this.firstName,
    this.isPro = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        firstName.isNotEmpty ? firstName.characters.first.toUpperCase() : '?';

    const proRing = Color(0xFF22C55E);
    const proGlow = Color(0xFF16A34A);

    final effectiveSize = size ?? (isPro ? 40.0 : 36.0);
    final fontSize = size != null
        ? size! * 0.4
        : (isPro ? 16.0 : 15.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isPro)
          Container(
            width: effectiveSize + 4,
            height: effectiveSize + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  proGlow.withValues(alpha: 0.30),
                  proGlow.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        Container(
          width: effectiveSize,
          height: effectiveSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.20),
            border: Border.all(
              color: isPro ? proRing : Colors.white.withValues(alpha: 0.35),
              width: isPro ? 2.4 : 1.2,
            ),
            boxShadow: isPro
                ? [
                    BoxShadow(
                      color: proRing.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (isPro)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size != null ? 20 : 16,
              height: size != null ? 20 : 16,
              decoration: BoxDecoration(
                color: proRing,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.check_rounded,
                size: size != null ? 13 : 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  MATCHES LIST  (unchanged)
// ═══════════════════════════════════════════════════════

class _MatchesList extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  const _MatchesList({required this.data, required this.onRefresh});

  String _conditionLabel(String? condition, AppLocalizations t) {
    switch (condition) {
      case 'NEW':
        return t.conditionNew;
      case 'LIKE_NEW':
        return t.conditionLikeNew;
      case 'GOOD':
        return t.conditionGood;
      case 'FAIR':
        return t.conditionFair;
      default:
        return condition?.replaceAll('_', ' ') ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final matches = (data['matches'] as List?) ?? [];
    final teasers = (data['teaserMatches'] as List?) ?? [];
    final total = data['totalCount'] ?? 0;
    final hidden = data['hiddenCount'] ?? 0;
    final tier = (data['tier'] as String?) ?? 'FREE';
    final isFree = tier == 'FREE';

    if (matches.isEmpty) {
      return EmptyView(
        icon: Icons.explore_outlined,
        title: t.noMatchesYet,
        message: t.noMatchesMessage,
      );
    }

    final openUpgrade = () => showUpgradePromptSheet(
          context,
          hiddenCount: hidden,
          totalCount: total,
        );

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFree
                        ? '${matches.length} of $total'
                        : t.matchesCount(total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (isFree && hidden > 0)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: openUpgrade,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.workspace_premium,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Upgrade',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          ...matches.map((m) {
            final match = m as Map<String, dynamic>;
            final p = match['product'] as Map<String, dynamic>;
            final score = (match['score'] as num).toInt();
            final reasons = (match['reasons'] as List?)?.cast<String>() ?? [];

            final cardData = MatchCardData.fromMatch(
              match,
              conditionLabel: (raw) => _conditionLabel(raw, t),
              fromPerson: t.fromPerson,
            );

            return MatchCard(
              data: cardData,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      productId: p['id'] as String,
                      matchScore: score,
                      matchReasons: reasons,
                    ),
                  ),
                );
              },
              onImageTap: cardData.imageUrl != null
                  ? () => showImageGallery(
                        context,
                        images: cardData.allImages,
                        initialIndex: 0,
                      )
                  : null,
            );
          }),

          if (isFree && teasers.isNotEmpty) ...[
            const SizedBox(height: 6),
            _TeaserSection(
              teasers: teasers.cast<Map<String, dynamic>>(),
              hidden: hidden,
              onOpenUpgrade: openUpgrade,
            ),
          ],
        ],
      ),
    );
  }
}

class _TeaserSection extends StatelessWidget {
  final List<Map<String, dynamic>> teasers;
  final int hidden;
  final VoidCallback onOpenUpgrade;

  const _TeaserSection({
    required this.teasers,
    required this.hidden,
    required this.onOpenUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$hidden locked match${hidden == 1 ? '' : 'es'}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: AppColors.border),
              ),
            ],
          ),
        ),
        ...teasers.map(
          (teaser) => MatchCard(
            locked: true,
            data: MatchCardData.fromTeaser(teaser),
            onTap: onOpenUpgrade,
          ),
        ),
      ],
    );
  }
}