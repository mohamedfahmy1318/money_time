import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/models/home_data.dart';
import 'package:mony_time/src/features/home/presentation/sections/budget_card.dart';
import 'package:mony_time/src/features/home/presentation/sections/categories_section.dart';
import 'package:mony_time/src/features/home/presentation/sections/home_header.dart';
import 'package:mony_time/src/features/home/presentation/sections/recent_section.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';

/// The Home dashboard tab: greeting header over the live budget summary,
/// categories and the latest ledger activity.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionsCubit>().state;
    final now = DateTime.now();
    final month = state.monthOf(DateTime(now.year, now.month));
    final locale = context.locale.toString();

    final budget = HomeBudget(
      month: AppDate.monthName(now, locale),
      total: HomeSampleData.budgetTotal,
      income: moneyWithSymbol(TransactionsState.sumIncome(month)),
      spent: moneyWithSymbol(TransactionsState.sumExpense(month)),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const HomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 100.h),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.totalStats),
                    child: BudgetCard(budget: budget),
                  ),
                  SizedBox(height: 24.h),
                  RecentSection(
                    transactions: state.latest(3),
                    onSeeAll: () => context.push(AppRoutes.transactions),
                    onTapTransaction: (t) => context.push(
                      AppRoutes.transactionDetail,
                      extra: t,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  const CategoriesSection(
                    categories: HomeSampleData.categories,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
