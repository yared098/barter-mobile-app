import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../providers/offers_provider.dart';
import '../theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(allChatsProvider);
    final currentUserId = ref.watch(authProvider).user?['id'] as String?;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(incomingOffersProvider);
              ref.invalidate(outgoingOffersProvider);
            },
          ),
        ],
      ),
      body: chatsAsync.when(
        loading: () => const LoadingView(message: 'Loading conversations...'),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () {
            ref.invalidate(incomingOffersProvider);
            ref.invalidate(outgoingOffersProvider);
          },
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyView(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              message:
                  'Send an offer from a match to start a conversation. '
                  'All your active barter negotiations appear here.',
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(incomingOffersProvider);
              ref.invalidate(outgoingOffersProvider);
              await ref.read(allChatsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.divider,
                indent: 84,
              ),
              itemBuilder: (_, i) => _ChatRow(
                offer: chats[i],
                currentUserId: currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final Map<String, dynamic> offer;
  final String? currentUserId;

  const _ChatRow({required this.offer, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final direction = offer['_direction'] as String? ?? 'incoming';
    final isIncoming = direction == 'incoming';

    // The "other" person
    final other = isIncoming ? offer['sender'] : offer['receiver'];
    final otherName = (other is Map ? other['name'] : null) as String? ??
        (isIncoming ? 'Sender' : 'Receiver');

    // The "their" product (what I'd receive if accepted)
    final theirProduct =
        isIncoming ? offer['offeredProduct'] : offer['requestedProduct'];
    final theirTitle =
        (theirProduct is Map ? theirProduct['title'] : null) as String? ??
            'Product';
    final theirImages = (theirProduct is Map ? theirProduct['images'] : null)
            as List? ??
        [];
    final theirFirstImage = theirImages.isNotEmpty ? theirImages.first : null;
    final imageUrl = theirFirstImage is String &&
            theirFirstImage.trim().isNotEmpty
        ? AppConfig.resolveImageUrl(theirFirstImage)
        : null;

    // Last message preview
    final messages = (offer['messages'] as List?) ?? [];
    String preview;
    DateTime? lastTime;

    if (messages.isNotEmpty) {
      final last = messages.last as Map<String, dynamic>;
      preview = (last['content'] as String? ?? '').trim();
      if (preview.isEmpty) preview = '📎 Message';
      final t = last['createdAt'];
      if (t is String) {
        try {
          lastTime = DateTime.parse(t);
        } catch (_) {}
      }
    } else {
      final msg = (offer['message'] as String? ?? '').trim();
      preview = msg.isEmpty ? 'New offer' : msg;
      final t = offer['createdAt'];
      if (t is String) {
        try {
          lastTime = DateTime.parse(t);
        } catch (_) {}
      }
    }

    if (preview.length > 60) {
      preview = '${preview.substring(0, 60)}…';
    }

    final status = offer['status'] as String? ?? 'PENDING';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(offerId: offer['id'] as String),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.primaryLight,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                  ),
                ),
                // Direction indicator
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isIncoming
                          ? AppColors.primary
                          : AppColors.textMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: Icon(
                      isIncoming
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 10,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Text column ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (lastTime != null)
                        Text(
                          _formatTime(lastTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: status == 'PENDING'
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: status == 'PENDING'
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'About: $theirTitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: messages.isEmpty
                          ? AppColors.textMuted
                          : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusPill(status: status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;

    switch (status) {
      case 'PENDING':
        color = AppColors.primary;
        label = 'Pending';
        break;
      case 'ACCEPTED':
        color = const Color(0xFF2E7D32);
        label = 'Accepted';
        break;
      case 'COMPLETED':
        color = const Color(0xFF2E7D32);
        label = 'Completed';
        break;
      case 'DECLINED':
        color = AppColors.error;
        label = 'Declined';
        break;
      case 'CANCELLED':
        color = AppColors.textMuted;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.textMuted;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
