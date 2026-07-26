import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/budgets/presentation/cubits/budgets_cubit.dart';
import 'package:mony_time/src/features/budgets/presentation/sections/budget_hero_card.dart';
import 'package:mony_time/src/features/budgets/presentation/widgets/budget_progress_row.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';

/// Budget bottom-nav tab: the monthly ceiling hero, the settings entry, the
/// per-category budget list with live spend progress, and the add-budget CTA.
class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetsState = context.watch<BudgetsCubit>().state;
    final transactionsState = context.watch<TransactionsCubit>().state;

    final now = DateTime.now();
    final month = transactionsState.monthOf(DateTime(now.year, now.month));
    final spent = TransactionsState.sumExpense(month);
    final locale = context.locale.toString();

    double spentOn(String category) => TransactionsState.sumExpense(
        month.where((t) => t.categoryLabel == category).toList());

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'budgets.title'.tr(),
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                Text(
                  AppDate.monthYear(now, locale),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Expanded(
            child: budgetsState.isLoading ||
                    budgetsState.status == BudgetsStatus.initial
                ? const AppLoading()
                : ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 100.h),
                    children: [
                      BudgetHeroCard(spent: spent),
                      SizedBox(height: 16.h),
                      AppSoftCard(
                        child: InkWell(
                          onTap: () =>
                              context.push(AppRoutes.budgetSettings),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.w, vertical: 16.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '⚙️ ${'budgets.setting'.tr()}',
                                    style: context.textTheme.titleSmall
                                        ?.copyWith(
                                      color: context.colors.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5.sp,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18.sp,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      if (budgetsState.activeExpense.isNotEmpty)
                        AppSoftCard(
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < budgetsState.activeExpense.length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: context.colors.outlineVariant,
                                  ),
                                Builder(builder: (context) {
                                  final budget =
                                      budgetsState.activeExpense[i];
                                  final categorySpent =
                                      spentOn(budget.categoryLabel);
                                  return InkWell(
                                    onTap: () => context.guardedPush(
                                      AppRoutes.budgetEdit,
                                      extra: budget,
                                    ),
                                    child: BudgetProgressRow(
                                      budget: budget,
                                      spent: categorySpent,
                                      trailing:
                                          moneyWithSymbol(categorySpent),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      SizedBox(height: 20.h),
                      AppGradientButton(
                        label: '＋ ${'budgets.add_budget'.tr()}',
                        onPressed: () =>
                            context.push(AppRoutes.budgetSettings),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
