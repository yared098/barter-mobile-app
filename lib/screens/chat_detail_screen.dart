import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
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
    // Poll for new messages every 5s while this screen is open
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
      // Wait a tick for the provider to refetch, then scroll
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
    setState(() => _actionLoading = true);
    try {
      final api = ref.read(apiProvider);
      await api.offerAction(widget.offerId, action);
      ref.invalidate(offerDetailProvider(widget.offerId));
      ref.invalidate(incomingOffersProvider);
      ref.invalidate(outgoingOffersProvider);
      ref.invalidate(allChatsProvider);

      if (!mounted) return;
      final label =
          {
            'accept': 'Offer accepted',
            'decline': 'Offer declined',
            'cancel': 'Offer cancelled',
            'complete': 'Swap completed',
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
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(offerDetailProvider(widget.offerId));
    final currentUserId = ref.watch(authProvider).user?['id'] as String?;

    // Scroll to bottom on first data + when message count grows
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
            return Text(name ?? 'Chat');
          },
          orElse: () => const Text('Chat'),
        ),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(offerDetailProvider(widget.offerId)),
        ),
        data: (offer) => _buildBody(offer, currentUserId),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> offer, String? currentUserId) {
    final amISender = offer['senderId'] == currentUserId;
    final amIReceiver = offer['receiverId'] == currentUserId;
    final status = offer['status'] as String? ?? 'PENDING';

    final myProduct = amISender
        ? offer['offeredProduct']
        : offer['requestedProduct'];
    final theirProduct = amISender
        ? offer['requestedProduct']
        : offer['offeredProduct'];

    final messages = (offer['messages'] as List?) ?? [];
    final chatClosed = ['COMPLETED', 'DECLINED', 'CANCELLED'].contains(status);

    return Column(
      children: [
        // ── Product pair header ──
        _ProductPairHeader(
          myProduct: myProduct,
          theirProduct: theirProduct,
          status: status,
        ),

        // ── Action buttons ──
        _buildActions(status, amISender, amIReceiver),

        const Divider(height: 1, color: AppColors.divider),

        // ── Messages ──
        Expanded(
          child: messages.isEmpty
              ? _emptyChat()
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
                                : null)
                            as String? ??
                        'Someone';
                    final content = m['content'] as String? ?? '';
                    DateTime? t;
                    final raw = m['createdAt'];
                    if (raw is String) {
                      try {
                        t = DateTime.parse(raw).toLocal();
                      } catch (_) {}
                    }
                    return _MessageBubble(
                      content: content,
                      mine: mine,
                      senderName: senderName,
                      time: t,
                    );
                  },
                ),
        ),

        // ── Input / closed notice ──
        if (!chatClosed) _buildInput(),
        if (chatClosed) _closedNotice(status),
      ],
    );
  }

  Widget _buildActions(String status, bool amISender, bool amIReceiver) {
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
                      'Decline offer?',
                      'The offer will be closed and both products unlocked.',
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
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await _confirmAction(
                      'Accept offer?',
                      'Ownership of both products will transfer immediately. '
                          'Meet the other person to physically exchange items.',
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
                  child: const Text('Accept'),
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
                'Cancel offer?',
                'The offer will be withdrawn. Both products unlock.',
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
            child: const Text('Cancel offer'),
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
              'Mark swap complete?',
              'Only do this after you have physically exchanged items.',
            );
            if (ok) _doAction('complete');
          },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Mark as completed'),
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

  Widget _emptyChat() {
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
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Say hi and arrange the details.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
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
              decoration: const InputDecoration(
                hintText: 'Write a message...',
                contentPadding: EdgeInsets.symmetric(
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

  Widget _closedNotice(String status) {
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
            ? 'Swap completed — chat is closed.'
            : 'This offer is ${status.toLowerCase()}. Chat is closed.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Compact header showing the two products in the deal.
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
          // ── Status pill ──
          Row(
            children: [
              _statusPill(status),
              const SizedBox(width: 8),
              const Text(
                'Barter deal',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Image + product pair ──
          Row(
            children: [
              // Their product image (what I'm getting)
              GestureDetector(
                onTap: theirImageUrl != null
                    ? () => showImageGallery(
                        context,
                        images: (theirImages
                            .whereType<String>()
                            .map(AppConfig.resolveImageUrl)
                            .toList()),
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
                    const Text(
                      'You give',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      (myProduct is Map ? myProduct['title'] : null)
                              as String? ??
                          'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You get',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      (theirProduct is Map ? theirProduct['title'] : null)
                              as String? ??
                          'Product',
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

  Widget _statusPill(String status) {
    late Color color;
    switch (status) {
      case 'PENDING':
        color = AppColors.primary;
        break;
      case 'ACCEPTED':
      case 'COMPLETED':
        color = const Color(0xFF2E7D32);
        break;
      case 'DECLINED':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
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
