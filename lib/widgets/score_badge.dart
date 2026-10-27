import 'package:flutter/material.dart';

import '../theme.dart';

class ScoreBadge extends StatelessWidget {
  final int score;

  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    // Color shifts from green → brighter green based on score
    final strength = (score / 100).clamp(0.0, 1.0);
    final color = Color.lerp(
      AppColors.primary.withValues(alpha: 0.7),
      AppColors.primary,
      strength,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score%',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}
