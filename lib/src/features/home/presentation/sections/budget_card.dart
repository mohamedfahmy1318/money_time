import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/models/home_data.dart';

/// Gradient hero card summarising the month's budget, income and spend.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget});

  final HomeBudget budget;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 159.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.6),
            offset: Offset(0, 18.h),
            blurRadius: 30.r,
            spreadRadius: -14.r,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30.r,
            right: -30.r,
            child: Container(
              width: 140.r,
              height: 140.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.budget_month'.tr(namedArgs: {'month': budget.month}),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                // Expanded + scaleDown fills the space between the label and
                // the pills (replacing a Spacer) while yielding sub-pixel slack
                // instead of overflowing when font metrics push the line taller.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.topStart,
                    child: Text(
                      budget.total,
                      maxLines: 1,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 31.sp,
                        letterSpacing: -0.62,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'home.income'.tr(),
                        value: budget.income,
                        up: true,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _StatPill(
                        label: 'home.spent'.tr(),
                        value: budget.spent,
                        up: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.up,
  });

  final String label;
  final String value;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${up ? '↑' : '↓'} $label',
            maxLines: 1,
            style: context.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11.sp,
              height: 1.1,
            ),
          ),
          SizedBox(height: 2.h),
          // Scale down rather than wrap when the live amount grows long.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: context.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                height: 1.1,
                letterSpacing: -0.16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
