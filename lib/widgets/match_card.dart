import 'dart:ui';
import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import 'score_badge.dart';

// ═══════════════════════════════════════════════════════
//  UNIFIED DATA MODEL
// ═══════════════════════════════════════════════════════

class MatchCardData {
  final String? imageUrl;
  final List<String> allImages;
  final int score;

  // Unlocked-only
  final String? title;
  final String? subtitle;
  final String? reason;
  final String? owner;

  // Locked-only
  final String? categoryLabel;
  final String? valueLabel;

  const MatchCardData({
    this.imageUrl,
    this.allImages = const [],
    required this.score,
    this.title,
    this.subtitle,
    this.reason,
    this.owner,
    this.categoryLabel,
    this.valueLabel,
  });

  factory MatchCardData.fromMatch(
    Map<String, dynamic> match, {
    required String Function(String? raw) conditionLabel,
    required String Function(String name) fromPerson,
  }) {
    final p = match['product'] as Map<String, dynamic>;
    final rawImages = (p['images'] as List?) ?? [];
    final images = rawImages
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .map(AppConfig.resolveImageUrl)
        .where((s) => s.isNotEmpty)
        .toList();

    final value = (p['estimatedValue'] as num?)?.toDouble() ?? 0;
    final condition = conditionLabel(p['condition'] as String?);
    final reasons = (match['reasons'] as List?)?.cast<String>() ?? [];
    final ownerName = p['owner']?['name'] as String? ?? '—';

    return MatchCardData(
      imageUrl: images.isNotEmpty ? images.first : null,
      allImages: images,
      score: (match['score'] as num).toInt(),
      title: p['title'] as String?,
      subtitle: 'ETB ${value.toStringAsFixed(0)} · $condition',
      reason: reasons.isNotEmpty ? reasons.first : null,
      owner: fromPerson(ownerName),
    );
  }

  factory MatchCardData.fromTeaser(Map<String, dynamic> teaser) {
    final rawImage = teaser['image'] as String?;
    final imageUrl = rawImage != null && rawImage.trim().isNotEmpty
        ? AppConfig.resolveImageUrl(rawImage)
        : null;

    final categoryName = teaser['categoryName'] as String?;
    final categoryIcon = teaser['categoryIcon'] as String?;
    final value = (teaser['estimatedValue'] as num?)?.toInt();

    return MatchCardData(
      imageUrl: imageUrl,
      score: (teaser['score'] as num?)?.toInt() ?? 0,
      categoryLabel: categoryName != null
          ? '${categoryIcon ?? ''} $categoryName'.trim()
          : null,
      valueLabel: value != null ? '~ ETB $value' : null,
    );
  }
}

// ═══════════════════════════════════════════════════════
//  UNIFIED CARD
// ═══════════════════════════════════════════════════════

class MatchCard extends StatelessWidget {
  final MatchCardData data;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onImageTap;
  final String unlockLabel;
  final String hiddenLabel;

  const MatchCard({
    super.key,
    required this.data,
    required this.onTap,
    this.locked = false,
    this.onImageTap,
    this.unlockLabel = 'Unlock with PRO',
    this.hiddenLabel = 'HIDDEN',
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: primary.withValues(alpha: 0.08),
          highlightColor: primary.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primary.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildImage(primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: _buildBody(primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  IMAGE
  // ─────────────────────────────────────────────────
  Widget _buildImage(Color primary) {
    final image = SizedBox(
      width: locked ? 76 : 72,
      height: locked ? 80 : 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (data.imageUrl != null)
            locked
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Image.network(
                      data.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(primary),
                    ),
                  )
                : Image.network(
                    data.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(primary),
                  )
          else
            _imageFallback(primary),

          // Lock overlay + centered lock only in locked mode
          if (locked) ...[
            Container(color: Colors.black.withValues(alpha: 0.22)),
            const Center(
              child: Icon(Icons.lock_rounded, color: Colors.white, size: 23),
            ),
          ],

          // Photo count badge (unlocked, >1 image)
          if (!locked && data.allImages.length > 1)
            Positioned(
              bottom: 3,
              right: 3,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 9,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${data.allImages.length}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Score pill on image — ONLY in locked mode
          if (locked)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${data.score}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: primary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: onImageTap != null && !locked
          ? GestureDetector(
              onTap: onImageTap,
              behavior: HitTestBehavior.opaque,
              child: image,
            )
          : image,
    );
  }

  Widget _imageFallback(Color primary) => Container(
        color: primary.withValues(alpha: 0.08),
        child: Icon(Icons.swap_horiz_rounded, color: primary, size: 26),
      );

  // ─────────────────────────────────────────────────
  //  BODY
  // ─────────────────────────────────────────────────
  List<Widget> _buildBody(Color primary) {
    return [
      // Title row + score badge (unlocked) OR hidden badge (locked)
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: locked
                ? _skeleton(height: 13)
                : Text(
                    data.title ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.25,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          if (locked) _hiddenBadge(primary) else ScoreBadge(score: data.score),
        ],
      ),
      const SizedBox(height: 5),

      // Subtitle / skeleton
      locked
          ? _skeleton(height: 10, width: 140)
          : Text(
              data.subtitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),

      // Extra row
      if (locked && (data.categoryLabel != null || data.valueLabel != null))
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: _categoryRow(primary),
        )
      else if (!locked && data.reason != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: _reasonChip(primary),
        ),

      const SizedBox(height: 8),

      // Bottom row
      locked ? _unlockRow(primary) : _ownerRow(primary),
    ];
  }

  Widget _categoryRow(Color primary) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (data.categoryLabel != null)
          Container(
            constraints: const BoxConstraints(maxWidth: 145),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              data.categoryLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (data.valueLabel != null)
          Text(
            data.valueLabel!,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _reasonChip(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 10, color: primary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              data.reason!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerRow(Color primary) {
    return Row(
      children: [
        Expanded(
          child: Text(
            data.owner ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chevron_right, size: 14, color: primary),
        ),
      ],
    );
  }

  Widget _unlockRow(Color primary) {
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded, size: 13, color: primary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            unlockLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
        Icon(
          Icons.arrow_forward_rounded,
          size: 15,
          color: primary.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  Widget _hiddenBadge(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: primary.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 9, color: primary),
          const SizedBox(width: 3),
          Text(
            hiddenLabel,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}