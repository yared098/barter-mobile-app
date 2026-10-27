import 'package:barter_ethio/l10n/app_localizations.dart';
import 'package:barter_ethio/providers/offers_provider.dart';
import 'package:barter_ethio/screens/chats_screen.dart';
import 'package:barter_ethio/screens/product_detail_screen.dart';
import 'package:barter_ethio/widgets/image_gallery.dart';
import 'package:barter_ethio/widgets/network_product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../providers/matches_provider.dart';
import '../providers/products_provider.dart';
import '../theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/score_badge.dart';
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
      appBar: AppBar(
        title: Text(t.homeTitle),
        actions: [
          _ChatsIconButton(
            tooltip: t.chats,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.refresh,
            onPressed: () {
              ref.invalidate(incomingOffersProvider);
              ref.invalidate(outgoingOffersProvider);
              ref.refresh(matchesProvider.future);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
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
              PopupMenuItem(value: 'logout', child: Text(t.signOut)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PostProductScreen()),
          );
          ref.invalidate(matchesProvider);
          ref.invalidate(myProductsProvider);
        },
        icon: const Icon(Icons.add),
        label: Text(t.postProduct),
      ),
      body: matchesAsync.when(
        // 🔑 THE FIX — keep old data visible during refresh so the
        // RefreshIndicator can animate smoothly without a loading flash.
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

/// Chats icon with a badge showing the number of pending offers.
class _ChatsIconButton extends ConsumerWidget {
  final VoidCallback onTap;
  final String? tooltip;
  const _ChatsIconButton({required this.onTap, this.tooltip});

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
          const Icon(Icons.chat_bubble_outline),
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

class _MatchesList extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  const _MatchesList({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final matches = (data['matches'] as List?) ?? [];
    final total = data['totalCount'] ?? 0;
    final hidden = data['hiddenCount'] ?? 0;

    if (matches.isEmpty) {
      return EmptyView(
        icon: Icons.explore_outlined,
        title: t.noMatchesYet,
        message: t.noMatchesMessage,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        // Always scrollable so pull-to-refresh works even with 1 item
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t.matchesCount(total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (hidden > 0)
                  Text(
                    t.upgradeForMore,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          ...matches.map((m) => _MatchCard(match: m)),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = match['product'] as Map<String, dynamic>;

    // Build absolute URLs for ALL images
    final rawImages = (p['images'] as List?) ?? [];
    final fullImageUrls = rawImages
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .map((s) => AppConfig.resolveImageUrl(s))
        .where((s) => s.isNotEmpty)
        .toList();

    final firstImage = fullImageUrls.isNotEmpty ? fullImageUrls.first : null;
    final score = (match['score'] as num).toInt();
    final reasons = (match['reasons'] as List?)?.cast<String>() ?? [];

    // Localized condition label
    final conditionLabel = _conditionLabel(p['condition'] as String?, t);

    return GestureDetector(
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (own tap → gallery) ──
            GestureDetector(
              onTap: firstImage != null
                  ? () => showImageGallery(
                        context,
                        images: fullImageUrls,
                        initialIndex: 0,
                      )
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  NetworkProductImage(
                    url: firstImage,
                    width: 88,
                    height: 88,
                    radius: 12,
                  ),
                  if (fullImageUrls.length > 1)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${fullImageUrls.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['title'] as String? ?? '—',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScoreBadge(score: score),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ETB ${(p['estimatedValue'] as num).toStringAsFixed(0)} · '
                    '$conditionLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: reasons.take(2).map((r) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.fromPerson(
                            p['owner']?['name'] as String? ?? '—',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}