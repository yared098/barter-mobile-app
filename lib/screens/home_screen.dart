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
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Your matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(matchesProvider),
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
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PostProductScreen()));
          ref.invalidate(matchesProvider);
          ref.invalidate(myProductsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Post product'),
      ),
      body: matchesAsync.when(
        loading: () => const LoadingView(message: 'Finding matches...'),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(matchesProvider),
        ),
        data: (data) => _MatchesList(
          data: data,
          onRefresh: () async {
            ref.invalidate(matchesProvider);
            await ref.read(matchesProvider.future);
          },
        ),
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
    final matches = (data['matches'] as List?) ?? [];
    final total = data['totalCount'] ?? 0;
    final hidden = data['hiddenCount'] ?? 0;

    if (matches.isEmpty) {
      return const EmptyView(
        icon: Icons.explore_outlined,
        title: 'No matches yet',
        message: 'Post another product with more categories you want — matches appear here automatically.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
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
                    '$total match${total == 1 ? '' : 'es'}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (hidden > 0)
                  const Text(
                    'upgrade for more',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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

    return GestureDetector(
      // ── Tapping anywhere on the card (except the image) opens Product Detail ──
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
            // ── Image has its OWN tap handler → opens gallery ──
            // GestureDetector on the image absorbs the tap so the parent
            // onTap (open detail) doesn't fire when the image is tapped.
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
                  // "+N" badge overlay on image
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
                          p['title'] as String? ?? 'Untitled',
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
                    '${(p['condition'] as String?)?.replaceAll('_', ' ')}',
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
                      Text(
                        'From ${p['owner']?['name'] ?? 'someone'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
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
}
