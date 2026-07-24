import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/models/report_data.dart';

/// Grouped income-vs-expense bars per month, with a legend on top and month
/// labels beneath. Income is drawn in the tertiary blue, expense in error red.
class IncomeExpenseBarChart extends StatelessWidget {
  const IncomeExpenseBarChart({
    super.key,
    required this.data,
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final List<MonthlyFlow> data;
  final String incomeTotal;
  final String expenseTotal;

  @override
  Widget build(BuildContext context) {
    final maxValue = data
        .expand((m) => [m.income, m.expense])
        .fold<double>(1, (a, b) => a > b ? a : b);

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      child: Column(
        children: [
          Row(
            children: [
              _Legend(
                color: context.colors.tertiary,
                label: 'reports.income'.tr(),
                amount: incomeTotal,
              ),
              const Spacer(),
              _Legend(
                color: context.colors.error,
                label: 'reports.expense'.tr(),
                amount: expenseTotal,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 96.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final m in data)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Bar(fraction: m.income / maxValue, color: context.colors.tertiary),
                        SizedBox(width: 4.w),
                        _Bar(fraction: m.expense / maxValue, color: context.colors.error),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              for (final m in data)
                Expanded(
                  child: Text(
                    m.month,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5.sp,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: fraction.clamp(0.04, 1.0),
      child: Container(
        width: 7.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.vertical(top: Radius.circular(3.r)),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.amount});

  final Color color;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8.r, height: 8.r, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6.w),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$label '),
              TextSpan(text: amount, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            style: context.textTheme.labelMedium?.copyWith(color: color, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }
}
