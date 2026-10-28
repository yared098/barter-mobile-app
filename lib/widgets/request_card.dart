import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

class RequestCard extends ConsumerWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final primary = AppColors.primary;

    final author = request['author'] as Map<String, dynamic>?;
    final authorName = (author?['name'] as String?)?.trim() ?? 'Someone';
    final initial = authorName.isNotEmpty
        ? authorName.characters.first.toUpperCase()
        : '?';

    final title = request['title'] as String? ?? '—';
    final description = request['description'] as String? ?? '';
    final status = request['status'] as String? ?? 'OPEN';
    final type = request['type'] as String? ?? 'BUY';
    final budgetMin = (request['budgetMin'] as num?)?.toDouble();
    final budgetMax = (request['budgetMax'] as num?)?.toDouble();
    final location = request['location'] as String?;
    final specs = (request['specifications'] as Map?) ?? {};
    final replyCount =
        ((request['_count'] as Map?)?['responses'] as num?)?.toInt() ?? 0;

    DateTime? created;
    final raw = request['createdAt'];
    if (raw is String) {
      try {
        created = DateTime.parse(raw).toLocal();
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: primary.withValues(alpha: 0.08),
          highlightColor: primary.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primary.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Author + status row ──
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    _TypePill(type: type),
                    const SizedBox(width: 6),
                    _StatusPill(status: status),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Title ──
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],

                // ── Spec chips ──
                if (specs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: specs.entries.take(4).map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // ── Budget + location ──
                if (budgetMin != null ||
                    budgetMax != null ||
                    (location != null && location.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (budgetMin != null || budgetMax != null) ...[
                        Icon(
                          Icons.payments_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _budgetLabel(budgetMin, budgetMax),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                      if ((budgetMin != null || budgetMax != null) &&
                          location != null &&
                          location.isNotEmpty)
                        const SizedBox(width: 10),
                      if (location != null && location.isNotEmpty) ...[
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // ── Footer: replies + time + chevron ──
                const SizedBox(height: 9),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: replyCount > 0
                            ? primary.withValues(alpha: 0.10)
                            : AppColors.border.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 10,
                            color: replyCount > 0
                                ? primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: replyCount > 0
                                  ? primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (created != null)
                      Text(
                        _timeAgo(created, t),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: primary.withValues(alpha: 0.6),
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

  String _budgetLabel(double? min, double? max) {
    if (min != null && max != null) {
      return 'ETB ${min.toStringAsFixed(0)} – ${max.toStringAsFixed(0)}';
    }
    if (min != null) return 'ETB ${min.toStringAsFixed(0)}+';
    return 'up to ETB ${max!.toStringAsFixed(0)}';
  }

  String _timeAgo(DateTime dt, AppLocalizations t) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return t.timeNow;
    if (diff.inMinutes < 60) return t.timeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return t.timeHours(diff.inHours);
    if (diff.inDays < 7) return t.timeDays(diff.inDays);
    return '${dt.day}/${dt.month}';
  }
}

class _TypePill extends StatelessWidget {
  final String type;
  const _TypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'BUY' => ('CASH', const Color(0xFF1E88E5)),
      'BARTER' => ('SWAP', const Color(0xFF7B1FA2)),
      _ => ('EITHER', const Color(0xFF00897B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'OPEN' => ('OPEN', AppColors.primary),
      'CLOSED' => ('CLOSED', const Color(0xFF2E7D32)),
      'FULFILLED' => ('DONE', const Color(0xFF2E7D32)),
      'EXPIRED' => ('EXPIRED', AppColors.textMuted),
      'CANCELLED' => ('CANCELLED', AppColors.error),
      _ => (status, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}