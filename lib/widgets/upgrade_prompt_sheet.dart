import 'package:flutter/material.dart';
import '../theme.dart';

/// Why the upgrade sheet is being shown — changes the copy.
enum UpgradeReason { matches, products }

Future<void> showUpgradePromptSheet(
  BuildContext context, {
  int hiddenCount = 0,
  int totalCount = 0,
  UpgradeReason reason = UpgradeReason.matches,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UpgradeSheet(
      hiddenCount: hiddenCount,
      totalCount: totalCount,
      reason: reason,
    ),
  );
}

class _UpgradeSheet extends StatelessWidget {
  final int hiddenCount;
  final int totalCount;
  final UpgradeReason reason;

  const _UpgradeSheet({
    required this.hiddenCount,
    required this.totalCount,
    required this.reason,
  });

  bool get isProducts => reason == UpgradeReason.products;

  String get _title => isProducts ? 'Unlock unlimited posts' : 'Unlock all matches';

  String get _subtitle {
    if (isProducts) {
      return 'You\'ve used your 1 free listing.\n'
          'Upgrade to PRO to post unlimited products and unlock every match.';
    }
    return 'You\'re seeing 3 of $totalCount matches.\n'
        'Upgrade to PRO to unlock $hiddenCount more.';
  }

  IconData get _icon =>
      isProducts ? Icons.inventory_2_outlined : Icons.visibility_outlined;

  List<(IconData, String)> get _benefits => isProducts
      ? const [
          (Icons.add_circle_outline, 'Post unlimited products (FREE = 1)'),
          (Icons.visibility_outlined, 'See every barter match'),
          (Icons.bolt, 'Priority ranking in other users\' matches'),
        ]
      : const [
          (Icons.visibility_outlined, 'See every barter match'),
          (Icons.add_circle_outline, 'Post unlimited products (FREE = 1)'),
          (Icons.bolt, 'Priority ranking in other users\' matches'),
        ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: _benefits
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              b.$1,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b.$2,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.text,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PRO subscription coming soon — stay tuned!'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Upgrade to PRO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Maybe later',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}