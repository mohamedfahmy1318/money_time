import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/models/report_data.dart';
import 'package:mony_time/src/features/reports/presentation/widgets/category_progress_row.dart';
import 'package:mony_time/src/features/reports/presentation/widgets/income_expense_bar_chart.dart';

/// Stats sub-tab: the income/expense bar chart over the category breakdown.
class ReportsStatsView extends StatelessWidget {
  const ReportsStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = ReportSampleData.categorySpend;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
      children: [
        const AppSoftCard(
          child: IncomeExpenseBarChart(
            data: ReportSampleData.monthlyFlow,
            incomeTotal: ReportSampleData.incomeTotal,
            expenseTotal: ReportSampleData.expenseTotal,
          ),
        ),
        SizedBox(height: 16.h),
        AppSoftCard(
          child: Column(
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: context.colors.outlineVariant),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  child: CategoryProgressRow(data: categories[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
