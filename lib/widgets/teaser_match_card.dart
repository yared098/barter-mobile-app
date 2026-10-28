import 'dart:ui';
import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

/// A locked "teaser" match card for FREE users.
/// Shows blurred image + rounded score + category — no title, no owner.
class TeaserMatchCard extends StatelessWidget {
  final Map<String, dynamic> teaser;
  final VoidCallback onTap;

  const TeaserMatchCard({
    super.key,
    required this.teaser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawImage = teaser['image'] as String?;
    final imageUrl = rawImage != null && rawImage.trim().isNotEmpty
        ? AppConfig.resolveImageUrl(rawImage)
        : null;

    final score = (teaser['score'] as num?)?.toInt() ?? 0;
    final categoryName = teaser['categoryName'] as String?;
    final categoryIcon = teaser['categoryIcon'] as String?;
    final value = (teaser['estimatedValue'] as num?)?.toInt();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blurred image + lock overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.primaryLight),
                        ),
                      )
                    else
                      Container(color: AppColors.primaryLight),
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Redacted text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 16,
                          margin: const EdgeInsets.only(right: 40),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$score%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (categoryName != null) ...[
                        Text(
                          '${categoryIcon ?? ''} $categoryName'.trim(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (value != null)
                        Text(
                          '~ETB $value',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.lock, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Upgrade to unlock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right,
                          size: 16, color: AppColors.primary),
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
