import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';

/// A budget row: emoji chip, category label with a status hint, a
/// status-coloured progress bar and a trailing amount.
///
/// Two trailing styles cover the designs: the Budget tab shows the spent
/// amount, the reports budget view shows how much is left — pass [trailing].
class BudgetProgressRow extends StatelessWidget {
  const BudgetProgressRow({
    super.key,
    required this.budget,
    required this.spent,
    required this.trailing,
    this.showStatus = true,
  });

  final Budget budget;
  final double spent;

  /// Pre-formatted trailing text (`E£ 450` / `220 left`).
  final String trailing;

  /// Show the `· on track` / `· 82%` / `· over!` hint next to the label.
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final status = budget.statusFor(spent);
    final fraction = budget.isSet ? spent / budget.limit : 0.0;

    final (statusColor, statusText, gradient) = switch (status) {
      BudgetStatus.onTrack => (
          context.colors.primary,
          'budgets.on_track'.tr(),
          AppGradients.primaryButton,
        ),
      BudgetStatus.warning => (
          AppColors.amberDeep,
          '${(fraction * 100).round()}%',
          const LinearGradient(
            colors: [AppColors.amber, AppColors.amberDeep],
          ),
        ),
      BudgetStatus.over => (
          context.colors.error,
          'budgets.over'.tr(),
          LinearGradient(
            colors: [AppColors.errorLight, context.colors.error],
          ),
        ),
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child:
                Text(budget.categoryEmoji, style: TextStyle(fontSize: 13.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        budget.categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    if (showStatus) ...[
                      SizedBox(width: 6.w),
                      Text(
                        '· $statusText',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 7.h),
                // Status-coloured fill on the shared track geometry.
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: Stack(
                    children: [
                      Container(height: 6.h, color: context.colors.surface),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: Container(
                          height: 6.h,
                          decoration: BoxDecoration(gradient: gradient),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            trailing,
            style: context.textTheme.labelMedium?.copyWith(
              color: status == BudgetStatus.over
                  ? context.colors.error
                  : context.colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 12.7.sp,
              letterSpacing: -0.13,
            ),
          ),
        ],
      ),
    );
  }
}
