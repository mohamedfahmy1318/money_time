import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_import_flow.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_message_card.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_message_row.dart';

/// The bank-message inbox: To review (cards with quick Add / Ignore and a
/// bulk "Add all" for the clear ones), Added, and Ignored (restorable).
class BankInboxScreen extends StatefulWidget {
  const BankInboxScreen({super.key});

  @override
  State<BankInboxScreen> createState() => _BankInboxScreenState();
}

class _BankInboxScreenState extends State<BankInboxScreen> with BankImportFlow {
  /// 0 to review · 1 added · 2 ignored.
  int _tab = 0;

  @override
  void onImported(int count) =>
      showToast(context, message: 'bank_sync.added_count'.plural(count));

  void _open(BankMessage message) =>
      context.push(AppRoutes.bankMessage, extra: message);

  void _importOne(BankSyncState state, BankMessage message) =>
      context.guardedRun(() => importMessages({
            message.id: message.toTransaction(state.bankById(message.bankId)),
          }));

  void _importAll(BankSyncState state) =>
      context.guardedRun(() => importMessages({
            for (final m in state.pendingConfident)
              m.id: m.toTransaction(state.bankById(m.bankId)),
          }));

  void _ignore(BankMessage message) {
    context.read<BankSyncCubit>().ignore(message.id);
    showToast(context, message: 'bank_sync.ignored_toast'.tr(), status: 'info');
  }

  @override
  Widget build(BuildContext context) {
    return importListener(
      child: BlocBuilder<BankSyncCubit, BankSyncState>(
        builder: (context, state) {
          final confident = state.pendingConfident;

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
                        '${'bank_sync.tab_review'.tr()} (${state.pending.length})',
                        'bank_sync.tab_added'.tr(),
                        'bank_sync.tab_ignored'.tr(),
                      ],
                      selectedIndex: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                  Expanded(
                    child: state.isLoading ||
                            state.status == BankSyncStatus.initial
                        ? const AppLoading()
                        : switch (_tab) {
                            0 => _review(state),
                            1 => _added(state),
                            _ => _ignored(state),
                          },
                  ),
                  if (_tab == 0 && confident.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                      child: AppGradientButton(
                        label: confident.length == state.pending.length
                            ? 'bank_sync.add_all'.plural(confident.length)
                            : 'bank_sync.add_all_clear'.plural(confident.length),
                        isLoading: isImporting,
                        onPressed: () => _importAll(state),
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

  Widget _review(BankSyncState state) {
    if (!state.isConnected && state.messages.isEmpty) {
      return AppEmptyState(
        icon: Icons.sms_outlined,
        title: 'bank_sync.not_connected_title'.tr(),
        subtitle: 'bank_sync.not_connected_desc'.tr(),
        actionLabel: 'bank_sync.connect_cta'.tr(),
        onAction: () => context.guardedPush(AppRoutes.bankLinkSetup),
      );
    }

    final pending = state.pending;
    if (pending.isEmpty) {
      return AppEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'bank_sync.all_caught_up'.tr(),
        subtitle: 'bank_sync.empty_review_desc'.tr(),
        actionLabel: state.isConnected ? 'bank_sync.paste_title'.tr() : null,
        onAction: state.isConnected ? addPastedMessage : null,
      );
    }

    return ListView.separated(
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
          onAdd: () => _importOne(state, message),
          onIgnore: () => _ignore(message),
        );
      },
    );
  }

  Widget _added(BankSyncState state) {
    final imported = state.imported;
    if (imported.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'bank_sync.empty_added_title'.tr(),
        subtitle: 'bank_sync.empty_added_desc'.tr(),
      );
    }
    final locale = context.locale.toString();

    return _SettledList(
      children: [
        for (final m in imported)
          BankMessageRow(
            message: m,
            bank: state.bankById(m.bankId),
            subtitle: '${AppDate.relative(m.receivedAt, locale)} · '
                '${m.parsed?.categoryEmoji ?? ''} ${m.parsed?.categoryLabel ?? ''}',
            onTap: () => _open(m),
          ),
      ],
    );
  }

  Widget _ignored(BankSyncState state) {
    final ignored = state.ignored;
    if (ignored.isEmpty) {
      return AppEmptyState(
        icon: Icons.visibility_off_outlined,
        title: 'bank_sync.empty_ignored_title'.tr(),
        subtitle: 'bank_sync.empty_ignored_desc'.tr(),
      );
    }
    final locale = context.locale.toString();

    return _SettledList(
      footer: 'bank_sync.ignored_footer'.tr(),
      children: [
        for (final m in ignored)
          BankMessageRow(
            message: m,
            bank: state.bankById(m.bankId),
            subtitle: m.isTransaction
                ? AppDate.relative(m.receivedAt, locale)
                : '${'bank_sync.not_transaction_short'.tr()} · '
                    '${AppDate.relative(m.receivedAt, locale)}',
            onTap: () => _open(m),
            trailing: m.isTransaction
                ? TextButton(
                    onPressed: () =>
                        context.read<BankSyncCubit>().restore(m.id),
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
      ],
    );
  }
}

/// Money in / money out across the messages waiting for review.
class _FlowSummary extends StatelessWidget {
  const _FlowSummary({required this.messages});

  final List<BankMessage> messages;

  @override
  Widget build(BuildContext context) {
    var moneyIn = 0.0;
    var moneyOut = 0.0;
    for (final m in messages) {
      final p = m.parsed;
      if (p == null) continue;
      if (p.type.isIncome) {
        moneyIn += p.amount;
      } else {
        moneyOut += p.amount;
      }
    }

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

/// Added / ignored rows in one card, with an optional caption beneath.
class _SettledList extends StatelessWidget {
  const _SettledList({required this.children, this.footer});

  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
      children: [
        AppSoftCard(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.colors.outlineVariant,
                  ),
                children[i],
              ],
            ],
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
    );
  }
}
