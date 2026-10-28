import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../providers/api_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/offers_provider.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/image_gallery.dart';
import '../widgets/loading_view.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String offerId;
  const ChatDetailScreen({super.key, required this.offerId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _actionLoading = false;
  Timer? _pollTimer;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(offerDetailProvider(widget.offerId));
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final api = ref.read(apiProvider);
      await api.sendOfferMessage(widget.offerId, text);
      _msgCtrl.clear();
      ref.invalidate(offerDetailProvider(widget.offerId));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

  Future<void> _doAction(String action) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _actionLoading = true);
    try {
      final api = ref.read(apiProvider);
      await api.offerAction(widget.offerId, action);
      ref.invalidate(offerDetailProvider(widget.offerId));
      ref.invalidate(incomingOffersProvider);
      ref.invalidate(outgoingOffersProvider);
      ref.invalidate(allChatsProvider);

      if (!mounted) return;
      final label = {
            'accept': t.offerAccepted,
            'decline': t.offerDeclined,
            'cancel': t.offerCancelled,
            'complete': t.swapCompleted,
          }[action] ??
          action;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<bool> _confirmAction(String title, String message) async {
    final t = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  t.confirm,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(offerDetailProvider(widget.offerId));
    final currentUserId = ref.watch(authProvider).user?['id'] as String?;

    ref.listen(offerDetailProvider(widget.offerId), (prev, next) {
      if (next.hasValue) {
        final msgs = (next.value?['messages'] as List?) ?? [];
        if (msgs.length > _lastMessageCount) {
          _lastMessageCount = msgs.length;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(animate: prev != null),
          );
        }
      }
    });

    // Extract chat header info (for AppBar)
    String otherName = t.chats;
    String otherInitial = '?';
    String status = 'PENDING';
    async.whenData((offer) {
      final isIncoming = offer['receiverId'] == currentUserId;
      final other = isIncoming ? offer['sender'] : offer['receiver'];
      final name = (other is Map ? other['name'] : null) as String?;
      if (name != null && name.trim().isNotEmpty) {
        otherName = name.trim();
        otherInitial = otherName.characters.first.toUpperCase();
      }
      status = offer['status'] as String? ?? 'PENDING';
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7), // very light neutral
      appBar: _ChatAppBar(
        title: otherName,
        initial: otherInitial,
        status: status,
        t: t,
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(offerDetailProvider(widget.offerId)),
        ),
        data: (offer) => _buildBody(offer, currentUserId, t),
      ),
    );
  }

  Widget _buildBody(
    Map<String, dynamic> offer,
    String? currentUserId,
    AppLocalizations t,
  ) {
    final amISender = offer['senderId'] == currentUserId;
    final amIReceiver = offer['receiverId'] == currentUserId;
    final status = offer['status'] as String? ?? 'PENDING';

    final myProduct =
        amISender ? offer['offeredProduct'] : offer['requestedProduct'];
    final theirProduct =
        amISender ? offer['requestedProduct'] : offer['offeredProduct'];

    final messages = (offer['messages'] as List?) ?? [];
    final chatClosed =
        ['COMPLETED', 'DECLINED', 'CANCELLED'].contains(status);

    return Column(
      children: [
        _ProductPairHeader(
          myProduct: myProduct,
          theirProduct: theirProduct,
          status: status,
        ),
        _buildActions(status, amISender, amIReceiver, t),
        Expanded(
          child: messages.isEmpty
              ? _emptyChat(t)
              : _buildMessageList(messages, currentUserId, t),
        ),
        if (!chatClosed) _buildInput(t),
        if (chatClosed) _closedNotice(status, t),
      ],
    );
  }

  Widget _buildMessageList(
    List messages,
    String? currentUserId,
    AppLocalizations t,
  ) {
    // Build items with optional date separators
    final items = <Widget>[];
    DateTime? previousDate;

    for (var i = 0; i < messages.length; i++) {
      final m = messages[i] as Map<String, dynamic>;

      DateTime? dt;
      final raw = m['createdAt'];
      if (raw is String) {
        try {
          dt = DateTime.parse(raw).toLocal();
        } catch (_) {}
      }

      // Date separator
      if (dt != null) {
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        if (previousDate == null ||
            !(previousDate.year == dateOnly.year &&
                previousDate.month == dateOnly.month &&
                previousDate.day == dateOnly.day)) {
          items.add(_DateSeparator(date: dt, t: t));
          previousDate = dateOnly;
        }
      }

      final mine = m['senderId'] == currentUserId ||
          (m['sender'] is Map &&
              (m['sender'] as Map)['id'] == currentUserId);
      final senderName =
          (m['sender'] is Map ? (m['sender'] as Map)['name'] : null)
                  as String? ??
              t.someone;
      final content = m['content'] as String? ?? '';

      items.add(_MessageBubble(
        content: content,
        mine: mine,
        senderName: senderName,
        time: dt,
      ));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _buildActions(
    String status,
    bool amISender,
    bool amIReceiver,
    AppLocalizations t,
  ) {
    if (_actionLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (status == 'PENDING' && amIReceiver) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await _confirmAction(
                    t.declineOfferConfirmTitle,
                    t.declineOfferConfirmMessage,
                  );
                  if (ok) _doAction('decline');
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(t.declineOffer),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final ok = await _confirmAction(
                    t.acceptOfferConfirmTitle,
                    t.acceptOfferConfirmMessage,
                  );
                  if (ok) _doAction('accept');
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(t.acceptOffer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'PENDING' && amISender) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: OutlinedButton.icon(
          onPressed: () async {
            final ok = await _confirmAction(
              t.cancelOfferConfirmTitle,
              t.cancelOfferConfirmMessage,
            );
            if (ok) _doAction('cancel');
          },
          icon: const Icon(Icons.close_rounded, size: 16),
          label: Text(t.cancelOffer),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            side: const BorderSide(color: AppColors.border, width: 1.2),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (status == 'ACCEPTED') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: ElevatedButton.icon(
          onPressed: () async {
            final ok = await _confirmAction(
              t.completeSwapConfirmTitle,
              t.completeSwapConfirmMessage,
            );
            if (ok) _doAction('complete');
          },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: Text(t.completeSwap),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _emptyChat(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              t.noMessagesYet,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.sayHi,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(AppLocalizations t) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(fontSize: 14.5, height: 1.35),
                decoration: InputDecoration(
                  hintText: t.replyMessageHint,
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _sending
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _closedNotice(String status, AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: 14 + MediaQuery.of(context).viewPadding.bottom,
      ),
      color: AppColors.primaryLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == 'COMPLETED'
                ? Icons.check_circle_outline
                : Icons.lock_outline,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status == 'COMPLETED'
                  ? t.chatClosedCompleted
                  : t.chatClosedOther(_statusLabel(status, t)),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'PENDING':
        return t.pending;
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
}

// ═══════════════════════════════════════════════════════
//  CHAT APP BAR — gradient + avatar + status subtitle
// ═══════════════════════════════════════════════════════

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String initial;
  final String status;
  final AppLocalizations t;

  const _ChatAppBar({
    required this.title,
    required this.initial,
    required this.status,
    required this.t,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final darkPrimary =
        Color.lerp(AppColors.primary, Colors.black, 0.18) ?? AppColors.primary;

    return AppBar(
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, darkPrimary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                _MiniStatusPill(status: status, t: t),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  final String status;
  final AppLocalizations t;

  const _MiniStatusPill({required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    late String label;
    switch (status) {
      case 'PENDING':
        label = t.pending;
        break;
      case 'ACCEPTED':
        label = t.accepted;
        break;
      case 'COMPLETED':
        label = t.completed;
        break;
      case 'DECLINED':
        label = t.declined;
        break;
      case 'CANCELLED':
        label = t.cancelled;
        break;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PRODUCT PAIR HEADER — "you give → you get" card
// ═══════════════════════════════════════════════════════

class _ProductPairHeader extends StatelessWidget {
  final dynamic myProduct;
  final dynamic theirProduct;
  final String status;

  const _ProductPairHeader({
    required this.myProduct,
    required this.theirProduct,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final primary = AppColors.primary;

    final myImages =
        (myProduct is Map ? myProduct['images'] : null) as List? ?? [];
    final theirImages =
        (theirProduct is Map ? theirProduct['images'] : null) as List? ?? [];

    final myImageUrl = myImages.isNotEmpty
        ? AppConfig.resolveImageUrl(myImages.first.toString())
        : null;
    final theirImageUrl = theirImages.isNotEmpty
        ? AppConfig.resolveImageUrl(theirImages.first.toString())
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // YOU GIVE
          Expanded(
            child: _ProductMini(
              label: t.youGive,
              title: (myProduct is Map ? myProduct['title'] : null) as String?,
              imageUrl: myImageUrl,
              allImages: myImages.whereType<String>().toList(),
              t: t,
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: primary,
              ),
            ),
          ),
          // YOU GET
          Expanded(
            child: _ProductMini(
              label: t.youGet,
              title:
                  (theirProduct is Map ? theirProduct['title'] : null)
                      as String?,
              imageUrl: theirImageUrl,
              allImages: theirImages.whereType<String>().toList(),
              t: t,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductMini extends StatelessWidget {
  final String label;
  final String? title;
  final String? imageUrl;
  final List<String> allImages;
  final AppLocalizations t;
  final bool highlight;

  const _ProductMini({
    required this.label,
    required this.title,
    required this.imageUrl,
    required this.allImages,
    required this.t,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return GestureDetector(
      onTap: allImages.isEmpty
          ? null
          : () => showImageGallery(
                context,
                images: allImages.map(AppConfig.resolveImageUrl).toList(),
              ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 42,
              height: 42,
              color: primary.withValues(alpha: 0.08),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      color: primary,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: primary.withValues(alpha: 0.75),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title ?? t.product,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        highlight ? FontWeight.w700 : FontWeight.w600,
                    color: highlight ? primary : AppColors.text,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  DATE SEPARATOR
// ═══════════════════════════════════════════════════════

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final AppLocalizations t;

  const _DateSeparator({required this.date, required this.t});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    String label;

    final diff = today.difference(d).inDays;
    if (diff == 0) {
      label = t.timeNow;
    } else if (diff == 1) {
      label = '${t.timeDays(1)}';
    } else if (diff < 7) {
      label = t.timeDays(diff);
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  MESSAGE BUBBLE — tails + timestamps inside
// ═══════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool mine;
  final String senderName;
  final DateTime? time;

  const _MessageBubble({
    required this.content,
    required this.mine,
    required this.senderName,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine
              ? null
              : Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1,
                ),
          boxShadow: mine
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: mine ? AppColors.white : AppColors.text,
              ),
            ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(time!),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: mine
                            ? AppColors.white.withValues(alpha: 0.75)
                            : AppColors.textMuted,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all_rounded,
                        size: 11,
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}