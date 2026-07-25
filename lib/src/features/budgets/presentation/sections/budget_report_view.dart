import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/budgets/presentation/cubits/budgets_cubit.dart';
import 'package:mony_time/src/features/budgets/presentation/widgets/budget_progress_row.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';

/// The Reports "Budget" sub-tab: remaining amount for the month with overall
/// progress, then how much is left per budgeted category.
class BudgetReportView extends StatelessWidget {
  const BudgetReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetsState = context.watch<BudgetsCubit>().state;
    final transactionsState = context.watch<TransactionsCubit>().state;

    final now = DateTime.now();
    final month = transactionsState.monthOf(DateTime(now.year, now.month));
    final spent = TransactionsState.sumExpense(month);
    final remaining = (kMonthlyBudget - spent).clamp(0, kMonthlyBudget);
    final fraction = spent / kMonthlyBudget;

    double spentOn(String category) => TransactionsState.sumExpense(
        month.where((t) => t.categoryLabel == category).toList());

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
      children: [
        AppSoftCard(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'budgets.remaining_monthly'.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 11.8.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                moneyWithSymbol(remaining),
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 25.5.sp,
                  letterSpacing: -0.26,
                ),
              ),
              SizedBox(height: 10.h),
              GradientProgressBar(fraction: fraction, height: 12.h),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'budgets.spent_amount'.tr(
                          namedArgs: {'amount': moneyWithSymbol(spent)}),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                  Text(
                    '${(fraction * 100).round()}%',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        if (budgetsState.activeExpense.isNotEmpty)
          AppSoftCard(
            child: Column(
              children: [
                for (var i = 0; i < budgetsState.activeExpense.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.outlineVariant,
                    ),
                  Builder(builder: (context) {
                    final budget = budgetsState.activeExpense[i];
                    final categorySpent = spentOn(budget.categoryLabel);
                    final left = budget.limit - categorySpent;
                    return BudgetProgressRow(
                      budget: budget,
                      spent: categorySpent,
                      showStatus: false,
                      trailing: left >= 0
                          ? 'budgets.left'.tr(
                              namedArgs: {'amount': formatMoney(left)})
                          : 'budgets.over'.tr(),
                    );
                  }),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
