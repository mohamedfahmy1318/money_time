import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/models/transaction_filter.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/amount_stat.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/check_row.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/percent_ring.dart';

/// Month filter screen: income/expense share donuts, a type scope
/// (Income / Exp. / Category) and a category checklist. Pops with the chosen
/// [TransactionFilter]; closing with ✕ changes nothing.
class TransactionFilterScreen extends StatefulWidget {
  const TransactionFilterScreen({super.key, required this.args});

  final FilterScreenArgs args;

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen> {
  /// 0 income · 1 expense · 2 all categories.
  late int _tab;
  Set<String>? _selected;

  @override
  void initState() {
    super.initState();
    final current = widget.args.current;
    _tab = switch (current?.type) {
      TransactionType.income => 0,
      TransactionType.expense => 1,
      null => 2,
    };
    _selected = current?.categories?.toSet();
  }

  TransactionType? get _scopeType => switch (_tab) {
        0 => TransactionType.income,
        1 => TransactionType.expense,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionsCubit>().state;
    final monthTransactions = state.monthOf(widget.args.month);
    final scope = _scopeType == null
        ? monthTransactions
        : monthTransactions.where((t) => t.type == _scopeType).toList();

    // Categories offered by the checklist, with their month totals.
    final totals = <String, ({String emoji, double amount, bool income})>{};
    for (final t in scope) {
      final existing = totals[t.categoryLabel];
      totals[t.categoryLabel] = (
        emoji: t.categoryEmoji,
        amount: (existing?.amount ?? 0) + t.amount,
        income: t.isIncome,
      );
    }
    final labels = totals.keys.toList();
    final selected = _selected ?? labels.toSet();

    // Donuts preview the current selection.
    final preview = monthTransactions
        .where((t) =>
            (_scopeType == null || t.type == _scopeType) &&
            selected.contains(t.categoryLabel))
        .toList();
    final income = TransactionsState.sumIncome(preview);
    final expense = TransactionsState.sumExpense(preview);
    final volume = income + expense;

    return Scaffold(
      body: Column(
        children: [
          _Header(month: widget.args.month),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      PercentRing(
                        fraction: volume == 0 ? 0 : income / volume,
                        color: context.colors.tertiary,
                        caption: 'transactions.income'.tr(),
                      ),
                      PercentRing(
                        fraction: volume == 0 ? 0 : expense / volume,
                        color: context.colors.error,
                        caption: 'transactions.expense'.tr(),
                      ),
                      AmountStat(
                        label: 'transactions.total'.tr(),
                        value: moneyWithSymbol(volume),
                        color: expense >= income
                            ? context.colors.error
                            : context.colors.tertiary,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  UnderlineTabs(
                    labels: [
                      'transactions.income'.tr(),
                      'transactions.exp_short'.tr(),
                      'transactions.category'.tr(),
                    ],
                    selectedIndex: _tab,
                    onChanged: (i) => setState(() {
                      _tab = i;
                      // New scope, new checklist — start from everything.
                      _selected = null;
                    }),
                  ),
                  SizedBox(height: 14.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: AppSoftCard(
                        child: Column(
                          children: [
                            CheckRow(
                              label: 'transactions.all'.tr(),
                              checked: selected.length == labels.length,
                              onTap: () => setState(() {
                                _selected = selected.length == labels.length
                                    ? <String>{}
                                    : null;
                              }),
                            ),
                            for (final label in labels) ...[
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: context.colors.outlineVariant,
                              ),
                              CheckRow(
                                label: '${totals[label]!.emoji} $label',
                                checked: selected.contains(label),
                                amount: signedMoney(
                                  totals[label]!.amount,
                                  isIncome: totals[label]!.income,
                                ),
                                amountColor: totals[label]!.income
                                    ? context.colors.tertiary
                                    : context.colors.error,
                                onTap: () => setState(() {
                                  final next = selected.toSet();
                                  if (!next.remove(label)) next.add(label);
                                  _selected = next;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  AppGradientButton(
                    label: 'transactions.apply_filter'.tr(),
                    onPressed: () => context.pop(
                      TransactionFilter(
                        type: _scopeType,
                        categories: selected.length == labels.length
                            ? null
                            : selected,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deep-slate title bar with a close ✕, screen title and the month context.
class _Header extends StatelessWidget {
  const _Header({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.slateDeep,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 49.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.popOrGo(AppRoutes.home),
                  behavior: HitTestBehavior.opaque,
                  child:
                      Icon(Icons.close_rounded, size: 20.sp, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    'transactions.filter_title'.tr(),
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                Text(
                  AppDate.monthYear(month, context.locale.toString()),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
