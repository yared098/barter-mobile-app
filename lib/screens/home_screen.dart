import 'package:barter_ethio/l10n/app_localizations.dart';
import 'package:barter_ethio/providers/offers_provider.dart';
import 'package:barter_ethio/screens/chats_screen.dart';
import 'package:barter_ethio/screens/product_detail_screen.dart';
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
import 'login_screen.dart';
import 'post_product_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _HomeAppBar(
        onOpenChats: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatsScreen()),
          );
        },
      ),
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
//  BRANDED HOME APP BAR
// ═══════════════════════════════════════════════════════

class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onOpenChats;
  const _HomeAppBar({required this.onOpenChats});

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;

    final rawName = (user?['name'] as String?)?.trim() ?? '';
    final firstName = rawName.split(RegExp(r'\s+')).first;
    final isPro = (user?['tier'] as String?) == 'PRO';

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
      titleSpacing: 14,
      title: Row(
        children: [
          _Avatar(firstName: firstName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.homeTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (isPro) ...[
                      const SizedBox(width: 6),
                      const _ProBadge(),
                    ],
                  ],
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
        const _PostActionButton(),
        _ChatsIconButton(
          onTap: onOpenChats,
          tooltip: t.chats,
          light: true,
        ),
        const _OverflowMenu(),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _PostActionButton extends ConsumerWidget {
  const _PostActionButton();

  bool _isPro(dynamic user) {
    if (user == null) return false;
    final tier = user['tier'] as String?;
    if (tier != 'PRO') return false;
    final proExpiresAt = user['proExpiresAt'];
    if (proExpiresAt == null) return true;
    try {
      return DateTime.parse(proExpiresAt as String).isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isPro = _isPro(user);
    final products = ref.watch(myProductsProvider).value;

    if (products == null) return const SizedBox.shrink();

    final activeCount = products
        .whereType<Map<String, dynamic>>()
        .where((p) => p['status'] == 'AVAILABLE')
        .length;

    if (isPro) {
      return _AppBarPillButton(
        icon: Icons.add_rounded,
        label: 'Post',
        onTap: () => _openPostScreen(context, ref, products.isEmpty),
      );
    }

    if (activeCount == 0) {
      return _AppBarPillButton(
        icon: Icons.add_rounded,
        label: 'Post',
        onTap: () => _openPostScreen(context, ref, true),
      );
    }

    return _AppBarPillButton(
      icon: Icons.workspace_premium,
      label: 'PRO',
      onTap: () => showUpgradePromptSheet(
        context,
        reason: UpgradeReason.products,
      ),
    );
  }

  Future<void> _openPostScreen(
    BuildContext context,
    WidgetRef ref,
    bool isFirstProduct,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostProductScreen(isFirstProduct: isFirstProduct),
      ),
    );
    ref.invalidate(matchesProvider);
    ref.invalidate(myProductsProvider);
  }
}

class _AppBarPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppBarPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String firstName;
  const _Avatar({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final initial =
        firstName.isNotEmpty ? firstName.characters.first.toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 9, color: AppColors.primary),
          SizedBox(width: 2),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: Colors.white,
      elevation: 8,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) async {
        if (v == 'refresh') {
          ref.invalidate(incomingOffersProvider);
          ref.invalidate(outgoingOffersProvider);
          ref.refresh(matchesProvider.future);
        } else if (v == 'logout') {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              const Icon(Icons.refresh, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Text(t.refresh),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Text(t.signOut),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatsIconButton extends ConsumerWidget {
  final VoidCallback onTap;
  final String? tooltip;
  final bool light;
  const _ChatsIconButton({
    required this.onTap,
    this.tooltip,
    this.light = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingOffersProvider).value ?? [];
    final outgoing = ref.watch(outgoingOffersProvider).value ?? [];

    int pending = 0;
    for (final o in [...incoming, ...outgoing]) {
      if (o is Map && o['status'] == 'PENDING') pending++;
    }

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: light ? Colors.white : null,
          ),
          if (pending > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: light
                      ? Border.all(color: Colors.white, width: 1.2)
                      : null,
                ),
                child: Text(
                  pending > 9 ? '9+' : '$pending',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  MATCHES LIST
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
          // ── Compact header ──
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

          // ── Visible matches ──
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

          // ── Teaser section ──
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

/// Compact teaser section — badge + locked MatchCards.
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