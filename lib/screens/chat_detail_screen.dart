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
      }[action] ?? action;
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

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: async.maybeWhen(
          data: (offer) {
            final isIncoming = offer['receiverId'] == currentUserId;
            final other = isIncoming ? offer['sender'] : offer['receiver'];
            final name = (other is Map ? other['name'] : null) as String?;
            return Text(name ?? t.chats);
          },
          orElse: () => Text(t.chats),
        ),
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
    final chatClosed = ['COMPLETED', 'DECLINED', 'CANCELLED'].contains(status);

    return Column(
      children: [
        _ProductPairHeader(
          myProduct: myProduct,
          theirProduct: theirProduct,
          status: status,
        ),
        _buildActions(status, amISender, amIReceiver, t),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: messages.isEmpty
              ? _emptyChat(t)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i] as Map<String, dynamic>;
                    final mine =
                        m['senderId'] == currentUserId ||
                        (m['sender'] is Map &&
                            (m['sender'] as Map)['id'] == currentUserId);
                    final senderName =
                        (m['sender'] is Map
                                ? (m['sender'] as Map)['name']
                                : null) as String? ??
                        t.someone;
                    final content = m['content'] as String? ?? '';
                    DateTime? time;
                    final raw = m['createdAt'];
                    if (raw is String) {
                      try {
                        time = DateTime.parse(raw).toLocal();
                      } catch (_) {}
                    }
                    return _MessageBubble(
                      content: content,
                      mine: mine,
                      senderName: senderName,
                      time: time,
                    );
                  },
                ),
        ),
        if (!chatClosed) _buildInput(t),
        if (chatClosed) _closedNotice(status, t),
      ],
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

    if (status == 'PENDING') {
      if (amIReceiver) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await _confirmAction(
                      t.declineOfferConfirmTitle,
                      t.declineOfferConfirmMessage,
                    );
                    if (ok) _doAction('decline');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(t.declineOffer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await _confirmAction(
                      t.acceptOfferConfirmTitle,
                      t.acceptOfferConfirmMessage,
                    );
                    if (ok) _doAction('accept');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(t.acceptOffer),
                ),
              ),
            ],
          ),
        );
      }
      if (amISender) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: OutlinedButton(
            onPressed: () async {
              final ok = await _confirmAction(
                t.cancelOfferConfirmTitle,
                t.cancelOfferConfirmMessage,
              );
              if (ok) _doAction('cancel');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.cancelOffer),
          ),
        );
      }
    }

    if (status == 'ACCEPTED') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
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
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: t.writeMessage,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.all(12),
              minimumSize: const Size(48, 48),
            ),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 20),
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
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      color: AppColors.primaryLight,
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
//  Product pair header
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
    final theirImages =
        (theirProduct is Map ? theirProduct['images'] : null) as List? ?? [];
    final theirFirstImage = theirImages.isNotEmpty ? theirImages.first : null;
    final theirImageUrl =
        theirFirstImage is String && theirFirstImage.trim().isNotEmpty
            ? AppConfig.resolveImageUrl(theirFirstImage)
            : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusPill(status, t),
              const SizedBox(width: 8),
              Text(
                t.barterDeal,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: theirImageUrl != null
                    ? () => showImageGallery(
                          context,
                          images: theirImages
                              .whereType<String>()
                              .map(AppConfig.resolveImageUrl)
                              .toList(),
                        )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.primaryLight,
                    child: theirImageUrl != null
                        ? Image.network(
                            theirImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.youGive,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      (myProduct is Map ? myProduct['title'] : null)
                              as String? ??
                          t.product,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.youGet,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      (theirProduct is Map ? theirProduct['title'] : null)
                              as String? ??
                          t.product,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status, AppLocalizations t) {
    late Color color;
    late String label;

    switch (status) {
      case 'PENDING':
        color = AppColors.primary;
        label = t.pending;
        break;
      case 'ACCEPTED':
        color = const Color(0xFF2E7D32);
        label = t.accepted;
        break;
      case 'COMPLETED':
        color = const Color(0xFF2E7D32);
        label = t.completed;
        break;
      case 'DECLINED':
        color = AppColors.error;
        label = t.declined;
        break;
      case 'CANCELLED':
        color = AppColors.textMuted;
        label = t.cancelled;
        break;
      default:
        color = AppColors.textMuted;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

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
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: mine ? AppColors.white : AppColors.text,
              ),
            ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: mine
                        ? AppColors.white.withValues(alpha: 0.75)
                        : AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}