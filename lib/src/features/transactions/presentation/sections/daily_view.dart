import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/month_summary_strip.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_row.dart';

/// Daily ledger view: month totals strip over day-grouped transaction cards.
class DailyView extends StatelessWidget {
  const DailyView({
    super.key,
    required this.transactions,
    required this.onTapTransaction,
  });

  /// The month's transactions, newest first (already filtered by the hub).
  final List<Transaction> transactions;
  final ValueChanged<Transaction> onTapTransaction;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'transactions.empty_title'.tr(),
        subtitle: 'transactions.empty_subtitle'.tr(),
      );
    }

    final groups = TransactionsState.groupByDay(transactions);
    final locale = context.locale.toString();

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
      children: [
        MonthSummaryStrip(transactions: transactions),
        SizedBox(height: 18.h),
        for (final entry in groups.entries) ...[
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              AppDate.dayHeader(entry.key, locale),
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          TransactionCard(
            rows: [
              for (final t in entry.value)
                TransactionRow(
                  transaction: t,
                  onTap: () => onTapTransaction(t),
                ),
            ],
          ),
          SizedBox(height: 18.h),
        ],
      ],
    );
  }
}
