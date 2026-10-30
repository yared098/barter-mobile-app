import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';        // ⭐ ADDED
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chapa_webview_screen.dart';
import 'package:barter_ethio/l10n/app_localizations.dart';
import '../models/plan_option.dart';
import '../providers/auth_provider.dart';                        // ⭐ ADDED
import '../services/api_service.dart';
import '../theme.dart';

Future<bool> showPremiumSheet(BuildContext context, {String? reason}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PremiumCheckoutSheet(reason: reason),
  );
  return r == true;
}

// ⭐ CHANGED: StatefulWidget → ConsumerStatefulWidget
class PremiumCheckoutSheet extends ConsumerStatefulWidget {
  final String? reason;
  const PremiumCheckoutSheet({super.key, this.reason});

  @override
  ConsumerState<PremiumCheckoutSheet> createState() =>
      _PremiumCheckoutSheetState();
}

enum _State { pick, pending, paid, failed, expired }

// ⭐ CHANGED: State → ConsumerState
class _PremiumCheckoutSheetState extends ConsumerState<PremiumCheckoutSheet> {
  final _api = ApiService();

  List<PlanOption>? _plans;
  bool _plansFromFallback = false;

  _State _state = _State.pick;
  PlanOption? _pendingPlan;
  String? _paymentId;
  String? _checkoutUrl;
  DateTime? _expiresAt;
  String _countdown = '--:--';
  String? _error;

  Timer? _pollTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final fetched = await _api.getPlans();
      if (!mounted) return;
      setState(() {
        _plans = fetched.isEmpty ? PlanOption.fallback : fetched;
        _plansFromFallback = fetched.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plans = PlanOption.fallback;
        _plansFromFallback = true;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  // ─── LOCALIZED PLAN TEXT ───────────────────────────────────────

  ({String label, String description}) _planText(
    AppLocalizations l10n,
    PlanOption p,
  ) {
    switch (p.id) {
      case 'daily_pass':
        return (label: l10n.planDailyPass, description: l10n.planDailyPassDesc);
      case 'credit_100':
        return (label: l10n.planCredit100, description: l10n.planCredit100Desc);
      case 'credit_500':
        return (label: l10n.planCredit500, description: l10n.planCredit500Desc);
      case 'credit_1000':
        return (
          label: l10n.planCredit1000,
          description: l10n.planCredit1000Desc,
        );
      case 'monthly_pro':
        return (
          label: l10n.planMonthlyPro,
          description: l10n.planMonthlyProDesc,
        );
      case 'yearly_pro':
        return (label: l10n.planYearlyPro, description: l10n.planYearlyProDesc);
      default:
        return (label: p.label, description: p.description);
    }
  }

  String? _badgeText(AppLocalizations l10n, String? key) {
    if (key == null) return null;
    switch (key) {
      case 'save_20':
        return l10n.badgeSave20;
      case 'save_16':
        return l10n.badgeSave16;
      case 'best_value':
        return l10n.badgeBestValue;
      default:
        return key;
    }
  }

  // ─── PAYMENT FLOW ──────────────────────────────────────────────

  Future<void> _startPayment(PlanOption plan) async {
    setState(() {
      _state = _State.pending;
      _pendingPlan = plan;
      _error = null;
    });

    try {
      final data = await _api.initPayment(plan.id);
      if (!mounted) return;

      setState(() {
        _paymentId = data['paymentId'] as String?;
        _checkoutUrl = data['checkoutUrl'] as String?;
        _expiresAt = DateTime.tryParse(data['expiresAt']?.toString() ?? '');
      });

      _startPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _State.failed;
        _error = e.message;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
    _tickTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());

    Future.delayed(const Duration(minutes: 15), () {
      if (!mounted) return;
      if (_state == _State.pending) {
        _stopTimers();
        setState(() => _state = _State.expired);
      }
    });
  }

  Future<void> _check() async {
    final pid = _paymentId;
    if (pid == null || !mounted) return;

    try {
      final data = await _api.getPaymentStatus(pid);
      if (!mounted) return;

      final status = data['status']?.toString() ?? 'pending';
      if (status == 'paid') {
        _stopTimers();
        setState(() => _state = _State.paid);

        // ⭐ THE FIX — refresh the current user from backend BEFORE
        // closing the sheet. Updates tier / credits / expiry in the
        // auth provider, so every screen rebuilds with the new tier.
        try {
          await ref.read(authProvider.notifier).refreshUser();
        } catch (_) {
          // Silent fail — next refresh (app resume / manual) will retry
        }

        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted && _state == _State.paid) {
            Navigator.of(context).pop(true);
          }
        });
      } else if (status == 'failed') {
        _stopTimers();
        setState(() => _state = _State.failed);
      } else if (status == 'expired') {
        _stopTimers();
        setState(() => _state = _State.expired);
      }
    } catch (_) {}
  }

  void _updateCountdown() {
    final exp = _expiresAt;
    if (exp == null) return;
    final left = exp.difference(DateTime.now());
    if (left.isNegative) {
      _stopTimers();
      if (mounted) setState(() => _state = _State.expired);
      return;
    }
    if (!mounted) return;
    setState(() {
      final m = left.inMinutes.toString().padLeft(2, '0');
      final s = (left.inSeconds % 60).toString().padLeft(2, '0');
      _countdown = '$m:$s';
    });
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
  }

  Future<void> _openCheckout() async {
    final url = _checkoutUrl;
    if (url == null || !mounted) return;

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChapaWebViewScreen(
          checkoutUrl: url,
          title: _pendingPlan?.label ?? 'Complete payment',
          subtitle: _pendingPlan != null
              ? '${_pendingPlan!.price} ${_pendingPlan!.currency}'
              : null,
        ),
      ),
    );

    if (!mounted) return;

    // WebView returned `true` → user reached return URL.
    // Trigger an immediate status check so the sheet doesn't wait 3s.
    if (completed == true) {
      await _check();
    }
    // If `false` or `null` → user cancelled. Polling keeps running
    // (webhook might still mark paid if they used another phone).
  }

  Future<void> _copyLink() async {
    final url = _checkoutUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.premiumLinkCopied),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            _buildDragHandle(),
            _buildHeader(),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 32, left: 32),
            child: Column(
              children: [
                if (_state == _State.pick) ...[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.premiumUpgradeTitle,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.reason ?? l10n.premiumPickSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ] else if (_state == _State.pending) ...[
                  Text(
                    l10n.premiumCompletePayment,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.premiumUpdatesAutomatically,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_state != _State.paid)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Material(
                color: AppColors.primaryFaint,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(false),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    switch (_state) {
      case _State.pick:
        return _buildPicker(l10n);
      case _State.pending:
        return _buildPending(l10n);
      case _State.paid:
        return _buildPaid(l10n);
      case _State.failed:
        return _buildRetry(
          l10n,
          _error ?? l10n.premiumFailedTitle,
          expired: false,
        );
      case _State.expired:
        return _buildRetry(l10n, l10n.premiumWindowExpired, expired: true);
    }
  }

  // ─── PICKER ────────────────────────────────────────────────────

  Widget _buildPicker(AppLocalizations l10n) {
    if (_plans == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    }

    final plans = _plans!;
    final dailies = plans.where((p) => p.tier == 'daily').toList();
    final credits = plans.where((p) => p.tier == 'credit').toList();
    final pros = plans.where((p) => p.tier == 'pro').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_plansFromFallback)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.premiumFallbackBanner,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        if (dailies.isNotEmpty) ...[
          _sectionLabel(l10n.premiumSectionDaily),
          for (final p in dailies) _planTile(l10n, p),
          const SizedBox(height: 18),
        ],
        if (credits.isNotEmpty) ...[
          _sectionLabel(l10n.premiumSectionCredits),
          for (final p in credits) _planTile(l10n, p),
          const SizedBox(height: 18),
        ],
        if (pros.isNotEmpty) ...[
          _sectionLabel(l10n.premiumSectionPro),
          for (final p in pros) _planTile(l10n, p),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.premiumMaybeLater,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String s) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            s.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );

  Widget _planTile(AppLocalizations l10n, PlanOption p) {
    final highlighted = p.highlighted;
    final badgeText = _badgeText(l10n, p.badgeKey);
    final text = _planText(l10n, p);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: highlighted ? AppColors.primaryLight : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _startPayment(p),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: highlighted ? AppColors.primary : AppColors.border,
                width: highlighted ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _planIcon(p.tier, highlighted: highlighted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (badgeText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? AppColors.primary
                              : AppColors.primaryMid,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: highlighted
                                ? AppColors.white
                                : AppColors.text,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '${p.price} ${p.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planIcon(String tier, {bool highlighted = false}) {
    final icon = switch (tier) {
      'daily' => Icons.today_rounded,
      'pro' => Icons.workspace_premium,
      _ => Icons.confirmation_number_outlined,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.white : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }

  // ─── PENDING ──────────────────────────────────────────────────

  Widget _buildPending(AppLocalizations l10n) {
    final isUrgent = _expiresAt != null &&
        _expiresAt!.difference(DateTime.now()).inMinutes < 2;
    final planText =
        _pendingPlan != null ? _planText(l10n, _pendingPlan!) : null;

    return Column(
      children: [
        if (_pendingPlan != null && planText != null)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planText.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        '${_pendingPlan!.price} ${_pendingPlan!.currency}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: isUrgent ? AppColors.error : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _countdown,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color:
                              isUrgent ? AppColors.error : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        if (_checkoutUrl != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: QrImageView(
              data: _checkoutUrl!,
              size: 210,
              backgroundColor: AppColors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.text,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.premiumScanWith,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.primaryFaint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _step(1, l10n.premiumStep1),
              _step(2, l10n.premiumStep2),
              _step(3, l10n.premiumStep3),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openCheckout,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(l10n.premiumOpenCheckout),
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _copyLink,
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: Text(l10n.premiumCopyLink),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.premiumWaiting,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _step(int n, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$n',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.text,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  // ─── PAID ─────────────────────────────────────────────────────

  Widget _buildPaid(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, __) => Transform.scale(
            scale: v,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 56,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.premiumPaidTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.premiumPaidSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── FAILED / EXPIRED ─────────────────────────────────────────

  Widget _buildRetry(
    AppLocalizations l10n,
    String msg, {
    required bool expired,
  }) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: (expired ? AppColors.warning : AppColors.error)
                .withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            expired ? Icons.timer_off_outlined : Icons.error_outline_rounded,
            color: expired ? AppColors.warning : AppColors.error,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          expired ? l10n.premiumExpiredTitle : l10n.premiumFailedTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() {
              _state = _State.pick;
              _error = null;
            }),
            child: Text(
              expired ? l10n.premiumChooseAnotherPlan : l10n.premiumTryAgain,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.premiumClose,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}