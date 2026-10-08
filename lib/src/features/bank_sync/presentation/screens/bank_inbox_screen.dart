import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_import_flow.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_message_card.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_message_row.dart';

/// The bank-message inbox: To review (cards with quick Add / Ignore and a
/// bulk "Add N clear messages"), Added, and Ignored (restorable). Counts
/// come from the server summary; the settled tabs page as you scroll; every
/// tab pulls to refresh.
class BankInboxScreen extends StatefulWidget {
  const BankInboxScreen({super.key});

  @override
  State<BankInboxScreen> createState() => _BankInboxScreenState();
}

class _BankInboxScreenState extends State<BankInboxScreen> with BankImportFlow {
  /// 0 to review · 1 added · 2 ignored.
  int _tab = 0;

  @override
  void onImported(int count, int skipped) {
    showToast(
      context,
      message: skipped == 0
          ? 'bank_sync.added_count'.plural(count)
          : 'bank_sync.added_skipped'.tr(
              namedArgs: {'added': '$count', 'skipped': '$skipped'},
            ),
      status: skipped == 0 ? 'success' : 'info',
    );
  }

  void _open(BankMessage message) =>
      context.push(AppRoutes.bankMessage, extra: message);

  Future<void> _refresh() => refreshInbox();

  @override
  Widget build(BuildContext context) {
    return importListener(
      child: BlocBuilder<BankSyncCubit, BankSyncState>(
        builder: (context, state) {
          final confident = state.pendingConfident;
          final summary = state.summary;

          return Scaffold(
            appBar: AppTopBar(
              title: 'bank_sync.inbox_title'.tr(),
              actions: [
                if (state.isConnected)
                  IconButton(
                    tooltip: 'bank_sync.paste_title'.tr(),
                    onPressed: addPastedMessage,
                    icon: Icon(
                      Icons.add_comment_outlined,
                      size: 21.sp,
                      color: context.colors.onSurface,
                    ),
                  ),
                SizedBox(width: 8.w),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: UnderlineTabs(
                      labels: [
                        _tabLabel('bank_sync.tab_review', summary.pendingCount),
                        _tabLabel('bank_sync.tab_added', summary.importedCount),
                        _tabLabel(
                          'bank_sync.tab_ignored',
                          summary.ignoredCount,
                        ),
                      ],
                      selectedIndex: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                  Expanded(
                    child: state.isLoading ||
                            state.status == BankSyncStatus.initial
                        ? const AppLoading()
                        : state.status == BankSyncStatus.failure &&
                                !state.hasContent
                            ? AppErrorWidget(
                                message: state.errorMessage,
                                onRetry: () =>
                                    context.read<BankSyncCubit>().load(),
                              )
                            : RefreshIndicator(
                            onRefresh: _refresh,
                            color: context.colors.primary,
                            child: switch (_tab) {
                              0 => _review(state),
                              1 => _settled(state, BankMessageStatus.imported),
                              _ => _settled(state, BankMessageStatus.ignored),
                            },
                          ),
                  ),
                  if (_tab == 0 && confident.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                      child: AppGradientButton(
                        label: confident.length == state.pending.length
                            ? 'bank_sync.add_all'.plural(confident.length)
                            : 'bank_sync.add_all_clear'
                                .plural(confident.length),
                        isLoading: isImporting,
                        onPressed: () =>
                            context.guardedRun(() => importClear(confident)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _tabLabel(String key, int count) =>
      count > 0 ? '${key.tr()} ($count)' : key.tr();

  Widget _review(BankSyncState state) {
    if (!state.isConnected && state.pending.isEmpty) {
      return _ScrollableEmpty(
        child: AppEmptyState(
          icon: Icons.sms_outlined,
          title: 'bank_sync.not_connected_title'.tr(),
          subtitle: 'bank_sync.not_connected_desc'.tr(),
          actionLabel: 'bank_sync.connect_cta'.tr(),
          onAction: () => context.guardedPush(AppRoutes.bankLinkSetup),
        ),
      );
    }

    final pending = state.pending;
    if (pending.isEmpty) {
      return _ScrollableEmpty(
        child: AppEmptyState(
          icon: Icons.task_alt_rounded,
          title: 'bank_sync.all_caught_up'.tr(),
          subtitle: 'bank_sync.empty_review_desc'.tr(),
          actionLabel: state.isConnected ? 'bank_sync.paste_title'.tr() : null,
          onAction: state.isConnected ? addPastedMessage : null,
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
      itemCount: pending.length + 1,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        if (index == 0) return _FlowSummary(messages: pending);
        final message = pending[index - 1];
        return BankMessageCard(
          message: message,
          bank: state.bankById(message.bankId),
          enabled: !isImporting,
          onTap: () => _open(message),
          onAdd: () => context.guardedRun(() => importOne(message)),
          onIgnore: () => ignoreMessage(message),
        );
      },
    );
  }

  Widget _settled(BankSyncState state, BankMessageStatus status) {
    final isImported = status == BankMessageStatus.imported;
    final page = isImported ? state.imported : state.ignored;

    if (page.items.isEmpty) {
      return _ScrollableEmpty(
        child: isImported
            ? AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'bank_sync.empty_added_title'.tr(),
                subtitle: 'bank_sync.empty_added_desc'.tr(),
              )
            : AppEmptyState(
                icon: Icons.visibility_off_outlined,
                title: 'bank_sync.empty_ignored_title'.tr(),
                subtitle: 'bank_sync.empty_ignored_desc'.tr(),
              ),
      );
    }
    final locale = context.locale.toString();

    return _SettledList(
      page: page,
      isLoadingMore: state.loadingMore.contains(status),
      onEndReached: () => context.read<BankSyncCubit>().loadMore(status),
      footer: isImported ? null : 'bank_sync.ignored_footer'.tr(),
      rowBuilder: (m) => BankMessageRow(
        message: m,
        bank: state.bankById(m.bankId),
        subtitle: isImported || m.isTransaction
            ? [
                AppDate.relative(m.receivedAt, locale),
                if (isImported) m.categoryLine(),
              ].join(' · ')
            : '${'bank_sync.not_transaction_short'.tr()} · '
                '${AppDate.relative(m.receivedAt, locale)}',
        onTap: () => _open(m),
        trailing: !isImported && m.isTransaction
            ? TextButton(
                onPressed: () => restoreMessage(m),
                child: Text(
                  'bank_sync.restore'.tr(),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Lets pull-to-refresh work on an empty tab.
class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Money in / money out across the messages waiting for review.
class _FlowSummary extends StatelessWidget {
  const _FlowSummary({required this.messages});

  final List<BankMessage> messages;

  @override
  Widget build(BuildContext context) {
    final parsed = [
      for (final m in messages)
        if (m.parsed != null) m.parsed!,
    ];
    final moneyIn = sumAmounts([
      for (final p in parsed)
        if (p.type.isIncome) p.amount
    ]);
    final moneyOut = sumAmounts([
      for (final p in parsed)
        if (!p.type.isIncome) p.amount
    ]);

    Widget stat(String label, String value, Color color) => Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 10.5.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        stat(
          'bank_sync.money_out'.tr(),
          signedMoneyWithSymbol(moneyOut, isIncome: false),
          context.colors.error,
        ),
        SizedBox(width: 10.w),
        stat(
          'bank_sync.money_in'.tr(),
          signedMoneyWithSymbol(moneyIn, isIncome: true),
          context.colors.tertiary,
        ),
      ],
    );
  }
}

/// Added / ignored rows in one card that loads the next page near the end.
class _SettledList extends StatelessWidget {
  const _SettledList({
    required this.page,
    required this.rowBuilder,
    required this.onEndReached,
    required this.isLoadingMore,
    this.footer,
  });

  final BankMessagePage page;
  final Widget Function(BankMessage message) rowBuilder;
  final VoidCallback onEndReached;
  final bool isLoadingMore;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final items = page.items;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (page.hasMore && metrics.pixels >= metrics.maxScrollExtent - 240.h) {
          onEndReached();
        }
        return false;
      },
      // Rows are built lazily (pages add 50 at a time); the card chrome is
      // painted once behind the whole sliver.
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
            sliver: DecoratedSliver(
              decoration: AppSoftCard.decorationOf(context),
              sliver: SliverList.separated(
                itemCount: items.length,
                itemBuilder: (context, i) => rowBuilder(items[i]),
                separatorBuilder: (context, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colors.outlineVariant,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (isLoadingMore || page.hasMore)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: isLoadingMore
                          ? const AppLoading()
                          : TextButton(
                              onPressed: onEndReached,
                              child: Text('bank_sync.load_more'.tr()),
                            ),
                    ),
                  if (footer != null) ...[
                    SizedBox(height: 10.h),
                    Text(
                      footer!,
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
