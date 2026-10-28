import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/requests_provider.dart';
import '../theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/request_card.dart';
import '../widgets/upgrade_prompt_sheet.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';

class WantedBoardScreen extends ConsumerStatefulWidget {
  const WantedBoardScreen({super.key});

  @override
  ConsumerState<WantedBoardScreen> createState() => _WantedBoardScreenState();
}

class _WantedBoardScreenState extends ConsumerState<WantedBoardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _scopes = ['all', 'mine', 'replies'];

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _scopes.length, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      if (_tabIndex != _tabs.index) {
        setState(() => _tabIndex = _tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isPro(dynamic user) {
    if (user == null) return false;
    final tier = user['tier'] as String?;
    if (tier != 'PRO') return false;
    final proExpiresAt = user['proExpiresAt'];
    if (proExpiresAt == null) return true;
    try {
      return DateTime.parse(proExpiresAt as String).isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  /// Opens create screen — but checks tier limit first.
  Future<void> _openCreate() async {
    final user = ref.read(authProvider).user;
    final isPro = _isPro(user);

    // FREE users: block if they already have 1 open request
    if (!isPro) {
      final mine = ref.read(wantedFeedProvider('mine')).asData?.value ?? [];
      final openCount = mine
          .whereType<Map<String, dynamic>>()
          .where((r) => r['status'] == 'OPEN')
          .length;

      if (openCount >= 1) {
        // Show upgrade prompt instead of the form
        if (!mounted) return;
        showUpgradePromptSheet(
          context,
          reason: UpgradeReason.products,
        );
        return;
      }
    }

    // Proceed
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
    );
    if (created == true) {
      ref.invalidate(wantedFeedProvider('mine'));
      ref.invalidate(wantedFeedProvider('all'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final showFab = _tabIndex == 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(t),
      floatingActionButton: showFab ? _buildPostFab(t) : null,
      body: TabBarView(
        controller: _tabs,
        children: _scopes
            .map((s) => _FeedTab(
                  scope: s,
                  onRefresh: () async {
                    ref.invalidate(wantedFeedProvider(s));
                    await ref.read(wantedFeedProvider(s).future);
                  },
                ))
            .toList(),
      ),
    );
  }

  /// Tier-gated FAB:
  ///   • PRO              → normal "Post request" (+ icon)
  ///   • FREE with 0 open → normal "Post request" (+ icon)
  ///   • FREE with 1 open → white "Go PRO" pill (crown icon)
  Widget _buildPostFab(AppLocalizations t) {
    final user = ref.watch(authProvider).user;
    final isPro = _isPro(user);

    // Count open requests only from "mine" feed (already cached)
    final mineAsync = ref.watch(wantedFeedProvider('mine'));
    final mine = mineAsync.asData?.value ?? [];
    final openCount = mine
        .whereType<Map<String, dynamic>>()
        .where((r) => r['status'] == 'OPEN')
        .length;

    final canPost = isPro || openCount == 0;

    if (canPost) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          t.postRequest,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      );
    }

    // FREE at limit → "Go PRO" pill
    return FloatingActionButton.extended(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 5,
      onPressed: () => showUpgradePromptSheet(
        context,
        reason: UpgradeReason.products,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      icon: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.workspace_premium,
          size: 14,
          color: AppColors.primary,
        ),
      ),
      label: const Text(
        'Go PRO',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations t) {
    final darkPrimary =
        Color.lerp(AppColors.primary, Colors.black, 0.18) ?? AppColors.primary;

    final tabs = <Tab>[
      Tab(text: t.browse),
      Tab(text: t.myRequests),
      Tab(text: t.myReplies),
    ];

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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.wantedBoard,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            t.wantedBoardSubtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        tabs: tabs,
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  final String scope;
  final Future<void> Function() onRefresh;

  const _FeedTab({required this.scope, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(wantedFeedProvider(scope));

    return async.when(
      skipLoadingOnRefresh: true,
      loading: () => LoadingView(message: t.loadingRequests),
      error: (e, _) => ErrorView(
        message: e.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(wantedFeedProvider(scope)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyView(
            icon: Icons.assignment_outlined,
            title: switch (scope) {
              'mine' => t.noRequestsYet,
              'replies' => t.noRepliesYet,
              _ => t.nobodyAskingYet,
            },
            message: switch (scope) {
              'mine' => t.tapPostRequestHint,
              'replies' => t.browseBoardHint,
              _ => t.boardQuietHint,
            },
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i] as Map<String, dynamic>;
              return RequestCard(
                request: r,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestDetailScreen(requestId: r['id'] as String),
                    ),
                  );
                  ref.invalidate(wantedFeedProvider(scope));
                },
              );
            },
          ),
        );
      },
    );
  }
}