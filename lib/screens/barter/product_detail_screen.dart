import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/offers_provider.dart';
import '../../theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/image_gallery.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/send_offer_sheet.dart';

/// Public product detail — fetched by id.
final productDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiProvider);
  return api.getProduct(id);
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  final int? matchScore;
  final List<String>? matchReasons;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.matchScore,
    this.matchReasons,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(t.productTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.refresh,
            onPressed: () => ref.invalidate(productDetailProvider(productId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) => _Body(
          product: product,
          matchScore: matchScore,
          matchReasons: matchReasons,
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  final int? matchScore;
  final List<String>? matchReasons;

  const _Body({required this.product, this.matchScore, this.matchReasons});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _sendOffer(AppLocalizations t) async {
    final sent = await showSendOfferSheet(
      context,
      targetProduct: widget.product,
    );
    if (sent == true && mounted) {
      ref.invalidate(matchesProvider);
      ref.invalidate(incomingOffersProvider);
      ref.invalidate(outgoingOffersProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.offerSent),
          backgroundColor: AppColors.primary,
        ),
      );
    }
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

  String _statusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'AVAILABLE':
        return t.available;
      case 'PENDING':
        return t.pending;
      case 'SWAPPED':
        return t.swapped;
      case 'ACCEPTED':
        return t.accepted;
      case 'COMPLETED':
        return t.completed;
      case 'DECLINED':
        return t.declined;
      case 'CANCELLED':
        return t.cancelled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = widget.product;
    final images = ((p['images'] as List?) ?? [])
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .map((s) => AppConfig.resolveImageUrl(s))
        .where((s) => s.isNotEmpty)
        .toList();
    final status = p['status'] as String? ?? 'AVAILABLE';
    final isAvailable = status == 'AVAILABLE';
    final category = p['category'] as Map<String, dynamic>?;
    final owner = p['owner'] as Map<String, dynamic>?;
    final wants = (p['wants'] as List?) ?? [];
    final conditionLabel = _conditionLabel(p['condition'] as String?, t);
    final statusLabel = _statusLabel(status, t);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image carousel ──
          _ImageCarousel(
            images: images,
            pageController: _pageController,
            currentIndex: _currentImageIndex,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            onTapImage: (i) =>
                showImageGallery(context, images: images, initialIndex: i),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Match score badge ──
                if (widget.matchScore != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.matchPercentBadge(widget.matchScore!),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.matchReasons?.isNotEmpty == true)
                        Expanded(
                          child: Text(
                            widget.matchReasons!.first,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Title ──
                Text(
                  p['title'] as String? ?? t.untitled,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Price + condition + status ──
                Row(
                  children: [
                    Text(
                      'ETB ${(p['estimatedValue'] as num).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        conditionLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // ── Category ──
                if (category != null) ...[
                  _sectionTitle(t.categoryLabel),
                  Text(
                    '${category['icon'] ?? ''} ${category['name'] ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Description ──
                _sectionTitle(t.description),
                Text(
                  p['description'] as String? ?? t.noDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Wants ──
                if (wants.isNotEmpty) ...[
                  _sectionTitle(t.ownerWantsInExchange),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: wants.map((w) {
                      final wm = w as Map<String, dynamic>;
                      final cat = wm['category'] as Map<String, dynamic>?;
                      final kw = wm['keywords'] as String?;
                      final label =
                          '${cat?['icon'] ?? ''} ${cat?['name'] ?? t.categoryFallback}'
                              .trim();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (kw != null && kw.isNotEmpty)
                              Text(
                                t.lookingFor(kw),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Owner ──
                if (owner != null) ...[
                  _sectionTitle(t.listedBy),
                  Text(
                    owner['name'] as String? ?? t.someone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Send offer ──
                if (isAvailable) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendOffer(t),
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(t.sendOffer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      t.productUnavailable(statusLabel),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════
//  Image carousel (unchanged — no UI strings)
// ═══════════════════════════════════════════════════════

class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTapImage;

  const _ImageCarousel({
    required this.images,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onTapImage,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 240,
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(
            Icons.inventory_2_outlined,
            color: AppColors.primary,
            size: 56,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 320,
          child: Stack(
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: images.length,
                onPageChanged: onPageChanged,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => onTapImage(i),
                  child: Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.primaryLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == currentIndex
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              ),
            ),
          ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = i == currentIndex;
                  return GestureDetector(
                    onTap: () {
                      pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryLight,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}