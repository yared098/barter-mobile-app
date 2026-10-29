import 'package:flutter/material.dart';
import 'premium_checkout_sheet.dart';

/// Legacy reasons — kept so existing callers compile.
@Deprecated('Use showPremiumSheet() from premium_checkout_sheet.dart')
enum UpgradeReason { matches, products }

/// Legacy entry point.
/// Returns `true` if the user completed a payment, `false` otherwise.
@Deprecated('Use showPremiumSheet() from premium_checkout_sheet.dart')
Future<bool> showUpgradePromptSheet(
  BuildContext context, {
  int hiddenCount = 0,
  int totalCount = 0,
  UpgradeReason reason = UpgradeReason.matches,
}) {
  final shown = totalCount - hiddenCount;
  final String? reasonText;
  switch (reason) {
    case UpgradeReason.products:
      reasonText = 'You have reached your posting limit.';
      break;
    case UpgradeReason.matches:
      reasonText = hiddenCount > 0
          ? "You're seeing $shown of $totalCount matches."
          : null;
      break;
  }
  return showPremiumSheet(context, reason: reasonText);
}