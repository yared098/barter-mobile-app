enum PostingMode { pro, credit, daily, free }

class PostingStatus {
  final PostingMode mode;
  final bool canPost;
  final String? reason;

  final int postsUsedToday;
  final int dailyCap;
  final int postsLeftToday;

  final int? budgetLeft;       // credits remaining OR pro budget remaining
  final int? proDaysLeft;      // days until PRO expires
  final DateTime? proExpiresAt;
  final DateTime? dailyPassExpiresAt;
  final int creditsRemaining;

  PostingStatus({
    required this.mode,
    required this.canPost,
    this.reason,
    required this.postsUsedToday,
    required this.dailyCap,
    required this.postsLeftToday,
    this.budgetLeft,
    this.proDaysLeft,
    this.proExpiresAt,
    this.dailyPassExpiresAt,
    required this.creditsRemaining,
  });

  factory PostingStatus.fromJson(Map<String, dynamic> j) {
    return PostingStatus(
      mode: switch (j['mode']?.toString().toUpperCase()) {
        'PRO' => PostingMode.pro,
        'CREDIT' => PostingMode.credit,
        'DAILY' => PostingMode.daily,
        _ => PostingMode.free,
      },
      canPost: j['canPost'] == true,
      reason: j['reason']?.toString(),
      postsUsedToday: (j['postsUsedToday'] as num?)?.toInt() ?? 0,
      dailyCap: (j['dailyCap'] as num?)?.toInt() ?? 1,
      postsLeftToday: (j['postsLeftToday'] as num?)?.toInt() ?? 0,
      budgetLeft: (j['budgetLeft'] as num?)?.toInt(),
      proDaysLeft: (j['proDaysLeft'] as num?)?.toInt(),
      proExpiresAt: j['proExpiresAt'] != null
          ? DateTime.tryParse(j['proExpiresAt'].toString())
          : null,
      dailyPassExpiresAt: j['dailyPassExpiresAt'] != null
          ? DateTime.tryParse(j['dailyPassExpiresAt'].toString())
          : null,
      creditsRemaining: (j['creditsRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  /// Human label for the status card.
  String get label {
    switch (mode) {
      case PostingMode.pro:
        return 'PRO · ${budgetLeft ?? 0} posts left · ${proDaysLeft ?? 0} days';
      case PostingMode.credit:
        return 'Credits · ${budgetLeft ?? 0} left';
      case PostingMode.daily:
        return 'Daily pass · $postsUsedToday/$dailyCap used today';
      case PostingMode.free:
        return 'Free · $postsUsedToday/$dailyCap today';
    }
  }
}