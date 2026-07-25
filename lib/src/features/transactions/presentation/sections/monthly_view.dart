import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';

/// Monthly ledger view: each month of the selected year with its income and
/// expense totals. Tapping a month jumps to its daily list.
class MonthlyView extends StatelessWidget {
  const MonthlyView({
    super.key,
    required this.year,
    required this.state,
    required this.onPickMonth,
  });

  final int year;
  final TransactionsState state;
  final ValueChanged<DateTime> onPickMonth;

  @override
  Widget build(BuildContext context) {
    final months = state.monthsWith(year);

    if (months.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'transactions.empty_title'.tr(),
        subtitle: 'transactions.empty_year'.tr(),
      );
    }

    final locale = context.locale.toString();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
      itemCount: months.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: context.colors.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final month = months[index];
        final list = state.monthOf(month);
        final lastDay = DateTime(month.year, month.month + 1, 0).day;
        final mm = month.month.toString().padLeft(2, '0');

        return InkWell(
          onTap: () => onPickMonth(month),
          child: SizedBox(
            height: 59.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppDate.monthAbbr(month, locale),
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.6.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '01–$lastDay/$mm',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontSize: 9.4.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        moneyWithSymbol(TransactionsState.sumIncome(list)),
                        style: _amountStyle(context, context.colors.tertiary),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        moneyWithSymbol(TransactionsState.sumExpense(list)),
                        style: _amountStyle(context, context.colors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle? _amountStyle(BuildContext context, Color color) =>
      context.textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 13.sp,
        letterSpacing: -0.13,
      );
}
