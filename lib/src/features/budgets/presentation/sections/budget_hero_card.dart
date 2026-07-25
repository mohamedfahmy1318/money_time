import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/widgets/percent_ring.dart';

/// Emerald hero card on the Budget tab: monthly ceiling, spent so far and a
/// white consumption ring.
class BudgetHeroCard extends StatelessWidget {
  const BudgetHeroCard({super.key, required this.spent});

  final double spent;

  @override
  Widget build(BuildContext context) {
    final fraction = spent / kMonthlyBudget;

    return Container(
      height: 164.h,
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
            padding: EdgeInsets.all(18.r),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'budgets.monthly_budget'.tr(),
                        style: context.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          moneyWithSymbol(kMonthlyBudget),
                          style: context.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 26.sp,
                            letterSpacing: -0.54,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'budgets.spent'.tr(),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          moneyWithSymbol(spent),
                          style: context.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.6.sp,
                            letterSpacing: -0.16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Align(
                  alignment: Alignment.bottomRight,
                  child: PercentRing(
                    fraction: fraction,
                    color: Colors.white,
                    size: 66.r,
                    trackColor: Colors.white.withValues(alpha: 0.25),
                    labelColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
