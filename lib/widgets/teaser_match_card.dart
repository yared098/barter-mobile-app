import 'package:barter_ethio/l10n/app_localizations.dart';
import 'package:barter_ethio/providers/offers_provider.dart';
import 'package:barter_ethio/screens/chats_screen.dart';
import 'package:barter_ethio/screens/product_detail_screen.dart';
import 'package:barter_ethio/widgets/image_gallery.dart';
import 'package:barter_ethio/widgets/network_product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/match_card.dart';
import '../widgets/upgrade_prompt_sheet.dart';
import '../config.dart';
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

// ─── (unchanged) AppBar / avatar / pro badge / overflow / chats icon ───
// Copy the existing _HomeAppBar, _PostActionButton, _AppBarPillButton,
// _Avatar, _ProBadge, _OverflowMenu, _ChatsIconButton from your current
// file — nothing there needs to change.
// ... [keep them exactly as-is] ...

// ═══════════════════════════════════════════════════════
//  MATCHES LIST  → now uses the unified MatchCard
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
          // Compact header (unchanged)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            horizontal: 8, vertical: 4),
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

          // ─── VISIBLE MATCHES ───
          ...matches.map((m) {
            final match = m as Map<String, dynamic>;
            final p = match['product'] as Map<String, dynamic>;
            final score = (match['score'] as num).toInt();
            final reasons =
                (match['reasons'] as List?)?.cast<String>() ?? [];

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

          // ─── TEASER SECTION ───
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

// ═══════════════════════════════════════════════════════
//  TEASER SECTION  → now uses the unified MatchCard(locked: true)
// ═══════════════════════════════════════════════════════

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

        // Locked cards — one line each
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