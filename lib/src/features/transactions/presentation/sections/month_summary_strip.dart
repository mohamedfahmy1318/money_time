import 'package:mony_time/src/imports/core_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/amount_stat.dart';

/// The Income / Exp. / Total three-column strip shown above the daily list
/// and on the summary view.
class MonthSummaryStrip extends StatelessWidget {
  const MonthSummaryStrip({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final income = TransactionsState.sumIncome(transactions);
    final expense = TransactionsState.sumExpense(transactions);

    return Row(
      children: [
        Expanded(
          child: AmountStat(
            label: 'transactions.income'.tr(),
            value: formatMoney(income),
            color: context.colors.tertiary,
          ),
        ),
        Expanded(
          child: AmountStat(
            label: 'transactions.exp_short'.tr(),
            value: formatMoney(expense),
            color: context.colors.error,
          ),
        ),
        Expanded(
          child: AmountStat(
            label: 'transactions.total'.tr(),
            value: formatMoney(income - expense),
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}
