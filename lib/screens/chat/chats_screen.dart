import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../theme.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final chatsAsync = ref.watch(allChatsProvider);
    final currentUserId = ref.watch(authProvider).user?['id'] as String?;

    final chatCount = chatsAsync.asData?.value.length ?? 0;

    void refreshAll() {
      ref.invalidate(incomingOffersProvider);
      ref.invalidate(outgoingOffersProvider);
      ref.refresh(allChatsProvider.future);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _ChatsAppBar(
        title: t.chats,
        count: chatCount,
        onRefresh: refreshAll,
      ),
      body: chatsAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => LoadingView(message: t.loadingConversations),
        error: (e, _) => ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () {
            ref.invalidate(incomingOffersProvider);
            ref.invalidate(outgoingOffersProvider);
          },
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return EmptyView(
              icon: Icons.chat_bubble_outline,
              title: t.noChatsYet,
              message: t.noChatsMessage,
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(incomingOffersProvider);
              ref.invalidate(outgoingOffersProvider);
              await ref.refresh(allChatsProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: chats.length,
              itemBuilder: (_, i) => _ChatCard(
                offer: chats[i] as Map<String, dynamic>,
                currentUserId: currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  BRANDED CHATS APP BAR
// ═══════════════════════════════════════════════════════

class _ChatsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int count;
  final VoidCallback onRefresh;

  const _ChatsAppBar({
    required this.title,
    required this.count,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final darkPrimary =
        Color.lerp(AppColors.primary, Colors.black, 0.18) ?? AppColors.primary;

    return AppBar(
      toolbarHeight: 60,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(color: Colors.white),
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
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: AppLocalizations.of(context)!.refresh,
          onPressed: onRefresh,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CHAT CARD
// ═══════════════════════════════════════════════════════

class _ChatCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final String? currentUserId;

  const _ChatCard({required this.offer, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final direction = offer['_direction'] as String? ?? 'incoming';
    final isIncoming = direction == 'incoming';

    final other = isIncoming ? offer['sender'] : offer['receiver'];
    final otherName = (other is Map ? other['name'] : null) as String? ??
        (isIncoming ? t.sender : t.receiver);

    final theirProduct =
        isIncoming ? offer['offeredProduct'] : offer['requestedProduct'];
    final theirTitle =
        (theirProduct is Map ? theirProduct['title'] : null) as String? ??
            t.product;
    final theirImages =
        (theirProduct is Map ? theirProduct['images'] : null) as List? ?? [];
    final theirFirstImage = theirImages.isNotEmpty ? theirImages.first : null;
    final imageUrl =
        theirFirstImage is String && theirFirstImage.trim().isNotEmpty
            ? AppConfig.resolveImageUrl(theirFirstImage)
            : null;

    final messages = (offer['messages'] as List?) ?? [];
    String preview;
    DateTime? lastTime;

    if (messages.isNotEmpty) {
      final last = messages.last as Map<String, dynamic>;
      preview = (last['content'] as String? ?? '').trim();
      if (preview.isEmpty) preview = t.attachment;
      final raw = last['createdAt'];
      if (raw is String) {
        try {
          lastTime = DateTime.parse(raw);
        } catch (_) {}
      }
    } else {
      final msg = (offer['message'] as String? ?? '').trim();
      preview = msg.isEmpty ? t.newOffer : msg;
      final raw = offer['createdAt'];
      if (raw is String) {
        try {
          lastTime = DateTime.parse(raw);
        } catch (_) {}
      }
    }

    if (preview.length > 60) {
      preview = '${preview.substring(0, 60)}…';
    }

    final status = offer['status'] as String? ?? 'PENDING';
    final unreadCount = (offer['unreadCount'] as num?)?.toInt() ?? 0;
    final hasUnread = unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ChatDetailScreen(offerId: offer['id'] as String),
              ),
            );
          },
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasUnread
                    ? AppColors.primary.withValues(alpha: 0.22)
                    : AppColors.primary.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image avatar with direction badge ──
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
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
                      ),
                      // Direction badge (bottom-right)
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
                            border:
                                Border.all(color: AppColors.white, width: 2),
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
                ),
                const SizedBox(width: 12),

                // ── Text column ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + time + unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          if (lastTime != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                _formatTime(lastTime, t),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: status == 'PENDING' || hasUnread
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  fontWeight:
                                      status == 'PENDING' || hasUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                ),
                              ),
                            ),
                          if (hasUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              constraints:
                                  const BoxConstraints(minWidth: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Product title
                      Text(
                        t.aboutProduct(theirTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Preview
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: messages.isEmpty
                              ? AppColors.textMuted
                              : AppColors.text,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Status pill
                      _StatusPill(status: status, t: t),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt, AppLocalizations t) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return t.timeNow;
    if (diff.inMinutes < 60) return t.timeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return t.timeHours(diff.inHours);
    if (diff.inDays < 7) return t.timeDays(diff.inDays);
    return '${dt.day}/${dt.month}';
  }
}

// ═══════════════════════════════════════════════════════
//  STATUS PILL
// ═══════════════════════════════════════════════════════

class _StatusPill extends StatelessWidget {
  final String status;
  final AppLocalizations t;

  const _StatusPill({required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}