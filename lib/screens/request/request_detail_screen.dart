import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_detail_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/requests_provider.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_detail_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/offers_provider.dart';   // ← ADD THIS
import '../providers/products_provider.dart';
import '../providers/requests_provider.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _busy = false;

  AppLocalizations get _t => AppLocalizations.of(context)!;

  Future<void> _respond() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReplySheet(requestId: widget.requestId),
    );
    if (result == true) {
      ref.invalidate(requestDetailProvider(widget.requestId));
      _snack(_t.replySentSuccess);
    }
  }

  Future<void> _accept(String replyId) async {
    final t = _t;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t.acceptThisReply),
            content: Text(t.acceptReplyBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  t.accept,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(requestsServiceProvider)
          .acceptReply(widget.requestId, replyId);

      ref.invalidate(requestDetailProvider(widget.requestId));
      ref.invalidate(wantedFeedProvider('mine'));
      ref.invalidate(incomingOffersProvider);   // ← NEW
      ref.invalidate(outgoingOffersProvider);   // ← NEW
      ref.invalidate(allChatsProvider);         // ← NEW


      if (!mounted) return;

      final offerId = result['offerId'] as String?;
      if (offerId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(offerId: offerId),
          ),
        );
      } else {
        _snack(t.replyAcceptedSuccess);
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(String replyId) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(requestsServiceProvider)
          .withdrawReply(widget.requestId, replyId);
      ref.invalidate(requestDetailProvider(widget.requestId));
      _snack(_t.replyWithdrawn);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final async = ref.watch(requestDetailProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          t.request,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16.5,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: async.when(
        loading: () => LoadingView(message: t.loading),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(requestDetailProvider(widget.requestId)),
        ),
        data: (r) {
  // ── Robust flag resolution ──
  // Prefer backend flags. Fall back to comparing IDs directly
  // if the backend is a stale version that doesn't return them yet.
  final me = ref.read(authProvider).user?['id'] as String?;
  final author = r['author'] as Map<String, dynamic>?;
  final authorId = r['authorId'] as String? ?? author?['id'] as String?;

  final responses = (r['responses'] as List?) ?? [];
  final status = r['status'] as String? ?? 'OPEN';

  final isAuthor = (r['isAuthor'] as bool?) ??
      (me != null && me == authorId);

  final canRespond = (r['canRespond'] as bool?) ??
      (!isAuthor && status == 'OPEN' && responses.isEmpty);

  final canAccept = (r['canAccept'] as bool?) ??
      (isAuthor && status == 'OPEN' && responses.isNotEmpty);

  // ── Debug log (remove after verifying) ──
  // ignore: avoid_print
  print('[RequestDetail] me=$me authorId=$authorId '
      'isAuthor=$isAuthor canRespond=$canRespond canAccept=$canAccept '
      'responses=${responses.length} status=$status');

  return RefreshIndicator(
    color: AppColors.primary,
    onRefresh: () async {
      ref.invalidate(requestDetailProvider(widget.requestId));
      await ref.read(requestDetailProvider(widget.requestId).future);
    },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _headerCard(r),
                const SizedBox(height: 14),

                // ── Non-author: Respond button ──
                if (canRespond) ...[
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _respond,
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: Text(
                      t.respondToRequest,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],

                // ── Author: reply list with Accept ──
                if (isAuthor) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.inbox_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          canAccept
                              ? t.pickBestOffer
                              : t.replyCount(responses.length),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (responses.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${responses.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (responses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_empty,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.noRepliesPullToRefresh,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...responses.map((raw) {
                      final rep = raw as Map<String, dynamic>;
                      return _ReplyTile(
                        reply: rep,
                        isAuthorView: true,
                        busy: _busy,
                        onAccept: () => _accept(rep['id'] as String),
                        onWithdraw: () {},
                      );
                    }),
                ],

                // ── Non-author: own reply ──
                if (!isAuthor && responses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    t.yourReply,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...responses.map((raw) {
                    final rep = raw as Map<String, dynamic>;
                    return _ReplyTile(
                      reply: rep,
                      isAuthorView: false,
                      busy: _busy,
                      onAccept: () {},
                      onWithdraw: () => _withdraw(rep['id'] as String),
                    );
                  }),
                ],

                // ── Closed banner ──
                if (status == 'CLOSED') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.replyAcceptedBanner,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerCard(Map<String, dynamic> r) {
    final t = _t;
    final primary = AppColors.primary;
    final author = r['author'] as Map<String, dynamic>?;
    final authorName = (author?['name'] as String?) ?? t.someone;
    final title = r['title'] as String? ?? '—';
    final desc = r['description'] as String? ?? '';
    final status = r['status'] as String? ?? 'OPEN';
    final type = r['type'] as String? ?? 'BUY';
    final location = r['location'] as String?;
    final budgetMin = (r['budgetMin'] as num?)?.toDouble();
    final budgetMax = (r['budgetMax'] as num?)?.toDouble();
    final specs = (r['specifications'] as Map?) ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(status, t),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _typeLabel(type, t),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  t.postedBy(authorName),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.3,
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
          if (specs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: specs.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (budgetMin != null || budgetMax != null) ...[
                Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _budgetLabel(t, budgetMin, budgetMax),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
              if ((budgetMin != null || budgetMax != null) &&
                  location != null)
                const SizedBox(width: 12),
              if (location != null) ...[
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _budgetLabel(AppLocalizations t, double? min, double? max) {
    if (min != null && max != null) {
      return t.etbRange(
        min.toStringAsFixed(0),
        max.toStringAsFixed(0),
      );
    }
    if (min != null) return t.etbMinPlus(min.toStringAsFixed(0));
    return t.etbUpTo(max!.toStringAsFixed(0));
  }

  String _statusLabel(String s, AppLocalizations t) {
    switch (s) {
      case 'OPEN':
        return t.statusOpen;
      case 'CLOSED':
        return t.statusClosed;
      case 'FULFILLED':
        return t.statusFulfilled;
      case 'EXPIRED':
        return t.statusExpired;
      case 'CANCELLED':
        return t.statusCancelled;
      default:
        return s;
    }
  }

  String _typeLabel(String s, AppLocalizations t) {
    switch (s) {
      case 'BUY':
        return t.cash;
      case 'BARTER':
        return t.barter;
      case 'EITHER':
        return t.either;
      default:
        return s;
    }
  }
}

// ═══════════════════════════════════════════════════════
//  REPLY TILE
// ═══════════════════════════════════════════════════════

class _ReplyTile extends StatelessWidget {
  final Map<String, dynamic> reply;
  final bool isAuthorView;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onWithdraw;

  const _ReplyTile({
    required this.reply,
    required this.isAuthorView,
    required this.busy,
    required this.onAccept,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final primary = AppColors.primary;
    final responder = reply['responder'] as Map<String, dynamic>?;
    final responderName = (responder?['name'] as String?) ?? t.someone;
    final message = reply['message'] as String? ?? '';
    final status = reply['status'] as String? ?? 'PENDING';
    final product = reply['product'] as Map<String, dynamic>?;
    final price = (reply['offeredPrice'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'ACCEPTED'
              ? const Color(0xFF2E7D32)
              : primary.withValues(alpha: 0.12),
          width: status == 'ACCEPTED' ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  responderName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (price != null)
                Text(
                  t.etbAmount(price.toStringAsFixed(0)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              const SizedBox(width: 6),
              if (status != 'PENDING')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (status == 'ACCEPTED'
                            ? const Color(0xFF2E7D32)
                            : AppColors.textMuted)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _replyStatusLabel(status, t),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: status == 'ACCEPTED'
                          ? const Color(0xFF2E7D32)
                          : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          if (product != null) ...[
            const SizedBox(height: 4),
            Text(
              t.offers(product['title'] ?? '—'),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.4,
            ),
          ),
          if (status == 'PENDING') ...[
            const SizedBox(height: 10),
            if (isAuthorView)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onAccept,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(
                          color: primary.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size.fromHeight(36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        t.accept,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onWithdraw,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        t.withdrawMyReply,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  String _replyStatusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'PENDING':
        return t.replyPendingStatus;
      case 'ACCEPTED':
        return t.replyAcceptedStatus;
      case 'REJECTED':
        return t.replyRejectedStatus;
      case 'WITHDRAWN':
        return t.replyWithdrawnStatus;
      default:
        return status;
    }
  }
}

// ═══════════════════════════════════════════════════════
//  REPLY SHEET
// ═══════════════════════════════════════════════════════

class _ReplySheet extends ConsumerStatefulWidget {
  final String requestId;
  const _ReplySheet({required this.requestId});

  @override
  ConsumerState<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends ConsumerState<_ReplySheet> {
  final _msgCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _productId;
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(requestsServiceProvider).reply(
            widget.requestId,
            message: msg,
            productId: _productId,
            offeredPrice: double.tryParse(_priceCtrl.text.trim()),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(myProductsProvider);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + viewInsets,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.replyToRequest,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.requesterWillBeNotified,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                t.attachProductOptional,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              productsAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) {
                  final items = (list ?? [])
                      .whereType<Map<String, dynamic>>()
                      .where((p) => p['status'] == 'AVAILABLE')
                      .toList();
                  if (items.isEmpty) {
                    return Text(
                      t.noAvailableProductsMessage,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map((p) {
                      final id = p['id'] as String;
                      final title = p['title'] as String? ?? '—';
                      final selected = _productId == id;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _productId = selected ? null : id;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.primary
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: t.askPriceOptional,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.primaryLight.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _msgCtrl,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: t.replyMessageHint,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.primaryLight.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t.sendReply,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}