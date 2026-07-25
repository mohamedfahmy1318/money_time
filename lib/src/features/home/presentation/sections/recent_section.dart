import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/widgets/section_header.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_row.dart';

/// "Recent" header plus a card listing the latest transactions from the
/// app-wide ledger.
class RecentSection extends StatelessWidget {
  const RecentSection({
    super.key,
    required this.transactions,
    required this.onSeeAll,
    required this.onTapTransaction,
  });

  final List<Transaction> transactions;
  final VoidCallback onSeeAll;
  final ValueChanged<Transaction> onTapTransaction;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();

    return Column(
      children: [
        SectionHeader(
          title: 'home.recent'.tr(),
          action: 'home.see_all'.tr(),
          onAction: onSeeAll,
        ),
        SizedBox(height: 12.h),
        if (transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              'transactions.empty_title'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          )
        else
          TransactionCard(
            rows: [
              for (final t in transactions)
                TransactionRow(
                  transaction: t,
                  subtitle: AppDate.shortDate(t.date, locale),
                  onTap: () => onTapTransaction(t),
                ),
            ],
          ),
      ],
    );
  }
}
